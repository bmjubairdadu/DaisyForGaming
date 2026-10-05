/*
 *  drivers/cpufreq/cpufreq_interactive.c
 *
 *  Copyright (C) 2001 Russell King
 *            (C) 2003 Venkatesh Pallipadi <venkatesh.pallipadi@intel.com>
 *            (C) 2013, 2014, 2015 Linaro Ltd.
 *            (C) 2018 DaisyForGaming
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2
 * as published by the Free Software Foundation.
 */

#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

#include <linux/cpu.h>
#include <linux/list.h>
#include <linux/slab.h>
#include <linux/tick.h>

#include "cpufreq_governor.h"

/* Interactive governor macros */
#define DEF_TARGET_LOAD			(95)
#define MIN_TARGET_LOAD			(1)
#define MAX_TARGET_LOAD			(100)
#define DEF_FREQUENCY_UP_THRESHOLD	(98)
#define MIN_FREQUENCY_UP_THRESHOLD	(1)
#define MAX_FREQUENCY_UP_THRESHOLD	(100)
#define DEF_SAMPLING_DOWN_FACTOR	(1)
#define MAX_SAMPLING_DOWN_FACTOR	(100000)
#define DEF_SAMPLING_RATE		(100000)

struct interactive_policy_dbs_info {
	struct policy_dbs_info policy_dbs;
};

static inline struct interactive_policy_dbs_info *to_dbs_info(struct policy_dbs_info *policy_dbs)
{
	return container_of(policy_dbs, struct interactive_policy_dbs_info, policy_dbs);
}

struct interactive_dbs_tuners {
	unsigned int target_load;
};

/*
 * Interactive governor: instead of scaling the frequency proportionally to
 * the load, stay at min while the load is under target_load and jump straight
 * to max once it crosses up_threshold. This trades fine-grained scaling for a
 * much lower wake-up latency, which is what interactive-mode users want.
 */
static unsigned int interactive_dbs_update(struct cpufreq_policy *policy)
{
	struct policy_dbs_info *policy_dbs = policy->governor_data;
	struct dbs_data *dbs_data = policy_dbs->dbs_data;
	struct interactive_dbs_tuners *tuners = dbs_data->tuners;
	unsigned int load = dbs_update(policy);
	unsigned int old_freq = policy->cur;
	unsigned int new_freq;

	if (load > dbs_data->up_threshold) {
		/* Busy: apply sampling_down_factor and go to max. */
		if (old_freq < policy->max)
			policy_dbs->rate_mult = dbs_data->sampling_down_factor;
		new_freq = policy->max;
	} else if (load < tuners->target_load) {
		/* Idle enough: drop to min. */
		policy_dbs->rate_mult = 1;
		new_freq = policy->min;
	} else {
		/* In the dead band: hold the current frequency. */
		policy_dbs->rate_mult = 1;
		new_freq = old_freq;
	}

	if (new_freq != old_freq) {
		__cpufreq_driver_target(policy, new_freq,
			new_freq > old_freq ? CPUFREQ_RELATION_H :
					      CPUFREQ_RELATION_L);
	}

	return dbs_data->sampling_rate * policy_dbs->rate_mult;
}

/************************** sysfs interface ************************/

static ssize_t store_target_load(struct gov_attr_set *attr_set,
				 const char *buf, size_t count)
{
	struct dbs_data *dbs_data = to_dbs_data(attr_set);
	struct interactive_dbs_tuners *tuners = dbs_data->tuners;
	unsigned int input;
	int ret;

	ret = sscanf(buf, "%u", &input);
	if (ret != 1 || input < MIN_TARGET_LOAD || input > MAX_TARGET_LOAD)
		return -EINVAL;

	if (input == tuners->target_load)
		return count;

	tuners->target_load = input;
	return count;
}

static ssize_t store_up_threshold(struct gov_attr_set *attr_set,
				  const char *buf, size_t count)
{
	struct dbs_data *dbs_data = to_dbs_data(attr_set);
	unsigned int input;
	int ret;

	ret = sscanf(buf, "%u", &input);
	if (ret != 1 || input > MAX_FREQUENCY_UP_THRESHOLD ||
			input < MIN_FREQUENCY_UP_THRESHOLD)
		return -EINVAL;

	dbs_data->up_threshold = input;
	return count;
}

