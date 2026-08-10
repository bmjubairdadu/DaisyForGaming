#!/bin/bash
# ============================================================================
# release_kernel.sh - DaisyForGaming kernel build + GitHub Release publisher
#
# Usage:
#     ./scripts/release_kernel.sh                 # automated end-to-end
#     CHANGELOG="custom text" ./scripts/release_kernel.sh
#
# Pipeline:
#   1. Determine kernel version from source Makefile (never hardcoded)
#   2. Build the kernel with the project toolchain
#   3. Package a flashable AnyKernel3 ZIP (pack/ak3 + Image.gz-dtb)
#   4. Calculate SHA-256
#   5. Create a version tag (kernel-v<version>)
#   6. Create the GitHub Release + upload the ZIP
#   7. Fetch the REAL browser_download_url
#   8. Update kernel_update.json (version/date/url/sha256/changelog)
#   9. Commit + push the manifest
#  10. Print release information
#
# Safety: never duplicates an existing tag/release; stops if one exists.
# ============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; NC=$'\033[0m'

BRAND="DaisyForGaming"                       # release name suffix
OWNER="bmjubairdadu"
REPO="DaisyForGaming"
TOOLCHAIN="/opt/toolchains/proton-clang-13"  # project toolchain (clang-13)
DEFCONFIG="daisy_defconfig"
PKG_SRC="pack/ak3"                           # vendored AnyKernel3 template
DIST_DIR="dist"
BUILD_LOG="/tmp/kernel_release_build.log"

# --- 1. determine version ---------------------------------------------------
V="$(sed -n 's/^VERSION = *\([0-9]*\)/\1/p' Makefile | head -1)"
P="$(sed -n 's/^PATCHLEVEL = *\([0-9]*\)/\1/p' Makefile | head -1)"
S="$(sed -n 's/^SUBLEVEL = *\([0-9]*\)/\1/p' Makefile | head -1)"
E="$(sed -n 's/^EXTRAVERSION = *\(.*\)/\1/p' Makefile | head -1)"
[ -n "$V" ] && [ -n "$P" ] && [ -n "$S" ] || { echo "${RED}Cannot parse kernel version from Makefile${NC}"; exit 1; }
KVER="${V}.${P}.${S}${E}"
FULL="${KVER}-${BRAND}"
TAG="kernel-v${KVER}-${BRAND}"
ZIP="DaisyForGaming_v${KVER}-${BRAND}.zip"
echo "${GREEN}== Kernel version: $FULL ==${NC}"

# --- 2. prerequisites --------------------------------------------------------
command -v gh >/dev/null || { echo "${RED}gh CLI missing. Install: https://cli.github.com/${NC}"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "${RED}Not authenticated with gh. Run: gh auth login${NC}"; exit 1; }
[ -d "$TOOLCHAIN/bin" ] || { echo "${RED}Toolchain not found at $TOOLCHAIN.${NC}"; echo "Set TOOLCHAIN=/path/to/toolchain"; exit 1; }

# --- 3. stop if version already released --------------------------------------
if gh release view "$TAG" --repo "$OWNER/$REPO" >/dev/null 2>&1; then
    echo "${RED}Release $TAG already exists. Not creating a duplicate.${NC}"
    echo "Remove/delete the release+tag first if you really need to redo it."
    exit 1
fi
if git tag -l "$TAG" | grep -qx "$TAG"; then
    echo "${RED}Tag $TAG already exists locally. Refusing to duplicate.${NC}"
    exit 1
fi

# --- 4. build ----------------------------------------------------------------
echo "${YELLOW}== Building kernel ($(date)) ==${NC}"
export ARCH=arm64
export PATH="$PATH:$TOOLCHAIN/bin"
if [ ! -f out/.config ]; then
    make O=out "$DEFCONFIG"
fi
make -j"$(nproc)" O=out \
  CC="clang-13" AR="llvm-ar" AS="llvm-as" NM="llvm-nm" LD="ld.lld" \
  STRIP="llvm-strip" OBJCOPY="llvm-objcopy" OBJDUMP="llvm-objdump" \
  OBJSIZE="llvm-size" READELF="llvm-readelf" \
  CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
  2>&1 | tee "$BUILD_LOG"
