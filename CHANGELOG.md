# Changelog

All notable changes to the **DaisyForGaming** kernel for the Xiaomi Mi A2 Lite (`daisy`) are documented here.

## v1.0 — first release (2026-10-05)

Fresh versioning starts here. Everything below ships in both zips; the only
difference between them is the root stack.

### 🎮 Gaming & performance
- **CPU touch boost — ON by default:** little cluster (cpu0–3) boosts to
  **1401600 kHz**, big cluster (cpu4–7) to **1689600 kHz**, **300 ms** hold,
  re-triggered while touching (`drivers/cpufreq/cpu-boost.c` now seeds its
  per-CPU table at boot — earlier kernels shipped all-zero defaults, so the
  feature never ran). New Kconfig: `INPUT_BOOST_FREQ_BIG`, `INPUT_BOOST_SCHED`.
- **WALT full-throttle scheduler boost on every input** — foreground tasks
  migrate to the big cluster instantly.
- **top-app schedtune lift** (`boost=10`, `prefer_idle=1`) applied by the
  boot-time script, so the foreground game keeps scheduler priority.
- **schedutil** default governor; interactive / performance / ondemand /
  conservative / userspace all compiled in (`GOV_ATTR_SET`), so any tuning
  app works out of the box.
- **zRAM lz4** (2 GB, lowest CPU overhead) + writeback, **UKSM/KSM** page
  merging, compaction.
- **deadline** I/O scheduler default (cfq/noop available), **fq_codel** qdisc
  + **BBR** TCP congestion control.
- **300 Hz + PREEMPT**, WALT scheduler, schedtune cgroup support.
- Sane thermal trips (CPU 80 °C / per-CPU 90 °C / GPU 85 °C / pop-mem 80 °C)
  for sustained gaming without sudden drops. No overclock on purpose —
  thermal headroom beats a paper spec.
- Fast-charge paths (2 A, safe 4.40 V float), power-efficient workqueues,
  IPA, PM8953 thermal zone active.
- fsync toggle at `/sys/module/sync/parameters/fsync_enabled` (default on).

### 🔓 Root stacks (pick ONE per kernel — never mix)
| Zip | Root stack | Kernel build |
|---|---|---|
| `DaisyForGaming-v1.0-Gaming-KSU-<date>.zip` | KernelSU (built-in) **or** Magisk | `CONFIG_KSU=y` + SusFS v1.5.5 |
| `DaisyForGaming-v1.0-Gaming-Vannila-<date>.zip` | FolkPatch (patch boot) **or** Magisk | vanilla — no in-kernel root |

- KernelSU v0.9.5 with manual kprobe-free hooks + Safe Mode (triple-tap Vol−);
  SusFS sus-path/mount/kstat hiding, uname/cmdline spoof, kallsyms hiding.
- KernelPatch requirements verified on device: `KALLSYMS`+`KALLSYMS_ALL` on,
  KASLR/KPTI off, `RELOCATABLE` off.
- ⚠️ **KernelPatch on 4.9 must be ≥ 0.13.8** (FolkPatch V6 Sol = KP 0.13.9,
  verified booting). Older kpimg hangs the kernel in `setup_arch`
  (boot-logo hang) — a documented upstream 4.9 bug fixed in 0.13.8.
- `MODVERSIONS` on (VINTF) — no "system inconsistent" boot dialog on
  Android 11.

### 🧪 Verified on device (Mi A2 Lite, Android 11, Magisk root)
Touch boost live (1401/1689, 300 ms, sched_boost=1), top-app boost=10,
zRAM 2 GB lz4 swap active, vm sysctls applied (swappiness 30, page-cluster 0,
vfs_cache_pressure 20, dirty_background_ratio 5), deadline default, dmesg
clean (only stock camera/wlan noise), VINTF dialog absent.

### 📦 Packaging & repo
- Fresh AnyKernel3 base; one parameterized script (`dfg_zip.sh ksu|fp`)
  producing `DaisyForGaming-v1.0-Gaming-{KSU,Vannila}-<DD-MM-YYYY>.zip`.
- `99-dfg-tune.sh` (Magisk service.d): re-asserts input boost, lifts
  top-app schedtune, zram lz4 swap with **retry** (ROM init race), vm
  sysctls, logs final state to `/data/local/tmp/dfg_tune.log`.
- `dfg_boot_rebuild.py` swaps a boot image's kernel blob keeping header +
  ramdisk byte-identical (for safe KernelPatch testing via `fastboot boot`).
