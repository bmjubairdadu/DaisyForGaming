#!/bin/bash
S=/root/daisy-build/kernel_source
echo "---config gov---"
grep -E "CPU_FREQ_GOV" "$S/out/.config" | head -12
echo "---gaming obj---"
ls -lh "$S/out/drivers/cpufreq/"cpufreq_gaming.o "$S/out/drivers/cpufreq/"cpufreq_performance.o 2>&1
echo "---src---"
ls -l "$S/drivers/cpufreq/cpufreq_gaming.c" "$S/drivers/cpufreq/cpufreq_performance.c" 2>&1
echo "---Image---"
ls -lh "$S/out/arch/arm64/boot/Image.gz-dtb"
date
echo "---make running?---"
ps aux | grep -E "make|gcc|clang" | grep -v grep | head -5 || echo NOMAKE
