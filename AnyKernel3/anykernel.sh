# AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
#
# DaisyForGaming Kernel for Xiaomi Mi A2 Lite (daisy)
# Developer : JUBAIR HOSEN
# Base      : Linux 4.9.337 | Performance + Smooth + Gaming
# Features  : All Driver-Loaders supported, APatch/KernelSU ready

### AnyKernel setup
# begin properties
properties() { '
kernel.string=DaisyForGaming v2.4 by JUBAIR HOSEN (GCC build)
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

# boot shell variables - MUST be UPPERCASE (ak3-core.sh reads $BLOCK etc.)
# daisy is A-only eMMC: explicit path because auto-detect fails on OrangeFox
if [ -e /dev/block/bootdevice/by-name/boot ]; then
  BLOCK=/dev/block/bootdevice/by-name/boot;
elif [ -e /dev/block/platform/soc/7824900.sdhci/by-name/boot ]; then
  BLOCK=/dev/block/platform/soc/7824900.sdhci/by-name/boot;
else
  BLOCK=auto;
fi;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

### AnyKernel methods (do not change)
# import patching functions
. tools/ak3-core.sh;

### DaisyForGaming stylish flashing screen
ui_print " ";
ui_print "  ############################################";
ui_print "  #      D A I S Y  F O R  G A M I N G       #";
ui_print "  #             by JUBAIR HOSEN              #";
ui_print "  #                                          #";
ui_print "  #       Device  : Mi A2 Lite (daisy)       #";
ui_print "  #         Kernel  : 4.9.337 Gaming         #";
ui_print "  ############################################";
ui_print " ";

### Device + Android version check (runs after AK3 devicecheck)
ui_print "  Checking device and Android version...";
ui_print "  Device   : $(getprop ro.product.device 2>/dev/null)";
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null);
if [ ! "$ANDROID_VER" ]; then
  ANDROID_VER=$(grep -m1 "^ro.build.version.release=" /system/build.prop 2>/dev/null | cut -d= -f2-);
fi;
ui_print "  Android  : $ANDROID_VER";
case "$ANDROID_VER" in
  9*|10*|11*|12*)
    ui_print "  Supported version. Continuing...";
    ;;
  "")
    ui_print "  Warning: version undetectable, continuing...";
    ;;
  *)
    abort "  Android $ANDROID_VER is not supported by DaisyForGaming. Aborting...";
    ;;
esac;
ui_print " ";

### AnyKernel install
dump_boot;

# begin ramdisk changes

# DaisyForGaming is kernel + dtb only (Image.gz-dtb already
# contains the daisy device tree), so no ramdisk changes needed.

# end ramdisk changes

write_boot;
## end install

ui_print " ";
ui_print "  ############################################";
ui_print "  #              Flashing done!              #";
ui_print "  #           Enjoy smooth gaming.           #";
ui_print "  #         Developer : JUBAIR HOSEN         #";
ui_print "  ############################################";
ui_print " ";
