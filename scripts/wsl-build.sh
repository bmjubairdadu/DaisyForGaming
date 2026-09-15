#!/bin/bash
# WSL-native DaisyForGaming build (ext4) - REQUIRED, do not build on /mnt/d.
#
# Why: kernel_source checked out on Windows (NTFS) can NEVER build:
#  1. git symlinks (arch/arm64/boot/dts/include/dt-bindings) become plain
#     text files -> DTC fails: "dt-bindings/gpio/gpio.h: No such file".
#  2. NTFS is case-insensitive: net/netfilter/xt_HL.c vs xt_hl.c (and
#     xt_DSCP.c/xt_dscp.c, xt_TCPMSS.c/xt_tcpmss.c, ...) collide, one
#     overwrites the other -> "No rule to make target 'net/netfilter/xt_HL.o'".
#
# This script builds on ext4 ($HOME/daisy-build) reusing repo build.sh,
# then copies Image.gz-dtb + zip + build.log back to /mnt/d/Kernel/out/.
set -e
WIN=/mnt/d/Kernel
LNX=$HOME/daisy-build
REF=ff7b84e240fd035ca76d54bc95e64ce560461bf9
REPO=https://github.com/TogoFire/kernel_xiaomi_panda.git
SRC=$LNX/kernel_source

mkdir -p "$LNX" "$WIN/out"
for d in configs patches scripts .ak3-custom docs; do
  [ -e "$LNX/$d" ] || ln -s "$WIN/$d" "$LNX/$d"
done

# Fresh Linux-native source (skip if already valid)
if [ ! -e "$SRC/.git" ]; then
  echo "[*] Cloning TogoFire 4.9.337 on ext4..."
  git clone --filter=blob:none "$REPO" "$SRC"
fi
git -C "$SRC" checkout --detach "$REF"

echo "[*] Sanity: case-sensitive files + symlinks must exist:"
ls "$SRC/net/netfilter/xt_HL.c" "$SRC/net/netfilter/xt_hl.c"
ls "$SRC/net/netfilter/xt_DSCP.c" "$SRC/net/netfilter/xt_dscp.c"
test -L "$SRC/arch/arm64/boot/dts/include/dt-bindings" && echo "SYMLINK_OK"

cd "$LNX"
bash "$WIN/build.sh" all

echo "=== COPY ARTIFACTS BACK ==="
ls -lh "$LNX"/out/*.zip
cp -f "$LNX"/out/*.zip "$WIN/out/"
cp -f "$LNX/out/build.log" "$WIN/out/build.log"
ls -lh "$SRC/out/arch/arm64/boot/Image.gz-dtb"
cp -f "$SRC/out/arch/arm64/boot/Image.gz-dtb" "$WIN/out/" 2>/dev/null || true
echo "=== CONFIG PROOF ==="
grep -E "CONFIG_KPROBES=|CONFIG_PROC_KCORE=|CONFIG_UNUSED_SYMBOLS=|CONFIG_DYNAMIC_FSYNC=|CONFIG_DEVFREQ_BOOST=|CONFIG_KALLSYMS_ALL=|CONFIG_MODULES=|CONFIG_LOCALVERSION=" "$SRC/out/.config"
echo "=== WIN OUT ==="
ls -lh "$WIN/out/"
