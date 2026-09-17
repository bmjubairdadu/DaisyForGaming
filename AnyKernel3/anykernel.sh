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

# shell variables
# block is resolved below (after ak3-core import) - daisy is A-only
block=auto;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

### AnyKernel methods (do not change)
# import patching functions
. tools/ak3-core.sh;

# Daisy boot partition: explicit paths because auto-detection fails
# on some recoveries ("unable to determine partition" error)
if [ -e /dev/block/bootdevice/by-name/boot ]; then
  block=/dev/block/bootdevice/by-name/boot;
elif [ -e /dev/block/platform/soc/7824900.sdhci/by-name/boot ]; then
  block=/dev/block/platform/soc/7824900.sdhci/by-name/boot;
else
  abort "Boot partition not found! Note your recovery name/version and tell JUBAIR HOSEN.";
fi;

### DaisyForGaming stylish flashing screen
ui_print " ";
ui_print "  ############################################";
ui_print "  #                                          #";
ui_print "  #     D A I S Y  F O R  G A M I N G        #";
ui_print "  #                                          #";
ui_print "  #       Developer : JUBAIR HOSEN           #";
ui_print "  #       Device    : Mi A2 Lite (daisy)     #";
ui_print "  #       Kernel    : 4.9.337 Gaming         #";
ui_print "  #                                          #";
ui_print "  ############################################";
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
ui_print "  ********************************************";
ui_print "  *   Flashing done! Enjoy smooth gaming.    *";
ui_print "  *   Developer : JUBAIR HOSEN               *";
ui_print "  ********************************************";
ui_print " ";
