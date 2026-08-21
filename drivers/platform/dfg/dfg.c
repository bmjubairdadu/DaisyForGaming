// SPDX-License-Identifier: GPL-2.0
/*
 * DaisyForGaming control interface
 *
 * Exposes a runtime control interface for the DaisyForGaming kernel
 * under /sys/devices/platform/dfg/:
 *
 *   profile          - "performance" | "balanced" | "battery"
 *   cpu_min_freq     - per-policy minimum frequency (kHz)
 *   cpu_max_freq     - per-policy maximum frequency (kHz)
 *   governor         - cpufreq governor, applied to all policies
 *   io_scheduler     - block I/O elevator of the boot disk
 *   thermal_override - bool; allow the "performance" profile past the
 *                      soft thermal limit (hard limit always applies)
 *   boost_ms         - one-shot frequency boost duration (ms)
 *   deep_idle        - bool; disable deep cpuidle states (gaming mode)
 *   thermal_events   - ring buffer of the last thermal events
 *   thermal_limits   - current soft/hard limits and thermal state
 *   vendor_compat    - result of the vendor/platform runtime check
 *
 * The default boot profile is chosen by CONFIG_DFG_DEFAULT_PERF and is
 * applied from an early initcall path (before userspace starts). All
 * tunables remain writable at runtime by root and, with the shipped
 * SELinux policy, by the DFG-Controller app.
 *
 * Thermal safety: this driver implements its own watchdog on top of the
 * regular kernel thermal framework (tsens/qpnp). Soft and hard limits
 * are enforced by clamping the CPU frequency ceiling. CONFIG_DFG_*
 * values are compile-time defaults; the hard limit can never be
 * disabled by userspace.
 */
#define pr_fmt(fmt) "dfg: " fmt

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/string.h>
#include <linux/sysfs.h>
#include <linux/device.h>
#include <linux/platform_device.h>
#include <linux/cpu.h>
#include <linux/cpufreq.h>
#include <linux/cpuidle.h>
#include <linux/elevator.h>
#include <linux/genhd.h>
#include <linux/thermal.h>
#include <linux/of.h>
#include <linux/workqueue.h>
#include <linux/spinlock.h>
#include <linux/timekeeping.h>
#include <linux/jiffies.h>

#define DFG_PROFILE_MAX		(32)
#define DFG_GOVERNOR_MAX	(24)
#define DFG_IOSCHED_MAX		(24)
#define DFG_ZONE_NAME_MAX	(24)
#define DFG_ACTION_MAX		(24)
#define DFG_MAX_ZONES		(32)
#define DFG_THERM_EVENTS_MAX	(16)
#define DFG_PROFILES_MAX	(3)

/* ------------------------------------------------------------------ */
/* Compile-time defaults (see drivers/platform/dfg/Kconfig)            */

#define DFG_PERF_MIN_FREQ	CONFIG_DFG_PERF_MIN_FREQ
#define DFG_PERF_MAX_FREQ	CONFIG_DFG_PERF_MAX_FREQ
#define DFG_BAL_MIN_FREQ	CONFIG_DFG_BAL_MIN_FREQ
#define DFG_BAL_MAX_FREQ	CONFIG_DFG_BAL_MAX_FREQ
#define DFG_BAT_MIN_FREQ	CONFIG_DFG_BAT_MIN_FREQ
#define DFG_BAT_MAX_FREQ	CONFIG_DFG_BAT_MAX_FREQ
#define DFG_THERM_SOFT_LIMIT	CONFIG_DFG_THERM_SOFT_LIMIT
#define DFG_THERM_HARD_LIMIT	CONFIG_DFG_THERM_HARD_LIMIT
#define DFG_THERM_HYSTERESIS	CONFIG_DFG_THERM_HYSTERESIS
#define DFG_THERM_SAFE_FREQ	CONFIG_DFG_THERMAL_SAFE_FREQ
#define DFG_THERM_SAFE_MIN	CONFIG_DFG_THERMAL_SAFE_MIN_FREQ
#define DFG_THERM_SAMPLE_MS	CONFIG_DFG_THERMAL_SAMPLE_MS
#define DFG_BOOT_BOOST_MS	CONFIG_DFG_BOOT_BOOST_MS

