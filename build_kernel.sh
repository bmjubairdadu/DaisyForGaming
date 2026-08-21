#!/usr/bin/env bash
#
# build_kernel.sh - reproducible DaisyForGaming kernel build for daisy
#
# Produces:
#   out/arch/arm64/boot/Image.gz-dtb   - bootable kernel image
#   out/arch/arm64/boot/Image          - uncompressed image (debug)
#   out/modules/                       - external modules (if any)
#   out/dist/DaisyForGaming-*.zip      - AnyKernel3 flashable ZIP (optional)
#
# Requirements (Linux only; see .github/workflows/kernel-build.yml):
#   - clang-13/llvm-13/lld-13 or a cross GCC aarch64 toolchain
#   - make, zip, python3
#
# Usage:
#   ./build_kernel.sh                 # defconfig + kernel (uses clang if found)
#   ./build_kernel.sh clean           # wipe out/ first
#   CC=clang-13 ./build_kernel.sh
#   CROSS_COMPILE=aarch64-linux-gnu- ./build_kernel.sh   # force GCC
#   ./build_kernel.sh --with-zip      # also build the AnyKernel3 ZIP
#
set -euo pipefail

DEFCONFIG="${DEFCONFIG:-daisy_defconfig}"
ARCH="arm64"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"
OUT="out"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SRC"

if [ "${1:-}" = "clean" ] || [ "${1:-}" = "--clean" ]; then
	rm -rf "$OUT"
	shift || true
fi

WITH_ZIP=0
for arg in "$@"; do
	case "$arg" in
		--with-zip) WITH_ZIP=1 ;;
		*) echo "unknown argument: $arg" >&2; exit 1 ;;
	esac
done

# ----------------------------------------------------------------------
# Toolchain selection
# ----------------------------------------------------------------------
# Prefer LLVM/clang (LTO build) when available; fall back to GCC.
if [ -n "${CC:-}" ]; then
	TOOLCHAIN=manual
elif command -v clang-13 >/dev/null 2>&1; then
	TOOLCHAIN=clang
elif command -v clang >/dev/null 2>&1; then
	TOOLCHAIN=clang
else
	TOOLCHAIN=gcc
fi

case "$TOOLCHAIN" in
	clang)
		CC="${CC:-clang}"
		MAKE_TOOLCHAIN=(
			CC="$CC"
			AR=llvm-ar
			AS=llvm-as
			NM=llvm-nm
			LD=ld.lld
			STRIP=llvm-strip
			OBJCOPY=llvm-objcopy
			OBJDUMP=llvm-objdump
			OBJSIZE=llvm-size
			READELF=llvm-readelf
			HOSTCC=gcc
			HOSTCXX=g++
		)
		CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
		CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32:-arm-linux-gnueabi-}"
		;;
	gcc|manual)
		CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
		CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32:-arm-linux-gnueabi-}"
		MAKE_TOOLCHAIN=()
		;;
esac

if ! command -v "${CROSS_COMPILE}gcc" >/dev/null 2>&1 &&
   [ "$TOOLCHAIN" != "manual" ]; then
	echo "error: ${CROSS_COMPILE}gcc not found on PATH" >&2
	echo "  install e.g. gcc-aarch64-linux-gnu, or set CC=clang-13 and" >&2
	echo "  have clang/llvm/lld tools on PATH (see ci/)." >&2
	exit 1
fi

# ----------------------------------------------------------------------
# Build
# ----------------------------------------------------------------------
echo "==> DaisyForGaming build"
echo "    defconfig : $DEFCONFIG"
echo "    toolchain : $TOOLCHAIN (CC=${CC:-${CROSS_COMPILE}gcc})"
echo "    jobs      : $JOBS"

mkdir -p "$OUT"

make O="$OUT" ARCH="$ARCH" "$DEFCONFIG"

make -j"$JOBS" O="$OUT" ARCH="$ARCH" \
	"CROSS_COMPILE=$CROSS_COMPILE" \
	"CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32" \
	"${MAKE_TOOLCHAIN[@]}" \
	Image.gz-dtb dtbs modules

# ----------------------------------------------------------------------
# Modules
# ----------------------------------------------------------------------
rm -rf "$OUT/modules"
make -j"$JOBS" O="$OUT" ARCH="$ARCH" \
	"CROSS_COMPILE=$CROSS_COMPILE" \
	"CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32" \
	"${MAKE_TOOLCHAIN[@]}" \
	INSTALL_MOD_PATH="$OUT/modules" modules_install

# ----------------------------------------------------------------------
# Results
# ----------------------------------------------------------------------
IMAGE="$OUT/arch/arm64/boot/Image.gz-dtb"
test -f "$IMAGE" || { echo "error: $IMAGE not produced" >&2; exit 1; }

VERSION="$(make O="$OUT" -s kernelversion)-DaisyForGaming"
echo "==> Build OK: $VERSION"
echo "    $IMAGE"
echo "    $OUT/modules/  (module tree)"
echo "    boot via:  fastboot boot $IMAGE"

if [ "$WITH_ZIP" = "1" ] && [ -d "pack/ak3" ]; then
	mkdir -p "$OUT/dist"
	rm -rf "$OUT/.pkg"
	cp -r pack/ak3 "$OUT/.pkg"
	cp "$IMAGE" "$OUT/.pkg/Image.gz-dtb"
	pushd "$OUT/.pkg" >/dev/null
	zip -r9q "../dist/DaisyForGaming-$VERSION.zip" .
	popd >/dev/null
	rm -rf "$OUT/.pkg"
	echo "    zip: $OUT/dist/DaisyForGaming-$VERSION.zip (TWRP flashable)"
fi