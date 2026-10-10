#!/usr/bin/env bash
# DaisyForGaming v1.0 (final line) - THE build. Vanilla-shaped kernel:
# KernelSU/SusFS removed from the tree, root via FolkPatch (patch boot after
# flashing) or Magisk. Run from WSL:  bash dfg_build.sh
SRC=/mnt/d/DaisyForGaming
cd "$SRC" || exit 1

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export PATH=$PATH:/usr/lib/ccache
export LLVM=1 LLVM_IAS=1
export KBUILD_BUILD_USER=daisy KBUILD_BUILD_HOST=daisy

LOG=$SRC/.dfg_build.log
: > "$LOG"

echo "toolchain: $(clang --version | head -1)"

echo "=== pre-build source checks ==="
if grep -q '^CONFIG_KSU=' arch/arm64/configs/daisy_defconfig drivers/Makefile 2>/dev/null; then
  echo "FATAL: CONFIG_KSU reference still in tree"; exit 1
fi
if [ -d drivers/kernelsu ]; then
  echo "FATAL: drivers/kernelsu still present"; exit 1
fi
grep -q 'CONFIG_LOCALVERSION="-DaisyForGaming"' arch/arm64/configs/daisy_defconfig \
  && echo LOCALVERSION_OK || { echo "FATAL: LOCALVERSION wrong"; exit 1; }
grep -q '^CONFIG_KALLSYMS_ALL=y' arch/arm64/configs/daisy_defconfig \
  && echo KALLSYMS_OK || { echo "FATAL: KALLSYMS_ALL off (FolkPatch needs it)"; exit 1; }
grep -q '^CONFIG_KPROBES=y' arch/arm64/configs/daisy_defconfig \
  && echo KPROBES_OK || { echo "FATAL: KPROBES off"; exit 1; }
grep -q '^CONFIG_MODVERSIONS=y' arch/arm64/configs/daisy_defconfig \
  && echo MODVERSIONS_OK || { echo "FATAL: MODVERSIONS off (VINTF)"; exit 1; }
echo DEFCONFIG_OK

make O=out ARCH=arm64 daisy_defconfig 2>&1 | tail -3

echo "=== sanity (must be vanilla-shaped for FolkPatch/Magisk) ==="
grep -E '^CONFIG_LOCALVERSION=' out/.config
echo "KSU lines in config: $(grep -c '^CONFIG_KSU' out/.config)  (expect 0)"
echo "SusFS lines in config: $(grep -c 'SUSFS' out/.config)  (expect 0)"
grep -E '^CONFIG_KALLSYMS=|^CONFIG_KALLSYMS_ALL=|^CONFIG_KPROBES=|^CONFIG_MODVERSIONS=' out/.config
grep -E '^CONFIG_CPU_BOOST=|^CONFIG_INPUT_BOOST_FREQ=|^CONFIG_INPUT_BOOST_FREQ_BIG=|^CONFIG_INPUT_BOOST_DURATION_MS=|^CONFIG_INPUT_BOOST_SCHED=|^CONFIG_ZRAM_DEFAULT_COMP_ALGORITHM=' out/.config

echo "=== build (this takes a while) ==="
make O=out ARCH=arm64 -j8 2>&1 | tee -a "$LOG" | grep -E 'error:|Error [0-9]|Kernel panic' | head -20
echo "--- warnings count: $(grep -c 'warning:' "$LOG" 2>/dev/null) ---"

ls -l out/arch/arm64/boot/Image.gz-dtb && echo IMAGE_OK

echo "=== banner + absence checks ==="
strings out/vmlinux 2>/dev/null | grep -m1 'Linux version 4\.9'
echo "KSU strings:   $(strings out/vmlinux 2>/dev/null | grep -c -i kernelsu)  (expect 0)"
echo "SusFS strings: $(strings out/vmlinux 2>/dev/null | grep -c -i susfs)  (expect 0)"
echo "input boost:   $(strings out/vmlinux 2>/dev/null | grep -c 'input boost on by default')"
echo "boost_mode:    $(strings out/vmlinux 2>/dev/null | grep -c 'boost_mode=auto')  (expect >=1)"

echo BUILD_DONE
