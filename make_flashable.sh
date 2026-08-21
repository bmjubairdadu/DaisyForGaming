#!/usr/bin/env bash
#
# make_flashable.sh - Create a flashable Magisk module ZIP for DaisyForGaming kernel
#
# Usage:
#   ./make_flashable.sh                    # Uses existing Image.gz-dtb in out/
#   ./make_flashable.sh --build            # Build kernel first, then package
#   ./make_flashable.sh --zip-name=foo.zip # Custom output name
#
# Output: dfg_kernel-<date>.zip (Magisk module format)
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

BUILD_FIRST=0
ZIP_NAME=""

for arg in "$@"; do
    case "$arg" in
        --build) BUILD_FIRST=1 ;;
        --zip-name=*) ZIP_NAME="${arg#--zip-name=}" ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

# Build kernel if requested
if [ "$BUILD_FIRST" = "1" ]; then
    echo "==> Building kernel..."
    ./build_kernel.sh
fi

# Find the kernel image
IMAGE="out/arch/arm64/boot/Image.gz-dtb"
if [ ! -f "$IMAGE" ]; then
    echo "Error: Kernel image not found at $IMAGE" >&2
    echo "Run with --build or build first using ./build_kernel.sh" >&2
    exit 1
fi

# Determine version from Makefile
V="$(sed -n 's/^VERSION = *\([0-9]*\)/\1/p' Makefile | head -1)"
P="$(sed -n 's/^PATCHLEVEL = *\([0-9]*\)/\1/p' Makefile | head -1)"
S="$(sed -n 's/^SUBLEVEL = *\([0-9]*\)/\1/p' Makefile | head -1)"
E="$(sed -n 's/^EXTRAVERSION = *\(.*\)/\1/p' Makefile | head -1)"
KVER="${V}.${P}.${S}${E}"

DATE="$(date +%Y%m%d)"
OUTPUT="${ZIP_NAME:-dfg_kernel-${DATE}.zip}"

echo "==> Creating Magisk module ZIP: $OUTPUT"

# Clean up any previous staging
rm -rf magisk-module/system/lib/modules
mkdir -p magisk-module/system/lib/modules

# Copy kernel image to Magisk module (Magisk will inject it via boot image patching)
# Note: The actual boot image patching is done by Magisk at install time
# We include the Image.gz-dtb here for reference/verification
cp "$IMAGE" magisk-module/Image.gz-dtb

# Copy kernel modules if they exist
if [ -d "out/modules" ]; then
    find out/modules -name "*.ko" -exec cp {} magisk-module/system/lib/modules/ \;
fi

# Create the ZIP
cd magisk-module
zip -r9q "../$OUTPUT" .
cd ..

# Verify
if [ -f "$OUTPUT" ]; then
    SHA256="$(sha256sum "$OUTPUT" | awk '{print $1}')"
    echo "==> Created: $OUTPUT"
    echo "    SHA256: $SHA256"
    echo "    Size: $(du -h "$OUTPUT" | cut -f1)"
else
    echo "Error: Failed to create ZIP" >&2
    exit 1
fi

echo "==> Flash via Magisk Manager or TWRP"