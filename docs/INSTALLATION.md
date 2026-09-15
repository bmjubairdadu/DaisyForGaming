# DaisyForGaming install guide - Mi A2 Lite (daisy), 4.9.337

1. Download `DaisyForGaming-v2.2-Gaming-4.9.337-*.zip`.
2. Reboot to TWRP / OrangeFox.
3. Backup boot (important!).
4. Flash the zip, wipe cache/dalvik, reboot.
5. Settings -> System -> About phone -> Kernel version should show `4.9.337-DaisyForGaming`.

Requirements: Xiaomi Mi A2 Lite (daisy) only (NOT jasmine_sprout / Mi A2), unlocked bootloader, TWRP 3.5+.
Works on Stock + LineageOS / PE / Evolution X / crDroid / Havoc / Arrow (Android 9-14)
because AnyKernel3 keeps your ramdisk.

Latest flashable zip: https://github.com/bmjubairdadu/DaisyForGaming/releases/tag/DaisyForGaming-v1.0

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

### Game mod / kernel-level apps + network errors in background
Two different causes, don't mix them:
1. **Mid-game freeze/lag (no mod app): kernel thermal+GPU.** Fixed in
   v2.2: schedutil down-hold 10 ms, adreno-idler gaming defaults,
   thermal 48C/2000ms. Flash v2.2.
2. **Network error only when mod app runs in background: the APP's fault,
   not kernel.** These apps hook `connect`/`getaddrinfo`/SSL, run a local
   VPN/proxy, or suspend sockets while scanning memory. When Android
   dozes the app, its proxy dies -> game gets `ENETUNREACH`/timeout.
   Fix in app: whitelist game, disable VPN/proxy mode, lock app in
   recents (no battery optimization), or use Magisk module version
   instead of background-APK version. Verify: stop mod app -> network
   error gone = 100% app fault, kernel innocent (`westwood` + BBR,
   `mmi` WiFi path untouched by this kernel).

### APatch patched boot.img flashes but phone won't boot
Your APatch log (e.g. v11224 on DaisyForGaming v1.1) shows `patch_rc=0`
and `Repack completed` - the kernel patch itself SUCCEEDED. Every `[?]`
line in that log is benign: `kallsyms_markers elem_size 8 rejected` ->
absolute-address fallback found the table; `can't find arm64 relocation
table` -> stock daisy has no KASLR/RELOCATABLE so no table exists;
`no symbol: memblock_phys_alloc_try_nid` -> fallback found; `no CFI
handler` -> no CFI in this kernel, nothing needed. Kernel side needs:
`KALLSYMS=y + KALLSYMS_ALL=y` (absolute), OverlayFS + tmpfs xattr/acl -
all present in this kernel. So a no-boot after flash is NOT a kernel
config problem. Checklist:
1. **Patch the STOCK boot.img**, not an already-custom-kernel one.
2. **Flash to BOTH slots** (daisy is A/B): `fastboot flash boot_a` +
   `fastboot flash boot_b`, or flash the current slot then
   `fastboot --set-active=other` and flash again.
3. **Keep a boot backup** (TWRP Backup -> Boot) before patching.
4. If black screen: check vibration/charging LED - panel-DTBO mismatch
   shows black while the phone is actually on; restore backup boot.
5. `fastboot getvar current-slot` + `fastboot getvar unlocked` to
   confirm slot and unlock state before flashing.
