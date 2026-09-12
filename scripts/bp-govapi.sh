#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===== D1. 4.9 sched governor framework ====="
grep -n "struct gov_attr_set\|gov_attr_set_init\|gov_show_\|gov_store_" $S/drivers/cpufreq/cpufreq_governor.h | head -20
echo ""
echo "===== D2. ondemand .c governor ops sample ====="
sed -n "540,640p" $S/drivers/cpufreq/cpufreq_ondemand.c
echo ""
echo "===== D3. powersave gov (simplest template) ====="
cat $S/drivers/cpufreq/cpufreq_powersave.c
