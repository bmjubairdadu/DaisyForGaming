# CHANGELOG

All entries below are derived from the actual git history of this
repository (from the rebuilt history: one import commit + project commits).
Old upstream history was intentionally not carried into this repository;
see [ARCHITECTURE.md](ARCHITECTURE.md) for the base.

## Unreleased

- **DFG control interface** (`drivers/platform/dfg/dfg.c`,
  `CONFIG_DFG`): unified runtime control at `/sys/devices/platform/dfg/` —
  `profile` (performance/balanced/battery), `cpu_min_freq`/`cpu_max_freq`,
  `governor`, `io_scheduler`, `thermal_override`, `boost_ms`, `deep_idle`,
  `thermal_events`, `thermal_limits`, `vendor_compat`.
- **Default performance mode** (`CONFIG_DFG_DEFAULT_PERF=y`): boots with
  the performance profile (schedutil, min 1401 MHz) applied from an early
  initcall, before userspace starts.
- **Thermal override + hard limits** (DFG watchdog): soft cap 50 °C
  (liftable via `thermal_override`), hard cap 60 °C that always enforces
  safe frequencies and resets the override; transitions logged to dmesg
  and `thermal_events` ring buffer; stock tsens/limiter framework
  remains fully active.
- **cpufreq governor switching helper** (`drivers/cpufreq/cpufreq.c`):
  `cpufreq_set_policy_governor()` exported so drivers can switch
  governors from kernel space.
- **Android 11 cgroup baseline**: `CONFIG_MEMCG=y` +
  `CONFIG_MEMCG_KMEM=y` added to `daisy_defconfig`; binder/ashmem/
  cgroup scheduling already present.
- **Build & CI**: `build_kernel.sh` (reproducible, clang/GCC auto-detect,
  `--with-zip`), `ci/check.sh` + `ci/static-checks.yml` (checkpatch,
  defconfig validation, Kconfig cross-check), `sepolicy/` sample for
  DFG-Controller.
- **Documentation**: `docs/SYSFS_API.md`, `Documentation/dfg/dfg-sysfs.rst`,
  `MIGRATION.md`, `flash_instructions.md`, README overhaul.
- **Boot boost**: `CONFIG_DFG_BOOT_BOOST_MS` (default 0) — optional
  one-shot boost shortly after boot when default profile is performance.

---

## 2026-08-11 — 4.9.337-DaisyForGaming

Updated build of the same version (banner unchanged). Flashable ZIP:
`DaisyForGaming-4.9.337-11-08-2026.zip`
(SHA-256: `ff38dae0c81c455af53d62776847d4bc742cb5b90df21f7abccde7d4620d24e6`).

### New in this build

- **CPU input boost** (`drivers/cpufreq/input_boost.c`): adapted the touch
  boost driver to the `input_boost` interface — `/sys/module/input_boost/
  parameters/{enabled, boost_freq, boost_duration_ms}` (default 1.4 GHz /
  60 ms; `boost_freq` clamped to a safe sub-maximum, duration clamped to
  20–150 ms).
- **lmk_aggressive** (`drivers/staging/android/lowmemorykiller.c`,
  `drivers/misc/daisy_mm.c`): `/sys/kernel/mm/lmk_aggressive` — moderate
  6-level minfree tuning (32–96 MB, adj 0/100/200/300/900/906), dormant by
  default (`enable_lmk=0`), snapshot/restore on disable.
- **Swappiness control** (`drivers/misc/daisy_mm.c`): `/sys/kernel/mm/
  swappiness` (0–200, boot default 100 instead of the baked 60) for
  zRAM-appropriate reclaim behavior.
- `CONFIG_ANDROID_LOW_MEMORY_KILLER=y` (dormant until toggled),
  `CONFIG_DAISY_MM=y`.

---

## 2026-08-10 — 4.9.337-DaisyForGaming (kernel-v4.9.337-DaisyForGaming)

First public release. Flashable ZIP:
`DaisyForGaming-4.9.337-10-08-2026.zip`
(SHA-256: `d278473f65e3ba0799b0ad7653d983ba2ca26b58776efa1a6d79dce23608fc5c`).

### Kernel changes (project commits)

- `net: enable TCP BBR + FQ qdisc, keep cubic as default (BBR runtime-switchable)`
- `kallsyms: add KALLSYMS_HARDENED (mask addresses in /proc/kallsyms)` — code + Kconfig added; **not enabled** in `daisy_defconfig` (dormant by default)
- `fs: sync: add dynamic fsync toggle (sysfs /sys/kernel/dyn_fsync/dyn_fsync)`
- `arm64: daisy: default I/O scheduler to BFQ (set DEFAULT_BFQ choice member)`
- `block: bfq: build as single merged object (bfq-iosched.c includes the other bfq files)`
- `block: bfq: fix API mismatches against 4.9.337 (bi_opf, elv_bio_merge_ok, rw_is_sync, elevator ops)`
- `cpufreq: interactive: add missing linux/irq_work.h include`
- `power: qpnp-smbcharger: add gaming_charge sysfs toggle (FCC 1200mA / vfloat 4000mV cap, charger-present interlock, auto-restore on unplug)`
- `DaisyForGaming: add BFQ scheduler (4.9 legacy split backport) + default bfq, enable interactive governor`
- `DaisyForGaming: bump version to 4.9.337, drop vendor git branding from compiler string`
- `DaisyForGaming: localversion branding`
- Vendor-wins merge work: `hexdump.c`, `event_timer.c`, `random32.c`,
  `early_random.c`, `drbg.h`/fuse ACLs, `random.h` decls, `kvm_host.h`,
  `hw_random/handle.c`, `fixmap.h`, plus restoration of the real vendor
  `daisy_defconfig`.

### Configuration (daisy_defconfig)

- `CONFIG_LOCALVERSION="-DaisyForGaming"`, `CONFIG_HZ=300`, `CONFIG_NR_CPUS=8`
- `CONFIG_LTO_CLANG=y` (Clang LTO)
- `CONFIG_TCP_CONG_BBR=y` with `CONFIG_DEFAULT_TCP_CONG="cubic"`
- `CONFIG_IOSCHED_BFQ=y`, `CONFIG_DEFAULT_BFQ=y`
- `CONFIG_CPU_FREQ_GOV_INTERACTIVE=y`
- `CONFIG_ZRAM=y` (lz4), `CONFIG_SWAP=y`

### Tooling (this repository)

- `scripts/build_kernel.sh`, `scripts/release_kernel.sh`,
  `scripts/sync_to_github.sh`
- `pack/ak3/` AnyKernel3 template (device-checked for daisy)
- `kernel_update.json` update manifest
- `.github/workflows/kernel-build.yml` CI
- `DFGController-update-checker/` app-side checker module
- Full documentation in `docs/`
