# DaisyForGaming 🎮

![Kernel](https://img.shields.io/badge/Linux-4.9.337-orange)
![Platform](https://img.shields.io/badge/SoC-Snapdragon_625_(MSM8953)-green)
![Root](https://img.shields.io/badge/root-FolkPatch_/_Magisk-purple)
![License](https://img.shields.io/badge/license-GPL--2.0-red)

> A performance-tuned custom kernel for the **Xiaomi Mi A2 Lite (daisy)** — built for gaming,
> one zip, no built-in root: patch it with **FolkPatch** or root it with **Magisk** after flashing.

---

## 📱 Device

| | |
|---|---|
| Device | Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`) |
| SoC | Snapdragon 625 (MSM8953, 8× Cortex-A53) |
| GPU | Adreno 506 (650 MHz) |
| Base tree | TogoFire r54 (Linux 4.9.337) |
| ROM | Android 11 (tested on Lineage-based ROM) |

## ⬇️ Downloads (v1.0 — the final line)

Grab the zip from the repo root or the [releases page](https://github.com/bmjubairdadu/DaisyForGaming/releases):

| Flashable zip | Root stack | Kernel build |
|---|---|---|
| **`DaisyForGaming-v1.0-Gaming-<date>.zip`** | FolkPatch (patch boot) **or** Magisk | vanilla — **no in-kernel root, KernelSU removed** |

One kernel, one zip. The old KSU + Vanilla dual-release split is gone: KernelSU and SusFS have
been pulled out of the kernel tree completely (driver, syscall hooks, configs), so the kernel is a
clean vanilla shape that FolkPatch/KernelPatch can patch without any hook conflicts. Magisk keeps
working as always — root is applied **after** flashing, never in-kernel.

## 🎮 Gaming & Performance Features

- **True Hardware Bypass Charging (Free Fire & Free Fire Max):**
  When Free Fire (`com.dts.freefireth` / `com.dts.freefiremax`) is active on screen (`top-app`) and the charger is plugged in, the kernel automatically enables true motherboard hardware bypass:
  - Charger connection remains continuously active (`charging_enabled = 1`) — no disconnect/reconnect loops or vibration chimes.
  - Battery charging is completely inhibited (`battery_charging_enabled = 0`, `constant_charge_current_max = 0`).
  - The phone runs 100% on AC adapter power: 0% battery charge, 0% battery drain, and zero battery heating while gaming!
  - When the game is closed or minimized, normal charging and balanced profile are instantly restored.

- **Cool Charging & Thermal Protection (Zero Video Lag / No Throttling):**
  - **`boost_on_charging = 0` (Default):** Disables CPU boost during charging, keeping the CPU cool and eliminating thermal throttling.
  - **Balanced Fast Charge (1500mA):** Optimized safe current for Snapdragon 625 on micro-USB. Charges rapidly while keeping battery temperatures below 38°C–40°C, so Qualcomm's thermal-engine never throttles CPU or GPU.
  - **Input Boost Duration (40 ms):** Snappy 60fps touch responsiveness without wasteful battery drain or heat.

- **GPU & Display Anti-Lag (Butter Smooth 60 FPS):**
  - **Adreno 506 GPU:** Minimum clock locked at **216 MHz** (governor: `msm-adreno-tz`). Eliminates micro-stutters during video playback (1080p/2K/4K) and surface compositing.
  - **Adreno Idler:** Disabled to prevent erratic frequency drops during gaming and video playback.
  - **Schedutil Rate Limits:** 500 µs (up) and 20,000 µs (down) for rock-solid frame pacing.
  - **CPUSets & SchedTune:** `top-app` and `foreground` assigned all 8 CPU cores with `schedtune.boost = 10` and `prefer_idle = 1`. Background tasks are constrained to cores 0-3 to prevent CPU contention.

- **Low-Latency Online Gaming Networking:**
  - **TCP BBR** congestion control + **FQ (Fair Queueing)** packet pacing enabled by default for lower, jitter-free in-game ping.

- **Autonomous Screen-Aware RAM & Junk Cleaner:**
  - Screen-aware daemon: NEVER touches memory while the screen is ON.
  - When screen is turned off and locked, trims dead dentries/inodes, compacts RAM, and cleans temporary junk silently without causing UI micro-freezes.

- **Storage & Memory:**
  - **zRAM lz4** (lowest CPU overhead) + balanced VM swappiness (60) and vfs_cache_pressure (100).
  - Storage I/O read-ahead: 1024 KB for instantaneous video streaming and app loading.
  - UKSM/KSM completely disabled to eliminate background CPU load and heating.

## 🔓 Root (FolkPatch / Magisk — never in-kernel)

- The kernel ships with **no root inside**: `KALLSYMS` + `KALLSYMS_ALL` = y, KASLR/KPTI off,
  `MODVERSIONS` on — all KernelPatch/FolkPatch requirements met, so KernelPatch can patch the
  flashed boot cleanly.
- **FolkPatch flow:** flash the zip → dump the new boot → patch it in
  [FolkPatch Manager](https://github.com/LyraVoid/FolkPatch/releases) → flash the patched boot.
- **Magisk flow:** flash the zip, install/keep Magisk — the ramdisk is preserved untouched.

> ⚠️ **KernelPatch on 4.9 must be ≥ 0.13.8** (FolkPatch V6 Sol = KP 0.13.9 ✅). Older kpimg builds
> hang the kernel in `setup_arch` at the boot logo — this is a documented upstream 4.9 bug fixed
> in 0.13.8.

> 💡 Safe test without flashing: `adb reboot bootloader` → `fastboot boot patched_boot.img` —
> boots once from RAM; force-restart returns to the bootloader.

## 🧩 Kernel modules

- `CONFIG_MODULES=y` with **`MODVERSIONS`** (VINTF requires it — keeps the Android-11
  "system inconsistent" dialog away) and **no signature enforcement**
  (`CONFIG_MODULE_SIG` off): unsigned `.ko` modules load without any crypto check on the load
  path, and there are no KernelSU hooks left on the read/execve/input syscall paths.
- Modules must be built from **this exact tree** (`MODVERSIONS` symbols) — rebuild your `.ko`
  files for every kernel you flash; old modules from a previous build will refuse to load.
- Load them the normal way: `insmod /path/xxx.ko` or `modprobe` with the module in
  `/vendor_dlkm`/`/system/lib/modules`. If a module misbehaves, `rmmod` it — the module loader
  itself adds no overhead beyond the module's own init.

## 📲 Flashing

### Recovery (recommended)
1. Reboot to TWRP / OrangeFox (or `adb reboot recovery`).
2. Install the zip — or **Advanced → ADB Sideload** then `adb sideload DaisyForGaming-v1.0-Gaming-*.zip`.
3. Reboot. The zip auto-detects `daisy`, gates on Android 11, and stages the boot-time tuning
   script (`99-dfg-tune.sh`) into Magisk `service.d`.

### Root setup
- **FolkPatch** → flash the zip first, then dump the new boot, patch it in FolkPatch Manager and
  flash the patched boot.
- **Magisk** → works as-is without patching.

## 🔧 Runtime tuning (all optional — defaults are already applied)

| Node | Value |
|---|---|
| `/sys/module/cpu_boost/parameters/boost_mode` | `3` (auto-detect) — `0` battery, `1` balanced, `2` gaming |
| `/sys/module/cpu_boost/parameters/boost_mode_effective` | read-only: profile auto applied now |
| `/sys/module/cpu_boost/parameters/auto_gpu_busy` | `50` (% GPU busy counted as "game running") |
| `/sys/module/cpu_boost/parameters/input_boost_freq` | `0:1036800 … 4:1401600` |
| `/sys/module/cpu_boost/parameters/input_boost_ms` | `150` |
| `/sys/module/cpu_boost/parameters/sched_boost_on_input` | `0` |
| `/sys/module/cpu_boost/parameters/boost_on_charging` | `0` (set `1` to boost while charging) |
| `/sys/module/cpu_boost/parameters/bypass_on_gaming` | `1` — charging pauses while gaming on the charger |
| `/sys/class/power_supply/battery/charging_enabled` | read it: `0` = bypass active, `1` = normal charging |
| `/sys/devices/system/cpu/cpu0/cpufreq/schedutil/up_rate_limit_us` | `5000` |
| `/sys/devices/system/cpu/cpu0/cpufreq/schedutil/down_rate_limit_us` | `20000` |
| `/dev/stune/top-app/schedtune.boost` | `10` |
| `/sys/module/sync/parameters/fsync_enabled` | `Y` (toggle for faster loading) |
| `/proc/sys/vm/{swappiness,vfs_cache_pressure,page-cluster,dirty_background_ratio}` | `30 / 50 / 0 / 5` |

Tuning log: `/data/local/tmp/dfg_tune.log` (written by `99-dfg-tune.sh` every boot).

## 🛠️ Building

WSL (Ubuntu 22.04) + clang 14, `LLVM=1 LLVM_IAS=1`:

```bash
bash dfg_build.sh    # kernel -> out/arch/arm64/boot/Image.gz-dtb
bash dfg_zip.sh      # -> DaisyForGaming-v1.0-Gaming-<date>.zip
```

`dfg_boot_rebuild.py` swaps a boot image's kernel blob while keeping the header + ramdisk
byte-identical (handy for kpatch testing).

## 🐞 Troubleshooting

| Symptom | Cause / fix |
|---|---|
| KernelPatch-patched boot hangs at logo | kpimg < 0.13.8 — use FolkPatch V6 Sol (KP 0.13.9) or newer |
| Old `.ko` module refuses to load | `MODVERSIONS` symbols changed — rebuild the module from this tree |
| `vm.swappiness` permission denied | fixed (sysctl mode 0644) |
| Boot warning dialog on Android 11 | keep `MODVERSIONS` on (it is enabled by default) |
| "zram swapon FAILED" in tune log | harmless ROM race (script retries and confirms swap state) |

## 🙏 Credits

- **TogoFire** r54 — base kernel tree
- **AnyKernel3** (osm0sis) — flashable packaging
- **FolkPatch** (LyraVoid) / **KernelPatch** (bmax121) — boot-patch root
- Everyone in the daisy community

## 📄 License & disclaimer

GPL-2.0 — see [COPYING](COPYING). Flash at your own risk; keep a backup of your boot image.
A/B device: the zip writes to the **active slot's** boot partition.
