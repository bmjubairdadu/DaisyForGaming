# DaisyForGaming

**Best custom gaming kernel for Xiaomi Mi A2 Lite (daisy) — Snapdragon 625 (msm8953) — Linux 4.9.337**

DaisyForGaming is a performance-focused custom Android kernel for the **Xiaomi Mi A2 Lite (codename: daisy)**. Built for smooth gaming (Free Fire, PUBG Mobile, eFootball), low latency networking, and all popular kernel driver-loaders, with support for APatch, FolkPatch and KernelSU root solutions.

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

Linux (or WSL) with clang toolchain:

```bash
make O=out ARCH=arm64 daisy_defconfig
make O=out ARCH=arm64 SUBARCH=arm64 \
  CC=<clang>/bin/clang LD=<clang>/bin/ld.lld \
  AR=<clang>/bin/llvm-ar AS=<clang>/bin/llvm-as \
  NM=<clang>/bin/llvm-nm OBJCOPY=<clang>/bin/llvm-objcopy \
  OBJDUMP=<clang>/bin/llvm-objdump STRIP=<clang>/bin/llvm-strip \
  LLVM=1 LLVM_IAS=1 \
  CROSS_COMPILE=<clang>/bin/aarch64-linux-gnu- \
  CROSS_COMPILE_ARM32=<clang>/bin/arm-linux-gnueabi- \
  -j$(nproc)
```

Pack a flashable ZIP with `AnyKernel3/pack_anykernel.ps1` (Windows) after building
`out/arch/arm64/boot/Image.gz-dtb`.

## Credits

- Developer: **JUBAIR HOSEN**
- Base: TogoFire Panda kernel (Linux 4.9, msm8953) + CAF + LineageOS
- Installer: [AnyKernel3 by osm0sis](https://github.com/osm0sis/AnyKernel3)
- Root: [APatch](https://github.com/bmax121/APatch) /
  [FolkPatch](https://github.com/LyraVoid/FolkPatch) /
  [KernelPatch](https://github.com/bmax121/KernelPatch)

## License

GPL-2.0 (see `COPYING`) — same as the Linux kernel.
