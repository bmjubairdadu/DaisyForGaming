# Fast testing (no flashing required)
====================================

The fastest way to test a build is `fastboot boot`, which runs the kernel
from RAM without touching the boot partition.

Prerequisites
-------------
* adb + fastboot from the Android platform-tools
* Unlocked bootloader on the device (required for both methods)
* A build: `./build_kernel.sh` produces `out/arch/arm64/boot/Image.gz-dtb`

Method 1 - fastboot boot (no flash, reboot-safe)
------------------------------------------------
1. Reboot the device to the bootloader:

       adb reboot bootloader

2. Boot the kernel from RAM:

       fastboot boot out/arch/arm64/boot/Image.gz-dtb

   The kernel boots into Android normally. A plain reboot (`adb reboot`)
   restores the previously installed kernel.

3. Sanity checks after boot (root adb shell):

       adb root
       adb shell "cat /proc/version"
       adb shell "ls -l /sys/devices/platform/dfg/"
       adb shell "cat /sys/devices/platform/dfg/profile"   # expect: performance
       adb shell "cat /sys/devices/platform/dfg/thermal_limits"

Method 2 - AnyKernel3 ZIP (permanent install via TWRP)
------------------------------------------------------
1. Build the flashable ZIP:

       ./build_kernel.sh --with-zip

   Result: `out/dist/DaisyForGaming-<version>.zip`

2. Reboot to TWRP:

       adb reboot recovery

3. Install the ZIP, reboot, verify as above.

Reverting
---------
* fastboot boot: just reboot - the old kernel is still installed.
* TWRP install: flash a stock boot image (`fastboot flash boot boot.img`)
  or re-flash the previous DaisyForGaming ZIP.

Risks
-----
* A kernel that fails to boot with fastboot boot is harmless - reboot and
  try another build.
* The DFG default performance profile keeps CPU min frequency high and may
  raise idle temperature; thermal throttling and the hard thermal limit
  remain active (see docs/SYSFS_API.md).