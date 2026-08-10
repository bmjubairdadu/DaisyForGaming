#!/bin/bash
# build_kernel.sh - plain kernel build (no release), O=out, project toolchain.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
export ARCH=arm64
export PATH="/opt/toolchains/proton-clang-13/bin:$PATH"
[ -f out/.config ] || make O=out daisy_defconfig
make -j"$(nproc)" O=out \
  CC="clang-13" AR="llvm-ar" AS="llvm-as" NM="llvm-nm" LD="ld.lld" \
  STRIP="llvm-strip" OBJCOPY="llvm-objcopy" OBJDUMP="llvm-objdump" \
  OBJSIZE="llvm-size" READELF="llvm-readelf" \
  CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
echo "Image: out/arch/arm64/boot/Image.gz-dtb"
