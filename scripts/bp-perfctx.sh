#!/bin/bash
S=/root/daisy-build/kernel_source
echo "===== F1. performance Kconfig context ====="
sed -n "100,140p" $S/drivers/cpufreq/Kconfig
echo ""
echo "===== F2. Makefile gov lines ====="
grep -n "GOV_" $S/drivers/cpufreq/Makefile
echo ""
echo "===== F3. userspace Kconfig entry ====="
grep -n -B2 -A6 "GOV_USERSPACE" $S/drivers/cpufreq/Kconfig | head -20
