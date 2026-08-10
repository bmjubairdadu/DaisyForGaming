# DaisyForGaming Kernel

Custom Android kernel for the **Xiaomi Mi A2 Lite (`daisy`)** and its
`msm8953-qrd-sku3` platform, built for gaming performance on Android 11.

[![Kernel](https://img.shields.io/badge/kernel-4.9.337--DaisyForGaming-blue)](https://github.com/bmjubairdadu/DaisyForGaming/releases)
[![Arch](https://img.shields.io/badge/arch-arm64-informational)](https://github.com/bmjubairdadu/DaisyForGaming)
[![Device](https://img.shields.io/badge/device-Xiaomi%20Mi%20A2%20Lite%20(daisy)-green)](https://github.com/bmjubairdadu/DaisyForGaming)
[![License](https://img.shields.io/badge/license-GPL--2.0-red)](https://github.com/bmjubairdadu/DaisyForGaming/blob/main/COPYING)

## Overview

DaisyForGaming is a Linux **4.9.337** kernel for the Xiaomi Mi A2 Lite,
forked from the Android 11 (eleven) base of
[Couchpotato-sauce/kernel_xiaomi_sleepy](https://github.com/Couchpotato-sauce/kernel_xiaomi_sleepy).
It exists to bring verified, gaming-oriented improvements to the stock
`msm8953` experience:

- Network throughput and latency (TCP BBR + FQ)
- I/O responsiveness (BFQ scheduler as default)
- Charging behavior control while gaming (gaming_charge toggle)
- Storage/IO safety toggles (dynamic fsync)
- Hardened symbol exposure (KALLSYMS_HARDENED code — dormant until enabled in the defconfig)
- The project's own toolchain setup (Proton Clang 13, LTO)

All features are verified from source, the committed `daisy_defconfig`,
and the build/package scripts in this repository.

## Supported Devices

| Device | Codename | SoC | Architecture |
| ------ | -------- | --- | ------------ |
| Xiaomi Mi A2 Lite | `daisy` | Snapdragon 625 (msm8953) | arm64 |

The AnyKernel3 installer (in `pack/ak3`) enforces a device check for
`daisy` / `Mi_A2_Lite` and aborts on any other device.

## Kernel Specifications

| | |
| --- | --- |
| **Kernel base** | Linux 4.9.337 (from the source `Makefile`) |
| **Local version** | `-DaisyForGaming` (`CONFIG_LOCALVERSION="-DaisyForGaming"`) |
| **Reported version** | `4.9.337-DaisyForGaming` |
| **Architecture** | arm64 |
| **Platform** | Qualcomm msm8953 (Snapdragon 625) |
| **Defconfig** | `arch/arm64/configs/daisy_defconfig` |
| **Toolchain** | Proton Clang 13 (`clang-13`, `ld.lld`, LLVM binutils), LTO enabled (`CONFIG_LTO_CLANG=y`) |
| **Cross toolchain** | `aarch64-linux-gnu-` (kernel) + `arm-linux-gnueabi-` (compat) |
| **Android base** | Android 11 (branch base `eleven`) |
| **HZ / CPUs** | 300 Hz, 8 cores (`CONFIG_HZ=300`, `CONFIG_NR_CPUS=8`) |
| **Packaging** | AnyKernel3 flashable ZIP (TWRP) |
| **Release tag** | `kernel-v<version>-DaisyForGaming` |

## Features

| Feature | Status | Description |
| ------- | ------ | ----------- |
| TCP BBR + FQ qdisc | ✅ Implemented | `CONFIG_TCP_CONG_BBR=y`, Cubic stays the default (`CONFIG_DEFAULT_TCP_CONG="cubic"`); switch at runtime via `sysctl net.ipv4.tcp_congestion_control` |
| BFQ I/O scheduler | ✅ Implemented | `CONFIG_IOSCHED_BFQ=y`, `CONFIG_DEFAULT_BFQ=y` (default scheduler) |
| KALLSYMS_HARDENED | 🟡 Partial (dormant) | Code + Kconfig option present (`kernel/kallsyms.c`); not enabled in `daisy_defconfig` — masks symbol addresses when enabled |
| Dynamic fsync | ✅ Implemented | `echo 0 > /sys/kernel/dyn_fsync/dyn_fsync` (default on); toggle aggressive fsync behavior (`fs/sync.c`) |
| Gaming charge toggle | ✅ Implemented | sysfs control in the daisy charger driver (`drivers/power/supply/qcom/qpnp-smbcharger_d1a.c`); caps charge current/vfloat, with charger-present interlock and auto-restore |
| Interactive governor | ✅ Implemented | `CONFIG_CPU_FREQ_GOV_INTERACTIVE=y` with a 4.9.337 build fix (`cpufreq: interactive: add missing linux/irq_work.h`) |
| zRAM | ✅ Implemented | `CONFIG_ZRAM=y` with lz4 compression (`CONFIG_ZRAM_DEFAULT_COMP_ALGORITHM="lz4"`), `CONFIG_SWAP=y` |
| LTO (Clang) | ✅ Implemented | `CONFIG_LTO_CLANG=y`, `CONFIG_LTO=y` — link-time optimization build |
| Version branding | ✅ Implemented | `CONFIG_LOCALVERSION="-DaisyForGaming"`; clean compiler string (no vendor git branding) |
| Vendor baseline | ✅ Implemented | Vendor-customized files restored to the daisy vendor baseline where upstream 4.9.337 differs (vendor-wins merge rule) |

Details and per-feature source/config references: [docs/FEATURES.md](docs/FEATURES.md)

## Installation

> ⚠️ **Before you flash anything:** verify your device is a **Xiaomi Mi A2
> Lite (daisy)**, take a full backup, and keep a known-good boot image.
> Flashing the wrong kernel can leave your phone unbootable.

The release ZIP is an **AnyKernel3** package. Install it in TWRP:

1. Boot to **TWRP recovery**.
2. **Backup** (TWRP → Backup → Boot + System) — or back up the boot image manually.
3. TWRP → **Install** → select the downloaded `DaisyForGaming_v4.9.337-DaisyForGaming.zip`.
4. **Swipe to confirm** the flash.
5. Reboot to system.

The installer checks the device name (`daisy` / `Mi_A2_Lite`), patches the
boot image with magiskboot (Magisk is preserved), and only touches the
**boot** partition — it does not flash dtbo or any other partition.

Full walkthrough, rollback, and fastboot fallback: [docs/INSTALLATION.md](docs/INSTALLATION.md)

## Building

Requirements: Linux (WSL works), Proton Clang 13 at
`/opt/toolchains/proton-clang-13`, `gcc-aarch64-linux-gnu` /
`gcc-arm-linux-gnueabi`, `make`, `zip`, `python3`.

```bash
git clone https://github.com/bmjubairdadu/DaisyForGaming.git
cd DaisyForGaming

# plain build (out-of-tree, O=out)
./scripts/build_kernel.sh

# full release pipeline (build + package + GitHub Release + manifest)
./scripts/release_kernel.sh
```

Artifacts appear in `out/arch/arm64/boot/` (`Image`, `Image.gz`,
`Image.gz-dtb`), the flashable ZIP in `dist/`.

Complete guide: [docs/BUILD.md](docs/BUILD.md)

## Project Structure

```text
DaisyForGaming/
├── arch/arm64/                # arm64 support, daisy_defconfig, device trees
│   └── configs/daisy_defconfig
│   └── boot/dts/qcom/         # msm8953-qrd-sku3-daisy(.dts) + sakura
├── block/                     # BFQ scheduler (bfq-iosched.c + merged objects)
├── drivers/power/supply/qcom/ # qpnp-smbcharger_d1a.c (gaming_charge)
├── fs/sync.c                  # dynamic fsync toggle
├── kernel/kallsyms.c          # KALLSYMS_HARDENED
├── net/ipv4/tcp_bbr.c         # BBR congestion control
├── pack/ak3/                  # AnyKernel3 template (TWRP flashable)
├── scripts/                   # kernel build scripts + project tooling
│   ├── build_kernel.sh        # plain build
│   ├── release_kernel.sh      # build + package + release + manifest
│   └── sync_to_github.sh      # safe source synchronization
├── docs/                      # this documentation
├── DFGController-update-checker/  # app-side update checker module
├── .github/workflows/         # CI (validate + build)
├── kernel_update.json         # update manifest for DFG Controller
├── Makefile                   # Linux 4.9.337 build system
└── README.md
```

## Update System

Kernel releases flow through GitHub Releases → manifest → DFG Controller:

```text
GitHub Release
      ↓
Kernel ZIP
      ↓
SHA-256
      ↓
kernel_update.json   (this repo, main branch)
      ↓
DFG Controller (app)
      ↓
Update notification
      ↓
Download + SHA-256 verification
      ↓
User-controlled flash in TWRP
```

Manifest URL:
`https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json`

**DFG Controller never flashes automatically.** It only notifies, downloads,
and verifies the checksum; the actual flash is always a manual TWRP action by
the user. The checker module (Kotlin, WorkManager-based) ships in
[`DFGController-update-checker/`](DFGController-update-checker/).

Full description: [docs/UPDATE_SYSTEM.md](docs/UPDATE_SYSTEM.md)

## Releases

- **Tag format:** `kernel-v<version>-DaisyForGaming` (e.g. `kernel-v4.9.337-DaisyForGaming`)
- **Assets:** flashable ZIP `DaisyForGaming_v<version>.zip` + SHA-256 in the
  release notes and manifest
- **Release process:** `./scripts/release_kernel.sh` (never duplicates an existing tag)

See [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) and
[docs/CHANGELOG.md](docs/CHANGELOG.md).

## Development

1. Clone and create a branch: `git checkout -b my-change`
2. Modify source / Kconfig / `daisy_defconfig`
3. Build: `./scripts/build_kernel.sh`
4. Test on your device (keep a backup!)
5. Sync: `./scripts/sync_to_github.sh` (scans for secrets, never force-pushes)
6. Open a pull request using [the PR template](.github/pull_request_template.md)

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Documentation Index

| Document | Contents |
| -------- | -------- |
| [docs/FEATURES.md](docs/FEATURES.md) | Verified feature list with source/config references |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Kernel architecture, boot flow, packaging |
| [docs/BUILD.md](docs/BUILD.md) | Build environment and commands |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Safe flashing and rollback |
| [docs/USER_GUIDE.md](docs/USER_GUIDE.md) | End-user usage (toggles, updates, backups) |
| [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) | Device and ROM compatibility |
| [docs/UPDATE_SYSTEM.md](docs/UPDATE_SYSTEM.md) | How kernel updates are published and detected |
| [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) | Release script and manual fallback |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common problems and fixes |
| [docs/FAQ.md](docs/FAQ.md) | Frequently asked questions |
| [docs/SECURITY.md](docs/SECURITY.md) | Integrity, secrets, safe-update behavior |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | For kernel developers |
| [docs/CHANGELOG.md](docs/CHANGELOG.md) | Version history |
| [docs/SYNC.md](docs/SYNC.md) | Source synchronization guide |

## Troubleshooting

Quick start: if the device bootloops after flashing, **do not panic** —
reboot to TWRP, restore the boot backup you made before flashing, or flash
the previous known-good kernel ZIP. See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## FAQ

Short version: supported device = Xiaomi Mi A2 Lite (`daisy`); base =
Linux 4.9.337; builds need Proton Clang 13; install = TWRP only; updates =
detected by DFG Controller, flashed manually. Full answers:
[docs/FAQ.md](docs/FAQ.md)

## Security

- Every release ships a SHA-256 that you can verify locally.
- The app never auto-flashes; flashing is user-confirmed in TWRP.
- No signing keys or credentials are stored in this repository.
- See [docs/SECURITY.md](docs/SECURITY.md) for details and for reporting issues.

## Contributing

Bug reports: use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).
Feature requests: use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).
Pull requests: use the [PR template](.github/pull_request_template.md).

## License

The kernel source is **GPL-2.0** (see `COPYING` at the repository root).
The AnyKernel3 packaging template (`pack/ak3/`) is MIT (see `pack/ak3/LICENSE`).
