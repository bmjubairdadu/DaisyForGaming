#!/usr/bin/env bash
# v1.16-FolkPatch build - same source as v1.15 but CONFIG_KSU=n (+ SusFS off).
# Vanilla-shaped kernel so FolkPatch (LyraVoid fork of KernelPatch/APatch) can
# patch the boot image without hook conflicts. FolkPatch V6 Sol syncs KP 0.13.9
# which contains the 4.9 x29 boot-hang fix.
SRC=/mnt/d/DaisyForGaming
cd "$SRC"

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export PATH=$PATH:/usr/lib/ccache
export LLVM=1 LLVM_IAS=1
export KBUILD_BUILD_USER=daisy KBUILD_BUILD_HOST=daisy

LOG=$SRC/.dfg_build_fp.log
: > "$LOG"

echo "toolchain: $(clang --version | head -1)"

echo "=== pre-build source checks ==="
grep -q 'CONFIG_KSU is not set' arch/arm64/configs/daisy_fp_defconfig \
  && echo DEFCONFIG_OK || { echo "FATAL: fp defconfig wrong"; exit 1; }
grep -q 'CONFIG_LOCALVERSION="-DaisyForGaming"' arch/arm64/configs/daisy_fp_defconfig \
  && echo LOCALVERSION_OK || { echo "FATAL: LOCALVERSION wrong"; exit 1; }

make O=out-fp ARCH=arm64 daisy_fp_defconfig 2>&1 | tail -3

echo "=== sanity (must be vanilla-shaped for FolkPatch) ==="
grep -E '^CONFIG_LOCALVERSION=' out-fp/.config
echo "KSU lines in config: $(grep -c '^CONFIG_KSU' out-fp/.config)  (expect 0)"
grep -E '^# CONFIG_KSU_SUSFS is not set' out-fp/.config | head -1
grep -E '^CONFIG_KALLSYMS=|^CONFIG_KALLSYMS_ALL=|^CONFIG_KPROBES=|^CONFIG_MODVERSIONS=' out-fp/.config
grep -E '^CONFIG_IOSCHED_DEADLINE=|^CONFIG_INPUT_BOOST_FREQ=|^CONFIG_INPUT_BOOST_FREQ_BIG=|^CONFIG_INPUT_BOOST_SCHED=|^CONFIG_ZRAM_DEFAULT_COMP_ALGORITHM=' out-fp/.config

echo "=== build (this takes a while) ==="
make O=out-fp ARCH=arm64 -j8 2>&1 | tee -a "$LOG" | grep -E 'error:|Error [0-9]|Kernel panic' | head -20
echo "--- warnings count: $(grep -c 'warning:' "$LOG" 2>/dev/null) ---"

ls -l out-fp/arch/arm64/boot/Image.gz-dtb && echo IMAGE_OK

echo "=== banner + absence checks ==="
strings out-fp/vmlinux 2>/dev/null | grep -oE '4\.9\.337-DaisyForGaming[^ ]*' | head -1
echo "KSU strings:   $(strings out-fp/vmlinux 2>/dev/null | grep -c -i kernelsu)  (expect 0)"
echo "SusFS strings: $(strings out-fp/vmlinux 2>/dev/null | grep -c -i susfs)  (expect 0)"
echo "input boost:   $(strings out-fp/vmlinux 2>/dev/null | grep -c 'input boost on by default')"

echo FP_BUILD_DONE
