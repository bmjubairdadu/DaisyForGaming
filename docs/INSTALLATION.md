# DaisyForGaming install guide - Mi A2 Lite (daisy), 4.9.337

1. Download `DaisyForGaming-v1.2-Gaming-4.9.337-*.zip`.
2. Reboot to TWRP / OrangeFox.
3. Backup boot (important!).
4. Flash the zip, wipe cache/dalvik, reboot.
5. Settings -> System -> About phone -> Kernel version should show `4.9.337-DaisyForGaming`.

Requirements: Xiaomi Mi A2 Lite (daisy) only (NOT jasmine_sprout / Mi A2), unlocked bootloader, TWRP 3.5+.
Works on Stock + LineageOS / PE / Evolution X / crDroid / Havoc / Arrow (Android 9-14)
because AnyKernel3 keeps your ramdisk.

Latest flashable zip: https://github.com/bmjubairdadu/DaisyForGaming/releases/tag/v1.2-4.9.337

## Troubleshooting

### "There's an internal problem with your device" after flashing
This dialog is shown by Android (not a kernel crash) when the boot image
is modified: unlocked bootloader + custom kernel means verified-boot
reports `orange` and the stock fingerprint check no longer matches.
If the phone reaches the lockscreen, the kernel is working — just press OK.

- Verify: Settings -> System -> About phone -> Kernel version shows
  `4.9.337-DaisyForGaming`.
- It reappears once per boot while any custom kernel is installed.
  The only way to remove it is restoring your stock boot backup
  (TWRP -> Restore -> Boot), which also removes the custom kernel.
- It causes no data loss and is unrelated to root/FolkPatch.
