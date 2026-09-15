# DaisyForGaming v1.0 FRESH

> **Daisy kernel | Mi A2 Lite custom kernel | msm8953 Snapdragon 625 kernel | Cool & smooth gaming, no heat no lag | 100% SAFE, no pre-root**

Gaming kernel for **Xiaomi Mi A2 Lite (daisy)** — Snapdragon 625 (MSM8953 + PMI8950), Linux **4.9.337 `-DaisyForGaming`**.

Base: verified [TogoFire/kernel_xiaomi_panda](https://github.com/TogoFire/kernel_xiaomi_panda) `daisy_defconfig` @ `ff7b84e` + Treble/gaming fragment, modern AnyKernel3 flash UI.

**Android 9–14** — Stock, LineageOS, Pixel Experience, Evolution X, crDroid, Havoc, Arrow.

## Features

| Area | What you get |
|---|---|
| CPU | `schedutil` fastramp (0.5 ms up / 10 ms hold) / `ondemand` / `conservative` / `powersave` / `userspace`, touch input-boost (1.4 GHz/40 ms), SchedTune, `msm_performance`, WALT load-tracking, autogroup + bandwidth control |
| GPU | `msm-adreno-tz` + gaming `adreno_idler`, devfreq boost (stock 650 MHz table, no OC) |
| Network | TCP CUBIC default (boot) + BBR/Hybla/Vegas/Veno/Illinois/DCTCP, `westwood` fallback |
| Storage / IO | BFQ + CFQ (default) + deadline + NOOP, F2FS (+encryption/compression/check/stat), exFAT/NTFS, squashfs, ZRAM (`lz4`/`lz4hc` multi-comp, in-RAM), 1 MB readahead |
| Display | KCAL color control, DT2W gesture sysfs (`fts_gesture_mode`) |
| Battery | Stock charging path; app-triggered bypass via `battery_charging_enabled` (no patch needed) |
| Thermal | Gaming profile 48C/2s + battery-hot 45C charge mitigation |
| Memory | KSM (+legacy) page-merging, memcg + swap controller, compaction, reclaim stats |
| System | Treble, Binder IPC, ION, OverlayFS, dm-verity + dm-crypt + FDE, dynamic fsync (`/sys/kernel/dyn_fsync/Dyn_fsync_active`), powersuspend hooks |
| Debug / mod apps | Magic SysRq, hung-task + sched debug + stats, task-delay acct, fanotify, dynamic printk, `IKCONFIG_PROC`, `PRINTK=y` |
|Root policy | **100% SAFE — no KernelSU / APatch / FolkPatch inside.** Root later with FolkPatch/Magisk if you want (KALLSYMS_ALL=y ready) |

## Download

Get the flashable zip from [Releases](https://github.com/bmjubairdadu/DaisyForGaming/releases) — `DaisyForGaming-v1.0-Gaming-4.9.337-*-AnyKernel3.zip`. Flash with TWRP / OrangeFox.

## Flash

1. Download the zip.
2. Reboot to TWRP / OrangeFox.
3. Backup boot (important!).
4. Flash the zip, wipe cache/dalvik, reboot.
5. Settings → System → About phone → Kernel version should show `4.9.337-DaisyForGaming`.

Requirements: Xiaomi Mi A2 Lite (**daisy** only, NOT jasmine_sprout / Mi A2), unlocked bootloader, TWRP 3.5+. AnyKernel3 keeps your ramdisk.

## Build

```bash
bash build.sh all
# out/DaisyForGaming-v1.0-Gaming-4.9.337-*.zip
```

WSL users: `bash scripts/wsl-build.sh` (builds on ext4, copies artifacts back to `out/`).

```
DaisyForGaming/
├── build.sh                        # clone TogoFire 4.9.337 + compile + AnyKernel3 zip
├── configs/daisy_gaming_defconfig  # gaming + Treble fragment (4.9.337-safe only)
├── .ak3-custom/                    # anykernel.sh banner + version + thermal conf
├── AnyKernel3/                     # fetched osm0sis engine (ignored by git)
├── scripts/                        # apply-tree-patches + wsl-build + watch-progress + vintf-perblock
├── patches/                        # banner, KALLSYMS x3, IKCONFIG fixes (FolkPatch-safe)
├── toolchain/                      # Proton host tools (ignored, fetched by build.sh)
└── .github/workflows/build.yml     # CI build
```

- Name: DaisyForGaming v1.0-Gaming-4.9.337
- Developer: JUBAIR HOSEN (`JUBAIR` / `JUBAIR-HOSEN` / `-DaisyForGaming`)
- Base: TogoFire/kernel_xiaomi_panda Linux 4.9.337
- SAFE: No Pre-Root (No KernelSU/APatch) — anti-cheat safe

Flash at your own risk. Always backup boot first.

## FAQ

- **Best custom kernel for Mi A2 Lite (daisy)?** DaisyForGaming v1.0 — 4.9.337 gaming kernel, cool & smooth, no heat no lag.
- **Which Android versions?** Android 9, 10, 11, 12, 13, 14 (Stock, LineageOS, Pixel Experience, Evolution X, crDroid, Havoc, Arrow).
- **Safe for games / anti-cheat?** Yes — 100% SAFE, no pre-root (no KernelSU/APatch inside); optionally root later with FolkPatch.
- **Kernel version?** Linux 4.9.337 `-DaisyForGaming` for msm8953 / Snapdragon 625 (MSM8953 + PMI8950).
- **Treble / vendor?** Yes — Project Treble compatible, binderized HALs, vendor partition mounting for msm8953.
- **"There's an internal problem with your device" after flashing?** Cosmetic Android warning for a modified boot image (unlocked bootloader + custom kernel). Press OK. Confirm the kernel in About phone (`4.9.337-DaisyForGaming`). Restoring the stock boot backup removes it.

## Keywords (search: daisy kernel, Mi A2 Lite kernel, msm8953 kernel)

daisy kernel, xiaomi daisy kernel, mi a2 lite kernel, mi a2 lite custom kernel,
msm8953 kernel, snapdragon 625 kernel, sdm625 kernel, daisy custom kernel,
4.9.337 kernel daisy, daisy gaming kernel, best kernel for mi a2 lite,
daisy lineageos kernel, daisy crdroid kernel, daisy evolution x kernel,
daisy treble kernel, xiaomi msm8953 kernel, daisy anykernel3, daisy folkpatch ready kernel.
