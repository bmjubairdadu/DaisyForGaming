#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

static int __init daisy_hello_init(void)
{
	pr_info("DaisyForGaming: hello module loaded!\n");
	return 0;
}

static void __exit daisy_hello_exit(void)
{
	pr_info("DaisyForGaming: hello module unloaded.\n");
}

module_init(daisy_hello_init);
module_exit(daisy_hello_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("JUBAIR HOSEN");
MODULE_DESCRIPTION("DaisyForGaming module pipeline test");
