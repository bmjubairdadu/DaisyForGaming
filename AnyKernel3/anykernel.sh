# AnyKernel3 Ramdisk Mod Script
## DaisyForGaming v5.2 by JUBAIR HOSEN (4.9.337, AK3 repack style)

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

ui_print " ";
ui_print "  ############################################";
ui_print "  #      D A I S Y  F O R  G A M I N G       #";
ui_print "  #             by JUBAIR HOSEN              #";
ui_print "  #                                          #";
ui_print "  #       Device  : Mi A2 Lite (daisy)       #";
ui_print "  #         Kernel  : 4.9.337 Gaming         #";
ui_print "  ############################################";
ui_print " ";

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
