#!/bin/bash
# v2.3 patch applicator - runs INSIDE WSL, no quoting hell
set -e
S=/root/daisy-build/kernel_source
echo "=== V23 patch start ==="
grep -E "^VERSION|^PATCHLEVEL|^SUBLEVEL" $S/Makefile

# 1. gaming governor file (powersave-template, proven API)
cat > $S/drivers/cpufreq/cpufreq_gaming.c <<'CEOF'
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
CEOF
echo "gaming.c written:"
ls -l $S/drivers/cpufreq/cpufreq_gaming.c $S/drivers/cpufreq/cpufreq_performance.c

# 2+3. Kconfig + Makefile via python3 (exact, idempotent)
python3 <<'PYEOF'
import io
kp = "/root/daisy-build/kernel_source/drivers/cpufreq/Kconfig"
s = open(kp).read()
if "CPU_FREQ_GOV_PERFORMANCE" not in s:
    perf = '''
config CPU_FREQ_GOV_PERFORMANCE
\ttristate "'performance' governor"
\thelp
\t  This cpufreq governor sets the frequency statically to the
\t  highest available CPU frequency. Gaming profile: max perf.
\t  If in doubt, say Y.

config CPU_FREQ_GOV_GAMING
\ttristate "'gaming' governor for DaisyForGaming"
\thelp
\t  Gaming governor by JUBAIR HOSEN: holds max freq while active,
\t  powersave-template limits-hook, no timers, boot-safe.
\t  If in doubt, say Y.

'''
    s = s.replace("config CPU_FREQ_GOV_USERSPACE", perf + "config CPU_FREQ_GOV_USERSPACE", 1)
    open(kp, "w").write(s)
    print("Kconfig patched")
else:
    print("Kconfig already has PERFORMANCE")

mp = "/root/daisy-build/kernel_source/drivers/cpufreq/Makefile"
m = open(mp).read()
changed = False
if "cpufreq_performance.o" not in m:
    m = m.replace("obj-$(CONFIG_CPU_FREQ_GOV_POWERSAVE)\t+= cpufreq_powersave.o",
                  "obj-$(CONFIG_CPU_FREQ_GOV_POWERSAVE)\t+= cpufreq_powersave.o\nobj-$(CONFIG_CPU_FREQ_GOV_PERFORMANCE)\t+= cpufreq_performance.o\nobj-$(CONFIG_CPU_FREQ_GOV_GAMING)\t+= cpufreq_gaming.o",
                  1)
    changed = True
    print("Makefile patched")
else:
    print("Makefile already patched")
if changed:
    open(mp, "w").write(m)
PYEOF
grep -n "PERFORMANCE\|GAMING" $S/drivers/cpufreq/Kconfig | head
grep -n "performance\|gaming" $S/drivers/cpufreq/Makefile | head

# 4. wakelock blocker: minimal sysfs filter, default empty = stock behavior
python3 <<'PYEOF'
p = "/root/daisy-build/kernel_source/kernel/power/wakelock.c"
s = open(p).read()
if "daisy_wl_block" not in s:
    s = s.replace('#include <linux/sched.h>',
                  '#include <linux/sched.h>\n#include <linux/module.h>\n#include <linux/string.h>\n\n/* DaisyForGaming wakelock blocker - default empty = stock behavior */\nstatic char daisy_wl_block[256] = "";\nmodule_param_string(wakelock_block, daisy_wl_block, sizeof(daisy_wl_block), 0644);\nMODULE_PARM_DESC(wakelock_block, "substring to block in pm_wake_lock, empty=off");',
                  1)
    old = "\tlen = str - buf;\n\tif (!len)\n\t\treturn -EINVAL;"
    new = "\tlen = str - buf;\n\tif (!len)\n\t\treturn -EINVAL;\n\n\t/* DaisyForGaming: optional wakelock filter (off by default) */\n\tif (daisy_wl_block[0] != '\\0' && len < sizeof(daisy_wl_block)) {\n\t\tchar tmp[256];\n\t\tmemcpy(tmp, buf, len);\n\t\ttmp[len] = '\\0';\n\t\tif (strstr(tmp, daisy_wl_block))\n\t\t\treturn 0;\n\t}"
    assert old in s, "wakelock anchor not found"
    s = s.replace(old, new, 1)
    open(p, "w").write(s)
    print("wakelock.c patched")
else:
    print("wakelock already patched")
PYEOF
grep -n "daisy_wl_block\|wakelock_block" $S/kernel/power/wakelock.c | head
echo "=== V23 patch done ==="
