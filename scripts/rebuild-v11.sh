#!/bin/bash
# DaisyForGaming v1.1 - FULL clean rebuild with all tree-patch fixes
set -e
export PATH=/root/daisy-build/toolchain/proton-clang/bin:/root/daisy-build/proton-clang/bin:$PATH
S=/root/daisy-build/kernel_source
D=/mnt/d/Kernel
echo "=== 0. preflight ==="
test -x /root/daisy-build/toolchain/proton-clang/bin/ld.lld || test -x /root/daisy-build/proton-clang/bin/ld.lld
echo "ld.lld OK"
echo "=== 1. apply all repo patches ==="
bash "$D/scripts/apply-tree-patches.sh" "$S"
echo "=== 2. REMOVE out entirely ==="
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
grep -E "^CONFIG_KALLSYMS_ALL=|^CONFIG_KALLSYMS=|LOCALVERSION" "$S/out/.config"
test "$(grep -c '^CONFIG_KALLSYMS_ALL=y' "$S/out/.config")" = "1"
echo "DOTCONFIG_OK"
echo "=== 8. full build ==="
make -C "$S" O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- -j"$(nproc)" Image.gz-dtb
test -s "$S/out/arch/arm64/boot/Image.gz-dtb"
echo "=== 9. verify EMBEDDED config matches ==="
"$S/scripts/extract-ikconfig" "$S/out/arch/arm64/boot/Image" > /root/emb-v11.cfg
grep -E "KALLSYMS|OVERLAY_FS" /root/emb-v11.cfg | head -8
grep -q "^CONFIG_KALLSYMS_ALL=y" /root/emb-v11.cfg || { echo "EMBEDDED_MISMATCH_FAIL"; exit 1; }
diff <(grep -E "^CONFIG_KALLSYMS_ALL" "$S/out/.config") <(grep -E "^CONFIG_KALLSYMS_ALL" /root/emb-v11.cfg) && echo "EMBEDDED_OK"
echo "=== 10. verify lookup symbols kept ==="
grep -q "kallsyms_lookup_name" "$S/out/System.map" || { echo "LOOKUP_MISSING_FAIL"; exit 1; }
grep -q "kallsyms_on_each_symbol" "$S/out/System.map" || { echo "ONEACH_MISSING_FAIL"; exit 1; }
echo "LOOKUP_OK"
ls -lh "$S/out/arch/arm64/boot/Image" "$S/out/arch/arm64/boot/Image.gz-dtb"
sha256sum "$S/out/arch/arm64/boot/Image.gz-dtb"
echo "REBUILD_V11_DONE"
