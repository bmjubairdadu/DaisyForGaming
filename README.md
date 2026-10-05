# DaisyForGaming 🎮

![Version](https://img.shields.io/badge/version-v1.17_Final-blue)
![Kernel](https://img.shields.io/badge/Linux-4.9.337-orange)
![Platform](https://img.shields.io/badge/SoC-Snapdragon_625_(MSM8953)-green)
![Root](https://img.shields.io/badge/root-KernelSU_/_FolkPatch_/_Magisk-purple)
![License](https://img.shields.io/badge/license-GPL--2.0-red)

> A performance-tuned custom kernel for the **Xiaomi Mi A2 Lite (daisy)** — built for gaming, shipped in two root-stack flavors, flashable via sideload.

---

## 📱 Device

| | |
|---|---|
| Device | Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`) |
| SoC | Snapdragon 625 (MSM8953, 8× Cortex-A53) |
| GPU | Adreno 506 (650 MHz) |
| Base tree | TogoFire r54 (Linux 4.9.337) |
| ROM | Android 11 (tested on Lineage-based ROM) |

## ⬇️ Downloads (v1.17 Final)

| Flashable zip | Root stack | Kernel build |
|---|---|---|
| **[DaisyForGaming-v1.17-KSU.zip](releases/DaisyForGaming-v1.17-KSU.zip)** | KernelSU (built-in) **or** Magisk | `CONFIG_KSU=y` + SusFS v1.5.5 |
| **[DaisyForGaming-v1.17-FolkPatch-Magisk.zip](releases/DaisyForGaming-v1.17-FolkPatch-Magisk.zip)** | FolkPatch (patch boot) **or** Magisk | vanilla — no in-kernel root |

> **Pick ONE root stack per kernel.** Never patch the KSU build's boot with FolkPatch/KernelPatch — KernelPatch installs its own execve hooks and conflicts with in-kernel KernelSU (instant bootloop). The FolkPatch build has no in-kernel root, so KernelPatch can patch it cleanly.

## 🎮 Gaming features

- **CPU touch boost — ON by default** (this was dead in every previous release): little cluster **1401 MHz**, big cluster **1689 MHz**, **300 ms** hold, re-triggered while touching — plus a **WALT full-throttle scheduler boost on every input** so the game's threads migrate to the big cluster instantly. All values tunable at runtime in `/sys/module/cpu_boost/parameters/`.
- **top-app schedtune boost** (`boost=10`, `prefer_idle=1`) applied by the boot script — the foreground game keeps scheduler priority.
- **schedutil** default governor (interactive / performance / ondemand / conservative / userspace also compiled in, with `GOV_ATTR_SET`).
- **Adreno msm-adreno-tz** GPU governor + **Adreno Idler** — instant GPU ramp, no hot idling.
- **zRAM lz4** (2 GB, lowest CPU overhead) + writeback, **UKSM/KSM** page merging, compaction.
- **deadline** I/O scheduler (cfq/noop also available).
- **fq_codel** qdisc + **BBR** TCP congestion control — steadier online-game latency.
- **300 Hz + PREEMPT**, WALT scheduler, schedtune (cgroup boost) support.
- Sane **thermal trips** (CPU 80 °C, GPU 85 °C — v1.2 fixes) for sustained performance without sudden drops; **no overclock on purpose** — thermal headroom beats a paper spec.
- Fast-charge paths (2 A, safe 4.40 V float), power-efficient workqueues.

## 🔓 Root & stealth

- **KernelSU v0.9.5** (last non-GKI release) with manual, kprobe-free hooks + **Safe Mode** (triple-tap Vol−).
- **SusFS v1.5.5** (KSU build): sus-path/mount/kstat hiding, uname & cmdline spoofing, kallsyms hiding, try-umount.
- `CONFIG_KPROBES` + `KALLSYMS_ALL` stay on (perfetto/simpleperf ready), `MODVERSIONS` on for VINTF — **no "system inconsistent" boot dialog**.
- FolkPatch/KP requirements all met: `KALLSYMS` + `KALLSYMS_ALL` = y, KASLR/KPTI off.

## 📲 Flashing

### Recovery (recommended)
1. Reboot to TWRP / OrangeFox (or `adb reboot recovery`).
2. Install the zip — or **Advanced → ADB Sideload** then `adb sideload DaisyForGaming-v1.17-*.zip`.
3. Reboot. The zip auto-detects `daisy`, gates on Android 11, and stages the boot-time tuning script (`99-dfg-tune.sh`) into Magisk `service.d`.

### Root setup
- **KSU zip** → install [KernelSU Manager](https://github.com/tiann/KernelSU/releases); Magisk keeps working too.
- **FolkPatch zip** → flash the zip first, then dump the new boot, patch it in [FolkPatch Manager](https://github.com/LyraVoid/FolkPatch/releases) and flash the patched boot. Magisk works as-is without patching.

> ⚠️ **KernelPatch on 4.9 must be ≥ 0.13.8** (FolkPatch V6 Sol = KP 0.13.9 ✅). Older kpimg builds hang the kernel in `setup_arch` at the boot logo — this is a documented upstream 4.9 bug fixed in 0.13.8.

> 💡 Safe test without flashing: `adb reboot bootloader` → `fastboot boot patched_boot.img` — boots once from RAM; force-restart returns to bootloader.

## 🔧 Runtime tuning (all optional — defaults are already applied)

| Node | Value |
|---|---|
| `/sys/module/cpu_boost/parameters/input_boost_freq` | `0:1401600 … 4:1689600` |
| `/sys/module/cpu_boost/parameters/input_boost_ms` | `300` |
| `/sys/module/cpu_boost/parameters/sched_boost_on_input` | `1` |
| `/dev/stune/top-app/schedtune.boost` | `10` |
| `/sys/module/sync/parameters/fsync_enabled` | `Y` (toggle for faster loading) |
| `/proc/sys/vm/{swappiness,vfs_cache_pressure,page-cluster,dirty_background_ratio}` | `30 / 20 / 0 / 5` |

Tuning log: `/data/local/tmp/dfg_tune.log` (written by `99-dfg-tune.sh` every boot).

## 🛠️ Building

WSL (Ubuntu 22.04) + clang 14, `LLVM=1 LLVM_IAS=1`:

```bash
# FolkPatch/Magisk variant (vanilla kernel)
bash dfg_fp_build.sh

# KSU variant
wsl make O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 daisy_defconfig -j8

# Package a flashable zip
bash dfg_zip117.sh ksu   # -> DaisyForGaming-v1.17-KSU.zip
bash dfg_zip117.sh fp    # -> DaisyForGaming-v1.17-FolkPatch-Magisk.zip
```

`dfg_boot_rebuild.py` swaps a boot image's kernel blob while keeping the header + ramdisk byte-identical (handy for kpatch testing).

## 🐞 Troubleshooting

| Symptom | Cause / fix |
|---|---|
| KernelPatch-patched boot hangs at logo | kpimg < 0.13.8 — use FolkPatch V6 Sol (KP 0.13.9) or newer |
| KernelPatch + KSU kernel bootloops | wrong zip — use the FolkPatch build for KP patching |
| `vm.swappiness` permission denied | fixed since v1.14 (sysctl mode 0644) |
| Boot warning dialog on Android 11 | keep `MODVERSIONS` on (it is, since v1.11) |
| "zram swapon FAILED" in tune log | harmless ROM race since v1.17 — script retries and confirms swap state |

## 🙏 Credits

- **TogoFire** r54 — base kernel tree
- **KernelSU** (tiann) + **SusFS** (susfs4ksu) — root & stealth
- **AnyKernel3** (osm0sis) — flashable packaging
- **FolkPatch** (LyraVoid) / **KernelPatch** (bmax121) — boot-patch root
- Everyone in the daisy community

## 📄 License & disclaimer

GPL-2.0 — see [COPYING](COPYING). Flash at your own risk; keep a backup of your boot image. A/B device: the zip writes to the **active slot's** boot partition.
