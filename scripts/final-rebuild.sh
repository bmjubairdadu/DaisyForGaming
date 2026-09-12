#!/bin/bash
# Final researched-safe rebuild: sync fragment, re-merge, GCC rebuild, repack AK3.
set -e
B=/root/daisy-build
S=$B/kernel_source
cp /mnt/d/Kernel/configs/daisy_gaming_defconfig $B/configs/daisy_gaming_defconfig
FRAG=$B/configs/daisy_gaming_defconfig
echo '[*] Merging researched fragment over daisy_defconfig...'
$S/scripts/kconfig/merge_config.sh -m -O $S/out $S/out/.config $FRAG
$S/scripts/config --file $S/out/.config --set-str LOCALVERSION '-DaisyForGaming'
grep -q '^CONFIG_LOCALVERSION=' $S/out/.config || echo 'CONFIG_LOCALVERSION="-DaisyForGaming"' >> $S/out/.config
make -C $S O=out ARCH=arm64 olddefconfig
echo '[*] Final .config gaming values:'
grep -E '^CONFIG_LOCALVERSION=|CONFIG_CPU_FREQ_GOV_SCHEDUTIL|CONFIG_CPU_BOOST|CONFIG_CPU_INPUT_BOOST|CONFIG_TCP_CONG_BBR|CONFIG_IOSCHED_BFQ|CONFIG_FB_MSM_MDSS_KCAL_CTRL|CONFIG_ADRENO_IDLER|CONFIG_ZRAM=|CONFIG_DEBUG_FS=|CONFIG_DEFAULT_TCP_CONG|CONFIG_DEFAULT_IOSCHED|CONFIG_HZ=' $S/out/.config
echo '[*] Compiling...'
make -C $S O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- KBUILD_BUILD_USER=JUBAIR KBUILD_BUILD_HOST=JUBAIR-HOSEN -j12 Image.gz-dtb 2>&1 | tee $B/out/build-final.log | tail -n 5
ls -lh $S/out/arch/arm64/boot/Image.gz-dtb
echo BUILD_FINAL_OK
