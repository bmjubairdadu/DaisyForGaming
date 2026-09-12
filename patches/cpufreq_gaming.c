/*
 * DaisyForGaming "gaming" governor - powersave-template, boot-safe.
 * Simple limits-hook: hold max while active. No timers/workqueues/OC.
 * Device: daisy/msm8953 | 4.9.337 | by JUBAIR HOSEN.
 */
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt
#include <linux/cpufreq.h>
#include <linux/init.h>
#include <linux/module.h>

static void cpufreq_gov_gaming_limits(struct cpufreq_policy *policy)
{
	pr_debug("gaming: setting to %u kHz\n", policy->max);
	__cpufreq_driver_target(policy, policy->max, CPUFREQ_RELATION_H);
}

struct cpufreq_governor cpufreq_gov_gaming = {
	.name		= "gaming",
	.limits		= cpufreq_gov_gaming_limits,
	.owner		= THIS_MODULE,
};

MODULE_AUTHOR("JUBAIR HOSEN");
MODULE_DESCRIPTION("CPUfreq policy governor 'gaming' for DaisyForGaming");
MODULE_LICENSE("GPL");

cpufreq_governor_init(cpufreq_gov_gaming);
cpufreq_governor_exit(cpufreq_gov_gaming);
