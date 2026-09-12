#!/bin/bash
set -e
export ARCH=arm64 SUBARCH=arm64
export KBUILD_BUILD_USER=JUBAIR KBUILD_BUILD_HOST=JUBAIR-HOSEN
export PATH=/root/daisy-build/proton-clang/bin:$PATH
S=/root/daisy-build/kernel_source
FRAG=/mnt/d/Kernel/configs/daisy_gaming_defconfig

echo "=== V23 config ==="
# check PM_WAKELOCKS symbol exists
grep -n "PM_WAKELOCKS" $S/kernel/power/Kconfig | head -5 || echo "NO PM_WAKELOCKS in Kconfig"
grep -n "PM_WAKELOCKS" $S/arch/arm64/configs/daisy_defconfig | head -3 || echo "not in base defconfig"

make -C $S O=out ARCH=arm64 daisy_defconfig
$S/scripts/kconfig/merge_config.sh -m -O $S/out $S/out/.config $FRAG
$S/scripts/config --file $S/out/.config --set-str LOCALVERSION "-DaisyForGaming" || true
grep -q '^CONFIG_LOCALVERSION=' $S/out/.config || echo 'CONFIG_LOCALVERSION="-DaisyForGaming"' >> $S/out/.config
make -C $S O=out ARCH=arm64 olddefconfig
echo "--- gov check ---"
grep -E "GOV_PERFORMANCE|GOV_GAMING|GOV_POWERSAVE|GOV_USERSPACE" $S/out/.config
echo "--- wakelock check ---"
grep -E "WAKELOCK" $S/out/.config | head
echo "=== V23 build ==="
make -C $S O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- -j$(nproc) Image.gz-dtb 2>&1 | tail -30
echo "=== RESULT ==="
ls -lh $S/out/arch/arm64/boot/Image.gz-dtb
