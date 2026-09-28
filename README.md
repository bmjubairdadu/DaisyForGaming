# DaisyForGaming Kernel

**A fast, stable, gaming-focused custom kernel for the Xiaomi Mi A2 Lite (codename `daisy` / `daisy_sprout`, Qualcomm Snapdragon 625 / MSM8953).**

DaisyForGaming is a performance-tuned Linux kernel built for **smooth gaming, snappy everyday use, faster charging, and rock-solid stability** on the Xiaomi Mi A2 Lite running Android 11 custom ROMs (crDroid and other AOSP-based ROMs).

![Device](https://img.shields.io/badge/device-Xiaomi%20Mi%20A2%20Lite%20(daisy)-blue)
![SoC](https://img.shields.io/badge/SoC-Snapdragon%20625%20(MSM8953)-green)
![Android](https://img.shields.io/badge/Android-11-brightgreen)
![Kernel](https://img.shields.io/badge/Linux-4.9.337-orange)
![Release](https://img.shields.io/github/v/release/bmjubairdadu/DaisyForGaming?include_prereleases&label=release&color=success)
![License](https://img.shields.io/badge/license-GPL--2.0-blue)

---

## 📥 Download & Install

> ⚠️ Flashing a custom kernel can affect warranty/OTA. Back up first. You flash at your own risk.

**Requirements:** unlocked bootloader, a custom recovery (TWRP/OrangeFox) or your ROM's built-in recovery, and an **Android 11 `daisy` ROM** (crDroid v7.x recommended).

1. Grab the latest `DaisyForGaming-vX.X.zip` from the [**Releases**](https://github.com/bmjubairdadu/DaisyForGaming/releases) page.
2. Reboot to recovery.
3. Flash the zip (**Install → select zip → swipe**).
4. *(Optional)* Flash your root solution (KernelSU) afterwards.
5. Reboot. The first boot may take slightly longer.

The zip is an [AnyKernel3](https://github.com/osm0sis/AnyKernel3) package — it patches your current boot image and does **not** wipe data. It also checks device (`daisy`) and Android version (11) before installing, so it is safe against wrong flashes.

---

## 🚀 Features

### ⚡ Gaming & Performance
- **CPU Input Boost** — instant CPU ramp-up on touch, plus a fingerprint-unlock boost for lag-free app launches.
- **Adreno Idler** GPU tuning — keeps the Adreno 506 responsive under load and efficient at idle.
- **schedutil** CPU governor by default for a smooth performance/battery balance.
- **HZ = 300 + PREEMPT** low-latency configuration for a more responsive UI and steadier frame pacing.
- **Deadline I/O scheduler** for lower storage latency while gaming and loading apps.

### 🌐 Network
- **BBR** TCP congestion control (default) + **FQ** packet scheduler for lower latency and better throughput on mobile data and Wi-Fi.

### 🔌 Charging & Battery
- Tuned charging profile — up to **2000 mA** fast charge with relaxed thermal-mitigation steps for quicker top-ups.
- **Float voltage kept at the safe stock 4400 mV** (no risky over-voltage).
- **Power-efficient workqueues** to cut idle battery drain.
- Charging-control sysfs nodes (`charging_enabled` / `battery_charging_enabled`) remain writable for advanced users and bypass-charging apps.

### 🧠 Memory
- **zRAM + writeback** for better multitasking and RAM management.

### 🔓 Root Ready
- **KernelSU-ready** via `CONFIG_KPROBES` (kprobe hooks — no source patching required).
- **OverlayFS** enabled for KernelSU module support.
- Unsigned kernel-module loading allowed.

---

## 🛠️ Build from source

```bash
git clone https://github.com/bmjubairdadu/DaisyForGaming.git
cd DaisyForGaming

export ARCH=arm64
make O=out daisy_defconfig
make -j"$(nproc)" O=out CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as \
     NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
     LLVM=1 LLVM_IAS=1 \
     CROSS_COMPILE=aarch64-linux-gnu- \
     CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
     Image.gz-dtb
```

Output: `out/arch/arm64/boot/Image.gz-dtb` (daisy DTB already appended — ready for AnyKernel3).
Any recent Clang/LLVM toolchain works (tested with Ubuntu clang 14 / LLD 14).

---

## 📋 Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full history.

| Version | Date | Highlights |
|---------|------|------------|
| **v1.1** | 2026-09-28 | Bug-fix release: backported `pn533` out_urb use-after-free fix (`35529d6b827ee`) and `rbd` `do_rbd_add()` use-after-free fix (`71da2a151ed1a`) — clean fixed source tree, no device behavior change |
| **v1.0** | 2026-09-26 | Initial public release: gaming tuning (input boost, Adreno idler, HZ 300, deadline I/O), BBR + FQ, 2000 mA fast charge, zRAM + writeback, KernelSU-ready |

Bug tracking: [KNOWN-BUGS](KNOWN-BUGS) lists every backported stable fix and its status.

---

## 🙏 Credits

- Base kernel: [TogoFire](https://github.com/TogoFire/kernel_xiaomi_panda) (r54).
- [AnyKernel3](https://github.com/osm0sis/AnyKernel3) by osm0sis.
- The Xiaomi `daisy` developer community.

## 📄 License

Released under the **GNU General Public License v2.0 (GPL-2.0)**, the same license as the Linux kernel. See [COPYING](COPYING).

---

<sub>**Keywords:** Xiaomi Mi A2 Lite kernel · daisy kernel · daisy_sprout · MSM8953 kernel · Snapdragon 625 / SDM625 custom kernel · Android 11 gaming kernel · crDroid kernel · KernelSU kernel Mi A2 Lite · fast charging kernel daisy · DaisyForGaming</sub>