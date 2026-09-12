#!/bin/bash
export ARCH=arm64 SUBARCH=arm64
export KBUILD_BUILD_USER=JUBAIR KBUILD_BUILD_HOST=JUBAIR-HOSEN
S=/root/daisy-build/kernel_source
echo "=== 1. find ld.lld ==="
find /root/daisy-build -maxdepth 3 -name "ld.lld" 2>/dev/null | head -3
ls /root/daisy-build/proton-clang/bin/ld.lld 2>&1
ls /mnt/d/Kernel/toolchain/proton-clang/bin/ld.lld 2>&1
which ld.lld 2>&1
echo "=== 2. export PATH + rebuild link only ==="
for d in /root/daisy-build/proton-clang/bin /mnt/d/Kernel/toolchain/proton-clang/bin; do
  if [ -x "$d/ld.lld" ]; then export PATH="$d:$PATH"; echo "PATH += $d"; break; fi
done
which ld.lld
echo "=== 3. link ==="
date
make -C "$S" O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- -j$(nproc) Image.gz-dtb 2>&1 | tail -15
echo "=== 4. result ==="
ls -lh "$S/out/arch/arm64/boot/Image.gz-dtb"
date