#define DFG_IO_AVAILABLE					\
	"bfq cfq deadline noop"

/* ------------------------------------------------------------------ */
/* Profiles                                                            */

struct dfg_profile {
	const char *name;
	const char *governor;
	const char *io_sched;
	unsigned int min_khz;
	unsigned int max_khz;
};

static const struct dfg_profile dfg_profiles[DFG_PROFILES_MAX] = {
	{
		.name = "performance",
		.governor = CONFIG_DFG_PERF_GOVERNOR,
		.io_sched = CONFIG_DFG_PERF_IOSCHED,
		.min_khz = DFG_PERF_MIN_FREQ,
		.max_khz = DFG_PERF_MAX_FREQ,
	},
	{
		.name = "balanced",
		.governor = CONFIG_DFG_BAL_GOVERNOR,
		.io_sched = CONFIG_DFG_BAL_IOSCHED,
		.min_khz = DFG_BAL_MIN_FREQ,
		.max_khz = DFG_BAL_MAX_FREQ,
	},
	{
		.name = "battery",
		.governor = CONFIG_DFG_BAT_GOVERNOR,
		.io_sched = CONFIG_DFG_BAT_IOSCHED,
		.min_khz = DFG_BAT_MIN_FREQ,
		.max_khz = DFG_BAT_MAX_FREQ,
	},
};

/* ------------------------------------------------------------------ */
/* State                                                               */

struct dfg_therm_event {
	u64 ts;
	char zone[DFG_ZONE_NAME_MAX];
	int temp_mc;
	char action[DFG_ACTION_MAX];
};

struct dfg_zone {
	char name[DFG_ZONE_NAME_MAX];
	struct thermal_zone_device *tz;
};

static struct dfg_zone dfg_zones[DFG_MAX_ZONES];
static int dfg_zone_count;

static struct dfg_therm_event dfg_therm_events[DFG_THERM_EVENTS_MAX];
static int dfg_therm_events_idx;
static int dfg_therm_events_count;
static spinlock_t dfg_therm_lock;

static char dfg_active_governor[DFG_GOVERNOR_MAX];
static char dfg_active_iosched[DFG_IOSCHED_MAX];
static struct dfg_profile dfg_active;
static int dfg_active_profile;
static bool dfg_probe_done;
static bool dfg_fallback_active;
static bool dfg_thermal_override;
static bool dfg_deep_idle;
static unsigned int dfg_boost_ms;
static unsigned int dfg_max_temp_mc;
static bool dfg_soft_active;
static bool dfg_hard_active;

static struct delayed_work dfg_thermal_work;
static struct delayed_work dfg_boost_work;
static struct delayed_work dfg_boot_work;
static struct notifier_block dfg_cpufreq_nb;

static struct platform_device *dfg_pdev;
static struct platform_driver dfg_platform_driver;

static void dfg_recompute_limits(void);

static const char *dfg_therm_zone_label(void)
{
	return dfg_zone_count ? dfg_zones[0].name : "-";
}

/* ------------------------------------------------------------------ */
/* Thermal event ring buffer                                           */

static void dfg_therm_log(const char *zone, int temp_mc, const char *action)
{
	struct dfg_therm_event *ev;
	unsigned long flags;

	spin_lock_irqsave(&dfg_therm_lock, flags);
	ev = &dfg_therm_events[dfg_therm_events_idx];
	ev->ts = ktime_get_seconds();
	strlcpy(ev->zone, zone, sizeof(ev->zone));
	ev->temp_mc = temp_mc;
	strlcpy(ev->action, action, sizeof(ev->action));
	dfg_therm_events_idx = (dfg_therm_events_idx + 1) %
			       DFG_THERM_EVENTS_MAX;
	if (dfg_therm_events_count < DFG_THERM_EVENTS_MAX)
		dfg_therm_events_count++;
	spin_unlock_irqrestore(&dfg_therm_lock, flags);

	pr_info("thermal event: zone=%s temp=%d.%03dC action=%s\n",
		zone, temp_mc / 1000, temp_mc % 1000, action);
}

/* ------------------------------------------------------------------ */
/* cpufreq helpers                                                     */