static ssize_t store_sampling_down_factor(struct gov_attr_set *attr_set,
					  const char *buf, size_t count)
{
	struct dbs_data *dbs_data = to_dbs_data(attr_set);
	struct policy_dbs_info *policy_dbs;
	unsigned int input;
	int ret;

	ret = sscanf(buf, "%u", &input);
	if (ret != 1 || input > MAX_SAMPLING_DOWN_FACTOR || input < 1)
		return -EINVAL;

	dbs_data->sampling_down_factor = input;

	/* Reset down sampling multiplier in case it was active */
	list_for_each_entry(policy_dbs, &attr_set->policy_list, list) {
		mutex_lock(&policy_dbs->update_mutex);
		policy_dbs->rate_mult = 1;
		mutex_unlock(&policy_dbs->update_mutex);
	}

	return count;
}

static ssize_t store_ignore_nice_load(struct gov_attr_set *attr_set,
				      const char *buf, size_t count)
{
	struct dbs_data *dbs_data = to_dbs_data(attr_set);
	unsigned int input;
	int ret;

	ret = sscanf(buf, "%u", &input);
	if (ret != 1)
		return -EINVAL;

	if (input > 1)
		input = 1;

	if (input == dbs_data->ignore_nice_load) /* nothing to do */
		return count;

	dbs_data->ignore_nice_load = input;

	/* we need to re-evaluate prev_cpu_idle */
	gov_update_cpu_data(dbs_data);

	return count;
}

gov_show_one_common(sampling_rate);
gov_show_one_common(up_threshold);
gov_show_one_common(sampling_down_factor);
gov_show_one_common(ignore_nice_load);
gov_show_one(interactive, target_load);

gov_attr_rw(sampling_rate);
gov_attr_rw(up_threshold);
gov_attr_rw(sampling_down_factor);
gov_attr_rw(ignore_nice_load);
gov_attr_rw(target_load);

static struct attribute *interactive_attributes[] = {
	&sampling_rate.attr,
	&up_threshold.attr,
	&sampling_down_factor.attr,
	&ignore_nice_load.attr,
	&target_load.attr,
	NULL
};

/************************** sysfs end ************************/

static struct policy_dbs_info *interactive_alloc(void)
{
	struct interactive_policy_dbs_info *dbs_info;

	dbs_info = kzalloc(sizeof(*dbs_info), GFP_KERNEL);
	return dbs_info ? &dbs_info->policy_dbs : NULL;
}

static void interactive_free(struct policy_dbs_info *policy_dbs)
{
	kfree(to_dbs_info(policy_dbs));
}

static int interactive_init(struct dbs_data *dbs_data)
{
	struct interactive_dbs_tuners *tuners;

	tuners = kzalloc(sizeof(*tuners), GFP_KERNEL);
	if (!tuners)
		return -ENOMEM;

	tuners->target_load = DEF_TARGET_LOAD;
	dbs_data->up_threshold = DEF_FREQUENCY_UP_THRESHOLD;
	dbs_data->sampling_down_factor = DEF_SAMPLING_DOWN_FACTOR;
	dbs_data->ignore_nice_load = 0;
	dbs_data->sampling_rate = DEF_SAMPLING_RATE;

	dbs_data->tuners = tuners;
	return 0;
}

static void interactive_exit(struct dbs_data *dbs_data)
{
	kfree(dbs_data->tuners);
}

#ifndef CONFIG_CPU_FREQ_DEFAULT_GOV_INTERACTIVE
static
#endif
struct dbs_governor interactive_gov = {
	.gov = CPUFREQ_DBS_GOVERNOR_INITIALIZER("interactive"),
	.kobj_type = { .default_attrs = interactive_attributes },
	.gov_dbs_update = interactive_dbs_update,
	.alloc = interactive_alloc,
	.free = interactive_free,
	.init = interactive_init,
	.exit = interactive_exit,
};

#define CPU_FREQ_GOV_INTERACTIVE	(interactive_gov.gov)

MODULE_AUTHOR("Venkatesh Pallipadi <venkatesh.pallipadi@intel.com>");
MODULE_AUTHOR("Linaro Ltd.");
MODULE_AUTHOR("DaisyForGaming");
MODULE_DESCRIPTION("'cpufreq_interactive' - a dynamic cpufreq governor for "
		   "Low Latency Frequency Transition capable processors");
MODULE_LICENSE("GPL");

#ifdef CONFIG_CPU_FREQ_DEFAULT_GOV_INTERACTIVE
struct cpufreq_governor *cpufreq_default_governor(void)
{
	return &CPU_FREQ_GOV_INTERACTIVE;
}
#endif

cpufreq_governor_init(CPU_FREQ_GOV_INTERACTIVE);
cpufreq_governor_exit(CPU_FREQ_GOV_INTERACTIVE);
