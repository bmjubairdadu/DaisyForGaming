#!/bin/bash
S=/root/daisy-build/kernel_source
echo "---Kconfig---"
grep -n "WAKELOCK" "$S/kernel/power/Kconfig" | head -8
echo "---Makefile---"
grep -n "wakelock" "$S/kernel/power/Makefile"
echo "---base---"
grep -n "WAKELOCK" "$S/arch/arm64/configs/daisy_defconfig"
grep -n "POWERSUSPEND" "$S/arch/arm64/configs/daisy_defconfig"
grep -n "DYNAMIC_FSYNC" "$S/arch/arm64/configs/daisy_defconfig"
echo "---out config gov---"
grep -E "GOV_PERFORMANCE|GOV_GAMING" "$S/out/.config"
echo "---Image---"
ls -lh "$S/out/arch/arm64/boot/Image.gz-dtb"
