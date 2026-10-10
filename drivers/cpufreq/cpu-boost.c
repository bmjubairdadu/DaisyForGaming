/*
 * Copyright (c) 2013-2015,2017,2019, The Linux Foundation. All rights reserved.
 * Copyright (c) 2017, Paranoid Android.
 * Copyright (C) 2017, Razer Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#define pr_fmt(fmt) "cpu-boost: " fmt

#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/cpufreq.h>
#include <linux/cpu.h>
#include <linux/kthread.h>
#include <linux/sched.h>
#include <linux/moduleparam.h>
#include <linux/slab.h>
#include <linux/input.h>
#include <linux/time.h>
#include <linux/sched/rt.h>
#include <linux/power_supply.h>

#include <linux/sched.h>

struct cpu_sync {
	int cpu;
	unsigned int input_boost_min;
	unsigned int input_boost_freq;
};

static DEFINE_PER_CPU(struct cpu_sync, sync_info);

static struct kthread_work input_boost_work;

/*
 * DaisyForGaming v1.15: this driver used to ship with every default at 0, so
 * "CPU Input Boost" did nothing out of the box. Boot the per-CPU table from
 * the Kconfig values: the little cluster (cpu0-3) boosts to
 * CONFIG_INPUT_BOOST_FREQ, the big cluster (cpu4-7) to CONFIG_INPUT_BOOST_FREQ_BIG.
 */
#ifdef CONFIG_INPUT_BOOST_FREQ
#define IB_FREQ_LITTLE_DEFAULT CONFIG_INPUT_BOOST_FREQ
#else
#define IB_FREQ_LITTLE_DEFAULT 1401600
#endif

#ifdef CONFIG_INPUT_BOOST_FREQ_BIG
#define IB_FREQ_BIG_DEFAULT CONFIG_INPUT_BOOST_FREQ_BIG
#else
#define IB_FREQ_BIG_DEFAULT 1689600
#endif

#ifdef CONFIG_INPUT_BOOST_DURATION_MS
#define IB_MS_DEFAULT CONFIG_INPUT_BOOST_DURATION_MS
#else
#define IB_MS_DEFAULT 40
#endif

#ifdef CONFIG_INPUT_BOOST_SCHED
#define IB_SCHED_DEFAULT CONFIG_INPUT_BOOST_SCHED
#else
#define IB_SCHED_DEFAULT 1
#endif

static bool input_boost_enabled = true;

/*
 * DaisyForGaming v1.1: while the charger is connected, input boost stays off
 * by default. Boost heat makes the charger cut current (thermal mitigation),
 * so plugged-in use both charged slower and ran hotter. Charge-first is the
 * right default; set boost_on_charging=1 to get boosting while plugged in.
 */
static bool boost_on_charging;
module_param(boost_on_charging, bool, 0644);
MODULE_PARM_DESC(boost_on_charging,
	"Apply CPU input boost while USB/AC is connected (0 = off, keeps charging fast and cool)");

static bool usb_charger_online(void)
{
	struct power_supply *usb;
	union power_supply_propval val = { 0, };
	bool online = false;

	usb = power_supply_get_by_name("usb");
	if (!usb)
		return false;

	if (!power_supply_get_property(usb, POWER_SUPPLY_PROP_ONLINE, &val))
		online = !!val.intval;
	power_supply_put(usb);

	return online;
}

#ifdef CONFIG_INPUT_BOOST_DURATION_MS
static unsigned int input_boost_ms = CONFIG_INPUT_BOOST_DURATION_MS;
#else
static unsigned int input_boost_ms = 40;
#endif
module_param(input_boost_ms, uint, 0644);

#ifdef CONFIG_INPUT_BOOST_SCHED
static unsigned int sched_boost_on_input = CONFIG_INPUT_BOOST_SCHED;
#else
static unsigned int sched_boost_on_input = 1;
#endif
module_param(sched_boost_on_input, uint, 0644);

