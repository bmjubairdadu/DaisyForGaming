#!/bin/bash
echo "=== VINTF CONFIG ==="
grep -E "CONFIG_FHANDLE|CONFIG_AUDIT=|CONFIG_HARDENED_USERCOPY=|CONFIG_PROFILING=|CONFIG_NETFILTER_XT_TARGET_TRACE" /home/jubair/daisy-build/kernel_source/out/.config
echo "=== AK FUNCS ==="
grep -n -E "split_boot|dump_boot|write_boot|flash_boot" /home/jubair/daisy-build/AnyKernel3/anykernel.sh | head -n 10
echo "=== ZIP ==="
ls -lh /home/jubair/daisy-build/out/*.zip /home/jubair/daisy-build/kernel_source/out/arch/arm64/boot/Image.gz-dtb
