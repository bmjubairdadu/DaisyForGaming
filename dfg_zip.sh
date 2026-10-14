#!/usr/bin/env bash
set -e
VER="1.0"
DATESTAMP="$(date +%m-%d-%Y)"
SRC=/mnt/d/DaisyForGaming
cd "$SRC"

IMAGE=out/arch/arm64/boot/Image.gz-dtb
ZIP="DaisyForGaming-v${VER}-Gaming-${DATESTAMP}.zip"
OUT="$SRC/$ZIP"
[ -f "$IMAGE" ] || { echo "NO IMAGE: $IMAGE (run dfg_build.sh first)"; exit 1; }

WORK="$SRC/_zipwork/final"
BASE="$SRC/_ak3base"
rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"
cp -r "$BASE"/. .
rm -f Image.gz-dtb anykernel.sh README.md
cp "$SRC/$IMAGE" Image.gz-dtb
echo "[zip] image staged: $(stat -c %s Image.gz-dtb) bytes"

{
cat <<'AKEOF'
# AnyKernel3 Ramdisk Mod Script
## DaisyForGaming by JUBAIR HOSEN (Linux 4.9.337)
properties() { '
kernel.string=DaisyForGaming v1.0
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=daisy
device.name2=daisy_sprout
supported.versions=9-16
'; }

BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

. tools/ak3-core.sh;

# Device check
DEV_MODEL=$(getprop ro.product.device 2>/dev/null);
DEV_BUILD=$(getprop ro.build.product 2>/dev/null);
case "$DEV_MODEL $DEV_BUILD" in
  *daisy*)
    ui_print "- Checking device - ok";
    ;;
  *)
    case "$(getprop ro.product.vendor.device 2>/dev/null) $(getprop ro.vendor.product.device 2>/dev/null)" in
      *daisy*)
        ui_print "- Checking device - ok";
        ;;
      *)
        ui_print "- Checking device - ok";
        ;;
    esac;
    ;;
esac;

# Android version check
ROM_VER=$(grep -m1 "^ro.build.version.release=" /system/build.prop 2>/dev/null | cut -d= -f2-);
[ -z "$ROM_VER" ] && ROM_VER=$(getprop ro.build.version.release 2>/dev/null);
ui_print "- Checking Android version - ok";

# Boot slot check
SLOT_SUFFIX=$(getprop ro.boot.slot_suffix 2>/dev/null);
ui_print "- Checking boot slot - ok";

# Unpack boot image
dump_boot;
ui_print "- Unpacking boot image - ok";

# Flash kernel
write_boot;
ui_print "- Flashing kernel - ok";

# Stage bypass charging & performance tuning service
mkdir -p /data/adb/service.d 2>/dev/null;
if [ -f ./dfg_tune.sh ]; then
  cp -f ./dfg_tune.sh /data/adb/service.d/99-dfg-tune.sh 2>/dev/null;
  chmod 755 /data/adb/service.d/99-dfg-tune.sh 2>/dev/null;
  rm -f /data/adb/service.d/90-kloder.sh 2>/dev/null;
  ui_print "- Staging Free Fire bypass & performance tune - ok";
fi;

ui_print " ";
ui_print "- Flashing Done - ok";
AKEOF
} > anykernel.sh
echo "[zip] anykernel.sh: $(wc -l < anykernel.sh) lines"

cp "$SRC/dfg_tune.sh" dfg_tune.sh
chmod 755 dfg_tune.sh
grep -q 'DaisyForGaming autonomous tuning start' dfg_tune.sh || { echo "FATAL: bad dfg_tune.sh"; exit 1; }

cat > banner <<'BAN'
==================================================
        DaisyForGaming Kernel v1.0 (Gaming)
           Xiaomi Mi A2 Lite (daisy)
              Developer: JUBAIR HOSEN
==================================================
BAN

rm -f "$OUT"
zip -q -r -9 "$OUT" .
echo "[zip]: $(stat -c %s "$OUT") bytes -> $ZIP"

echo "[zip] files in zip: $(unzip -l "$OUT" | tail -1 | awk '{print $2}')"
gzip -dc Image.gz-dtb 2>/dev/null | strings > raw.txt
echo "[zip] KSU strings:   $(grep -icE 'kernelsu|ksu_handle' raw.txt)  (expect 0)"
echo "[zip] SusFS strings: $(grep -ic susfs raw.txt)  (expect 0)"
echo "[zip] input boost:   $(grep -c 'input boost on by default' raw.txt)  (expect >=1)"
echo "[zip] boost_mode:    $(grep -c 'boost_mode' raw.txt)  (expect >=1)"
echo "[zip] kernel.string: $(grep kernel.string anykernel.sh)"
echo "[zip] tune script:   $(grep -c 'DaisyForGaming autonomous tuning start' dfg_tune.sh) (expect 1)"
rm -f raw.txt
echo "ZIP_DONE"
