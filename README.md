# DaisyForGaming Kernel

Custom Android kernel for the **Xiaomi Mi A2 Lite (daisy / msm8953)**, built for
gaming performance on Android 11 (eleven).

| | |
|---|---|
| **Kernel** | Linux 4.9.337 (matching the source Makefile) |
| **Device** | Xiaomi Mi A2 Lite — `daisy`, Snapdragon 625 (msm8953) |
| **Branch** | `main` |
| **Repository** | https://github.com/bmjubairdadu/DaisyForGaming |
| **Update manifest** | https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json |
| **Toolchain** | Proton Clang 13 (llvm-ar/as/ld.lld, gcc aarch64/arm cross) |

## Feature highlights

- TCP **BBR** congestion control + **FQ** qdisc, runtime-switchable (Cubic stays default)
- **BFQ** I/O scheduler set as the default scheduler
- **KALLSYMS_HARDENED** (masks addresses in `/proc/kallsyms`)
- Dynamic **fsync** toggle (`/sys/kernel/dyn_fsync/dyn_fsync`)
- Gaming charge sysfs toggle (FCC/vfloat cap, charger-present interlock, auto-restore on unplug)
- Interactive governor fixes for 4.9.337

## Build instructions

Requirements (build host):

- Ubuntu 22.04 (or any Linux with the toolchain below)
- `Proton Clang 13` at `/opt/toolchains/proton-clang-13`
- `gcc-aarch64-linux-gnu` and `gcc-arm-linux-gnueabi` cross toolchains
- `make`, `zip`, `python3`, `gh` (GitHub CLI)

```bash
# one-shot build (in-tree)
./scripts/build_kernel.sh          # make daisy_defconfig && make -j$(nproc) Image.gz-dtb

# or the full release pipeline (build + package + publish)
./scripts/release_kernel.sh
```

The flashable ZIP is an **AnyKernel3** package (template vendored in `pack/ak3`):
safe TWRP-flashable, device-checked for `daisy`, preserves your boot image and Magisk.

## Source synchronization

After modifying kernel source/config/build files:

```bash
./scripts/sync_to_github.sh
```

This stages changes, scans for secrets (aborts if found), commits with a
meaningful message, and pushes to `origin/main` **without force**. If the remote
rejected the push, resolve with `git pull --rebase origin main` and re-run.

See [docs/SYNC.md](docs/SYNC.md).

## Release process

```bash
./scripts/release_kernel.sh
```

Reads the version from `Makefile` (currently **4.9.337**), builds, packages the
AnyKernel3 ZIP, computes SHA-256, creates tag `kernel-v<version>-DaisyForGaming`,
publishes a GitHub Release with the ZIP, and updates `kernel_update.json`
(version, date, download URL, SHA-256, changelog) in this repo.

It refuses to duplicate an existing tag/release. See [docs/RELEASE.md](docs/RELEASE.md).

## Update manifest

`kernel_update.json` (served at the raw URL above) is the single source of truth
for kernel update checks:

```json
{
  "kernel_version": "4.9.337-DaisyForGaming",
  "release_date": "2026-08-10",
  "download_url": "https://github.com/.../releases/download/.../DaisyForGaming_v4.9.337-DaisyForGaming.zip",
  "sha256": "<sha256 of the zip>",
  "release_url": "https://github.com/.../releases/...",
  "changelog": "...",
  "mandatory": false
}
```

## Kernel update notification (DFG Controller)

The companion app checks this manifest, compares against the installed kernel
version, and shows a notification with version/changelog/date plus a download
button. Download is verified with SHA-256; **the app never flashes automatically** —
flashing always happens manually in TWRP by the user.

The drop-in checker module (Kotlin) ships in [`DFGController-update-checker/`](DFGController-update-checker/).

## GitHub Actions

`.github/workflows/kernel-build.yml` validates and builds the kernel on pushes,
and (on `kernel-v*` tag pushes) can build + publish a release. The local
`release_kernel.sh` remains the primary release path.

## License

Kernel source retains its upstream license (GPL-2.0). AnyKernel3 template by
osm0sis (MIT). Your own additions are GPL-2.0.
