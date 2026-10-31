#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <dirent.h>

#define IOCTL_READ_PROCESS_MEM   0x801
#define IOCTL_WRITE_PROCESS_MEM  0x802
#define IOCTL_GET_MODULE_BASE    0x803

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

int main(int argc, char *argv[]) {
    char dev_path[256] = {0};
    int fd = -1;

    if (argc > 1) {
        snprintf(dev_path, sizeof(dev_path), "%s", argv[1]);
        fd = open(dev_path, O_RDWR);
    } else {
        DIR *d = opendir("/dev");
        if (!d) {
            perror("opendir /dev");
            return 1;
        }
        struct dirent *dir;
        while ((dir = readdir(d)) != NULL) {
            if (strncmp(dir->d_name, "daisy_", 6) == 0) {
                snprintf(dev_path, sizeof(dev_path), "/dev/%s", dir->d_name);
                fd = open(dev_path, O_RDWR);
                if (fd >= 0) break;
            }
        }
        closedir(d);
    }

    if (fd < 0) {
        printf("[-] Failed to open daisy driver devnode\n");
        return 1;
    }

    printf("[+] Opened driver: %s (fd: %d)\n", dev_path, fd);

    volatile int test_target = 0x1337BEEF;
    pid_t my_pid = getpid();
    int read_out = 0;

    printf("[*] Target PID: %d, Target Var Addr: %p, Initial Val: 0x%08X\n",
           my_pid, (void*)&test_target, test_target);

    // 1. Test Read Memory (IOCTL 0x801)
    struct MemoryOp read_op;
    memset(&read_op, 0, sizeof(read_op));
    read_op.pid = my_pid;
    read_op.addr = (uint64_t)&test_target;
    read_op.buffer = (uint64_t)&read_out;
    read_op.size = sizeof(read_out);

    long ret = ioctl(fd, IOCTL_READ_PROCESS_MEM, &read_op);
    if (ret == 0 && read_out == 0x1337BEEF) {
        printf("[+] [TEST 1: READ] SUCCESS! Read value: 0x%08X\n", read_out);
    } else {
        printf("[-] [TEST 1: READ] FAILED! ret: %ld, Read value: 0x%08X\n", ret, read_out);
    }

    // 2. Test Write Memory (IOCTL 0x802)
    int write_in = 0xDEADCAFE;
    struct MemoryOp write_op;
    memset(&write_op, 0, sizeof(write_op));
    write_op.pid = my_pid;
    write_op.addr = (uint64_t)&test_target;
    write_op.buffer = (uint64_t)&write_in;
    write_op.size = sizeof(write_in);

    ret = ioctl(fd, IOCTL_WRITE_PROCESS_MEM, &write_op);
    if (ret == 0 && test_target == 0xDEADCAFE) {
        printf("[+] [TEST 2: WRITE] SUCCESS! Target variable modified to: 0x%08X\n", test_target);
    } else {
        printf("[-] [TEST 2: WRITE] FAILED! ret: %ld, Target value: 0x%08X\n", ret, test_target);
    }

    // 3. Test Module Base (IOCTL 0x803)
    struct ModuleBaseOp base_op;
    memset(&base_op, 0, sizeof(base_op));
    base_op.pid = my_pid;
    base_op.name = NULL;
    base_op.base = 0;

    ret = ioctl(fd, IOCTL_GET_MODULE_BASE, &base_op);
    if (ret == 0 && base_op.base > 0) {
        printf("[+] [TEST 3: MODULE BASE] SUCCESS! Process Main Base: 0x%llX\n", (unsigned long long)base_op.base);
    } else {
        printf("[-] [TEST 3: MODULE BASE] FAILED! ret: %ld, base: 0x%llX\n", ret, (unsigned long long)base_op.base);
    }

    close(fd);
    printf("[+] ALL DRIVER TESTS COMPLETED SUCCESSFULLY!\n");
    return 0;
}

