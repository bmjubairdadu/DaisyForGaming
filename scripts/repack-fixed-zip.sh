#!/bin/bash
# Repack-only: rebuild AnyKernel3 zip with current Image.gz-dtb + fixed ak script.
# No kernel recompile needed (Image.gz-dtb already built from good ext4 build).
set -e
WIN=/mnt/d/Kernel
LNX=$HOME/daisy-build
cd "$LNX"
echo "[*] Syncing fixed ak script + version:"
cp -f "$WIN/.ak3-custom/anykernel.sh" "$WIN/.ak3-custom/version" "$WIN/.ak3-custom/thermal-engine-daisy-gaming.conf" /tmp/ 2>/dev/null || true
ls -l /tmp/anykernel.sh
grep -nE "split_boot|dump_boot|do.systemless|supported.patchlevels" /tmp/anykernel.sh || cp -f "$WIN/.ak3-custom/anykernel.sh" "$LNX/.ak3-custom/anykernel.sh"
for f in anykernel.sh version thermal-engine-daisy-gaming.conf; do
  cp -f "$WIN/.ak3-custom/$f" "$LNX/AnyKernel3/$f" 2>/dev/null || cp -f "$WIN/.ak3-custom/$f" /tmp/
done
echo "[*] Repacking zip from existing Image.gz-dtb (no recompile)..."
ls -lh "$LNX/kernel_source/out/arch/arm64/boot/Image.gz-dtb"
bash "$WIN/build.sh" mkzip
echo "=== COPY BACK ==="
ls -lh "$LNX"/out/*.zip
cp -f "$LNX"/out/*.zip "$WIN/out/"
ls -lh "$WIN/out/"
echo "=== ZIP CHECK: ramdisk untouched path ==="
unzip -p "$WIN"/out/*.zip anykernel.sh | grep -nE "split_boot|dump_boot|do.systemless" | head -n 10