/*
 * DaisyForGaming v1.0 (final): one node that switches the whole boost
 * profile at runtime — no script edits needed:
 *
 *   0 = battery   input boost completely off (coolest, best standby)
 *   1 = balanced  default: 1036/1401 MHz, 150 ms, no WALT sched boost
 *   2 = gaming    1401/1689 MHz, 250 ms + WALT sched boost on touch
 *
 * balanced/gaming keep the same clocks the v1.0/v1.1 zips shipped, so
 * nothing new heats up: gaming just re-enables the stronger v1.0 touch
 * boost while a game is actually running, battery suspends the boost for
 * cool video/browsing/standby.
 */
static unsigned int boost_mode = 1;

static void apply_boost_mode(void)
{
	unsigned int little = IB_FREQ_LITTLE_DEFAULT;
	unsigned int big = IB_FREQ_BIG_DEFAULT;
	int cpu;

	switch (boost_mode) {
	case 0:
		input_boost_enabled = false;
		pr_info("boost_mode=battery: input boost off\n");
		return;
	case 2:
		little = 1401600;
		big = 1689600;
		input_boost_ms = 250;
		sched_boost_on_input = 1;
		break;
	case 1:
	default:
		boost_mode = 1;
		input_boost_ms = IB_MS_DEFAULT;
		sched_boost_on_input = IB_SCHED_DEFAULT;
		break;
	}

	for_each_possible_cpu(cpu) {
		struct cpu_sync *s = &per_cpu(sync_info, cpu);
		s->input_boost_freq = (cpu < 4) ? little : big;
	}
	input_boost_enabled = true;
	pr_info("boost_mode=%u: little=%ukHz big=%ukHz ms=%u sched_boost=%u\n",
		boost_mode, little, big, input_boost_ms, sched_boost_on_input);
}

static int set_boost_mode(const char *buf, const struct kernel_param *kp)
{
	unsigned int val;

	if (kstrtouint(buf, 0, &val) || val > 2)
		return -EINVAL;
	boost_mode = val;
	apply_boost_mode();
	return 0;
}

static int get_boost_mode(char *buf, const struct kernel_param *kp)
{
	return scnprintf(buf, PAGE_SIZE, "%u\n", boost_mode);
}

static const struct kernel_param_ops param_ops_boost_mode = {
	.set = set_boost_mode,
	.get = get_boost_mode,
};
module_param_cb(boost_mode, &param_ops_boost_mode, NULL, 0644);
MODULE_PARM_DESC(boost_mode,
	"Input boost profile: 0=battery (off), 1=balanced (default), 2=gaming");

static bool sched_boost_active;

static struct delayed_work input_boost_rem;
static u64 last_input_time;

static struct kthread_worker cpu_boost_worker;
static struct task_struct *cpu_boost_worker_thread;

#define MIN_INPUT_INTERVAL (100 * USEC_PER_MSEC)

static int set_input_boost_freq(const char *buf, const struct kernel_param *kp)
{
	int i, ntokens = 0;
	unsigned int val, cpu;
	const char *cp = buf;
	bool enabled = false;

	while ((cp = strpbrk(cp + 1, " :")))
		ntokens++;

	/* single number: apply to all CPUs */
	if (!ntokens) {
		if (sscanf(buf, "%u\n", &val) != 1)
			return -EINVAL;
		for_each_possible_cpu(i)
			per_cpu(sync_info, i).input_boost_freq = val;
		goto check_enable;
	}

	/* CPU:value pair */
	if (!(ntokens % 2))
		return -EINVAL;

	cp = buf;
	for (i = 0; i < ntokens; i += 2) {
		if (sscanf(cp, "%u:%u", &cpu, &val) != 2)
			return -EINVAL;
		if (cpu >= num_possible_cpus())
			return -EINVAL;

		per_cpu(sync_info, cpu).input_boost_freq = val;
		cp = strchr(cp, ' ');
		cp++;
	}

check_enable:
	for_each_possible_cpu(i) {
		if (per_cpu(sync_info, i).input_boost_freq) {
			enabled = true;
			break;
		}
	}
	input_boost_enabled = enabled;

	return 0;
}

