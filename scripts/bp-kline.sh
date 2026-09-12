#!/bin/bash
S=/root/daisy-build/kernel_source
sed -n '117,145p' "$S/drivers/cpufreq/Kconfig"
echo "===MAKE 1-15==="
sed -n '1,15p' "$S/drivers/cpufreq/Makefile"
