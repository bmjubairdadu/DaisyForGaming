#!/bin/bash
# DaisyForGaming v1.0 - FULL clean rebuild with FolkPatch fix verification
# Ensures embedded IKCONFIG matches out/.config (no stale config_data.gz)
set -e
export PATH=/root/daisy-build/toolchain/proton-clang/bin:/root/daisy-build/proton-clang/bin:$PATH
S=/root/daisy-build/kernel_source
D=/mnt/d/Kernel
echo "=== 0. preflight ==="
test -x /root/daisy-build/toolchain/proton-clang/bin/ld.lld || test -x /root/daisy-build/proton-clang/bin/ld.lld
echo "ld.lld OK"
echo "=== 1. apply Kconfig patch (idempotent) ==="
bash /mnt/d/Kernel/scripts/apply-kallsyms-fix.sh
echo "=== 2. REMOVE out entirely (kill stale config_data.gz) ==="
rm -rf "$S/out"
mkdir -p "$S/out"
echo "=== 3. base defconfig ==="
make -C "$S" O=out ARCH=arm64 daisy_defconfig
echo "=== 4. merge gaming fragment ==="
"$S/scripts/kconfig/merge_config.sh" -m -O "$S/out" "$S/out/.config" "$D/configs/daisy_gaming_defconfig"
echo "=== 5. localversion ==="
"$S/scripts/config" --file "$S/out/.config" --set-str LOCALVERSION "-DaisyForGaming" 2>/dev/null || true
grep -q '^CONFIG_LOCALVERSION=' "$S/out/.config" || echo 'CONFIG_LOCALVERSION="-DaisyForGaming"' >> "$S/out/.config"
echo "=== 6. olddefconfig ==="
make -C "$S" O=out ARCH=arm64 olddefconfig
echo "=== 7. verify .config ==="
grep -E "^CONFIG_KALLSYMS_ALL=|^CONFIG_KALLSYMS=|RANDOMIZE_BASE|OVERLAY_FS|LOCALVERSION" "$S/out/.config"
test "$(grep -c '^CONFIG_KALLSYMS_ALL=y' "$S/out/.config")" = "1"
echo "DOTCONFIG_OK"
echo "=== 8. full build ==="
make -C "$S" O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- -j"$(nproc)" Image.gz-dtb
test -s "$S/out/arch/arm64/boot/Image.gz-dtb"
echo "=== 9. verify EMBEDDED config matches ==="
"$S/scripts/extract-ikconfig" "$S/out/arch/arm64/boot/Image" > /root/emb-final.cfg
grep -E "KALLSYMS|OVERLAY_FS|RANDOMIZE_BASE" /root/emb-final.cfg
grep -q "^CONFIG_KALLSYMS_ALL=y" /root/emb-final.cfg || { echo "EMBEDDED_MISMATCH_FAIL"; exit 1; }
echo "EMBEDDED_OK"
echo "=== 10. verify lookup symbols ==="
grep -q "kallsyms_lookup_name" "$S/out/System.map" || { echo "LOOKUP_MISSING_FAIL"; exit 1; }
echo "LOOKUP_OK"
ls -lh "$S/out/arch/arm64/boot/Image" "$S/out/arch/arm64/boot/Image.gz-dtb"
sha256sum "$S/out/arch/arm64/boot/Image.gz-dtb"
echo "REBUILD_DONE"