static void dfg_apply_limits(unsigned int min_khz, unsigned int max_khz)
{
	unsigned int cpu;

	get_online_cpus();
	for_each_online_cpu(cpu) {
		struct cpufreq_policy *policy = cpufreq_cpu_get(cpu);

		if (!policy)
			continue;
		if (policy->cpu == cpu) {
			policy->user_policy.min = min_khz;
			policy->user_policy.max = max_khz;
			cpufreq_update_policy(cpu);
		}
		cpufreq_cpu_put(policy);
	}
	put_online_cpus();
}

static void dfg_apply_governor(const char *governor)
{
	unsigned int cpu;
	int ret = 0;

	get_online_cpus();
	for_each_online_cpu(cpu) {
		struct cpufreq_policy *policy = cpufreq_cpu_get(cpu);

		if (!policy)
			continue;
		if (policy->cpu == cpu) {
			int r = cpufreq_set_policy_governor(policy, governor);

			if (r && !ret)
				ret = r;
		}
		cpufreq_cpu_put(policy);
	}
	put_online_cpus();

	if (ret)
		pr_warn("governor: %s not available or rejected (%d)\n",
			governor, ret);
}

/* ------------------------------------------------------------------ */
/* Block I/O scheduler                                                 */

static int dfg_block_match(struct device *dev, const void *data)
{
	return strcmp(dev_name(dev), (const char *)data) == 0;
}

static struct device *dfg_get_boot_disk_dev(void)
{
	return class_find_device(&block_class, NULL, "mmcblk0",
				 dfg_block_match);
}

static void dfg_apply_io_scheduler(const char *name)
{
	struct device *dev = dfg_get_boot_disk_dev();
	struct gendisk *disk;

	if (!dev) {
		pr_warn("io_scheduler: boot disk not found\n");
		return;
	}
	disk = dev_to_disk(dev);
	if (elevator_change(disk->queue, name))
		pr_warn("io_scheduler: %s unavailable on boot disk\n", name);
	else
		pr_info("io_scheduler: switched boot disk to %s\n", name);
	put_device(dev);
}

/* ------------------------------------------------------------------ */
/* Deep idle (gaming mode)                                             */

static void dfg_set_deep_idle(bool disable)
{
	unsigned int cpu;

	if (!IS_ENABLED(CONFIG_CPU_IDLE))
		return;

	get_online_cpus();
#ifdef CONFIG_CPU_IDLE
	for_each_online_cpu(cpu) {
		struct cpuidle_device *dev = per_cpu(cpuidle_devices, cpu);

		if (!dev)
			continue;
		if (disable)
			cpuidle_disable_device(dev);
		else
			cpuidle_enable_device(dev);
	}
#endif
	put_online_cpus();
	dfg_deep_idle = disable;
	pr_info("deep idle states %s\n", disable ? "disabled" : "enabled");
}

/* ------------------------------------------------------------------ */
/* Boost                                                               */

static void dfg_boost_work_fn(struct work_struct *work)
{
	dfg_recompute_limits();
}

static void dfg_start_boost(unsigned int ms)
{
	unsigned int cpu;
	unsigned int max_khz = 0;

	if (!ms)
		return;

	get_online_cpus();
	for_each_online_cpu(cpu) {
		struct cpufreq_policy *policy = cpufreq_cpu_get(cpu);

		if (policy) {
			max_khz = max(max_khz, policy->cpuinfo.max_freq);
			cpufreq_cpu_put(policy);
		}
	}
	put_online_cpus();

	if (!max_khz) {
		pr_warn("boost: no cpufreq policies available\n");
		return;
	}

	if (dfg_hard_active) {
		pr_warn("boost: denied while hard thermal limit is active\n");
		return;
	}

	cancel_delayed_work_sync(&dfg_boost_work);
	dfg_apply_limits(max_khz, max_khz);
	mod_delayed_work(system_wq, &dfg_boost_work,
			 msecs_to_jiffies(ms));
	pr_info("boost: full frequency boost for %u ms\n", ms);
}

/* ------------------------------------------------------------------ */
/* Profile / limits                                                    */

