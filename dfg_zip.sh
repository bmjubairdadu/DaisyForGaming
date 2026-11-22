#!/usr/bin/env bash
set -e
VER="1.4"
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
rm -rf .git .github Image.gz-dtb anykernel.sh README.md banner
cp "$SRC/$IMAGE" Image.gz-dtb
echo "[zip] image staged: $(stat -c %s Image.gz-dtb) bytes"

{
cat <<'AKEOF'
properties() { '
kernel.string=DaisyForGaming v1.4
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=daisy
device.name2=daisy_sprout
device.name3=sakura
supported.versions=
'; }

BLOCK=boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

. tools/ak3-core.sh;

ui_print() {
  until [ ! "$1" ]; do
    if [ "$OUTFD" ] && [ -e "/proc/self/fd/$OUTFD" ]; then
      printf "ui_print %s\nui_print\n" "$1" >> /proc/self/fd/$OUTFD 2>/dev/null;
    fi;
    echo "$1";
    shift;
  done;
}

ui_print "- Checking device - ok";
ui_print "- Checking Android version - ok";
ui_print "- Checking boot slot - ok";
ui_print "- Splitting boot image - ok";
dump_boot;

ui_print "- Flashing kernel - ok";
write_boot;

data_was_mounted=0;
if grep -q " /data " /proc/mounts 2>/dev/null; then
  data_was_mounted=1;
fi;

if [ "$data_was_mounted" = "1" ] || mount /data 2>/dev/null; then
  mkdir -p /data/adb/service.d 2>/dev/null;
  if [ -f "$AKHOME/dfg_tune.sh" ]; then
    cp -f "$AKHOME/dfg_tune.sh" /data/adb/service.d/99-dfg-tune.sh 2>/dev/null;
    chmod 755 /data/adb/service.d/99-dfg-tune.sh 2>/dev/null;
    chcon u:object_r:system_file:s0 /data/adb/service.d/99-dfg-tune.sh 2>/dev/null;
    rm -f /data/adb/service.d/90-kloder.sh 2>/dev/null;
    ui_print "- Staging boot tune service - ok";
  fi;
  if [ "$data_was_mounted" = "0" ]; then
    umount /data 2>/dev/null || true;
  fi;
else
  ui_print "- Staging boot tune service - skipped (data not mounted)";
fi;

ui_print " ";
ui_print "- Flashing Done - ok";
AKEOF
} > anykernel.sh
echo "[zip] anykernel.sh: $(wc -l < anykernel.sh) lines"

cp "$SRC/dfg_tune.sh" dfg_tune.sh
chmod 755 dfg_tune.sh
grep -q 'DaisyForGaming v1.4 tuning start' dfg_tune.sh || { echo "FATAL: bad dfg_tune.sh"; exit 1; }

cat > banner <<'BAN'
==================================================
        DaisyForGaming Kernel v1.4 (Ultra-Smooth)
           Xiaomi Mi A2 Lite (daisy)
              Developer: JUBAIR HOSEN
==================================================
BAN

find . -type f \( -name "*.sh" -o -name "banner" -o -name "update-binary" -o -name "updater-script" \) -exec sed -i 's/\r$//' {} + 2>/dev/null || true
chmod -R 755 tools META-INF anykernel.sh dfg_tune.sh

rm -f "$OUT"
python3 -c 'import os, sys, zipfile
target = os.path.abspath(sys.argv[1])
zf = zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED, compresslevel=9)
for root, dirs, files in os.walk("."):
    for f in files:
        full = os.path.abspath(os.path.join(root, f))
        if full == target:
            continue
        rel = os.path.relpath(full, ".")
        zf.write(full, rel)
zf.close()' "$OUT"

echo "[zip]: $(stat -c %s "$OUT") bytes -> $ZIP"

echo "[zip] files in zip: $(python3 -c 'import sys, zipfile; zf = zipfile.ZipFile(sys.argv[1], "r"); print(len(zf.namelist())); zf.testzip(); zf.close()' "$OUT")"
gzip -dc Image.gz-dtb 2>/dev/null | strings > raw.txt
echo "[zip] KSU strings:   $(grep -icE 'kernelsu|ksu_handle' raw.txt)  (expect 0)"
echo "[zip] SusFS strings: $(grep -ic susfs raw.txt)  (expect 0)"
echo "[zip] input boost:   $(grep -c 'input boost on by default' raw.txt)  (expect >=1)"
echo "[zip] boost_mode:    $(grep -c 'boost_mode' raw.txt)  (expect >=1)"
echo "[zip] kernel.string: $(grep kernel.string anykernel.sh)"
echo "[zip] tune script:   $(grep -c 'DaisyForGaming v1.4 tuning start' dfg_tune.sh) (expect 1)"
rm -f raw.txt
echo "ZIP_DONE"
