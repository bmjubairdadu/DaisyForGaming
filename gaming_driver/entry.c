#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include <linux/sched.h>
#include <linux/pid.h>
#include <linux/mm.h>
#include <linux/io.h>
#include <linux/slab.h>
#include <linux/random.h>
#include <linux/dcache.h>
#include <linux/path.h>
#include <linux/string.h>
#ifdef CONFIG_COMPAT
#include <linux/compat.h>
#endif

struct MemoryOp {
    pid_t pid;
    uint32_t _pad;
    uint64_t addr;
    uint64_t buffer;
    size_t size;
};

struct ModuleBaseOp {
    pid_t pid;
    uint32_t _pad;
    char *name;
    uint64_t base;
};

static char *devicename = NULL;
static char string[10];
static dev_t mem_tool_dev_t;
static struct cdev memdev;
static struct class *mem_tool_class = NULL;

static char *get_rand_str(void) {
    static const char charset[] = "BYNBBYNBBYNBBYNBABCDEFG";
    int i;
    for (i = 0; i < 6; i++) {
        int r;
        get_random_bytes(&r, sizeof(r));
        if (r < 0) r = -r;
        string[i] = charset[r % 23];
    }
    string[6] = '\0';
    return string;
}

static char *kmem_strcasestr(const char *haystack, const char *needle) {
    size_t n_len;
    if (!haystack || !needle) return NULL;
    n_len = strlen(needle);
    if (!n_len) return (char *)haystack;
    while (*haystack) {
        if (!strncasecmp(haystack, needle, n_len))
            return (char *)haystack;
        haystack++;
    }
    return NULL;
}

static inline uint64_t translate_linear_address(struct mm_struct *mm, uint64_t va) {
    pgd_t *pgd;
    pud_t *pud;
    pmd_t *pmd;
    pte_t *pte;

    if (!mm) return 0;

    pgd = pgd_offset(mm, va);
    if (pgd_none(*pgd) || pgd_bad(*pgd)) return 0;

    pud = pud_offset(pgd, va);
    if (pud_none(*pud) || pud_bad(*pud)) return 0;

    pmd = pmd_offset(pud, va);
    if (pmd_none(*pmd) || pmd_bad(*pmd)) return 0;

    pte = pte_offset_kernel(pmd, va);
    if (!pte || !pte_present(*pte)) return 0;

    return (pte_val(*pte) & PHYS_MASK & PAGE_MASK) | (va & ~PAGE_MASK);
}

static inline size_t read_physical_address(uint64_t pa, void __user *user_buf, size_t size) {
    unsigned long pfn = pa >> PAGE_SHIFT;
    void *kaddr;

    if (!pfn_valid(pfn)) return 0;

    kaddr = phys_to_virt(pa);
    if (copy_to_user(user_buf, kaddr, size))
        return 0;

    return size;
}

static inline size_t write_physical_address(uint64_t pa, const void __user *user_buf, size_t size) {
    unsigned long pfn = pa >> PAGE_SHIFT;
    void *kaddr;

    if (!pfn_valid(pfn)) return 0;

    kaddr = phys_to_virt(pa);
    if (copy_from_user(kaddr, user_buf, size))
        return 0;

#ifdef __aarch64__
    /* ARM64 hardware cache maintenance: clean D-cache and invalidate I-cache */
    asm volatile(
        "dc cvau, %0\n"
        "dsb ish\n"
        "ic ivau, %0\n"
        "dsb ish\n"
        "isb\n"
        : : "r"(kaddr) : "memory"
    );
#endif

    return size;
}

