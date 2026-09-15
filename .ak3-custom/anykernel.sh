# AnyKernel3 Ramdisk Mod Script
# DaisyForGaming by JUBAIR HOSEN - 4.9.337 Safe (No Pre-Root)
# Device: Xiaomi Mi A2 Lite (daisy / msm8953)

### AnyKernel3 setup ###
properties() { '
kernel.string=DaisyForGaming by JUBAIR HOSEN - 4.9.337 Safe (No Pre-Root)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=daisy
device.name2=msm8953
supported.versions=9-14
supported.patchlevels=
supported.vendorpatchlevels=
'; }

BLOCK=boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

### AnyKernel3 install ###
. tools/ak3-core.sh;

ui_print " ";
ui_print "  ╔════════════════════════════════════╗";
ui_print "  ║       D A I S Y  F O R G A M I N G ║";
ui_print "  ║   v1.0  ·  4.9.337 -DaisyForGaming ║";
ui_print "  ╠════════════════════════════════════╣";
ui_print "  ║  JUBAIR HOSEN  ·  Mi A2 Lite       ║";
ui_print "  ║  100% SAFE — No Pre-Root           ║";
ui_print "  ╚════════════════════════════════════╝";
ui_print " ";
# Kernel-only flash: split_boot + flash_boot keeps the stock ramdisk
# bit-identical (APatch note: patch the STOCK boot.img, flash this zip
# first, then flash the APatch image to BOTH slots; keep a boot backup).
split_boot;
flash_boot;
ui_print " ";
ui_print "  ✦ Kernel flashed — enjoy! ✦";
ui_print "  — JUBAIR HOSEN";
ui_print " ";
