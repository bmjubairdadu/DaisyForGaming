# INSTALLATION

Safe installation guide for the DaisyForGaming kernel.

> ⚠️ **Read this entirely first.** A bad or wrong kernel flash can leave the
> phone unbootable. The procedures below are the supported ones — do not
> flash this kernel with tools or for devices it was not designed for.

## 1. Compatibility check

- Device must be a **Xiaomi Mi A2 Lite** (`daisy`).
- The installer enforces this itself: AnyKernel3 performs a device check
  (`daisy` / `Mi_A2_Lite`) and **aborts** on any other device.
- Base system: Android 11 (Android 10 base images are *not* the tested
  target of this project — see [COMPATIBILITY.md](COMPATIBILITY.md)).

## 2. Backup requirements

**Make a backup before flashing.** At minimum back up the boot image:

- TWRP → **Backup** → select **Boot** (and System, if you want) → swipe.
  This is the recommended method — restoring it is trivial.
- or copy the current boot partition manually (requires root, device-specific):
  ```sh
  dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot_backup.img
  ```
  (the exact by-name path is device-specific — verify on your device first).

Keep the backup on external storage and keep a known-good boot image.
Without a backup, a bad flash can only be recovered via fastboot flashing
a full stock boot image (`fastboot flash boot boot.img`) — see below.

## 3. Install via TWRP (supported method)

1. Download the release ZIP (from the GitHub Release page or via DFG Controller)
   and place it on internal or external storage.
2. **Verify the checksum** (optional but recommended):
   ```sh
   sha256sum DaisyForGaming-4.9.337-10-08-2026.zip
   # compare against the manifest / release notes:
   curl -s https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json
   ```
3. Boot to **TWRP recovery**.
4. TWRP → **Install** → select the ZIP.
5. The installer checks the device, patches the boot image (Magisk is
   preserved via magiskboot), and writes only the **boot** partition.
6. **Swipe to confirm**.
7. Reboot to system.

## 4. Verify the installation

After booting:

```sh
uname -r        # should print: 4.9.337-DaisyForGaming
cat /proc/version
```

Optionally confirm feature toggles exist:

```sh
ls /sys/kernel/dyn_fsync/           # dynamic fsync
cat /sys/kernel/dyn_fsync/dyn_fsync # 1 = on
grep -o 'bbr' /proc/sys/net/ipv4/tcp_available_congestion_control
```

## 5. Rollback

- **TWRP backup restore:** TWRP → Restore → your backup → Boot → reboot.
- **Previous kernel ZIP:** flash the previous DaisyForGaming release ZIP
  the same way as step 3.
- **Stock boot image (fastboot):**
  ```sh
  fastboot flash boot boot.img
  fastboot reboot
  ```
  (boot.img must be the stock/known-good boot image for your exact ROM.)

## 6. After a bootloop

1. Do not panic; the device is usually recoverable.
2. Force-reboot to recovery (Power + Volume Down, device-specific).
3. Restore your Boot backup or re-flash the previous known-good kernel.
4. If no backup exists, flash the full stock `boot.img` via fastboot, then
   proceed with a fresh setup.

## Notes on what this installer does NOT do

- It does **not** flash dtbo, vendor, system, or super partitions.
- It does **not** wipe data.
- It does **not** modify your ROM's ramdisk beyond the standard
  magiskboot boot-image handling.