static void dfg_recompute_limits(void)
{
	unsigned int min_khz = dfg_active.min_khz;
	unsigned int max_khz = dfg_active.max_khz;

	if (dfg_hard_active) {
		max_khz = min(max_khz, DFG_THERM_SAFE_FREQ);
		min_khz = min(min_khz, DFG_THERM_SAFE_MIN);
	} else if (dfg_soft_active && !dfg_thermal_override) {
		max_khz = min(max_khz, DFG_THERM_SAFE_FREQ);
	}

	dfg_apply_limits(min_khz, max_khz);
}

static int dfg_set_profile(const char *name, bool from_boot)
{
	int i;

	for (i = 0; i < DFG_PROFILES_MAX; i++) {
		if (!strcasecmp(name, dfg_profiles[i].name))
			break;
	}
	if (i == DFG_PROFILES_MAX)
		return -EINVAL;

	if (dfg_fallback_active &&
	    !strcasecmp(name, dfg_profiles[0].name)) {
		pr_warn("profile: performance denied on unsupported platform\n");
		return -EPERM;
	}

	dfg_active_profile = i;
	dfg_active = dfg_profiles[i];
	dfg_active.governor = dfg_active_governor;
	dfg_active.io_sched = dfg_active_iosched;
	strlcpy(dfg_active_governor, dfg_profiles[i].governor,
		sizeof(dfg_active_governor));
	strlcpy(dfg_active_iosched, dfg_profiles[i].io_sched,
		sizeof(dfg_active_iosched));

	dfg_apply_governor(dfg_active.governor);
	dfg_apply_io_scheduler(dfg_active.io_sched);
	dfg_recompute_limits();

	pr_info("profile set to %s (min=%u kHz max=%u kHz gov=%s io=%s)%s\n",
		dfg_active.name, dfg_active.min_khz, dfg_active.max_khz,
		dfg_active.governor, dfg_active.io_sched,
		from_boot ? " [boot]" : "");
	if (!from_boot)
		dfg_therm_log("-", dfg_max_temp_mc, "PROFILE");

	return 0;
}

/* ------------------------------------------------------------------ */
/* Thermal watchdog                                                    */

static void dfg_thermal_enum_zones(void)
{
	struct device_node *tz_np, *child;

	if (dfg_zone_count)
		return;

	tz_np = of_find_node_by_path("/thermal-zones");
	if (!tz_np) {
		pr_warn("thermal: no /thermal-zones node in DT\n");
		return;
	}

	for_each_child_of_node(tz_np, child) {
		struct thermal_zone_device *tz;
		const char *name = child->name;

		if (dfg_zone_count >= DFG_MAX_ZONES)
			break;

		tz = thermal_zone_get_zone_by_name(name);
		if (IS_ERR(tz))
			continue;

		strlcpy(dfg_zones[dfg_zone_count].name, name,
			sizeof(dfg_zones[dfg_zone_count].name));
		dfg_zones[dfg_zone_count].tz = tz;
		dfg_zone_count++;
	}
	of_node_put(tz_np);

	pr_info("thermal: monitoring %d zone(s)\n", dfg_zone_count);
}

