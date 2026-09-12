#!/bin/bash
S=/root/daisy-build/kernel_source
echo "==powersave=="
cat "$S/drivers/cpufreq/cpufreq_powersave.c"
echo ""
echo "==perf=="
cat "$S/drivers/cpufreq/cpufreq_performance.c"
echo ""
echo "==Kconfig 100-215=="
sed -n '100,215p' "$S/drivers/cpufreq/Kconfig"
echo ""
echo "==interactive exists?=="
find "$S/drivers/cpufreq" -maxdepth 1 -type f | sort
