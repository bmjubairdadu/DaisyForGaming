# DaisyForGaming

[![Latest Release](https://img.shields.io/github/v/release/bmjubairdadu/DaisyForGaming)](https://github.com/bmjubairdadu/DaisyForGaming/releases) [![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](COPYING)

**Custom gaming kernel for Xiaomi Mi A2 Lite (daisy) — Snapdragon 625 (msm8953) — Linux 4.9.337**

DaisyForGaming is a performance-focused custom Android kernel for the **Xiaomi Mi A2 Lite (codename: daisy)**. Built for smooth gaming (Free Fire, PUBG Mobile, eFootball), low latency networking, loadable kernel modules (`.ko` driver support for root tools and driver loaders), with support for Magisk, APatch, FolkPatch and KernelSU root solutions.

## Highlights

- **Daisy-only** — clean device tree for Mi A2 Lite, no unused board code
- **Gaming tuned** — HZ 300, schedutil + EAS, CPU/GPU input boost, deadline I/O scheduler, ZRAM + LZ4
- **Low ping networking** — Westwood TCP congestion control, fq_codel queueing, BBR available
- **Loader friendly** — any `.ko` driver version loads (vermagic check bypassed), `CONFIG_MODULES` enabled
- **Root ready** — `KALLSYMS` + `KALLSYMS_ALL` for APatch, FolkPatch and KernelPatch (KPM)
- **AnyKernel3** — flashable ZIP with stylish installer UI by JUBAIR HOSEN

## Compatibility

- Device: Xiaomi Mi A2 Lite (daisy) only
- Kernel: Linux 4.9.337 (`4.9.337-DaisyForGaming`)
- ROMs: Android 9 / 10 / 11 / 12 based 4.9 ROMs (e.g. crDroid 7)
- Recovery: TWRP / OrangeFox (ADB sideload supported)

## Installation

1. Download the latest `DaisyForGaming-vX.X-JUBAIR-HOSEN.zip` from
   [Releases](https://github.com/bmjubairdadu/DaisyForGaming/releases)
2. Reboot to recovery (TWRP / OrangeFox)
3. Flash the ZIP (or `adb sideload <zip>`)
4. Reboot — first boot may take 5–10 minutes
5. Verify: Settings → About phone → Kernel version → `4.9.337-DaisyForGaming`

> Always keep a backup of your working `boot.img` before flashing any custom kernel.

## Building

> Tip: full history is large — slim clone with
> `git clone --depth 1 https://github.com/bmjubairdadu/DaisyForGaming.git`

Linux (or WSL) with GCC cross toolchain:

```bash
make O=out ARCH=arm64 daisy_defconfig
make O=out ARCH=arm64 SUBARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
  LD=aarch64-linux-gnu-ld \
  KBUILD_BUILD_USER="JUBAIR" KBUILD_BUILD_HOST="DaisyForGaming" \
  -j$(nproc)
```

Pack a flashable ZIP with `AnyKernel3/pack_anykernel.ps1` (Windows) after building
`out/arch/arm64/boot/Image.gz-dtb`.

## FAQ

- **Which ROMs work?** Any Android 9–12 based 4.9 ROM for daisy (e.g. crDroid 7).
  Check Settings → About phone → Kernel version after flashing.
- **Bootloop after flashing?** Restore your `boot.img` backup from recovery,
  then report the issue with your ROM name and version.
- **Magisk / root?** Flash Magisk or patch boot with APatch/FolkPatch after
  the kernel — root apps, driver loaders (`.ko` via `insmod`) and modules
  are supported (`CONFIG_MODULES`, forced-load friendly).
- **Lag or heat?** The kernel ships balanced thermal + boost settings; check
  background apps and give the first boot 10 minutes to settle.

## Credits

- Developer: **JUBAIR HOSEN**
- Base: Linux 4.9 CAF (msm8953) + LineageOS
- Installer: [AnyKernel3 by osm0sis](https://github.com/osm0sis/AnyKernel3)
- Root: [APatch](https://github.com/bmax121/APatch) /
  [FolkPatch](https://github.com/LyraVoid/FolkPatch) /
  [KernelPatch](https://github.com/bmax121/KernelPatch)

## License

GPL-2.0 (see `COPYING`) — same as the Linux kernel.