IMAGE="out/arch/arm64/boot/Image.gz-dtb"
[ -f "$IMAGE" ] || { echo "${RED}Build finished without $IMAGE${NC}"; tail -20 "$BUILD_LOG"; exit 1; }
BANNER="$(gzip -dc "$IMAGE" | strings | grep -m1 'Linux version' || echo 'Linux version <unparsed>')"
echo "${GREEN}$BANNER${NC}"

# --- 5. package AnyKernel3 ZIP -----------------------------------------------
echo "${YELLOW}== Packaging flashable ZIP ==${NC}"
[ -d "$PKG_SRC" ] || { echo "${RED}Missing AnyKernel3 template: $PKG_SRC${NC}"; exit 1; }
mkdir -p "$DIST_DIR"
rm -rf .pkg_stage && cp -r "$PKG_SRC" .pkg_stage
rm -f .pkg_stage/Image* .pkg_stage/*.zip
cp "$IMAGE" .pkg_stage/Image.gz-dtb
( cd .pkg_stage && zip -r9q "../$DIST_DIR/$ZIP" . )
rm -rf .pkg_stage
SHA256="$(sha256sum "$DIST_DIR/$ZIP" | awk '{print $1}')"
echo "${GREEN}ZIP:  $DIST_DIR/$ZIP${NC}"
echo "${GREEN}SHA256: $SHA256${NC}"

# --- 6. changelog -------------------------------------------------------------
if [ -n "${CHANGELOG:-}" ]; then
    NOTES="$CHANGELOG"
else
    LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
    if [ -n "$LAST_TAG" ]; then
        NOTES="$(git log --oneline "$LAST_TAG"..HEAD)"
    else
        NOTES="$(git log --oneline -12)"
    fi
fi

# --- 7. create release ----------------------------------------------------------
echo "${YELLOW}== Creating GitHub release $TAG ==${NC}"
git tag "$TAG" -m "DaisyForGaming kernel $FULL"
gh release create "$TAG" "$DIST_DIR/$ZIP" \
    --repo "$OWNER/$REPO" \
    --title "DaisyForGaming kernel $FULL" \
    --notes "$BANNER

$NOTES"
git push origin "$TAG"

# --- 8. real download URL -------------------------------------------------------
RELEASE_JSON="$(gh api "repos/$OWNER/$REPO/releases/tags/$TAG")"
HTML_URL="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["html_url"])' <<<"$RELEASE_JSON")"
DOWNLOAD_URL="$(python3 -c 'import json,sys; d=json.load(sys.stdin)["assets"]; print(d[0]["browser_download_url"] if d else "")' <<<"$RELEASE_JSON")"
[ -n "$DOWNLOAD_URL" ] || { echo "${RED}No asset URL found on release${NC}"; exit 1; }
echo "${GREEN}Release:  $HTML_URL${NC}"
echo "${GREEN}Download: $DOWNLOAD_URL${NC}"

# --- 9. update manifest ------------------------------------------------------------
echo "${YELLOW}== Updating kernel_update.json ==${NC}"
python3 - "$FULL" "$DOWNLOAD_URL" "$SHA256" "$HTML_URL" "$NOTES" <<'PYEOF'
import json, sys, datetime
kver, dl, sha, rel, notes = sys.argv[1:6]
path = "kernel_update.json"
with open(path, encoding="utf-8") as f:
    m = json.load(f)
m["kernel_version"] = kver
m["release_date"] = datetime.date.today().isoformat()
m["download_url"] = dl
m["sha256"] = sha
m["release_url"] = rel
m["changelog"] = notes
m["mandatory"] = False
with open(path, "w", encoding="utf-8") as f:
    json.dump(m, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("manifest updated")
PYEOF

# --- 10. commit + push manifest ----------------------------------------------------
git add kernel_update.json
git commit -m "kernel_update.json: release $FULL

download: $DOWNLOAD_URL
sha256:   $SHA256"
if ! git push origin HEAD:main; then
    echo "${RED}Manifest commit could not be pushed (remote moved).${NC}"
    echo "Run: git pull --rebase origin main && git push origin HEAD:main"
    exit 1
fi

# --- 11. summary ---------------------------------------------------------------------
echo
echo "${GREEN}================ RELEASE COMPLETE ================${NC}"
echo "Kernel version : $FULL"
echo "Release        : $HTML_URL"
echo "ZIP download   : $DOWNLOAD_URL"
echo "SHA-256        : $SHA256"
echo "Manifest       : https://raw.githubusercontent.com/$OWNER/$REPO/main/kernel_update.json"
echo "${GREEN}===================================================${NC}"
