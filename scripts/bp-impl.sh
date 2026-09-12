#!/bin/bash
S=/root/daisy-build/kernel_source
echo "==Makefile=="
cat $S/drivers/cpufreq/Makefile
echo ""
echo "==Kconfig govs=="
grep -n "config CPU_FREQ_GOV\|config CPUFREQ_DT" $S/drivers/cpufreq/Kconfig
echo ""
echo "==conservative files?=="
ls $S/drivers/cpufreq/ | head -30
echo ""
echo "==gov header used by ondemand?=="
head -40 $S/drivers/cpufreq/cpufreq_governor.h 2>/dev/null | cat
echo ""
echo "==powersuspend hooks in FTS?=="
grep -n "powersuspend\|fb_notif\|early_suspend" $S/drivers/input/touchscreen/focaltech_touch/focaltech_core.c | head -10
echo ""
echo "==dynfsync file?=="
ls $S/fs/sync.c
grep -n "dynfsync\|dynamic_fsync" $S/fs/sync.c | head -8
