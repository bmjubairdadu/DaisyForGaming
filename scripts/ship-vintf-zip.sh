#!/bin/bash
# Copy VINTF-fixed artifacts back to Windows out/ with distinct name
LNX=$HOME/daisy-build
WIN=/mnt/d/Kernel
DATE=$(date +%Y%m%d)
SRC_ZIP=$(ls -t "$LNX"/out/*.zip | head -n 1)
NEW_NAME="DaisyForGaming-v1.2.2-VINTF-${DATE}-AnyKernel3.zip"
echo "SRC: $SRC_ZIP"
ls -lh "$SRC_ZIP" "$LNX/kernel_source/out/arch/arm64/boot/Image.gz-dtb"
cp -f "$SRC_ZIP" "$WIN/out/$NEW_NAME"
cp -f "$LNX/out/build.log" "$WIN/out/build-vintf-${DATE}.log"
echo "=== VINTF CONFIG PROOF ==="
grep -E "CONFIG_AUDIT=|CONFIG_AUDITSYSCALL|CONFIG_PROFILING=|CONFIG_HARDENED_USERCOPY=|CONFIG_NETFILTER_XT_TARGET_TRACE|CONFIG_KALLSYMS_BASE_RELATIVE|CONFIG_LD_BFD|CONFIG_LOCALVERSION=" "$LNX/kernel_source/out/.config"
echo "=== WIN OUT ==="
ls -lh "$WIN/out/"
echo "=== ZIP AK CHECK ==="
unzip -p "$WIN/out/$NEW_NAME" anykernel.sh | grep -nE "^(split_boot|dump_boot|write_boot|flash_boot);" | head -n 5