static int read_process_memory(pid_t pid, uint64_t addr, void __user *buf, size_t size) {
    struct task_struct *task;
    struct pid *pid_struct;
    struct mm_struct *mm;
    size_t bytes_read = 0;

    pid_struct = find_get_pid(pid);
    if (!pid_struct) return 0;

    task = get_pid_task(pid_struct, PIDTYPE_PID);
    put_pid(pid_struct);
    if (!task) return 0;

    mm = get_task_mm(task);
    if (!mm) {
        put_task_struct(task);
        return 0;
    }

    down_read(&mm->mmap_sem);
    while (size > 0) {
        uint64_t cur_page_offset = addr & ~PAGE_MASK;
        size_t chunk = PAGE_SIZE - cur_page_offset;
        uint64_t pa;

        if (chunk > size) chunk = size;

        pa = translate_linear_address(mm, addr);
        if (!pa) {
            struct page *page = NULL;
            long gup_res = get_user_pages_remote(task, mm, addr, 1, FOLL_FORCE, &page, NULL);
            if (gup_res > 0 && page) {
                put_page(page);
                pa = translate_linear_address(mm, addr);
            }
        }
        if (!pa) break;

        if (read_physical_address(pa, (void __user *)((uintptr_t)buf + bytes_read), chunk) != chunk)
            break;

        bytes_read += chunk;
        addr += chunk;
        size -= chunk;
    }
    up_read(&mm->mmap_sem);

    mmput(mm);
    put_task_struct(task);
    return bytes_read;
}

static int write_process_memory(pid_t pid, uint64_t addr, const void __user *buf, size_t size) {
    struct task_struct *task;
    struct pid *pid_struct;
    struct mm_struct *mm;
    size_t bytes_written = 0;

    pid_struct = find_get_pid(pid);
    if (!pid_struct) return 0;

    task = get_pid_task(pid_struct, PIDTYPE_PID);
    put_pid(pid_struct);
    if (!task) return 0;

    mm = get_task_mm(task);
    if (!mm) {
        put_task_struct(task);
        return 0;
    }

    down_read(&mm->mmap_sem);
    while (size > 0) {
        uint64_t cur_page_offset = addr & ~PAGE_MASK;
        size_t chunk = PAGE_SIZE - cur_page_offset;
        uint64_t pa;

        if (chunk > size) chunk = size;

        pa = translate_linear_address(mm, addr);
        if (!pa) {
            struct page *page = NULL;
            long gup_res = get_user_pages_remote(task, mm, addr, 1, FOLL_FORCE | FOLL_WRITE, &page, NULL);
            if (gup_res > 0 && page) {
                put_page(page);
                pa = translate_linear_address(mm, addr);
            }
        }
        if (!pa) break;

        if (write_physical_address(pa, (const void __user *)((uintptr_t)buf + bytes_written), chunk) != chunk)
            break;

        bytes_written += chunk;
        addr += chunk;
        size -= chunk;
    }
    up_read(&mm->mmap_sem);

    mmput(mm);
    put_task_struct(task);
    return bytes_written;
}

static uint64_t get_module_base(pid_t pid, const char *module_name) {
    struct task_struct *task;
    struct pid *pid_struct;
    struct mm_struct *mm;
    struct vm_area_struct *vma;
    uint64_t base_addr = 0;
    char *buf;

    pid_struct = find_get_pid(pid);
    if (!pid_struct) return 0;

    task = get_pid_task(pid_struct, PIDTYPE_PID);
    put_pid(pid_struct);
    if (!task) return 0;

    mm = get_task_mm(task);
    put_task_struct(task);
    if (!mm) return 0;

    buf = kmalloc(1024, GFP_KERNEL);

    down_read(&mm->mmap_sem);
    if (!module_name || module_name[0] == '\0') {
        for (vma = mm->mmap; vma; vma = vma->vm_next) {
            if (vma->vm_file && (vma->vm_flags & VM_EXEC)) {
                base_addr = vma->vm_start;
                break;
            }
        }
        if (!base_addr && mm->mmap) {
            base_addr = mm->mmap->vm_start;
        }
    } else {
        for (vma = mm->mmap; vma; vma = vma->vm_next) {
            if (vma->vm_file && buf) {
                char *path = d_path(&vma->vm_file->f_path, buf, 1024);
                if (!IS_ERR(path) && kmem_strcasestr(path, module_name)) {
                    base_addr = vma->vm_start;
                    break;
                }
            }
        }
    }
    up_read(&mm->mmap_sem);

    if (buf) kfree(buf);
    mmput(mm);
    return base_addr;
}

