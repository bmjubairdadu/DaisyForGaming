# DaisyForGaming Kernel 🎮

![Kernel](https://img.shields.io/badge/Linux-4.9.337--DaisyForGaming-orange.svg)
![Platform](https://img.shields.io/badge/SoC-Snapdragon_625_(MSM8953)-green.svg)
![Version](https://img.shields.io/badge/Release-v1.0_Official-blue.svg)
![Developer](https://img.shields.io/badge/Developer-JUBAIR_HOSEN-brightgreen.svg)
![Root](https://img.shields.io/badge/Root-Magisk_/_FolkPatch-purple.svg)
![License](https://img.shields.io/badge/License-GPL--2.0-red.svg)

> **DaisyForGaming** is a high-performance, gaming-optimized custom kernel specifically crafted for the **Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)**. Built on Linux 4.9.337 with Clang 14 and LLD, it features sustained 8-core CPU performance, hardware bypass charging, ALSA digital audio boost, recovery storage decryption fixes, and a 100% anti-cheat safe vanilla kernel structure.

---

## 📱 Device Specifications

| Specification | Details |
|---|---|
| **Device Model** | Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`) |
| **SoC** | Qualcomm Snapdragon 625 (MSM8953, 8× Cortex-A53 up to 2.0 GHz) |
| **GPU** | Qualcomm Adreno 506 (650 MHz) |
| **Kernel Version** | Linux 4.9.337-DaisyForGaming |
| **Compiler** | Clang 14.0.0 (LLVM + LLD Linker) |
| **Architecture** | ARM64 (`aarch64`) |
| **Developer** | **JUBAIR HOSEN** |

---

## ⚡ Key Highlights & Features

### 🔓 1. Recovery Decryption & Stability Fix
* **Fixed Recovery Auto-Shutdown:** Reclassified the motherboard thermistor trip (`modem_trip2` at 75°C) to passive in `msm8953-thermal.dtsi` and moved critical power-off to 95°C. Storage decryption in TWRP / OrangeFox completes smoothly with zero shutdowns.
* **Qualcomm Hardware Entropy (`/dev/hw_random` & `/dev/msm-rng`):** Enabled `CONFIG_HW_RANDOM=y` and `CONFIG_HW_RANDOM_MSM_LEGACY=y` in defconfig. Ensures Android Keymaster HAL can communicate with Qualcomm TrustZone during recovery decryption, preventing SIGABRT crashes and reboot loops.
* **Storage Checkpoints:** Enabled `CONFIG_DM_BOW=y` and `CONFIG_CRYPTO_TWOFISH=y` for Android FBE decryption checkpoints.

### 🎮 2. Sustained 8-Core Performance & Cool Thermals
* **Zero Core-Isolation:** Completely disabled `sched_isolate_cpu()` core-killing mechanism. All 8 Cortex-A53 cores stay online unconditionally under heavy thermal load, preventing micro-stutters and sudden FPS drops.
* **True Hardware Bypass Charging (Free Fire & Free Fire Max):** When Free Fire (`com.dts.freefireth` / `com.dts.freefiremax`) is focused in `top-app` and the charger is plugged in:
  - Phone runs directly on AC adapter power (`charging_enabled = 1`).
  - Battery charging is completely inhibited (`battery_charging_enabled = 0`, `constant_charge_current_max = 0`).
  - 0% battery charge, 0% battery drain, and **zero battery heat** while gaming!
* **Optimized Fast Charging (1500mA):** Charges rapidly while keeping battery temperature below 38°C–40°C on micro-USB.

### 🔊 3. Audio Loudness & Quality Boost
* **Restored ALSA Digital Volume Controls:** Exposed `RX1/RX2/RX3 Digital Volume` and `DEC1/DEC2 Volume` mixer controls to the Android Audio HAL (`msm-digital-cdc-legacy.c`).
* **Sysfs Sound Boost (`dfg_tune.sh`):**
  - **Speaker Gain:** `+4dB` for louder, crystal-clear media playback without distortion.
  - **Headphone Gain:** `+4dB` (L/R) for punchy bass and clean highs.
  - **Mic Gain:** `+2dB` for crisp in-game voice chat (Discord, Free Fire, PUBG).
  - **Earpiece Gain:** `+3dB` for clear voice call audio.

### 🎬 4. Butter Smooth 60 FPS UI & Video
* **Schedutil Frame Pacing:** `up_rate_limit_us 500` (0.5ms instant ramp) and `down_rate_limit_us 20000` (20ms hold down) eliminates video playback and UI scrolling micro-stutters.
* **Adreno 506 GPU Floor:** Minimum clock locked at **216 MHz** (governor: `msm-adreno-tz`) with `adreno_idler` disabled for zero frame drops in 1080p/2K/4K video streaming and 3D games.
* **Low Ping Network:** Default **TCP BBR** congestion control + **FQ** packet scheduling for stable, jitter-free ping.

### 🛡️ 5. 100% Anti-Cheat Safe (No Account Bans)
* **Pure Vanilla Architecture:** Zero in-kernel root hooks, zero KSU modifications, and zero SusFS strings in `vmlinux`.
* **Zero Ban Risk:** Modern game anti-cheat scanners (Free Fire, Mobile Legends, PUBG Mobile) detect absolutely nothing at the kernel level.
* **Root Flexibility:** Compatible with standard **Magisk** or **FolkPatch / KernelPatch** (patch boot image after flash).

---

## ⬇️ Download & Verification (v1.0 Official)

| Flashable Zip | Size | SHA256 Checksum |
|---|---|---|
| **`DaisyForGaming-v1.0-Gaming-11-01-2026.zip`** | 18.3 MB (18,307,175 bytes) | `ecfeb0ca2124655c68c3c47a523591a64d1a268bde81ee6a8f662f0ba9ac6121` |

Grab the latest zip from the [Releases Page](https://github.com/bmjubairdadu/DaisyForGaming/releases).

---

## 📲 Installation Guide

### Via Custom Recovery (TWRP / OrangeFox):
1. Download **`DaisyForGaming-v1.0-Gaming-11-01-2026.zip`** and place it on your device storage or SD card.
2. Boot into recovery (TWRP or OrangeFox).
3. *(Recommended)* Back up your current `boot` partition.
4. Go to **Install**, select the zip file, and swipe to flash.
5. *(Optional)* If you want root access, flash **Magisk** zip now or patch the boot partition with **FolkPatch**.
6. Reboot to System and enjoy butter smooth 60 FPS performance!

---

## 🛠️ Building From Source

Built on Ubuntu 22.04 (WSL2 / Linux) with Clang 14.0.0 and LLVM:

```bash
# Clone the repository
git clone https://github.com/bmjubairdadu/DaisyForGaming.git
cd DaisyForGaming

# Build kernel image
bash dfg_build.sh

# Package flashable AnyKernel3 zip
bash dfg_zip.sh
```

---

## 🙏 Credits

- **JUBAIR HOSEN** — Lead Developer & Maintainer
- **AnyKernel3** by osm0sis — Universal Ramdisk Flasher
- The Xiaomi daisy open-source community

---

## 📄 License

This project is licensed under the **GNU General Public License v2.0 (GPL-2.0)**.
