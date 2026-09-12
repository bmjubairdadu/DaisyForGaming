#!/bin/bash
set -e
S=/root/daisy-build/kernel_source
echo "==V1 source present?=="
grep -E "^VERSION|^PATCHLEVEL|^SUBLEVEL" "$S/Makefile" | cat
ls "$S/drivers/cpufreq/cpufreq_performance.c" "$S/drivers/cpufreq/cpufreq_powersave.c"
echo ""
echo "==V2 current Kconfig perf?=="
grep -n "PERFORMANCE\|GAMING" "$S/drivers/cpufreq/Kconfig" || echo NONE
echo ""
echo "==V3 current Makefile perf/gaming?=="
grep -n "performance\|gaming\|powersave" "$S/drivers/cpufreq/Makefile" || echo NONE
echo ""
echo "==V4 wakelock.c head=="
sed -n '1,60p' "$S/kernel/power/wakelock.c"
