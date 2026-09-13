#!/bin/bash
LNX=$HOME/daisy-build
echo "=== LNX OUT ==="
ls -lh "$LNX/out/" 2>&1
echo "=== LNX KIMAGE ==="
ls -lh "$LNX/kernel_source/out/arch/arm64/boot/Image.gz-dtb" 2>&1
echo "=== LNX BUILD LOG TAIL ==="
tail -n 25 "$LNX/out/build.log" 2>&1
echo "=== STILL RUNNING ==="
ps aux | grep -E "make.*Image|build\.sh|wsl-build" | grep -v grep | head -n 10
echo "=== VINTF CONFIG IN NEW BUILD ==="
grep -E "CONFIG_AUDIT=|CONFIG_AUDITSYSCALL|CONFIG_PROFILING=|CONFIG_HARDENED_USERCOPY=|CONFIG_NETFILTER_XT_TARGET_TRACE" "$LNX/kernel_source/out/.config" 2>&1
