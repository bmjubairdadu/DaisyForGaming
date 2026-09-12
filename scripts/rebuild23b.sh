#!/bin/bash
set -e
export ARCH=arm64 SUBARCH=arm64
export KBUILD_BUILD_USER=JUBAIR KBUILD_BUILD_HOST=JUBAIR-HOSEN
S=/root/daisy-build/kernel_source
FRAG=/mnt/d/Kernel/configs/daisy_gaming_defconfig
echo "=== 1. Kconfig still patched? ==="
grep -c "CPU_FREQ_GOV_PERFORMANCE\|CPU_FREQ_GOV_GAMING" "$S/drivers/cpufreq/Kconfig"
grep -n "performance\|gaming" "$S/drivers/cpufreq/Makefile" | head -4
echo "=== 2. merge ==="
make -C "$S" O=out ARCH=arm64 daisy_defconfig 2>&1 | tail -1
"$S/scripts/kconfig/merge_config.sh" -m -O "$S/out" "$S/out/.config" "$FRAG" 2>&1 | tail -3
"$S/scripts/config" --file "$S/out/.config" --set-str LOCALVERSION "-DaisyForGaming" >/dev/null 2>&1 || true
grep -q '^CONFIG_LOCALVERSION=' "$S/out/.config" || echo 'CONFIG_LOCALVERSION="-DaisyForGaming"' >> "$S/out/.config"
make -C "$S" O=out ARCH=arm64 olddefconfig 2>&1 | tail -2
echo "=== 3. gov in .config ==="
grep -E "CPU_FREQ_GOV_PERFORMANCE|CPU_FREQ_GOV_GAMING|CPU_FREQ_GOV_POWERSAVE|CPU_FREQ_GOV_USERSPACE" "$S/out/.config"
echo "=== 4. build ==="
date
make -C "$S" O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- -j$(nproc) Image.gz-dtb 2>&1 | tail -25
echo "=== 5. result ==="
ls -lh "$S/out/arch/arm64/boot/Image.gz-dtb"
ls -lh "$S/out/drivers/cpufreq/cpufreq_gaming.o" "$S/out/drivers/cpufreq/cpufreq_performance.o"
date
