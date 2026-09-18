#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include <linux/slab.h>

#define DAISY_IOC_MAGIC		'd'
#define DAISY_IOC_GET_VERSION	_IOR(DAISY_IOC_MAGIC, 1, int)
#define DAISY_IOC_ECHO		_IOWR(DAISY_IOC_MAGIC, 2, char[64])
#define DAISY_VERSION		1

static dev_t dev_number;
static struct cdev daisy_cdev;
static struct class *daisy_class;

static int daisy_open(struct inode *inode, struct file *filp)
{
	pr_info("DaisyForGaming: device opened\n");
	return 0;
}

static int daisy_release(struct inode *inode, struct file *filp)
{
	pr_info("DaisyForGaming: device closed\n");
	return 0;
}

static long daisy_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
	int version = DAISY_VERSION;
	char kbuf[64];

	switch (cmd) {
	case DAISY_IOC_GET_VERSION:
		if (copy_to_user((int __user *)arg, &version, sizeof(version)))
			return -EFAULT;
		return 0;
	case DAISY_IOC_ECHO:
		if (copy_from_user(kbuf, (char __user *)arg, sizeof(kbuf)))
			return -EFAULT;
		if (copy_to_user((char __user *)arg, kbuf, sizeof(kbuf)))
			return -EFAULT;
		return 0;
	default:
		return -ENOTTY;
	}
}

static const struct file_operations daisy_fops = {
	.owner		= THIS_MODULE,
	.open		= daisy_open,
	.release	= daisy_release,
	.unlocked_ioctl	= daisy_ioctl,
};

static int __init daisy_hello_init(void)
{
	int ret;

	ret = alloc_chrdev_region(&dev_number, 0, 1, "daisyctl");
	if (ret < 0) {
		pr_err("DaisyForGaming: alloc_chrdev_region failed\n");
		return ret;
	}
	cdev_init(&daisy_cdev, &daisy_fops);
	ret = cdev_add(&daisy_cdev, dev_number, 1);
	if (ret < 0) {
		pr_err("DaisyForGaming: cdev_add failed\n");
		goto err_cdev;
	}
	daisy_class = class_create(THIS_MODULE, "daisyctl");
	if (IS_ERR(daisy_class)) {
		ret = PTR_ERR(daisy_class);
		pr_err("DaisyForGaming: class_create failed\n");
		goto err_class;
	}
	if (IS_ERR(device_create(daisy_class, NULL, dev_number, NULL,
				 "daisyctl"))) {
		pr_err("DaisyForGaming: device_create failed\n");
		ret = -ENODEV;
		goto err_device;
	}
	pr_info("DaisyForGaming: hello module loaded! (/dev/daisyctl)\n");
	return 0;

err_device:
	class_destroy(daisy_class);
err_class:
	cdev_del(&daisy_cdev);
err_cdev:
	unregister_chrdev_region(dev_number, 1);
	return ret;
}

static void __exit daisy_hello_exit(void)
{
	device_destroy(daisy_class, dev_number);
	class_destroy(daisy_class);
	cdev_del(&daisy_cdev);
	unregister_chrdev_region(dev_number, 1);
	pr_info("DaisyForGaming: hello module unloaded.\n");
}

module_init(daisy_hello_init);
module_exit(daisy_hello_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("JUBAIR HOSEN");
MODULE_DESCRIPTION("DaisyForGaming loader-app template driver (safe skeleton)");
