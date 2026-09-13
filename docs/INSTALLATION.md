# DaisyForGaming install guide - Mi A2 Lite (daisy), 4.9.337

1. Download `DaisyForGaming-v1.2-Gaming-4.9.337-*.zip`.
2. Reboot to TWRP / OrangeFox.
3. Backup boot (important!).
4. Flash the zip, wipe cache/dalvik, reboot.
5. Settings -> System -> About phone -> Kernel version should show `4.9.337-DaisyForGaming`.

Requirements: Xiaomi Mi A2 Lite (daisy) only (NOT jasmine_sprout / Mi A2), unlocked bootloader, TWRP 3.5+.
Works on Stock + LineageOS / PE / Evolution X / crDroid / Havoc / Arrow (Android 9-14)
because AnyKernel3 keeps your ramdisk.

Latest flashable zip: https://github.com/bmjubairdadu/DaisyForGaming/releases/tag/DaisyForGaming-v1.2

## Troubleshooting

### "There's an internal problem with your device" after flashing
This dialog is shown by Android (not a kernel crash) when the boot image's
ramdisk is unpacked and repacked during flash: the stock fingerprint check
no longer matches. The current zip avoids this with a kernel-only flash
(`split_boot` keeps your ramdisk bit-identical), so the dialog should NOT
appear with the latest `DaisyForGaming-v1.2` zip.

If you still see it (e.g. old zip), verify the kernel in
Settings -> System -> About phone -> Kernel version shows
`4.9.337-DaisyForGaming`, then just press OK. It causes no data loss
and is unrelated to root/FolkPatch.
