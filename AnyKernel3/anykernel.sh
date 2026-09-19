# AnyKernel3 Ramdisk Mod Script
## DaisyForGaming v1.0 by JUBAIR HOSEN (Panda 4.9.337, AK3 repack style)

### AnyKernel setup
# begin properties
properties() { '
kernel.string=DaisyForGaming v1.0 by JUBAIR HOSEN
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=daisy
device.name2=daisy_sprout
supported.versions=
supported.patchlevels=
supported.vendor.patchlevels=
'; } # end properties

# boot shell variables - MUST be UPPERCASE
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

### AnyKernel methods (do not change)
# import patching functions
. tools/ak3-core.sh;

# 1. Kernel main design text
ui_print " ";
ui_print "  ############################################";
ui_print "  #      D A I S Y  F O R  G A M I N G       #";
ui_print "  #             by JUBAIR HOSEN              #";
ui_print "  #                                          #";
ui_print "  #       Device  : Mi A2 Lite (daisy)       #";
ui_print "  #         Kernel  : 4.9.337 Gaming         #";
ui_print "  ############################################";
ui_print " ";

# 2. Checking device
ui_print "  Checking device...";
DEV_MODEL=$(getprop ro.product.device);
DEV_BUILD=$(getprop ro.build.product);
ui_print "  Device : $DEV_MODEL";
case "$DEV_MODEL $DEV_BUILD" in
  *daisy*)
    ui_print "  daisy confirmed. Continuing...";
    ;;
  *)
    abort "  This kernel is only for Mi A2 Lite (daisy). Aborting...";
    ;;
esac;
ui_print " ";

# 3. Checking Android version
ui_print "  Checking installed ROM version...";
ROM_VER=$(grep -m1 "^ro.build.version.release=" /system/build.prop 2>/dev/null | cut -d= -f2-);
ui_print "  ROM Android : $ROM_VER";
case "$ROM_VER" in
  9*|10*|11*|12*)
    ui_print "  Supported version. Continuing...";
    ;;
  "")
    ui_print "  Warning: ROM version unreadable, continuing...";
    ;;
  *)
    abort "  ROM Android $ROM_VER is not supported by DaisyForGaming. Aborting...";
    ;;
esac;
ui_print " ";

# 4. Checking slot
ui_print "  Checking slot...";
SLOT_SUFFIX=$(getprop ro.boot.slot_suffix);
if [ -z "$SLOT_SUFFIX" ]; then
  ui_print "  Slot : none (single boot partition)";
else
  ui_print "  Slot : $SLOT_SUFFIX";
fi;
ui_print " ";

# 5. Kernel flash path
ui_print "  Target : $BLOCK";
ui_print " ";

### AnyKernel install
dump_boot;

# 6. Kernel features one by one
ui_print "  Kernel features:";
ui_print "  + Base   : Linux 4.9.337 (Panda)";
ui_print "  + Timer  : HZ 300";
ui_print "  + Touch  : Input boost 150ms";
ui_print "  + Loader : Force-load + vermagic bypass";
ui_print "  + Root   : KALLSYMS_ALL (APatch ready)";
ui_print " ";

# DaisyForGaming is kernel + dtb only (Image.gz-dtb already
# contains the daisy device tree), so no ramdisk changes needed.

write_boot;
## end install

# 7. Flash complete text
ui_print " ";
ui_print "  Flashing done!";
ui_print "  Enjoy smooth gaming.";
ui_print "  Developer : JUBAIR HOSEN";
ui_print " ";
