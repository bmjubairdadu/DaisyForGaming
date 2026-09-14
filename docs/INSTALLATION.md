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
This dialog is shown by Android (not a kernel crash) when
`VintfObject.verifyWithoutAvb` fails against the Treble framework matrix
(logcat: `Build fingerprint is not consistent`). Proven 2026-09-14 on live
daisy (crDroid 11 + DaisyForGaming 4.9.337) against
`/system/etc/vintf/compatibility_matrix.3.xml` 4.9.84 main block (185 configs):
only `CONFIG_MODULES=y + CONFIG_MODULE_UNLOAD=y + CONFIG_MODVERSIONS=y`
mismatch when the kernel has `MODULES=n`. The repo fragment now sets all
three `=y` (+ `AUDIT/AUDITSYSCALL/PROFILING/HARDENED_USERCOPY/XT_TRACE` on,
`FHANDLE` off) to match matrix level 3. Rebuild + reflash is required —
the phone currently runs the old `MODULES=n` build (`/proc/config.gz`).

If you still see it, grab `adb logcat -d | grep -i "fingerprint is not"` and
compare `/proc/config.gz` against `/system/etc/vintf/compatibility_matrix.3.xml`
(see `scripts/vintf-perblock.py`). It causes no data loss.

### Play Integrity / banking apps (strong integrity)
Kernel gives honest stock-like provenance (no dirty tags, no BUILD_SALT
spoof, `BUG=y` clean WARNs) so BASIC + DEVICE verdicts can pass. STRONG
verdict needs locked bootloader + valid keybox - impossible on any custom
kernel. On device: root with FolkPatch/Magisk + PlayIntegrityFix or
TrickyStore module (userspace keybox/FP spoof). Never put
`ro.build.fingerprint` overrides in `anykernel.sh` - boot-img props are
trivially detectable.
