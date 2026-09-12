#!/bin/bash
S=/root/daisy-build/kernel_source
echo "==inputboost head=="
sed -n '1,60p' "$S/drivers/cpufreq/cpu_input_boost.c"
echo ""
echo "==idler params=="
grep -n "module_param" "$S/drivers/devfreq/adreno_idler.c" 2>/dev/null | head -15
ls "$S/drivers/devfreq/"
echo ""
echo "==base defconfig=="
grep -n "POWERSUSPEND\|DYNAMIC_FSYNC\|INPUT_BOOST\|ADRENO_IDLER\|KCAL\|BBR\|BFQ\|SCHEDUTIL\|ONDEMAND\|CONSERVATIVE" "$S/arch/arm64/configs/daisy_defconfig"
echo ""
echo "==sync head=="
sed -n '1,70p' "$S/fs/sync.c"
