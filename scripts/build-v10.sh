#!/bin/bash
set -e
export PATH=/root/daisy-build/toolchain/proton-clang/bin:/root/daisy-build/proton-clang/bin:$PATH
S=/root/daisy-build/kernel_source

test -x /root/daisy-build/toolchain/proton-clang/bin/ld.lld
grep -E 'CONFIG_KALLSYMS(_ALL)?=|CONFIG_LOCALVERSION' "$S/out/.config"
make -C "$S" O=out ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
  -j"$(nproc)" Image.gz-dtb
test -s "$S/out/arch/arm64/boot/Image.gz-dtb"
ls -lh "$S/out/arch/arm64/boot/Image.gz-dtb"