static void dfg_thermal_work_fn(struct work_struct *work)
{
	unsigned int max_temp = 0;
	int i;

	dfg_thermal_enum_zones();

	for (i = 0; i < dfg_zone_count; i++) {
		int temp = 0;

		if (thermal_zone_get_temp(dfg_zones[i].tz, &temp))
			continue;
		if (temp > max_temp)
			max_temp = temp;
	}

	dfg_max_temp_mc = max_temp;

	if (max_temp >= DFG_THERM_HARD_LIMIT) {
		if (!dfg_hard_active) {
			dfg_hard_active = true;
			dfg_soft_active = false;
			if (dfg_thermal_override) {
				dfg_thermal_override = false;
				dfg_therm_log(dfg_therm_zone_label(), max_temp,
					      "OVERRIDE_RESET");
				pr_warn("thermal: hard limit hit, override reset\n");
			}
			dfg_therm_log(dfg_therm_zone_label(), max_temp,
				      "HARD_LIMIT");
			pr_warn("thermal: HARD limit %d mC reached (%d mC), forcing safe frequencies\n",
				DFG_THERM_HARD_LIMIT, max_temp);
			dfg_recompute_limits();
		}
	} else if (max_temp >= DFG_THERM_SOFT_LIMIT) {
		if (dfg_thermal_override) {
			if (!dfg_soft_active && !dfg_hard_active) {
				dfg_soft_active = true;
				dfg_therm_log(dfg_therm_zone_label(), max_temp,
					      "OVERRIDE_ACTIVE");
				pr_info("thermal: soft limit exceeded but override active, keeping performance\n");
			}
		} else if (!dfg_soft_active && !dfg_hard_active) {
			dfg_soft_active = true;
			dfg_therm_log(dfg_therm_zone_label(), max_temp,
				      "THROTTLE");
			pr_warn("thermal: soft limit %d mC reached (%d mC), throttling\n",
				DFG_THERM_SOFT_LIMIT, max_temp);
			dfg_recompute_limits();
		}
	} else {
		if (dfg_hard_active &&
		    max_temp < DFG_THERM_HARD_LIMIT - DFG_THERM_HYSTERESIS) {
			dfg_hard_active = false;
			dfg_soft_active = false;
			dfg_therm_log(dfg_therm_zone_label(), max_temp,
				      "RECOVER");
			pr_info("thermal: recovered, restoring profile limits\n");
			dfg_recompute_limits();
		} else if (dfg_soft_active &&
			   max_temp < DFG_THERM_SOFT_LIMIT -
				      DFG_THERM_HYSTERESIS) {
			dfg_soft_active = false;
			dfg_therm_log(dfg_therm_zone_label(), max_temp,
				      "RECOVER");
			pr_info("thermal: recovered, restoring profile limits\n");
			dfg_recompute_limits();
		}
	}

	mod_delayed_work(system_wq, &dfg_thermal_work,
			 msecs_to_jiffies(DFG_THERM_SAMPLE_MS));
}

/* ------------------------------------------------------------------ */
/* Boot application (default performance mode)                         */

static void dfg_boot_work_fn(struct work_struct *work)
{
	if (!dfg_probe_done)
		return;

	if (IS_ENABLED(CONFIG_DFG_DEFAULT_PERF)) {
		dfg_set_profile("performance", true);
		dfg_therm_log("-", dfg_max_temp_mc, "BOOT_PERF");
		if (IS_ENABLED(CONFIG_DFG_PERF_DISABLE_DEEP_IDLE))
			dfg_set_deep_idle(true);
	} else {
		dfg_set_profile("balanced", true);
	}

	if (DFG_BOOT_BOOST_MS)
		dfg_start_boost(DFG_BOOT_BOOST_MS);
}

static int dfg_cpufreq_policy_notifier(struct notifier_block *nb,
				       unsigned long event, void *data)
{
	struct cpufreq_policy *policy = data;

	if (event == CPUFREQ_START && dfg_probe_done) {
		unsigned int min_khz = dfg_active.min_khz;
		unsigned int max_khz = dfg_active.max_khz;

		if (dfg_hard_active) {
			max_khz = min(max_khz, DFG_THERM_SAFE_FREQ);
			min_khz = min(min_khz, DFG_THERM_SAFE_MIN);
		} else if (dfg_soft_active && !dfg_thermal_override) {
			max_khz = min(max_khz, DFG_THERM_SAFE_FREQ);
		}

		policy->user_policy.min = min_khz;
		policy->user_policy.max = max_khz;
		policy->min = min_khz;
		policy->max = max_khz;
	}

	return NOTIFY_OK;
}

/* ------------------------------------------------------------------ */
/* Vendor compatibility runtime check                                  */

static bool dfg_vendor_compat_check(void)
{
	struct device_node *root = of_find_node_by_path("/");
	const char *compat = NULL;
	bool ok = false;

	if (!root)
		return false;

	of_property_read_string_index(root, "compatible", 0, &compat);
	of_node_put(root);

	if (!compat)
		return false;

	if (strstr(compat, "qcom,msm8953") || strstr(compat, "qcom,msm8937"))
		ok = true;

	if (!ok) {
		dfg_fallback_active = true;
		pr_warn("vendor_compat: incompatible platform \"%s\", falling back to balanced profile\n",
			compat);
		dfg_therm_log("-", 0, "VENDOR_FALLBACK");
	} else {
		pr_info("vendor_compat: platform \"%s\" supported\n", compat);
	}

	return ok;
}

