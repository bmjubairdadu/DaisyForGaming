#!/usr/bin/env bash
# Builds THE DaisyForGaming flashable zip (AnyKernel3, sideload-flashable).
# One kernel, one zip: vanilla shape, root via FolkPatch (patch boot after
# flashing) or Magisk. Run from WSL after dfg_build.sh:
#   bash dfg_zip.sh   ->  DaisyForGaming-v1.0-Gaming-<DD-MM-YYYY>.zip
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

# ---- anykernel.sh (emitted at BUILD time, not flash time) ----
{
cat <<'AKEOF1'
# AnyKernel3 Ramdisk Mod Script
## DaisyForGaming by JUBAIR HOSEN (Linux 4.9.337)

properties() { '
kernel.string=DaisyForGaming v1.0
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=daisy
device.name2=daisy_sprout
supported.versions=11
supported.patchlevels=
supported.vendor.patchlevels=
'; }

BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

. tools/ak3-core.sh;

ui_print " ";
ui_print "  [1/4] Checking device ...";
DEV_MODEL=$(getprop ro.product.device);
DEV_BUILD=$(getprop ro.build.product);
ui_print "        Detected : $DEV_MODEL";
case "$DEV_MODEL $DEV_BUILD" in
  *daisy*)
    ui_print "        Mi A2 Lite (daisy) confirmed.";
    ;;
  *)
    abort "  Not a Mi A2 Lite (daisy) device. Aborting.";
    ;;
esac;

ui_print "  [2/4] Checking ROM version ...";
ROM_VER=$(grep -m1 "^ro.build.version.release=" /system/build.prop 2>/dev/null | cut -d= -f2-);
case "$ROM_VER" in
  11*)  ui_print "        Android $ROM_VER supported." ;;
  "")   ui_print "        Android version unreadable, continuing." ;;
  *)    abort "  Android $ROM_VER not supported by DaisyForGaming. Aborting." ;;
esac;

ui_print "  [3/4] Checking boot slot ...";
SLOT_SUFFIX=$(getprop ro.boot.slot_suffix);
ui_print "        Slot : ${SLOT_SUFFIX:-single}";

ui_print "  [4/4] Installing kernel ...";
ui_print "        Target : $BLOCK";

dump_boot;

ui_print " ";
ui_print "  Kernel features:";
ui_print "    - Linux 4.9.337  (DaisyForGaming v1.0 final)";
ui_print "    - CPU touch boost: 1036MHz little /";
ui_print "      1401MHz big, 150ms, charging-aware";
ui_print "      boost_mode=auto: running game detected";
ui_print "      by GPU load -> gaming boost, screen off";
ui_print "      -> battery, else balanced (0/1/2 to force)";
ui_print "    - Bypass charging: gaming on the charger";
ui_print "      feeds the board, battery charging pauses";
ui_print "    - schedutil snappy-ramp tuning, Adreno";
ui_print "      msm-adreno-tz + Adreno Idler";
ui_print "    - top-app schedtune boost (boot script)";
ui_print "    - zRAM lz4 + writeback, KSM";
ui_print "    - deadline IO scheduler, fq_codel + BBR";
ui_print "    - NO built-in root (vanilla kernel shape)";
ui_print "      -> FolkPatch: patch boot AFTER this zip";
ui_print "      -> Magisk works normally (ramdisk)";
ui_print " ";

write_boot;

# Stage the tuning service script so it survives reboots.
if [ -f ./dfg_tune.sh ]; then
  if [ -d /data/adb/service.d ]; then
    cp -f ./dfg_tune.sh /data/adb/service.d/99-dfg-tune.sh 2>/dev/null;
    chmod 755 /data/adb/service.d/99-dfg-tune.sh 2>/dev/null;
    ui_print "  Staged tuning script (boost profile assert,";
    ui_print "  top-app schedtune, zram retry, vm tuning).";
  else
    ui_print "  Magisk service.d not found, tuning script skipped.";
  fi;
fi;

# Remove the legacy broken kloder autoload script if present.
if [ -f /data/adb/service.d/90-kloder.sh ]; then
  rm -f /data/adb/service.d/90-kloder.sh 2>/dev/null;
  ui_print "  Removed obsolete kloder autoload script.";
fi;

ui_print " ";
ui_print "  Done! DaisyForGaming v1.0 installed.";
ui_print "  Root: FolkPatch (patch this boot) or Magisk.";
ui_print "  - JUBAIR HOSEN";
ui_print " ";
AKEOF1
} > anykernel.sh
echo "[zip] anykernel.sh: $(wc -l < anykernel.sh) lines"

# sanity: no build-time variable may leak into the flash-time script
grep -q 'VARIANT' anykernel.sh && { echo "FATAL: VARIANT leaked into anykernel.sh"; exit 1; }

# ---- tuning script: single source from repo ----
cp "$SRC/dfg_tune.sh" dfg_tune.sh
chmod 755 dfg_tune.sh
grep -q 'v1.0-final tuning start' dfg_tune.sh || { echo "FATAL: bad dfg_tune.sh"; exit 1; }

# ---- banner ----
cat > banner <<'BAN'
**************************************************
*        DaisyForGaming v1.0 (final line)        *
**************************************************
*  Device : Xiaomi Mi A2 Lite (daisy)           *
*  Kernel : 4.9.337-DaisyForGaming              *
*  -------------------------------------------- *
*  CPU touch boost 1036/1401MHz, 150ms         *
*  boost_mode: battery / balanced / gaming      *
*  Charging-aware boost + top-app boost         *
*  No built-in root: FolkPatch / Magisk ready   *
*  zRAM lz4 + writeback, deadline IO, BBR       *
*  VINTF compliant: no boot warning dialog      *
**************************************************
BAN

rm -f "$OUT"
zip -q -r -9 "$OUT" .
echo "[zip]: $(stat -c %s "$OUT") bytes -> $ZIP"

# ---- verification ----
echo "[zip] files in zip: $(unzip -l "$OUT" | tail -1 | awk '{print $2}')"
gzip -dc Image.gz-dtb 2>/dev/null | strings > raw.txt
echo "[zip] KSU strings:   $(grep -icE 'kernelsu|ksu_handle' raw.txt)  (expect 0)"
echo "[zip] SusFS strings: $(grep -ic susfs raw.txt)  (expect 0)"
echo "[zip] input boost:   $(grep -c 'input boost on by default' raw.txt)  (expect >=1)"
echo "[zip] boost_mode:    $(grep -c 'boost_mode' raw.txt)  (expect >=1)"
echo "[zip] kernel.string: $(grep kernel.string anykernel.sh)"
echo "[zip] tune script:   $(grep -c 'v1.0-final tuning start' dfg_tune.sh) (expect 1)"
rm -f raw.txt
echo "ZIP_DONE"
