#!/bin/bash
export ARCH=arm64 SUBARCH=arm64
export KBUILD_BUILD_USER=JUBAIR KBUILD_BUILD_HOST=JUBAIR-HOSEN
export PATH=/root/daisy-build/toolchain/proton-clang/bin:$PATH
S=/root/daisy-build/kernel_source
echo "=== ld.lld ==="
which ld.lld
ld.lld --version 2>&1 | head -2
echo "=== link ==="
date
make -C "$S" O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- -j$(nproc) Image.gz-dtb 2>&1 | tail -15
echo "=== result ==="
ls -lh "$S/out/arch/arm64/boot/Image.gz-dtb"
date
