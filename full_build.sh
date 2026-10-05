#!/usr/bin/env bash
# DaisyForGaming - full kernel build -> out/arch/arm64/boot/Image.gz-dtb
#
# IMPORTANT: this tree MUST be built with Clang + LLD. It was originally
# shipped as a Clang/LLD build (see out/arch/arm64/kernel/.cpufeature.o.cmd),
# and the 4.9-era inline asm / macros in mm/ and arch/arm64/kernel/ do NOT
# compile with aarch64-linux-gnu-gcc 11 in this tree: DIV64_U64_ROUND_UP is
# absent from include/linux/math64.h, and arm64's asm goto jump_label fails
# with "impossible constraint". Switching toolchains also invalidates every
# prebuilt object, forcing a ~4000-file recompile.
#
# Run from WSL:  bash full_build.sh
set -o pipefail
cd /mnt/d/DaisyForGaming || exit 1

export ARCH=arm64
export SUBARCH=arm64

# The vendor build.sh (build.sh:246-259) passes every LLVM tool as an absolute
# path plus LLVM=1 / LLVM_IAS=1. CC must be set explicitly: with only LLVM=1
# exported, the 4.9 Makefile still falls back to aarch64-linux-gnu-gcc and
# `prepare-compiler-check` aborts with
# "Cannot use CONFIG_CC_STACKPROTECTOR_STRONG".
#
# If you cloned a vendor toolchain (clang-greenforce / clang-neutron /
# clang-weebx / clang-trb / clang-playground) as build.sh does, set
# DFG_CLANG_ROOT to its directory and everything below is picked up from there.
export DFG_CLANG_ROOT="${DFG_CLANG_ROOT:-}"
if [ -n "$DFG_CLANG_ROOT" ] && [ -x "$DFG_CLANG_ROOT/bin/clang" ]; then
	CLANG_BIN="$DFG_CLANG_ROOT/bin"
else
	CLANG_BIN="$(dirname "$(command -v clang)")"
fi

export CC="$CLANG_BIN/clang"
export LD="$CLANG_BIN/ld.lld"
export AR="$CLANG_BIN/llvm-ar"
export AS="$CLANG_BIN/llvm-as"
export NM="$CLANG_BIN/llvm-nm"
export OBJCOPY="$CLANG_BIN/llvm-objcopy"
export OBJDUMP="$CLANG_BIN/llvm-objdump"
export STRIP="$CLANG_BIN/llvm-strip"
export LLVM=1
export LLVM_IAS=1
# Kept only so 32-bit compat code can find binutils; with LLVM=1 the aarch64
# side is driven purely by $CC/$LD above.
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

export PATH="$PATH:/usr/lib/ccache"
export KBUILD_BUILD_USER=daisy
export KBUILD_BUILD_HOST=daisy
# NOTE: the version string comes from the committed .scmversion file only.
# scripts/setlocalversion does `cat .scmversion` and returns early, which avoids
# the multi-minute git walk this checkout triggers on DrvFS. Do NOT also export
# KBUILD_BUILD_VERSION here: its value is concatenated into
# out/include/generated/compile.h, so a stray newline corrupts the #define and
# breaks init/version.o with "missing terminating '\"' character".

echo "=== toolchain ==="
echo "CC   = $CC"
echo "LD   = $LD"
"$CC" --version 2>&1 | head -1

echo "=== regenerating daisy_defconfig ==="
make daisy_defconfig >/dev/null 2>&1 || { echo "DEFCONFIG FAILED"; exit 1; }
echo "=== config OK ==="

echo "=== building ($(nproc) jobs) ==="
make -j"$(nproc)" 2>&1 | tee /tmp/dfg_full.log | grep -E 'error:|Error [0-9]|LD |KernelSU|SUSFS|Image' || true
rc=${PIPESTATUS[0]}
echo "=== make exit: $rc ==="

echo "=== error count ==="
grep -c 'error:' /tmp/dfg_full.log || echo 0
echo "=== artifacts ==="
ls -la out/arch/arm64/boot/ 2>/dev/null | grep -Ei 'Image|dtb|System.map|vmlinux' || echo "NO IMAGE FOUND"
exit $rc