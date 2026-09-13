#!/bin/bash
cd /tmp || exit 1
rm -rf zipverify && mkdir zipverify && cd zipverify || exit 1
unzip -o -q "/mnt/d/Kernel/out/DaisyForGaming-v1.2-Gaming-4.9.337-20260913-AnyKernel3.zip" anykernel.sh
echo "=== BOOT FUNCS ==="
grep -n -E "split_boot|dump_boot|write_boot|flash_boot" anykernel.sh | head -n 10
echo "=== PROPS ==="
grep -n -E "do.systemless|do.modules|supported.patchlevels|supported.vendorpatchlevels" anykernel.sh
