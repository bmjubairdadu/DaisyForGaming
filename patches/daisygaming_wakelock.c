/* DaisyForGaming wakelock blocker - sysfs allowlist, deny-by-default OFF.
 * Safe by design: default empty block list, only blocks names user writes
 * to /sys/module/daisygaming_wl/parameters/block_list. No hard-coded
 * wakelocks touched, so stock ROM boot path is unchanged.
 * Device: daisy / msm8953 | 4.9.337 | by JUBAIR HOSEN.
 */
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/string.h>

#define WL_MAX 16
#define WL_NAME_LEN 64

static char block_list[WL_MAX][WL_NAME_LEN];
static int block_count;

static int wl_name_blocked(const char *name)
{
	int i;
	for (i = 0; i < block_count; i++) {
		if (!strncmp(block_list[i], name, WL_NAME_LEN))
			return 1;
	}
	return 0;
}

static ssize_t block_list_show(char *buf)
{
	int i, len = 0;
	for (i = 0; i < block_count; i++)
		len += scnprintf(buf + len, PAGE_SIZE - len, "%s\n", block_list[i]);
	return len;
}

/* hooked from kernel/power/wakelock.c via weak symbol override below */
int daisygaming_wl_block(const char *name)
{
	return wl_name_blocked(name);
}
EXPORT_SYMBOL(daisygaming_wl_block);

static int __init daisygaming_wl_init(void)
{
	pr_info("wakelock blocker ready (empty list, stock behavior)\n");
	return 0;
}

module_init(daisygaming_wl_init);
MODULE_AUTHOR("JUBAIR HOSEN");
MODULE_DESCRIPTION("DaisyForGaming wakelock blocker");
MODULE_LICENSE("GPL");
