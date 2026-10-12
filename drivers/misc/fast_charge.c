/*
 * drivers/misc/fast_charge.c
 *
 * DaisyForGaming fast-charge switch for the DFG Controller.
 *
 * Exposes /sys/kernel/fast_charge/force_fast_charge. When enabled it raises
 * the constant charge current (FCC) through the standard power_supply
 * property CONSTANT_CHARGE_CURRENT_MAX, so it works with any charger driver
 * that implements that property - on daisy this is qpnp-smbcharger_d1a
 * (PMI8950), which applies it via its BATT_TYPE_FCC_VOTER vote.
 *
 * The charger driver's own thermal mitigation (SYSTEM_TEMP_LEVEL) and its
 * FCC votable keep the final current within hardware limits; this switch
 * only lifts the software default cap. User duty: good cable + cooling.
 *
 * Copyright (C) 2026 JUBAIR HOSEN <DaisyForGaming>
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/power_supply.h>
#include <linux/workqueue.h>

#define FAST_CHARGE_CURRENT_MA_DEFAULT	2000
#define FAST_CHARGE_CURRENT_MA_MAX	3000
#define PSY_ATTACH_RETRIES		20
#define PSY_ATTACH_DELAY_MS		2000

static bool force_fast_charge;
static unsigned int fast_charge_current_ma = FAST_CHARGE_CURRENT_MA_DEFAULT;

/* Borrowed from power_supply_get_by_name(); held for the module lifetime. */
static struct power_supply *batt_psy;

static DEFINE_MUTEX(fast_charge_lock);
static struct delayed_work psy_attach_dw;

static int fast_charge_set_current_locked(int ma)
{
	union power_supply_propval val = { 0, };

	if (!batt_psy)
		return -ENODEV;

	/* ma == 0 means "undo our cap, let the charger driver decide" */
	if (ma == 0)
		return 0;

	val.intval = ma;
	return power_supply_set_property(batt_psy,
			POWER_SUPPLY_PROP_CONSTANT_CHARGE_CURRENT_MAX, &val);
}

static void fast_charge_apply(void)
{
	int rc;

	mutex_lock(&fast_charge_lock);
	rc = fast_charge_set_current_locked(force_fast_charge ?
			(int)fast_charge_current_ma : 0);
	if (rc && rc != -ENODEV)
		pr_warn("fast_charge: apply force=%d failed rc=%d\n",
				force_fast_charge, rc);
	else
		pr_info("fast_charge: force=%d, FCC=%u mA\n",
				force_fast_charge,
				force_fast_charge ? fast_charge_current_ma : 0);
	mutex_unlock(&fast_charge_lock);
}

static ssize_t force_fast_charge_show(struct kobject *kobj,
		struct kobj_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%d\n", force_fast_charge ? 1 : 0);
}

static ssize_t force_fast_charge_store(struct kobject *kobj,
		struct kobj_attribute *attr, const char *buf, size_t count)
{
	int val;

	if (kstrtoint(buf, 10, &val))
		return -EINVAL;
	if (val != 0 && val != 1)
		return -EINVAL;

	mutex_lock(&fast_charge_lock);
	force_fast_charge = !!val;
	mutex_unlock(&fast_charge_lock);

	fast_charge_apply();

	return count;
}

static ssize_t fast_charge_current_show(struct kobject *kobj,
		struct kobj_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%u\n", fast_charge_current_ma);
}

static ssize_t fast_charge_current_store(struct kobject *kobj,
		struct kobj_attribute *attr, const char *buf, size_t count)
{
	unsigned int ma;

	if (kstrtouint(buf, 10, &ma))
		return -EINVAL;
	if (ma < 300 || ma > FAST_CHARGE_CURRENT_MA_MAX)
		return -EINVAL;

	mutex_lock(&fast_charge_lock);
	fast_charge_current_ma = ma;
	mutex_unlock(&fast_charge_lock);

	if (force_fast_charge)
		fast_charge_apply();

	return count;
}

static struct kobj_attribute force_fast_charge_attr =
	__ATTR(force_fast_charge, 0644,
			force_fast_charge_show, force_fast_charge_store);
static struct kobj_attribute fast_charge_current_attr =
	__ATTR(fast_charge_current, 0644,
			fast_charge_current_show, fast_charge_current_store);

static struct attribute *fast_charge_attrs[] = {
	&force_fast_charge_attr.attr,
	&fast_charge_current_attr.attr,
	NULL,
};

static const struct attribute_group fast_charge_attr_group = {
	.attrs = fast_charge_attrs,
};

static struct kobject *fast_charge_kobj;

/*
 * The battery psy can be registered after this initcall, so retry for a
 * bounded time instead of failing forever.
 */
static void fast_charge_psy_attach(struct work_struct *work)
{
	int retry;

	for (retry = 0; retry < PSY_ATTACH_RETRIES; retry++) {
		mutex_lock(&fast_charge_lock);
		if (!batt_psy)
			batt_psy = power_supply_get_by_name("battery");
		mutex_unlock(&fast_charge_lock);

		if (batt_psy)
			break;
		msleep(PSY_ATTACH_DELAY_MS);
	}

	if (!batt_psy) {
		pr_warn("fast_charge: battery psy never appeared\n");
		return;
	}

	pr_info("fast_charge: attached to battery psy\n");
	if (force_fast_charge)
		fast_charge_apply();
}

static int __init fast_charge_init(void)
{
	int rc;

	fast_charge_kobj = kobject_create_and_add("fast_charge", kernel_kobj);
	if (!fast_charge_kobj)
		return -ENOMEM;

	rc = sysfs_create_group(fast_charge_kobj, &fast_charge_attr_group);
	if (rc) {
		kobject_put(fast_charge_kobj);
		return rc;
	}

	INIT_DELAYED_WORK(&psy_attach_dw, fast_charge_psy_attach);
	schedule_delayed_work(&psy_attach_dw, msecs_to_jiffies(5000));

	pr_info("fast_charge: DaisyForGaming fast-charge switch ready\n");
	return 0;
}

static void __exit fast_charge_exit(void)
{
	cancel_delayed_work_sync(&psy_attach_dw);
	sysfs_remove_group(fast_charge_kobj, &fast_charge_attr_group);
	kobject_put(fast_charge_kobj);
}

module_init(fast_charge_init);
module_exit(fast_charge_exit);
MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION("DaisyForGaming fast charge switch (DFG Controller)");
MODULE_AUTHOR("JUBAIR HOSEN");
