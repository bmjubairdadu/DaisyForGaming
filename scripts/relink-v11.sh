#!/bin/bash
set -e
S=/root/daisy-build/kernel_source
export PATH=/root/daisy-build/toolchain/proton-clang/bin:$PATH
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export CLANG_TRIPLE=aarch64-linux-gnu-
export CC=clang
cd "$S"
echo "=== incremental relink (kallsyms.c + lds changed) ==="
make -j"$(nproc)" O=out Image.gz-dtb 2>&1 | tail -5
echo "=== LOOKUP ==="
grep -c "kallsyms_lookup_name\|kallsyms_on_each_symbol" out/System.map || echo "LOOKUP 0"
grep "kallsyms_lookup_name$\|kallsyms_on_each_symbol$" out/System.map
echo "=== strings in Image ==="
strings out/arch/arm64/boot/Image | grep -c kallsyms_lookup_name || true
echo "=== EMBEDDED ==="
./scripts/extract-ikconfig out/arch/arm64/boot/Image | grep -E "KALLSYMS_ALL|OVERLAY_FS=y|RANDOMIZE_BASE"
echo "=== SHA ==="
sha256sum out/arch/arm64/boot/Image.gz-dtb
ls -l out/arch/arm64/boot/Image.gz-dtb
