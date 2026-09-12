#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===K1==="
grep -n "GOV_POWERSAVE\|GOV_USERSPACE" "$S/drivers/cpufreq/Kconfig"
echo "===K2 lines 117-142==="
sed -n '117,142p' "$S/drivers/cpufreq/Kconfig"
echo "===M1==="
grep -n "POWERSAVE\|USERSPACE\|ONDEMAND" "$S/drivers/cpufreq/Makefile"
echo "===W pm_wake_lock line==="
grep -n "int pm_wake_lock" "$S/kernel/power/wakelock.c"
sed -n '225,245p' "$S/kernel/power/wakelock.c"
