#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===== E1. interactive Kconfig anywhere? ====="
grep -rn "CPU_FREQ_GOV_INTERACTIVE" $S --include=Kconfig | head -5
echo "(empty = interactive NEVER existed here)"
echo ""
echo "===== E2. performance gov impl file? ====="
ls $S/drivers/cpufreq/ | grep -iE "perf|interactive"
grep -rn "cpufreq_gov_performance\|\"performance\"" $S/drivers/cpufreq/*.c $S/drivers/cpufreq/Kconfig 2>/dev/null | head -5
echo "(empty above except Makefile x86 refs = NO performance gov in 4.9 arm64 tree)"
echo ""
echo "===== E3. userspace gov impl ====="
grep -n "cpufreq_gov_userspace" $S/drivers/cpufreq/cpufreq_userspace.c | head -5
echo ""
echo "===== E4. existing input-boost sysfs knobs ====="
grep -n "DEVICE_ATTR\|__ATTR\|sysfs_create" $S/drivers/cpufreq/cpu_input_boost.c | head -10
echo ""
echo "===== E5. wcd9335 codec file? ====="
ls $S/sound/soc/codecs/ | grep -iE "wcd|tasha|tavil"
echo ""
echo "===== E6. qpnp fastchg sysfs knobs? ====="
grep -n "DEVICE_ATTR\|power_supply.*prop\|POWER_SUPPLY_PROP" $S/drivers/power/supply/qcom/qpnp-smbcharger.c | head -10
