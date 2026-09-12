#!/bin/bash
echo "=== dirs ==="
ls /root/daisy-build/ 2>&1
ls /mnt/d/Kernel/toolchain/ 2>&1
ls /mnt/d/Kernel/toolchain/proton-clang/ 2>&1 | head -20
echo "=== find ld ==="
find / -maxdepth 5 -name "ld.lld" 2>/dev/null | head -5
echo "=== find clang ==="
ls /root/daisy-build/proton-clang/ 2>&1 | head
find /mnt/d/Kernel -maxdepth 4 -name "clang" -type f 2>/dev/null | head -3
echo "=== LD config ==="
grep -E "LD_LLD|LD_VERSION|LD_IS_LLD" /root/daisy-build/kernel_source/out/.config