static int get_input_boost_freq(char *buf, const struct kernel_param *kp)
{
	int cnt = 0, cpu;
	struct cpu_sync *s;

	for_each_possible_cpu(cpu) {
		s = &per_cpu(sync_info, cpu);
		cnt += snprintf(buf + cnt, PAGE_SIZE - cnt,
				"%d:%u ", cpu, s->input_boost_freq);
	}
	cnt += snprintf(buf + cnt, PAGE_SIZE - cnt, "\n");
	return cnt;
}

static const struct kernel_param_ops param_ops_input_boost_freq = {
	.set = set_input_boost_freq,
	.get = get_input_boost_freq,
};
module_param_cb(input_boost_freq, &param_ops_input_boost_freq, NULL, 0644);

/*
 * The CPUFREQ_ADJUST notifier is used to override the current policy min to
 * make sure policy min >= boost_min. The cpufreq framework then does the job
 * of enforcing the new policy.
 */
static int boost_adjust_notify(struct notifier_block *nb, unsigned long val,
				void *data)
{
	struct cpufreq_policy *policy = data;
	unsigned int cpu = policy->cpu;
	struct cpu_sync *s = &per_cpu(sync_info, cpu);
	unsigned int ib_min = s->input_boost_min;

	switch (val) {
	case CPUFREQ_ADJUST:
		if (!ib_min)
			break;

		pr_debug("CPU%u policy min before boost: %u kHz\n",
			 cpu, policy->min);
		pr_debug("CPU%u boost min: %u kHz\n", cpu, ib_min);

		cpufreq_verify_within_limits(policy, ib_min, UINT_MAX);

		pr_debug("CPU%u policy min after boost: %u kHz\n",
			 cpu, policy->min);
		break;
	}

	return NOTIFY_OK;
}

static struct notifier_block boost_adjust_nb = {
	.notifier_call = boost_adjust_notify,
};

static void update_policy_online(void)
{
	unsigned int i;

	/* Re-evaluate policy to trigger adjust notifier for online CPUs */
	get_online_cpus();
	for_each_online_cpu(i) {
		pr_debug("Updating policy for CPU%d\n", i);
		cpufreq_update_policy(i);
	}
	put_online_cpus();
}

static void do_input_boost_rem(struct work_struct *work)
{
	unsigned int i, ret;
	struct cpu_sync *i_sync_info;

	/* Reset the input_boost_min for all CPUs in the system */
	pr_debug("Resetting input boost min for all CPUs\n");
	for_each_possible_cpu(i) {
		i_sync_info = &per_cpu(sync_info, i);
		i_sync_info->input_boost_min = 0;
	}

	/* Update policies for all online CPUs */
	update_policy_online();

	if (sched_boost_active) {
		ret = sched_set_boost(0);
		if (ret)
			pr_err("cpu-boost: HMP boost disable failed\n");
		sched_boost_active = false;
	}
}

static void do_input_boost(struct kthread_work *work)
{
	unsigned int i, ret;
	struct cpu_sync *i_sync_info;

	/*
	 * Charging guard: skip the boost without touching the pending
	 * input_boost_rem work — if a boost is still active, its own removal
	 * work clears the mins, so nothing gets stuck at boost frequency.
	 */
	if (!boost_on_charging && usb_charger_online())
		return;

	cancel_delayed_work_sync(&input_boost_rem);
	if (sched_boost_active) {
		sched_set_boost(0);
		sched_boost_active = false;
	}

	/* Set the input_boost_min for all CPUs in the system */
	pr_debug("Setting input boost min for all CPUs\n");
	for_each_possible_cpu(i) {
		i_sync_info = &per_cpu(sync_info, i);
		i_sync_info->input_boost_min = i_sync_info->input_boost_freq;
	}

	/* Update policies for all online CPUs */
	update_policy_online();

	/* Enable scheduler boost to migrate tasks to big cluster */
	if (sched_boost_on_input > 0) {
		ret = sched_set_boost(sched_boost_on_input);
		if (ret)
			pr_err("cpu-boost: HMP boost enable failed\n");
		else
			sched_boost_active = true;
	}

	schedule_delayed_work(&input_boost_rem, msecs_to_jiffies(input_boost_ms));
}

