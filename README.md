# DaisyForGaming - Mi A2 Lite (daisy) - by JUBAIR HOSEN

> **Cool & Smooth - No Heat, No Lag | 100% SAFE - No Pre-Root**

Gaming kernel for **Xiaomi Mi A2 Lite (daisy)** - Snapdragon 625 (MSM8953).
Kernel **4.9.337 `-DaisyForGaming`** only - this project contains no 3.18 code.

Base: verified **TogoFire/kernel_xiaomi_panda** Linux 4.9.337 (`daisy_defconfig`)
+ gaming branding, safe no-root policy, Treble/BBR/ZRAM tweaks, modern AK3 flash UI.

v2.3 adds (all boot-safe, researched in-tree): `performance` + `gaming` CPU governors,
wakelock filter (default OFF), DT2W gesture sysfs, devfreq boost, BFQ/BBR/KCAL.

Compatible with **Android 9-14**, Stock + LineageOS / PE / Evolution X / crDroid / Havoc / Arrow.

## Flash
1. Download `DaisyForGaming-v2.3-Gaming-4.9.337-*.zip`
2. TWRP/OrangeFox -> backup boot -> flash zip -> wipe cache/dalvik -> reboot

## Build
```bash
bash build.sh all
# out/DaisyForGaming-v2.3-Gaming-4.9.337-*.zip
```

## Project
```
DaisyForGaming/
├── build.sh                        # clone TogoFire 4.9.337 + compile + AnyKernel3 zip
├── configs/daisy_gaming_defconfig  # gaming + Treble fragment (4.9.337-safe only)
├── .ak3-custom/                    # our anykernel.sh banner + version + thermal conf
├── AnyKernel3/                     # fetched osm0sis engine (ignored by git)
├── scripts/                        # STORE repack + banner check
├── toolchain/setup-clang.sh        # Proton host tools (GCC cross from apt)
└── .github/workflows/build.yml     # CI build
```

- Name: DaisyForGaming v2.3-Gaming-4.9.337
- Developer: JUBAIR HOSEN (`JUBAIR` / `JUBAIR-HOSEN` / `-DaisyForGaming`)
- Base: TogoFire/kernel_xiaomi_panda Linux 4.9.337
- SAFE: No Pre-Root (No KernelSU/APatch) - anti-cheat safe

Flash at your own risk. Always backup boot first.
