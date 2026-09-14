#!/bin/bash
# ============================================================================
#  DaisyForGaming - Fully Automated Gaming Kernel Build Script
#  Device  : Xiaomi Mi A2 Lite (daisy / msm8953 / SDM625) - 4.9.337 ONLY
#  Developer : JUBAIR HOSEN
#  Branding  : KBUILD_BUILD_USER=JUBAIR | KBUILD_BUILD_HOST=JUBAIR-HOSEN
#              CONFIG_LOCALVERSION=-DaisyForGaming
#  SECURITY  : 100% SAFE - NO PRE-ROOT (No KernelSU / APatch / FolkPatch)
#  Base    : TogoFire/kernel_xiaomi_panda (daisy) Linux 4.9.337
#  Compiler: System GCC cross (era-correct for 4.9) + Proton Clang host tools
#  Target  : arch/arm64/boot/Image.gz-dtb
#  Pack    : AnyKernel3 flashable zip (modern flash UI, 10% -> 100%)
#  Usage   : bash build.sh [clean|build|mkzip|all]
# ============================================================================

set -e

KERNEL_NAME="DaisyForGaming"
DEV_NAME="JUBAIR HOSEN"
export KBUILD_BUILD_USER="JUBAIR"
export KBUILD_BUILD_HOST="JUBAIR-HOSEN"
LOCALVERSION="-DaisyForGaming"
VERSION="v1.0-Gaming-4.9.337"
BUILD_DATE=$(date +%Y%m%d)
ZIP_NAME="${KERNEL_NAME}-${VERSION}-${BUILD_DATE}-AnyKernel3.zip"

export ARCH=arm64
export SUBARCH=arm64

# ---------- Verified 4.9.337 source ONLY ----------
KERNEL_REPO="https://github.com/TogoFire/kernel_xiaomi_panda.git"
KERNEL_REF="ff7b84e240fd035ca76d54bc95e64ce560461bf9"
AK3_REPO="https://github.com/osm0sis/AnyKernel3.git"
PROTON_CLANG_REPO="https://github.com/kdrag0n/proton-clang.git"