static void cpuboost_input_event(struct input_handle *handle,
		unsigned int type, unsigned int code, int value)
{
	u64 now;

	if (!input_boost_enabled)
		return;

	now = ktime_to_us(ktime_get());
	if (now - last_input_time < MIN_INPUT_INTERVAL)
		return;

	if (queuing_blocked(&cpu_boost_worker, &input_boost_work))
		return;

	kthread_queue_work(&cpu_boost_worker, &input_boost_work);
	last_input_time = ktime_to_us(ktime_get());
}

static int cpuboost_input_connect(struct input_handler *handler,
		struct input_dev *dev, const struct input_device_id *id)
{
	struct input_handle *handle;
	int error;

	handle = kzalloc(sizeof(struct input_handle), GFP_KERNEL);
	if (!handle)
		return -ENOMEM;

	handle->dev = dev;
	handle->handler = handler;
	handle->name = "cpufreq";

	error = input_register_handle(handle);
	if (error)
		goto err2;

	error = input_open_device(handle);
	if (error)
		goto err1;

	return 0;
err1:
	input_unregister_handle(handle);
err2:
	kfree(handle);
	return error;
}

static void cpuboost_input_disconnect(struct input_handle *handle)
{
	input_close_device(handle);
	input_unregister_handle(handle);
	kfree(handle);
}

static const struct input_device_id cpuboost_ids[] = {
	/* multi-touch touchscreen */
	{
		.flags = INPUT_DEVICE_ID_MATCH_EVBIT |
			INPUT_DEVICE_ID_MATCH_ABSBIT,
		.evbit = { BIT_MASK(EV_ABS) },
		.absbit = { [BIT_WORD(ABS_MT_POSITION_X)] =
			BIT_MASK(ABS_MT_POSITION_X) |
			BIT_MASK(ABS_MT_POSITION_Y) },
	},
	/* touchpad */
	{
		.flags = INPUT_DEVICE_ID_MATCH_KEYBIT |
			INPUT_DEVICE_ID_MATCH_ABSBIT,
		.keybit = { [BIT_WORD(BTN_TOUCH)] = BIT_MASK(BTN_TOUCH) },
		.absbit = { [BIT_WORD(ABS_X)] =
			BIT_MASK(ABS_X) | BIT_MASK(ABS_Y) },
	},
	/* Keypad */
	{
		.flags = INPUT_DEVICE_ID_MATCH_EVBIT,
		.evbit = { BIT_MASK(EV_KEY) },
	},
	{ },
};

static struct input_handler cpuboost_input_handler = {
	.event          = cpuboost_input_event,
	.connect        = cpuboost_input_connect,
	.disconnect     = cpuboost_input_disconnect,
	.name           = "cpu-boost",
	.id_table       = cpuboost_ids,
};

static int cpu_boost_init(void)
{
	int cpu, ret;
	struct cpu_sync *s;
	struct sched_param param = { .sched_priority = MAX_RT_PRIO - 2 };

	kthread_init_worker(&cpu_boost_worker);
	cpu_boost_worker_thread = kthread_run(kthread_worker_fn,
		&cpu_boost_worker, "cpu_boost_worker_thread");
	if (IS_ERR(cpu_boost_worker_thread))
		return -EFAULT;

	sched_setscheduler(cpu_boost_worker_thread, SCHED_FIFO, &param);
	kthread_init_work(&input_boost_work, do_input_boost);
	INIT_DELAYED_WORK(&input_boost_rem, do_input_boost_rem);

	for_each_possible_cpu(cpu) {
		s = &per_cpu(sync_info, cpu);
		s->cpu = cpu;
		s->input_boost_freq = (cpu < 4) ? IB_FREQ_LITTLE_DEFAULT
						: IB_FREQ_BIG_DEFAULT;
	}
	pr_info("input boost on by default: little=%ukHz big=%ukHz ms=%u sched_boost=%u\n",
		IB_FREQ_LITTLE_DEFAULT, IB_FREQ_BIG_DEFAULT, input_boost_ms,
		sched_boost_on_input);
	cpufreq_register_notifier(&boost_adjust_nb, CPUFREQ_POLICY_NOTIFIER);

	ret = input_register_handler(&cpuboost_input_handler);
	return 0;
}
late_initcall(cpu_boost_init);