/* ------------------------------------------------------------------ */
/* sysfs interface                                                     */

static ssize_t profile_show(struct device *dev,
			    struct device_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%s\n", dfg_active.name);
}

static ssize_t profile_store(struct device *dev,
			     struct device_attribute *attr,
			     const char *buf, size_t count)
{
	char name[DFG_PROFILE_MAX];
	int ret;

	if (sscanf(buf, "%31s", name) != 1)
		return -EINVAL;

	ret = dfg_set_profile(name, false);
	if (ret)
		return ret;

	return count;
}
static DEVICE_ATTR_RW(profile);

static ssize_t cpu_min_freq_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%u\n", dfg_active.min_khz);
}

static ssize_t cpu_min_freq_store(struct device *dev,
				  struct device_attribute *attr,
				  const char *buf, size_t count)
{
	unsigned int val;
	int ret;

	ret = kstrtouint(buf, 10, &val);
	if (ret)
		return ret;
	if (!val)
		return -EINVAL;

	dfg_active.min_khz = val;
	dfg_recompute_limits();
	return count;
}
static DEVICE_ATTR_RW(cpu_min_freq);

static ssize_t cpu_max_freq_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%u\n", dfg_active.max_khz);
}

static ssize_t cpu_max_freq_store(struct device *dev,
				  struct device_attribute *attr,
				  const char *buf, size_t count)
{
	unsigned int val;
	int ret;

	ret = kstrtouint(buf, 10, &val);
	if (ret)
		return ret;
	if (!val)
		return -EINVAL;

	dfg_active.max_khz = val;
	dfg_recompute_limits();
	return count;
}
static DEVICE_ATTR_RW(cpu_max_freq);

static ssize_t governor_show(struct device *dev,
			     struct device_attribute *attr, char *buf)
{
	struct cpufreq_policy *policy = cpufreq_cpu_get(0);
	ssize_t ret;

	if (!policy)
		return -ENODEV;

	if (policy->governor)
		ret = scnprintf(buf, PAGE_SIZE, "%s\n",
				policy->governor->name);
	else
		ret = scnprintf(buf, PAGE_SIZE, "none\n");

	cpufreq_cpu_put(policy);
	return ret;
}

static ssize_t governor_store(struct device *dev,
			      struct device_attribute *attr,
			      const char *buf, size_t count)
{
	char name[DFG_GOVERNOR_MAX];

	if (sscanf(buf, "%23s", name) != 1)
		return -EINVAL;

	strlcpy(dfg_active_governor, name, sizeof(dfg_active_governor));
	dfg_apply_governor(dfg_active_governor);
	return count;
}
static DEVICE_ATTR_RW(governor);

static ssize_t io_scheduler_show(struct device *dev,
				 struct device_attribute *attr, char *buf)
{
	struct device *bdev = dfg_get_boot_disk_dev();
	struct gendisk *disk;
	ssize_t ret;

	if (!bdev)
		return scnprintf(buf, PAGE_SIZE, "unknown [%s available]\n",
				 DFG_IO_AVAILABLE);

	disk = dev_to_disk(bdev);
	if (disk->queue && disk->queue->elevator)
		ret = scnprintf(buf, PAGE_SIZE, "%s [%s available]\n",
				disk->queue->elevator->type->elevator_name,
				DFG_IO_AVAILABLE);
	else
		ret = scnprintf(buf, PAGE_SIZE, "unknown [%s available]\n",
				DFG_IO_AVAILABLE);
	put_device(bdev);

	return ret;
}

static ssize_t io_scheduler_store(struct device *dev,
				  struct device_attribute *attr,
				  const char *buf, size_t count)
{
	char name[DFG_IOSCHED_MAX];

	if (sscanf(buf, "%23s", name) != 1)
		return -EINVAL;

	strlcpy(dfg_active_iosched, name, sizeof(dfg_active_iosched));
	dfg_apply_io_scheduler(dfg_active_iosched);
	return count;
}
static DEVICE_ATTR_RW(io_scheduler);

static ssize_t thermal_override_show(struct device *dev,
				     struct device_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%d\n", dfg_thermal_override);
}

