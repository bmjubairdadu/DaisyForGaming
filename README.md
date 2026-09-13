# DaisyForGaming v1.2 Kernel for Xiaomi Mi A2 Lite (daisy) - 4.9.337 Gaming Kernel by JUBAIR HOSEN

> **Daisy kernel | Mi A2 Lite custom kernel | msm8953 Snapdragon 625 kernel | Cool & Smooth - No Heat, No Lag | 100% SAFE - No Pre-Root**

Gaming kernel for **Xiaomi Mi A2 Lite (daisy)** - Snapdragon 625 (MSM8953).
Kernel **4.9.337 `-DaisyForGaming`** only - this project contains no 3.18 code.

Base: verified **TogoFire/kernel_xiaomi_panda** Linux 4.9.337 (`daisy_defconfig`)
+ gaming branding, safe no-root policy, Treble/BBR/ZRAM tweaks, modern AK3 flash UI.

v1.2 adds (all boot-safe, researched in-tree): `performance` + `gaming` CPU governors,
wakelock filter (default OFF), DT2W gesture sysfs, devfreq boost, BFQ/BBR/KCAL.
v1.2 fixes FolkPatch boot: embedded IKCONFIG now matches the real build
(KALLSYMS_ALL=y) + keeps `kallsyms_lookup_name` for KernelPatch. The Linux
banner is clean and contains only DaisyForGaming/JUBAIR branding; compiler and
upstream repository details are no longer exposed.

Compatible with **Android 9-14**, Stock + LineageOS / PE / Evolution X / crDroid / Havoc / Arrow.

## Download (flashable zip)

Get the latest AnyKernel3 flashable zip from
[Releases](https://github.com/bmjubairdadu/DaisyForGaming/releases) -
`DaisyForGaming-v1.2-Gaming-4.9.337-*-AnyKernel3.zip`. Flash with TWRP / OrangeFox.

## Flash
1. Download `DaisyForGaming-v1.2-Gaming-4.9.337-*.zip`
2. TWRP/OrangeFox -> backup boot -> flash zip -> wipe cache/dalvik -> reboot

## Build
```bash
bash build.sh all
# out/DaisyForGaming-v1.2-Gaming-4.9.337-*.zip
```

## Project
```
DaisyForGaming/
├── build.sh                        # clone TogoFire 4.9.337 + compile + AnyKernel3 zip
├── configs/daisy_gaming_defconfig  # gaming + Treble fragment (4.9.337-safe only)
├── .ak3-custom/                    # our anykernel.sh banner + version + thermal conf
├── AnyKernel3/                     # fetched osm0sis engine (ignored by git)
├── scripts/                        # apply-tree-patches + wsl-build + watch-progress + vintf-perblock
├── patches/                        # 4 FolkPatch-safe tree patches (banner, kallsyms x2, ikconfig)
├── toolchain/                      # Proton host tools (ignored, fetched by build.sh)
└── .github/workflows/build.yml     # CI build
```

- Name: DaisyForGaming v1.1-Gaming-4.9.337
- Developer: JUBAIR HOSEN (`JUBAIR` / `JUBAIR-HOSEN` / `-DaisyForGaming`)
- Base: TogoFire/kernel_xiaomi_panda Linux 4.9.337
- SAFE: No Pre-Root (No KernelSU/APatch) - anti-cheat safe

Flash at your own risk. Always backup boot first.

## Keywords (search: daisy kernel, Mi A2 Lite kernel, msm8953 kernel)

daisy kernel, xiaomi daisy kernel, mi a2 lite kernel, mi a2 lite custom kernel,
msm8953 kernel, snapdragon 625 kernel, sdm625 kernel, daisy custom kernel,
4.9.337 kernel daisy, daisy gaming kernel, best kernel for mi a2 lite,
daisy lineageos kernel, daisy crdroid kernel, daisy evolution x kernel,
daisy treble kernel, xiaomi msm8953 kernel, daisy anykernel3, daisy folkpatch ready kernel.

## FAQ

- **Best custom kernel for Mi A2 Lite (daisy)?** DaisyForGaming v1.1 - 4.9.337 gaming kernel, cool & smooth, no heat no lag.
- **Which Android versions?** Android 9, 10, 11, 12, 13, 14 (Stock, LineageOS, Pixel Experience, Evolution X, crDroid, Havoc, Arrow).
- **Safe for games / anti-cheat?** Yes - 100% SAFE, no pre-root (no KernelSU/APatch inside); optionally root later with FolkPatch.
- **Kernel version?** Linux 4.9.337 `-DaisyForGaming` for msm8953 / Snapdragon 625 (MSM8953 + PMI8950).
- **Treble / vendor?** Yes - Project Treble compatible, binderized HALs, vendor partition mounting for msm8953.
- **"There's an internal problem with your device" after flashing?** Cosmetic Android warning for a modified boot image (unlocked bootloader + custom kernel). Press OK. Confirm the kernel in About phone (`4.9.337-DaisyForGaming`). Restoring the stock boot backup removes it.
