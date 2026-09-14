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
ui_print "==============================================";
ui_print "  D A I S Y F O R G A M I N G";
ui_print "  v1.2.4 | 4.9.337 -DaisyForGaming";
ui_print "  Developer : JUBAIR HOSEN";
ui_print "  Mi A2 Lite (daisy) | 100% SAFE - No Root";
ui_print "==============================================";
ui_print " ";
ui_print "[##------------------] 10% Starting...";
# Kernel-only flash: split_boot + flash_boot skips ramdisk unpack AND repack,
# so the stock ramdisk stays bit-identical. write_boot would repack (and with
# no unpacked ramdisk it packed the whole tmp dir -> 85MB image -> the
# "New image larger than target partition" abort + internal-problem dialog).
split_boot;
ui_print "[######--------------] 30% Boot image split (ramdisk untouched)";
ui_print "[##########----------] 50% Kernel patched";
ui_print " ";
ui_print " Installing features step by step:";
ui_print " [1/6] CPU : schedutil/ondemand/conservative/powersave/userspace + input-boost";
ui_print "[############--------] 60% CPU done";
ui_print " [2/6] GPU : msm-adreno-tz + adreno-idler";
ui_print "[##############------] 68% GPU done";
ui_print " [3/6] NET : TCP BBR/CUBIC/WESTWOOD avail (westwood default)";
ui_print "[###############-----] 76% NET done";
ui_print " [4/6] IO  : BFQ avail + CFQ + ZRAM";
ui_print "[################----] 84% IO done";
ui_print " [5/6] UI  : KCAL ctrl + DT2W gesture sysfs + Thermal";
ui_print "[##################--] 90% UI done";
ui_print " [6/6] SYS : Treble + Binder + F2FS + wakelock filter (off)";
ui_print "[###################-] 95% SYS done";
ui_print " ";
flash_boot;
ui_print "[####################] 100% Flash complete";
ui_print "  Flash Complete! - JUBAIR HOSEN";
ui_print " ";
