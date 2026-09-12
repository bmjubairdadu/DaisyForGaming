#!/bin/bash
echo "=== toolchain dir ==="
ls /root/daisy-build/toolchain/ 2>&1
find /root/daisy-build/toolchain -maxdepth 2 2>&1 | head -20
echo "=== gcc ld available ==="
which aarch64-linux-gnu-ld
aarch64-linux-gnu-ld --version 2>&1 | head -2
echo "=== switch LD to GNU ==="
grep -n "LD_LLD\|LD_IS_LLD\|LD_VERSION" /root/daisy-build/kernel_source/out/.config