BASE_DIR=$(pwd)
OUT_DIR="$BASE_DIR/out"
KERNEL_SRC="$BASE_DIR/kernel_source"
AK3_DIR="$BASE_DIR/AnyKernel3"
AK3_OUT="$OUT_DIR/AnyKernel3"
FRAGMENT="$BASE_DIR/configs/daisy_gaming_defconfig"
CLANG_DIR="$BASE_DIR/toolchain/proton-clang"
KIMAGE="$KERNEL_SRC/out/arch/arm64/boot/Image.gz-dtb"
JOBS=$(nproc --all)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'
msg() { echo -e "${GREEN}[*] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
err() { echo -e "${RED}[X] $1${NC}"; }

echo -e "${BLUE}============================================${NC}"
echo -e "${MAGENTA}  DaisyForGaming by JUBAIR HOSEN          ${NC}"
echo -e "${BLUE}  Mi A2 Lite (daisy/msm8953) | 4.9.337 ONLY${NC}"
echo -e "${CYAN}  100% SAFE - NO PRE-ROOT (No KSU/APatch)  ${NC}"
echo -e "${BLUE}  GCC cross -> Image.gz-dtb -> AnyKernel3  ${NC}"
echo -e "${BLUE}============================================${NC}"

do_clean() {
  msg "Cleaning out/ and kernel out/..."
  rm -rf "$OUT_DIR" "$KERNEL_SRC/out" 2>/dev/null || true
  mkdir -p "$OUT_DIR"
  msg "Clean done"
}

setup_toolchain() {
  msg "Setting up toolchains (system GCC cross + Proton host tools)..."
  mkdir -p "$BASE_DIR/toolchain"
  if [ ! -d "$CLANG_DIR/bin" ] || [ -z "$(ls -A "$CLANG_DIR/bin" 2>/dev/null)" ]; then
    if [ -d "$CLANG_DIR/.git" ]; then
      git -C "$CLANG_DIR" pull --depth=1 2>/dev/null || true
    else
      rm -rf "$CLANG_DIR"
      git clone --depth=1 "$PROTON_CLANG_REPO" "$CLANG_DIR" || {
        err "Proton Clang clone failed! Check network."
        exit 1
      }
    fi
  else
    msg "Proton Clang exists - skipping clone"
  fi
  if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    msg "System cross GCC: $(aarch64-linux-gnu-gcc --version | head -n1)"
  else
    err "aarch64-linux-gnu-gcc missing. Install: sudo apt install gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi"
    exit 1
  fi
  export PATH="$CLANG_DIR/bin:$PATH"
  msg "Toolchain ready"
}

is_valid_daisy_49337() {
  [ -e "$KERNEL_SRC/.git" ] &&
    grep -qE '^VERSION[[:space:]]*=[[:space:]]*4$' "$KERNEL_SRC/Makefile" &&
    grep -qE '^PATCHLEVEL[[:space:]]*=[[:space:]]*9$' "$KERNEL_SRC/Makefile" &&
    grep -qE '^SUBLEVEL[[:space:]]*=[[:space:]]*337$' "$KERNEL_SRC/Makefile" &&
    git -C "$KERNEL_SRC" remote -v 2>/dev/null | grep -q "TogoFire/kernel_xiaomi_panda"
}

apply_tree_patches() {
  msg "Applying tree patches (FolkPatch compat + embedded IKCONFIG fix)..."
  bash "$BASE_DIR/scripts/apply-tree-patches.sh" "$KERNEL_SRC"
}

clone_kernel_source() {
  if [ -d "$KERNEL_SRC" ] && [ -n "$(ls -A "$KERNEL_SRC" 2>/dev/null)" ] && ! is_valid_daisy_49337; then
    err "Invalid kernel_source: expected TogoFire daisy Linux 4.9.337 tree."
    exit 1
  fi
  if [ ! -e "$KERNEL_SRC/.git" ]; then
    msg "Cloning TogoFire daisy Linux 4.9.337 source..."
    git clone --filter=blob:none "$KERNEL_REPO" "$KERNEL_SRC" || {
      err "Kernel source clone failed!"
      exit 1
    }
    git -C "$KERNEL_SRC" checkout --detach "$KERNEL_REF"
  else
    msg "Kernel source exists - keeping local tree..."
  fi
  if ! is_valid_daisy_49337; then
    err "Source is not the verified TogoFire daisy Linux 4.9.337 tree."
    git -C "$KERNEL_SRC" remote -v || true
    grep -E '^VERSION|^PATCHLEVEL|^SUBLEVEL' "$KERNEL_SRC/Makefile" || true
    exit 1
  fi
  msg "Kernel version: $(grep -E '^VERSION|^PATCHLEVEL|^SUBLEVEL' "$KERNEL_SRC/Makefile" | tr '\n' ' ')"
}

verify_no_root() {
  msg "SECURITY CHECK: verifying pristine (No KSU/APatch/FolkPatch)..."
  if [ -d "$KERNEL_SRC/KernelSU" ] || [ -d "$KERNEL_SRC/kernel/KernelSU" ] || \
     [ -e "$KERNEL_SRC/drivers/kernelsu" ] || [ -e "$KERNEL_SRC/APATCH" ]; then
    err "Root patch detected in source! Refusing to build (SAFE policy)."
    exit 1
  fi
  for opt in KSU APATCH KPM FOLKPATCH; do
    grep -q "CONFIG_${opt} is not set" "$FRAGMENT" 2>/dev/null || echo "# CONFIG_${opt} is not set" >> "$FRAGMENT"
  done
  msg "PASS: source is pristine - NO inline root. Anti-cheat safe."
}

find_base_defconfig() {
  local cand
  for cand in daisy_defconfig msm8953_defconfig msm8953-perf_defconfig; do
    if [ -f "$KERNEL_SRC/arch/arm64/configs/$cand" ]; then
      echo "$cand"
      return 0
    fi
  done
  cand=$(ls "$KERNEL_SRC/arch/arm64/configs/" | grep -i daisy | head -n1)
  if [ -n "$cand" ]; then echo "$cand"; return 0; fi
  err "No daisy/msm8953 base defconfig found in arch/arm64/configs/"
  ls "$KERNEL_SRC/arch/arm64/configs/" | head -n 50
  exit 1
}

apply_gaming_config() {
  msg "Applying Treble + Gaming defconfig (verified 4.9.337 daisy)..."
  mkdir -p "$KERNEL_SRC/out"
  local base
  base=$(find_base_defconfig)
  msg "Base defconfig: $base"
  make -C "$KERNEL_SRC" O=out ARCH=arm64 "$base"
  if [ -f "$KERNEL_SRC/scripts/kconfig/merge_config.sh" ]; then
    "$KERNEL_SRC/scripts/kconfig/merge_config.sh" -m -O "$KERNEL_SRC/out" \
      "$KERNEL_SRC/out/.config" "$FRAGMENT"
  else
    cat "$FRAGMENT" >> "$KERNEL_SRC/out/.config"
  fi
  "$KERNEL_SRC/scripts/config" --file "$KERNEL_SRC/out/.config" \
    --set-str LOCALVERSION "$LOCALVERSION" 2>/dev/null || \
    sed -i 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-DaisyForGaming"/' "$KERNEL_SRC/out/.config"
  grep -q '^CONFIG_LOCALVERSION=' "$KERNEL_SRC/out/.config" || \
    echo 'CONFIG_LOCALVERSION="-DaisyForGaming"' >> "$KERNEL_SRC/out/.config"
  make -C "$KERNEL_SRC" O=out ARCH=arm64 olddefconfig
  msg "Config ready: $(grep '^CONFIG_LOCALVERSION=' "$KERNEL_SRC/out/.config")"
}

do_build() {
  msg "Compiling 4.9.337 with GCC cross (jobs=$JOBS)..."
  mkdir -p "$OUT_DIR"
  make -C "$KERNEL_SRC" O=out ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    KBUILD_BUILD_USER="JUBAIR" KBUILD_BUILD_HOST="JUBAIR-HOSEN" \
    -j"$JOBS" Image.gz-dtb 2>&1 | tee "$OUT_DIR/build.log"
  if [ ! -f "$KIMAGE" ]; then
    err "Build failed - $KIMAGE not found. See out/build.log"
    exit 1
  fi
  msg "Built: $KIMAGE ($(du -h "$KIMAGE" | cut -f1))"
}

setup_ak3() {
  if [ ! -d "$AK3_DIR/.git" ]; then
    msg "Cloning AnyKernel3 engine..."
    rm -rf "$AK3_DIR"
    git clone --depth=1 "$AK3_REPO" "$AK3_DIR" || { err "AnyKernel3 clone failed!"; exit 1; }
    if [ -f "$BASE_DIR/.ak3-custom/anykernel.sh" ]; then
      cp "$BASE_DIR/.ak3-custom/anykernel.sh" "$AK3_DIR/anykernel.sh"
    fi
    if [ -f "$BASE_DIR/.ak3-custom/version" ]; then
      cp "$BASE_DIR/.ak3-custom/version" "$AK3_DIR/version"
    fi
    if [ -f "$BASE_DIR/.ak3-custom/thermal-engine-daisy-gaming.conf" ]; then
      cp "$BASE_DIR/.ak3-custom/thermal-engine-daisy-gaming.conf" "$AK3_DIR/thermal-engine-daisy-gaming.conf"
    fi
  else
    msg "AnyKernel3 exists - keeping"
  fi
  # Always refresh our custom files (fixes stale v1.2/42C wrapper bug:
  # setup_ak3 used to copy these only on first clone, so later .ak3-custom
  # fixes never reached the zip).
  if [ -f "$BASE_DIR/.ak3-custom/anykernel.sh" ]; then
    cp "$BASE_DIR/.ak3-custom/anykernel.sh" "$AK3_DIR/anykernel.sh"
  fi
  if [ -f "$BASE_DIR/.ak3-custom/version" ]; then
    cp "$BASE_DIR/.ak3-custom/version" "$AK3_DIR/version"
  fi
  if [ -f "$BASE_DIR/.ak3-custom/thermal-engine-daisy-gaming.conf" ]; then
    cp "$BASE_DIR/.ak3-custom/thermal-engine-daisy-gaming.conf" "$AK3_DIR/thermal-engine-daisy-gaming.conf"
  fi
}

do_mkzip() {
  msg "Packaging AnyKernel3 flashable zip..."
  if [ ! -f "$KIMAGE" ]; then err "No Image.gz-dtb. Run: bash build.sh build"; exit 1; fi
  setup_ak3
  rm -rf "$AK3_OUT"; mkdir -p "$AK3_OUT"
  cp -r "$AK3_DIR"/. "$AK3_OUT/"
  rm -rf "$AK3_OUT/.git"
  cp "$KIMAGE" "$AK3_OUT/Image.gz-dtb"
  mkdir -p "$AK3_OUT/modules/vendor/etc"
  if [ -f "$AK3_DIR/thermal-engine-daisy-gaming.conf" ]; then
    cp "$AK3_DIR/thermal-engine-daisy-gaming.conf" "$AK3_OUT/modules/vendor/etc/thermal-engine-daisy-gaming.conf"
  fi
  {
    echo "DaisyForGaming $VERSION by $DEV_NAME"
    echo "Device: Mi A2 Lite (daisy/msm8953)"
    echo "Base: TogoFire/kernel_xiaomi_panda Linux 4.9.337"
    echo "Localversion: $LOCALVERSION"
    echo "Built: $BUILD_DATE by $KBUILD_BUILD_USER@$KBUILD_BUILD_HOST"
    echo "SAFE: No Pre-Root (No KernelSU/APatch)"
  } > "$AK3_OUT/version"
  python3 - "$AK3_OUT/anykernel.sh" <<'PYEOF'
import re, sys
p = sys.argv[1]
src = open(p).read()
src = re.sub(r"kernel\.string=.*",
             "kernel.string=DaisyForGaming by JUBAIR HOSEN - 4.9.337 Safe (No Pre-Root)", src)
open(p, "w").write(src)
PYEOF
  ( cd "$AK3_OUT" && zip -r9 "$OUT_DIR/$ZIP_NAME" . -x ".git/*" )
  msg "ZIP ready: $OUT_DIR/$ZIP_NAME ($(du -h "$OUT_DIR/$ZIP_NAME" | cut -f1))"
  echo -e "${GREEN}  SAFE 4.9.337 - No Pre-Root - Flash: out/$ZIP_NAME${NC}"
}

case "${1:-all}" in
  clean) do_clean ;;
  build)
    do_clean
    setup_toolchain
    clone_kernel_source
    verify_no_root
    apply_tree_patches
    apply_gaming_config
    do_build
    ;;
  mkzip) do_mkzip ;;
  all)
    do_clean
    setup_toolchain
    clone_kernel_source
    verify_no_root
    apply_tree_patches
    apply_gaming_config
    do_build
    do_mkzip
    ;;
  *) echo "Usage: bash build.sh [clean|build|mkzip|all]"; exit 1 ;;
esac
