#!/usr/bin/env bash
# DaisyForGaming - incremental compile check for the patched subtrees.
# Run from WSL:  bash build_check.sh
set -o pipefail

cd /mnt/d/DaisyForGaming || exit 1
export ARCH=arm64
export SUBARCH=arm64
# Must match the toolchain the tree was originally built with (Clang + LLD);
# a GCC build of mm/ and arch/arm64/kernel/ fails on this 4.9 tree.
# CC must be explicit: with only LLVM=1 the 4.9 Makefile still picks
# aarch64-linux-gnu-gcc and prepare-compiler-check aborts.
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
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export PATH="$PATH:/usr/lib/ccache"
export KBUILD_BUILD_USER=daisy
export KBUILD_BUILD_HOST=daisy
# The repo has a .git dir on /mnt/d (DrvFS). `git describe` inside
# scripts/setlocalversion takes >60s there and stalls every kernel.release
# regeneration, so short-circuit it with the committed .scmversion file.
# Do not export KBUILD_BUILD_VERSION: it ends up inside
# out/include/generated/compile.h and a newline there corrupts the #define.

echo "=== regenerating config ==="
make daisy_defconfig >/dev/null 2>&1 || { echo "DEFCONFIG FAILED"; exit 1; }

echo "=== compiling fs/ drivers/input/ drivers/kernelsu/ ==="
# tee instead of tail so progress/error lines are flushed line-by-line and we
# still keep only the last 120 lines when the log is read back.
make -C out -j"$(nproc)" fs/ drivers/input/ drivers/kernelsu/ 2>&1 | tee /tmp/dfg_build_raw.log | grep -E 'error|Error|warning:|CHSTCHK' || true
echo "=== exit: ${PIPESTATUS[0]} ==="
echo "=== last 60 lines of raw build ==="
tail -60 /tmp/dfg_build_raw.log
echo "=== error count ==="
grep -c 'error:' /tmp/dfg_build_raw.log || echo 0