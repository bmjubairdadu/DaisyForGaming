#!/bin/bash
set -e
export PATH=/root/daisy-build/toolchain/proton-clang/bin:$PATH
B=/root/daisy-build
S=$B/kernel_source
which ld.lld
echo '[*] Compiling with Proton in PATH...'
make -C $S O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- KBUILD_BUILD_USER=JUBAIR KBUILD_BUILD_HOST=JUBAIR-HOSEN -j12 Image.gz-dtb 2>&1 | tee $B/out/build-final3.log | tail -n 5
ls -lh $S/out/arch/arm64/boot/Image.gz-dtb
echo BUILD_FINAL3_OK
