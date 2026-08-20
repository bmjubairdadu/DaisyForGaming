// SPDX-License-Identifier: GPL-2.0
/*
 * DaisyForGaming: memory pressure controls
 *
 *   /sys/kernel/mm/swappiness      - vm.swappiness (clamped 0-200, boot
 *                                    default 100, zRAM-appropriate)
 *   /sys/kernel/mm/lmk_aggressive  - in-kernel LMK moderate minfree tuning
 *                                    (0/1, dormant until enabled)
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>

extern int vm_swappiness;
#ifdef CONFIG_ANDROID_LOW_MEMORY_KILLER
extern void daisy_lmk_set_aggressive(bool on);
#endif

static int daisy_lmk_aggressive;

static ssize_t swappiness_show(struct kobject *kobj,
			       struct kobj_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%d\n", vm_swappiness);
}

static ssize_t swappiness_store(struct kobject *kobj,
				struct kobj_attribute *attr, const char *buf,
				size_t count)
{
	unsigned int val;
	int ret;

	ret = kstrtouint(buf, 10, &val);
	if (ret)
		return ret;

	vm_swappiness = min(val, 200U);
	return count;
}

static struct kobj_attribute swappiness_attr =
	__ATTR(swappiness, 0644, swappiness_show, swappiness_store);

static ssize_t lmk_aggressive_show(struct kobject *kobj,
				   struct kobj_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%d\n", daisy_lmk_aggressive);
}

static ssize_t lmk_aggressive_store(struct kobject *kobj,
				    struct kobj_attribute *attr,
				    const char *buf, size_t count)
{
	unsigned int val;
	int ret;

	ret = kstrtouint(buf, 10, &val);
	if (ret)
		return ret;

	if (val > 1)
		return -EINVAL;

#ifdef CONFIG_ANDROID_LOW_MEMORY_KILLER
	daisy_lmk_set_aggressive(val ? true : false);
	daisy_lmk_aggressive = val ? 1 : 0;
#else
	return -ENOTSUPP;
#endif
	return count;
}

static struct kobj_attribute lmk_aggressive_attr =
	__ATTR(lmk_aggressive, 0644, lmk_aggressive_show,
	       lmk_aggressive_store);

static struct attribute *daisy_mm_attrs[] = {
	&swappiness_attr.attr,
	&lmk_aggressive_attr.attr,
	NULL,
};
ATTRIBUTE_GROUPS(daisy_mm);

static int __init daisy_mm_init(void)
{
	int ret;

	vm_swappiness = 100;

	ret = sysfs_create_groups(mm_kobj, daisy_mm_groups);
	if (ret)
		pr_err("daisy_mm: failed to create /sys/kernel/mm nodes: %d\n",
		       ret);

	return ret;
}
device_initcall(daisy_mm_init);
