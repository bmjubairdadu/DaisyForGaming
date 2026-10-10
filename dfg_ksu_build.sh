#!/usr/bin/env bash
# DaisyForGaming v1.1 KSU build (KernelSU + SusFS, manual kprobe-free hooks).
# Mirrors dfg_fp_build.sh env so both variants ship from one toolchain.
SRC=/mnt/d/DaisyForGaming
cd "$SRC"

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export PATH=$PATH:/usr/lib/ccache
export LLVM=1 LLVM_IAS=1
export KBUILD_BUILD_USER=daisy KBUILD_BUILD_HOST=daisy

LOG=$SRC/.dfg_build_ksu_v11.log
: > "$LOG"

echo "toolchain: $(clang --version | head -1)"

echo "=== pre-build source checks ==="
grep -q '^CONFIG_KSU=y' arch/arm64/configs/daisy_defconfig \
  && echo DEFCONFIG_OK || { echo "FATAL: KSU defconfig wrong"; exit 1; }
grep -q 'bool ksu_vfs_read_hook __read_mostly = true' drivers/kernelsu/ksud.c \
  && echo MANUAL_HOOK_FLAGS_OK || { echo "FATAL: hook flags missing"; exit 1; }
if grep -q 'register_kprobe' drivers/kernelsu/ksud.c drivers/kernelsu/sucompat.c; then
  echo "FATAL: kprobe registration leftovers in ksud.c/sucompat.c"; exit 1
fi
echo KPROBE_FREE_OK

# Objects from the pre-v1.1 tree: ksud.o was built with the kprobe branch, so
# it lacks the hook flags the fs/ call sites reference. Nuke and rebuild.
rm -rf out/drivers/kernelsu

make O=out ARCH=arm64 daisy_defconfig 2>&1 | tail -2

echo "=== sanity ==="
grep -E '^CONFIG_KSU=|^CONFIG_KSU_SUSFS=|^CONFIG_KPROBES=|^CONFIG_LOCALVERSION=' out/.config
grep -E '^CONFIG_INPUT_BOOST_FREQ=|^CONFIG_INPUT_BOOST_FREQ_BIG=|^CONFIG_INPUT_BOOST_DURATION_MS=|^CONFIG_INPUT_BOOST_SCHED=' out/.config

echo "=== build ==="
make O=out ARCH=arm64 -j8 2>&1 | tee -a "$LOG" | grep -E 'error:|Error [0-9]|undefined symbol' | head -30
echo "--- warnings: $(grep -c 'warning:' "$LOG" 2>/dev/null) ---"

ls -l out/arch/arm64/boot/Image.gz-dtb && echo IMAGE_OK

echo "=== strings checks ==="
strings out/vmlinux | grep -oE '4\.9\.337-DaisyForGaming[^ ]*' | head -1
echo "KSU strings:  $(strings out/vmlinux | grep -c -i kernelsu)  (expect >0)"
echo "SusFS strings: $(strings out/vmlinux | grep -c susfs)  (expect >0)"
echo "manual hooks: $(strings out/vmlinux | grep -c 'manual (kprobe-free) hooks active')  (expect >=1)"
echo "input boost:  $(strings out/vmlinux | grep -c 'input boost on by default')  (expect >=1)"
echo "charge guard: $(strings out/vmlinux | grep -c 'boost_on_charging')  (expect >=1)"
echo KSU_BUILD_DONE
