# CHANGELOG

All entries below are derived from the actual git history of this
repository (from the rebuilt history: one import commit + project commits).
Old upstream history was intentionally not carried into this repository;
see [ARCHITECTURE.md](ARCHITECTURE.md) for the base.

## Unreleased

- (nothing yet)

---

## 2026-08-10 — 4.9.337-DaisyForGaming (kernel-v4.9.337-DaisyForGaming)

First public release. Flashable ZIP:
`DaisyForGaming_v4.9.337-DaisyForGaming.zip`
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
