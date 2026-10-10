# Changelog

All notable changes to the **DaisyForGaming** kernel for the Xiaomi Mi A2 Lite (`daisy`) are documented here.

## v1.0 — FINAL line: single zip, KSU removed, smoother ramp (2026-10-11)

Fresh versioning restart — this is the **final build line**. The old KSU/Vannila split is gone:
**one kernel, one zip**, root applied after flashing (FolkPatch / Magisk), never in-kernel.

### 🔓 Root stack change (the big one)
- **KernelSU and SusFS removed from the kernel tree entirely** — not just disabled:
  `drivers/kernelsu/` deleted, all in-tree hook points removed (`fs/exec.c`,
  `fs/read_write.c`, `fs/open.c`, `fs/stat.c`, `fs/devpts/inode.c`,
  `drivers/input/input.c`), `drivers/Kconfig`/`drivers/Makefile` entries dropped and
  every `CONFIG_KSU*` line removed from the defconfig.
- That also removes the last syscall-path overhead the KSU build carried: the execve /
  vfs_read / input hooks (however cheap) are gone — the syscall paths are stock again.
- Root now = **FolkPatch** (patch the flashed boot) or **Magisk**. KernelPatch requirements
  stay met (`KALLSYMS` + `KALLSYMS_ALL` on, KASLR/KPTI off, `RELOCATABLE` off).
- **One defconfig** (`daisy_defconfig`), **one build script** (`dfg_build.sh`), **one zip**
  (`DaisyForGaming-v1.0-Gaming-<date>.zip`). `daisy_fp_defconfig`, `dfg_fp_build.sh`,
  `dfg_ksu_build.sh` and the old dual zips deleted.

### 🧩 Kernel modules
- Module loading is as lean as 4.9 allows: no signature enforcement
  (`CONFIG_MODULE_SIG` off — zero crypto on the load path), `MODVERSIONS` kept for VINTF,
  `MODULE_FORCE_LOAD/UNLOAD` on, and no third-party hooks left in the module/syscall paths.
- Modules must be rebuilt from this tree (MODVERSIONS symbols) — documented in the README.

### 🎮 Performance / smoothness
- **schedutil rate-limit retune (default):** up 20 ms → **5 ms** (bursts ramp inside the frame),
  down 0.5 ms → **20 ms** (clocks hold one WALT window before dropping — removes the up/down
  seesaw behind **video frame-time jitter** and needless transition churn). Still
  runtime-tunable per policy.
- **New `boost_mode` node in cpu-boost — now with AUTO game detection (default):** one write
  switches the whole input-boost profile, no scripts: `0` battery (boost off), `1` balanced
  (1036/1401 MHz, 150 ms, no sched boost — the cool v1.1 values), `2` gaming (1401/1689 MHz,
  250 ms, WALT sched boost on touch — the proven v1.0 values), and **`3` auto (default)**:
  the kernel watches the Adreno busy ratio on every msm-adreno-tz update — screen off drops to
  battery instantly, a sustained GPU-heavy foreground app (≥ `auto_gpu_busy` % busy, default 50,
  for ~6 s) counts as a running game and lifts the profile to gaming, everything else (video,
  browsing, scrolling) stays balanced. Three-sample hysteresis both ways keeps game-loading
  screens from flapping the mode; the detection threshold is runtime-tunable via
  `/sys/module/cpu_boost/parameters/auto_gpu_busy` and the applied profile is visible in
  `boost_mode_effective`.
- Boot tune script (`99-dfg-tune.sh`) asserts `boost_mode=3` (auto), keeps
  `boost_on_charging=0`, and logs the schedutil rate limits + effective boost profile for
  diagnostics.

### 🧪 Unchanged (all still shipped)
- Thermal trips CPU 80 °C / per-CPU 90 °C / GPU 85 °C / pop-mem 80 °C, charging-aware boost
  (no boost while plugged in), SDR50 microSD cap, zRAM lz4 2 GB + writeback, KSM, deadline I/O,
  fq_codel + BBR, 300 Hz PREEMPT + WALT, `MODVERSIONS` (no VINTF dialog), pn533/rbd fixes.

## v1.1 — stability, cool thermals & charging-aware boost (2026-10-10) — *legacy*

The "it crashes / heats / charges slow" release. Everything in v1.0 ships too —
the only difference between the two zips is still the root stack.

### 🐞 Fixed
- **KSU build fixed for real:** the manual (kprobe-free) KSU hooks in
  `fs/read_write.c`, `fs/exec.c` and `drivers/input/input.c` gate on three
  flags that only existed in the kprobe-free half of `ksud.c` — with
  `CONFIG_KPROBES=y` the kernel never linked (the v1.0 zips shipped the older
  kprobe-based image). `ksud.c` / `sucompat.c` / `ksu.c` now always use the
  manual hooks. `CONFIG_KPROBES` stays on (perfetto/simpleperf ready), but KSU
  no longer puts kprobe traps on the read / execve / input hot paths — less
  syscall jitter, same stealth, same Safe Mode (triple-tap Vol− during boot).
- **microSD cards going missing:** dropped UHS-I SDR104 — its 200 MHz tuning
  fails intermittently on several cards ("card not found" until re-insert);
  now capped at SDR50 (100 MHz).

### 🌡️ Thermals & charging (the heat complaints)
- **Charging-aware input boost (new):** new `boost_on_charging` kernel param
  (default **off**) — while USB is connected, the touch boost stays off, so
  the SoC stops heating from boost-on-every-touch while plugged in. That heat
  is what made thermal-engine cut the charger current ("charging speed কমে
  যায় while using"). Want boost while charging (gaming on the charger)?
  `echo 1 > /sys/module/cpu_boost/parameters/boost_on_charging`.
- **Cooler daily defaults:** v1.0 boosted every touch to 1401/1689 MHz for
  300 ms *and* full-throttled the WALT scheduler on every input — that was
  the main heat source, and heat is what triggers the 80 °C cap that causes
  the sudden lag/drop feeling. Now: **1036/1401 MHz, 150 ms,
  `sched_boost_on_input=0`**. Games still push the big cluster to max via
  schedutil under load; scrolling/browsing no longer cooks the phone.
- **vm:** `vfs_cache_pressure` 20 → 50 (20 could grow kernel caches on the
  3 GB variant and add memory pressure — pressure is what gets apps and
  SystemUI killed).

### 🧪 Unchanged
- KernelSU 0.9.5 + SusFS v1.5.5 (KSU zip), FolkPatch/Magisk-ready vanilla zip.
- schedutil default, zRAM lz4 2 GB, UKSM (governor `low` via boot script),
  deadline I/O, fq_codel + BBR, fsync toggle, thermal trips CPU 80 °C /
  per-CPU 90 °C / GPU 85 °C / pop-mem 80 °C, `MODVERSIONS` (no VINTF dialog).

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