static ssize_t thermal_override_store(struct device *dev,
				      struct device_attribute *attr,
				      const char *buf, size_t count)
{
	bool val;
	int ret;

	ret = kstrtobool(buf, &val);
	if (ret)
		return ret;

	if (dfg_fallback_active)
		return -EPERM;

	if (val && dfg_hard_active) {
		dfg_therm_log(dfg_therm_zone_label(), dfg_max_temp_mc,
			      "OVERRIDE_DENIED");
		pr_warn("thermal: override denied, hard limit active\n");
		return -EPERM;
	}

	dfg_thermal_override = val;
	dfg_recompute_limits();
	pr_info("thermal_override %s\n", val ? "enabled" : "disabled");
	return count;
}
static DEVICE_ATTR_RW(thermal_override);

static ssize_t boost_ms_show(struct device *dev,
			     struct device_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%u\n", dfg_boost_ms);
}

static ssize_t boost_ms_store(struct device *dev,
			      struct device_attribute *attr,
			      const char *buf, size_t count)
{
	unsigned int val;
	int ret;

	ret = kstrtouint(buf, 10, &val);
	if (ret)
		return ret;
	if (val > 60000)
		return -EINVAL;

	dfg_boost_ms = val;
	dfg_start_boost(dfg_boost_ms);
	return count;
}
static DEVICE_ATTR_RW(boost_ms);

static ssize_t deep_idle_show(struct device *dev,
			      struct device_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%d\n", dfg_deep_idle);
}

static ssize_t deep_idle_store(struct device *dev,
			       struct device_attribute *attr,
			       const char *buf, size_t count)
{
	bool val;
	int ret;

	ret = kstrtobool(buf, &val);
	if (ret)
		return ret;

	dfg_set_deep_idle(val);
	return count;
}
static DEVICE_ATTR_RW(deep_idle);

static ssize_t thermal_events_show(struct device *dev,
				   struct device_attribute *attr, char *buf)
{
	ssize_t len = 0;
	unsigned long flags;
	int i, idx;

	spin_lock_irqsave(&dfg_therm_lock, flags);
	for (i = 0; i < dfg_therm_events_count; i++) {
		struct dfg_therm_event *ev;

		idx = (dfg_therm_events_idx - 1 - i + DFG_THERM_EVENTS_MAX) %
		      DFG_THERM_EVENTS_MAX;
		ev = &dfg_therm_events[idx];
		len += scnprintf(buf + len, PAGE_SIZE - len,
				 "%llu %s %d %s\n",
				 (unsigned long long)ev->ts, ev->zone,
				 ev->temp_mc, ev->action);
	}
	spin_unlock_irqrestore(&dfg_therm_lock, flags);

	return len;
}
static DEVICE_ATTR_RO(thermal_events);

static ssize_t thermal_limits_show(struct device *dev,
				   struct device_attribute *attr, char *buf)
{
	const char *state = "ok";

	if (dfg_hard_active)
		state = "hard-limit";
	else if (dfg_soft_active)
		state = "throttled";

	return scnprintf(buf, PAGE_SIZE,
			 "soft_limit=%d hard_limit=%d hysteresis=%d "
			 "safe_max=%u safe_min=%u sample_ms=%d state=%s "
			 "max_temp=%d override=%d\n",
			 DFG_THERM_SOFT_LIMIT, DFG_THERM_HARD_LIMIT,
			 DFG_THERM_HYSTERESIS, DFG_THERM_SAFE_FREQ,
			 DFG_THERM_SAFE_MIN, DFG_THERM_SAMPLE_MS, state,
			 dfg_max_temp_mc, dfg_thermal_override);
}
static DEVICE_ATTR_RO(thermal_limits);

static ssize_t vendor_compat_show(struct device *dev,
				  struct device_attribute *attr, char *buf)
{
	struct device_node *root = of_find_node_by_path("/");
	const char *compat = NULL;
	ssize_t ret;

	if (root) {
		of_property_read_string_index(root, "compatible", 0, &compat);
		of_node_put(root);
	}

