# DEVELOPMENT

Guide for developers who want to modify and build DaisyForGaming.

## Source tree

Standard Linux 4.9.337 tree plus project additions:

| Path | Purpose |
| ---- | ------- |
| `arch/arm64/configs/daisy_defconfig` | Project config — most feature enable/disable happens here |
| `block/bfq-iosched.c` etc. | BFQ scheduler (backport, 4.9.337 API-fixed) |
| `fs/sync.c` | dyn_fsync toggle |
| `kernel/kallsyms.c` | KALLSYMS_HARDENED |
| `net/ipv4/tcp_bbr.c` | BBR |
| `drivers/power/supply/qcom/qpnp-smbcharger_d1a.c` | gaming_charge |
| `pack/ak3/` | AnyKernel3 template (installer) |
| `scripts/` | build/release/sync tooling |
| `docs/` | This documentation |

## Branch strategy

- `main` is the integration branch. It must always build (CI validates on
  push).
- Work on topic branches: `git checkout -b feature/my-change`.
- Merge via pull requests; the [PR template](../.github/pull_request_template.md)
  requires build + device-test info.

## Making a kernel change

1. **Source changes** in the relevant subsystem (e.g. a new scheduler,
   driver, or fs change).
2. **Config changes**:
   - Feature toggle that should ship by default → edit
     `arch/arm64/configs/daisy_defconfig` (and keep it in sync with what
     the build actually uses — verify with `grep CONFIG_ out/.config`).
   - New Kconfig symbol → add it in the subsystem's `Kconfig`, then enable
     it in `daisy_defconfig`.
3. **Build**:
   ```bash
   ./scripts/build_kernel.sh
   ```
4. **Verify**:
   ```bash
   gzip -dc out/arch/arm64/boot/Image.gz-dtb | strings | grep -m1 'Linux version [0-9]'
   grep -E 'CONFIG_YOUR_FEATURE' out/.config
   ```
5. **Test on device** — always with a TWRP boot backup first.

## Commit conventions

- One logical change per commit.
- Conventional subject lines used in this repo:
  `subsystem: short description` (e.g. `net: enable TCP BBR + FQ qdisc`).
- The project prefix `DaisyForGaming: ` is used for branding/vendor merge
  decisions.
- Never commit: build outputs (`out/`, `dist/`, `*.zip`), `.config`,
  logs, or secrets — they are git-ignored and the sync script scans for
  secrets.

## Syncing to GitHub

```bash
./scripts/sync_to_github.sh
```

Detects changes, scans for secrets, commits, and pushes to `main`
(no force-push). If the push is rejected, `git pull --rebase origin main`
and re-run. See [SYNC.md](SYNC.md).

## Testing

- `scripts/build_kernel.sh` must complete with a valid
  `out/arch/arm64/boot/Image.gz-dtb`.
- CI runs the full build on every push to `main` (`.github/workflows/kernel-build.yml`).
- On-device: verify `uname -r` = `4.9.337-DaisyForGaming`, check the
  feature toggles exist, and run your normal workload for stability/battery.

## Preparing a release

1. Merge tested changes to `main`.
2. Run `./scripts/release_kernel.sh` (builds, packages, releases, updates
   the manifest). See [RELEASE_PROCESS.md](RELEASE_PROCESS.md).
3. Verify the manifest at the raw URL and the release asset checksum.

## Pull requests

Use the [PR template](../.github/pull_request_template.md): summary,
subsystem, source/config changes, build result, device tested, logs,
performance/battery impact, breaking changes, checklist.
