#!/bin/bash
S=/root/daisy-build/kernel_source
C="$S/out/.config"
echo "=== FINAL KP CHECK ==="
echo "--- arch arm64? ---"
grep -E "^CONFIG_ARM64=y|^CONFIG_64BIT" "$C"
echo "--- version 3.18-6.6? ---"
grep -E "^VERSION|^PATCHLEVEL|^SUBLEVEL" "$S/Makefile"
echo "--- KALLSYMS=y? ---"
grep -E "^CONFIG_KALLSYMS=y" "$C" && echo PRESENT || echo MISSING
echo "--- Image uncompressed size (>3MB needed for KP patch) ---"
ls -lh "$S/out/arch/arm64/boot/Image"
echo "--- CONFIG_MODULES? ---"
grep -E "^CONFIG_MODULES=" "$C" || echo "MODULES OFF (check)"
echo "--- STRIP_ASM_SYMS off? ---"
grep -E "STRIP_ASM_SYMS" "$C"
echo "--- kallsyms in Image? (strings check) ---"
strings "$S/out/arch/arm64/boot/Image" 2>/dev/null | grep -c "kallsyms" || echo "strings check skipped"
