#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===KCONFIG 117-130==="
sed -n '117,130p' "$S/drivers/cpufreq/Kconfig"
echo "===MAKE 8-14==="
sed -n '8,14p' "$S/drivers/cpufreq/Makefile"
echo "===WAKELOCK 200,280==="
sed -n '200,280p' "$S/kernel/power/wakelock.c"
