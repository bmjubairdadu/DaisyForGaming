### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=DaisyForGaming v4.9.337
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=daisy
device.name2=Mi_A2_Lite
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

ui_print "                                    "
ui_print "======================================"
ui_print "        DFG - DaisyForGaming          "
ui_print "         Kernel v4.9.337               "
ui_print "======================================"
ui_print " "
ui_print "Developed by: JUBAIR HOSEN"
ui_print "Device: Xiaomi Mi A2 Lite (daisy)"
ui_print " "
ui_print "Features included:"
ui_print " - CPU Governors (Schedutil, Interactive)"
ui_print " - BFQ I/O Scheduler"
ui_print " - KCAL Color Control"
ui_print " - GPU Frequency Control"
ui_print " - Gaming Charge Limiter"
ui_print " - Dynamic Fsync Control"
ui_print " - zRAM Support (lz4)"
ui_print " - TCP BBR Congestion Control"
ui_print " - KallSyms Hardening"
ui_print " - Wakelock Inspector Support"
ui_print " "
ui_print "Installing kernel..."
ui_print " "

# boot install
dump_boot; # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk

# init.rc - add cgroup cpu controller mount for DFG
backup_file init.rc;
replace_string init.rc "cpuctl cpu,timer_slack" "mount cgroup none /dev/cpuctl cpu" "mount cgroup none /dev/cpuctl cpu,timer_slack";

# fstab.qcom - Daisy (msm8953) fstab optimizations
# Disable barriers for better performance on eMMC
backup_file fstab.qcom;
patch_fstab fstab.qcom /system ext4 options "noatime,barrier=1" "noatime,nodiratime,barrier=0";
patch_fstab fstab.qcom /vendor ext4 options "noatime,barrier=1" "noatime,nodiratime,barrier=0";
patch_fstab fstab.qcom /data f2fs options "data=ordered" "nomblk_io_submit,data=writeback";

write_boot; # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
## end boot install

ui_print " "
ui_print "Installation complete!"
ui_print "Reboot and use DFG Controller app to configure features."
ui_print " "
ui_print "Thank you for using DaisyForGaming"
ui_print "         - JUBAIR HOSEN"
ui_print " "


## init_boot files attributes
#init_boot_attributes() {
#set_perm_recursive 0 0 755 644 $RAMDISK/*;
#set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
#} # end attributes

# init_boot shell variables
#BLOCK=init_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for init_boot patching
#reset_ak;

# init_boot install
#dump_boot; # unpack ramdisk since it is the new first stage init ramdisk where overlay.d must go

#write_boot;
## end init_boot install


## vendor_kernel_boot shell variables
#BLOCK=vendor_kernel_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for vendor_kernel_boot patching
#reset_ak;

# vendor_kernel_boot install
#split_boot; # skip unpack/repack ramdisk, e.g. for dtb on devices with hdr v4 and vendor_kernel_boot

#flash_boot;
## end vendor_kernel_boot install


## vendor_boot files attributes
#vendor_boot_attributes() {
#set_perm_recursive 0 0 755 644 $RAMDISK/*;
#set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
#} # end attributes

# vendor_boot shell variables
#BLOCK=vendor_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for vendor_boot patching
#reset_ak;

# vendor_boot install
#dump_boot; # use split_boot to skip ramdisk unpack, e.g. for dtb on devices with hdr v4 but no vendor_kernel_boot

#write_boot; # use flash_boot to skip ramdisk repack, e.g. for dtb on devices with hdr v4 but no vendor_kernel_boot
## end vendor_boot install