	if (dfg_fallback_active)
		ret = scnprintf(buf, PAGE_SIZE, "fallback: %s\n",
				compat ? compat : "unknown");
	else
		ret = scnprintf(buf, PAGE_SIZE, "ok: %s\n",
				compat ? compat : "unknown");

	return ret;
}
static DEVICE_ATTR_RO(vendor_compat);

static struct attribute *dfg_attrs[] = {
	&dev_attr_profile.attr,
	&dev_attr_cpu_min_freq.attr,
	&dev_attr_cpu_max_freq.attr,
	&dev_attr_governor.attr,
	&dev_attr_io_scheduler.attr,
	&dev_attr_thermal_override.attr,
	&dev_attr_boost_ms.attr,
	&dev_attr_deep_idle.attr,
	&dev_attr_thermal_events.attr,
	&dev_attr_thermal_limits.attr,
	&dev_attr_vendor_compat.attr,
	NULL,
};
ATTRIBUTE_GROUPS(dfg);

/* ------------------------------------------------------------------ */
/* Platform driver                                                     */

static int dfg_probe(struct platform_device *pdev)
{
	dfg_thermal_enum_zones();

	dfg_thermal_override = false;
	dfg_deep_idle = false;
	dfg_boost_ms = 0;
	dfg_soft_active = false;
	dfg_hard_active = false;
	dfg_active_profile = 1;
	dfg_active = dfg_profiles[1];
	dfg_active.governor = dfg_active_governor;
	dfg_active.io_sched = dfg_active_iosched;
	strlcpy(dfg_active_governor, dfg_profiles[1].governor,
		sizeof(dfg_active_governor));
	strlcpy(dfg_active_iosched, dfg_profiles[1].io_sched,
		sizeof(dfg_active_iosched));

	dfg_vendor_compat_check();

	dfg_probe_done = true;

	mod_delayed_work(system_wq, &dfg_boot_work,
			 msecs_to_jiffies(1000));

	pr_info("control interface ready at /sys/devices/platform/dfg\n");
	return 0;
}

static int dfg_remove(struct platform_device *pdev)
{
	dfg_probe_done = false;
	cancel_delayed_work_sync(&dfg_thermal_work);
	cancel_delayed_work_sync(&dfg_boost_work);
	cancel_delayed_work_sync(&dfg_boot_work);
	return 0;
}

static struct platform_driver dfg_platform_driver = {
	.probe = dfg_probe,
	.remove = dfg_remove,
	.driver = {
		.name = "dfg",
		.owner = THIS_MODULE,
		.dev_groups = dfg_groups,
	},
};

static int __init dfg_init(void)
{
	int ret;

	spin_lock_init(&dfg_therm_lock);
	INIT_DELAYED_WORK(&dfg_thermal_work, dfg_thermal_work_fn);
	INIT_DELAYED_WORK(&dfg_boost_work, dfg_boost_work_fn);
	INIT_DELAYED_WORK(&dfg_boot_work, dfg_boot_work_fn);

	dfg_cpufreq_nb.notifier_call = dfg_cpufreq_policy_notifier;
	cpufreq_register_notifier(&dfg_cpufreq_nb, CPUFREQ_POLICY_NOTIFIER);

	ret = platform_driver_register(&dfg_platform_driver);
	if (ret)
		return ret;

	dfg_pdev = platform_device_register_simple("dfg", -1, NULL, 0);
	if (IS_ERR(dfg_pdev)) {
		ret = PTR_ERR(dfg_pdev);
		platform_driver_unregister(&dfg_platform_driver);
		return ret;
	}

	return 0;
}
device_initcall(dfg_init);

static void __exit dfg_exit(void)
{
	cancel_delayed_work_sync(&dfg_thermal_work);
	cancel_delayed_work_sync(&dfg_boost_work);
	cancel_delayed_work_sync(&dfg_boot_work);
	platform_device_unregister(dfg_pdev);
	platform_driver_unregister(&dfg_platform_driver);
}
module_exit(dfg_exit);

module_param_named(profile, dfg_active_profile, int, 0444);
module_param(thermal_override, bool, 0644);
module_param(boost_ms, uint, 0644);
module_param(deep_idle, bool, 0644);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("DaisyForGaming");
MODULE_DESCRIPTION("DaisyForGaming control interface for Xiaomi Mi A2 Lite");