static long dispatch_ioctl(struct file *file, unsigned int cmd, unsigned long arg) {
    switch (cmd) {
        case 0x801: {
            struct MemoryOp req;
            if (copy_from_user(&req, (void __user *)arg, sizeof(req)))
                return -EFAULT;
            if (read_process_memory(req.pid, req.addr, (void __user *)req.buffer, req.size))
                return 0;
            return -EIO;
        }
        case 0x802: {
            struct MemoryOp req;
            if (copy_from_user(&req, (void __user *)arg, sizeof(req)))
                return -EFAULT;
            if (write_process_memory(req.pid, req.addr, (const void __user *)req.buffer, req.size))
                return 0;
            return -EIO;
        }
        case 0x803: {
            struct ModuleBaseOp req;
            char name_buf[256] = {0};

            if (copy_from_user(&req, (void __user *)arg, sizeof(req)))
                return -EFAULT;

            if (req.name) {
                if (strncpy_from_user(name_buf, req.name, sizeof(name_buf) - 1) < 0) {
                    name_buf[0] = '\0';
                }
                name_buf[sizeof(name_buf) - 1] = '\0';
            }

            req.base = get_module_base(req.pid, name_buf);

            if (copy_to_user((void __user *)arg, &req, sizeof(req)))
                return -EFAULT;
            return 0;
        }
        default:
            return -EINVAL;
    }
}

#ifdef CONFIG_COMPAT
static long dispatch_compat_ioctl(struct file *file, unsigned int cmd, unsigned long arg) {
    return dispatch_ioctl(file, cmd, (unsigned long)compat_ptr(arg));
}
#endif

static int dispatch_open(struct inode *inode, struct file *file) {
    file->private_data = &memdev;
    return 0;
}

static int dispatch_close(struct inode *inode, struct file *file) {
    return 0;
}

static const struct file_operations dispatch_functions = {
    .owner = THIS_MODULE,
    .open = dispatch_open,
    .release = dispatch_close,
    .unlocked_ioctl = dispatch_ioctl,
#ifdef CONFIG_COMPAT
    .compat_ioctl = dispatch_compat_ioctl,
#endif
};

static char *mem_devnode(struct device *dev, umode_t *mode) {
    if (mode)
        *mode = 0666;
    return NULL;
}

static int __init init_module_entry(void) {
    int ret;

    devicename = get_rand_str();

    ret = alloc_chrdev_region(&mem_tool_dev_t, 0, 1, devicename);
    if (ret < 0)
        return ret;

    cdev_init(&memdev, &dispatch_functions);
    memdev.owner = THIS_MODULE;
    ret = cdev_add(&memdev, mem_tool_dev_t, 1);
    if (ret < 0) {
        unregister_chrdev_region(mem_tool_dev_t, 1);
        return ret;
    }

    mem_tool_class = class_create(THIS_MODULE, devicename);
    if (IS_ERR(mem_tool_class)) {
        ret = PTR_ERR(mem_tool_class);
        cdev_del(&memdev);
        unregister_chrdev_region(mem_tool_dev_t, 1);
        return ret;
    }
    mem_tool_class->devnode = mem_devnode;

    if (IS_ERR(device_create(mem_tool_class, NULL, mem_tool_dev_t, NULL, devicename))) {
        ret = -EINVAL;
        class_destroy(mem_tool_class);
        cdev_del(&memdev);
        unregister_chrdev_region(mem_tool_dev_t, 1);
        return ret;
    }

    /* Pure RT Stealth: unlink from sysfs and module list */
    list_del_init(&THIS_MODULE->list);
    kobject_del(&THIS_MODULE->mkobj.kobj);

    return 0;
}

static void __exit cleanup_module_entry(void) {
    device_destroy(mem_tool_class, mem_tool_dev_t);
    class_destroy(mem_tool_class);
    cdev_del(&memdev);
    unregister_chrdev_region(mem_tool_dev_t, 1);
}

module_init(init_module_entry);
module_exit(cleanup_module_entry);
MODULE_LICENSE("GPL");
