#!/bin/bash
# Rebuild WITHOUT CPU_BOOST (proven broken in this tree). Keep BFQ+KCAL+BBR.
set -e
B=/root/daisy-build
S=$B/kernel_source
cp /mnt/d/Kernel/configs/daisy_gaming_defconfig $B/configs/daisy_gaming_defconfig
FRAG=$B/configs/daisy_gaming_defconfig
$S/scripts/kconfig/merge_config.sh -m -O $S/out $S/out/.config $FRAG
$S/scripts/config --file $S/out/.config --set-str LOCALVERSION '-DaisyForGaming'
grep -q '^CONFIG_LOCALVERSION=' $S/out/.config || echo 'CONFIG_LOCALVERSION="-DaisyForGaming"' >> $S/out/.config
$S/scripts/config --file $S/out/.config -d CPU_BOOST
make -C $S O=out ARCH=arm64 olddefconfig
echo '[*] Gaming values:'
grep -E '^CONFIG_LOCALVERSION=|CONFIG_CPU_BOOST|CONFIG_CPU_INPUT_BOOST|CONFIG_TCP_CONG_BBR|CONFIG_IOSCHED_BFQ|CONFIG_FB_MSM_MDSS_KCAL_CTRL|CONFIG_ADRENO_IDLER|CONFIG_ZRAM=' $S/out/.config
echo '[*] Compiling...'
make -C $S O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- KBUILD_BUILD_USER=JUBAIR KBUILD_BUILD_HOST=JUBAIR-HOSEN -j12 Image.gz-dtb 2>&1 | tee $B/out/build-final2.log | tail -n 5
ls -lh $S/out/arch/arm64/boot/Image.gz-dtb
echo BUILD_FINAL2_OK
