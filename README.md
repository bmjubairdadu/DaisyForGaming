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

## 🎮 Gaming features

- **Auto game detection — one node (new in v1.0-final):** `boost_mode` in
  `/sys/module/cpu_boost/parameters/` runs the whole touch-boost profile, **default `3` = auto**:
  the kernel samples the Adreno busy ratio — screen off drops to **battery** instantly, a
  sustained GPU-heavy foreground app (busy ≥ 50 % for ~6 s — that's a running game) lifts to
  **gaming** (little 1401 MHz / big 1689 MHz, 250 ms + WALT sched boost on touch), and everything
  else (video, browsing, scrolling — all low-GPU work) stays on **balanced** (little 1036 MHz,
  big 1401 MHz, 150 ms). Hysteresis keeps game-loading screens from flapping the mode. Force a
  fixed profile any time with `0`/`1`/`2`; threshold is
  `/sys/module/cpu_boost/parameters/auto_gpu_busy`, applied profile shows in
  `boost_mode_effective`. While the charger is connected the boost stays off
  (`boost_on_charging=0` default) — that heat made thermal-engine cut charger current. Set `1`
  in `boost_on_charging` if you game on the charger.
- **Bypass charging while gaming on the charger (new in v1.0-final):** when the gaming profile
  is active and USB is connected, the kernel inhibits battery charging — the charger feeds the
  board directly through the SMB power-path while the battery sits still. Cooler SoC, no charge
  cycles while gaming, and charging is restored the moment the profile leaves gaming or the
  charger is unplugged. Toggle the whole feature with `bypass_on_gaming` in
  `/sys/module/cpu_boost/parameters/`; current state is visible as
  `/sys/class/power_supply/battery/charging_enabled` (`0` while bypassing).
- **schedutil ramp retune (new in v1.0-final):** up-rate-limit 20 ms → **5 ms** (burst loads —
  frame starts, scene changes, video seeks — reach target clocks inside the frame, not a full
  WALT window later) and down-rate-limit 0.5 ms → **20 ms** (clocks hold one window before
  dropping — kills the up/down seesaw that showed up as **video frame-time jitter**). Both still
  runtime-tunable per policy.
- **top-app schedtune boost** (`boost=10`, `prefer_idle=1`) applied by the boot script — the
  foreground game keeps scheduler priority.
- **schedutil** default governor (interactive / performance / ondemand / conservative / userspace
  also compiled in, with `GOV_ATTR_SET`).
- **Adreno msm-adreno-tz** GPU governor + **Adreno Idler** — instant GPU ramp, no hot idling.
- **zRAM lz4** (2 GB, lowest CPU overhead) + writeback, KSM page merging, compaction.
- **deadline** I/O scheduler (cfq/noop also available).
- **fq_codel** qdisc + **BBR** TCP congestion control — steadier online-game latency.
- **300 Hz + PREEMPT**, WALT scheduler, schedtune (cgroup boost) support.
- **microSD fix:** UHS-I capped at SDR50 — SDR104 tuning failed intermittently on several cards.
- Sane **thermal trips** (CPU 80 °C, GPU 85 °C) for sustained performance without sudden drops;
  **no overclock on purpose** — thermal headroom beats a paper spec.
- Fast-charge paths (2 A, safe 4.40 V float), power-efficient workqueues.

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
