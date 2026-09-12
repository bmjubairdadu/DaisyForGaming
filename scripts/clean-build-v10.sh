#!/bin/bash
set -e
export PATH=/root/daisy-build/toolchain/proton-clang/bin:/root/daisy-build/proton-clang/bin:$PATH
S=/root/daisy-build/kernel_source

make -C "$S" O=out ARCH=arm64 clean
make -C "$S" O=out ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
  -j"$(nproc)" Image.gz-dtb
test -s "$S/out/arch/arm64/boot/Image.gz-dtb"
grep -E '^CONFIG_(DEBUG_KERNEL|KALLSYMS(_ALL)?|LOCALVERSION)=' "$S/out/.config"
ls -lh "$S/out/arch/arm64/boot/Image.gz-dtb"
