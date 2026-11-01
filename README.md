# DaisyForGaming Kernel

[![Linux](https://img.shields.io/badge/Kernel-Linux%204.9.337-24292e.svg?style=flat-square&logo=linux&logoColor=white)](https://github.com/bmjubairdadu/DaisyForGaming)
[![Device](https://img.shields.io/badge/Device-Xiaomi%20Mi%20A2%20Lite%20(daisy)-0078d4.svg?style=flat-square)](https://github.com/bmjubairdadu/DaisyForGaming)
[![Platform](https://img.shields.io/badge/Platform-Qualcomm%20Snapdragon%20625-e65100.svg?style=flat-square)](https://github.com/bmjubairdadu/DaisyForGaming)
[![Compiler](https://img.shields.io/badge/Compiler-Clang%2014.0%20%2B%20LLD-5c2d91.svg?style=flat-square)](https://github.com/bmjubairdadu/DaisyForGaming)
[![Release](https://img.shields.io/badge/Version-v1.0%20Official-008000.svg?style=flat-square)](https://github.com/bmjubairdadu/DaisyForGaming/releases)
[![Developer](https://img.shields.io/badge/Developer-JUBAIR%20HOSEN-1f2328.svg?style=flat-square)](https://github.com/bmjubairdadu)
[![License](https://img.shields.io/badge/License-GPL%202.0-d32f2f.svg?style=flat-square)](COPYING)

**DaisyForGaming** is a high-performance custom kernel engineered specifically for the **Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)**. Built on upstream Linux 4.9.337 with Clang 14 and LLD, it delivers sustained eight-core computing power, hardware AC bypass charging, restored digital audio gain, emergency recovery safeguards, and a clean vanilla architecture designed to eliminate anti-cheat false positives.

---

## Technical Specifications

| Parameter | Specification |
|:---|:---|
| **Target Device** | Xiaomi Mi A2 Lite (`daisy`, `daisy_sprout`) |
| **SoC** | Qualcomm Snapdragon 625 (MSM8953) |
| **CPU Architecture** | 8x ARM Cortex-A53 up to 2.0 GHz (64-bit ARMv8-A) |
| **GPU Architecture** | Qualcomm Adreno 506 (650 MHz max) |
| **Base Kernel** | Linux 4.9.337-DaisyForGaming |
| **Toolchain** | Clang 14.0.0 (LLVM + LLD Linker) |
| **Target ABI** | ARM64 (`aarch64-linux-gnu`) |
| **Lead Developer** | JUBAIR HOSEN |

---

## Core Enhancements

### 1. Recovery Decryption and Hardware Safeguards
* **Motherboard Thermal Trip Correction:** In `msm8953-thermal.dtsi`, trip point `modem_trip2` on sensor `pm8953_vadc 0x13` (`case_therm`) was previously misclassified as a critical trip at 75 deg C. Under multi-core cryptographic load during recovery storage decryption, the thermistor reached 75 deg C, causing `thermal_core.c` to issue `orderly_poweroff(true)` and shut down the handset. The trip has been reclassified to passive at 80 deg C, and the emergency hardware power-off threshold is now safely pinned at 95 deg C.
* **Qualcomm Hardware Entropy Routing:** Enabled `CONFIG_HW_RANDOM=y` and `CONFIG_HW_RANDOM_MSM_LEGACY=y` in `daisy_defconfig`. Character nodes `/dev/hw_random` and `/dev/msm-rng` now initialize properly, enabling Keymaster HAL (`android.hardware.keymaster@3.0/4.0-service`) to securely communicate with Qualcomm TrustZone during recovery decryption without SIGABRT abort loops.
* **Android Checkpoints:** Enabled `CONFIG_DM_BOW=y` (Backup on Write) and `CONFIG_CRYPTO_TWOFISH=y` for Android FBE storage decryption checkpoints.

### 2. Sustained Eight-Core Gaming Performance
* **Elimination of Core Isolation:** Completely disabled `sched_isolate_cpu()` core-dropping routines in `cpu_cooling.c`. Frequency scaling is clamped safely to 1.68 GHz and 1.4 GHz floors under thermal regulation, guaranteeing that all eight CPU cores remain online under heavy gaming load.
* **True Hardware AC Bypass Charging:** When Free Fire (`com.dts.freefireth` / `com.dts.freefiremax`) is focused in `top-app` while connected to a power supply, the kernel activates hardware bypass mode:
  - Phone logic runs directly from external charger power (`charging_enabled = 1`).
  - Battery charging is completely suspended (`battery_charging_enabled = 0`, `constant_charge_current_max = 0`).
  - Prevents battery heating and battery wear during extended gaming sessions.
* **Calibrated Charging Current:** Fast charging current is optimized to 1500 mA on micro-USB to maintain battery temperatures below 38–40 deg C.

### 3. Audio Loudness and ALSA Mixer Control
* **Restored ALSA Digital Volume Controls:** Removed `#ifndef CONFIG_SOUND_CONTROL` wrappers in `msm-digital-cdc-legacy.c`. `RX1`, `RX2`, `RX3 Digital Volume` and `DEC1`, `DEC2 Volume` registers are now fully exposed to the ALSA mixer interface, enabling Android Audio HAL (`audio.primary.msm8953.so` / `mixer_paths.xml`) to drive full dynamic range without artificial digital attenuation.
* **Autonomous Sysfs Gain Boosts:**
  - **Speaker Gain:** +4 dB for clear, distortion-free loudspeaker output.
  - **Headphone Gain:** +4 dB (Left/Right) for full-range analog audio output.
  - **Microphone Gain:** +2 dB for crisp communication in Discord, cellular, and in-game calls.
  - **Earpiece Gain:** +3 dB for loud, intelligible voice calls.

### 4. Display Synchronization and 60 FPS Video Frame Pacing
* **Schedutil Rate Limits:** Configured `up_rate_limit_us` to 500 us (0.5 ms instantaneous response) and `down_rate_limit_us` to 20,000 us (20 ms hold down). Prevents frequency oscillation and eliminates stutter during 60 FPS video streaming and app transitions.
* **Adreno 506 GPU Floor:** Baseline GPU frequency is maintained at 216 MHz with `adreno_idler` disabled, preventing dropped frames during high-bitrate video decoding and 3D surface composition.
* **Network Latency Optimization:** Built with default TCP BBR congestion control and Fair Queueing (FQ) packet scheduling to minimize ping jitter.

### 5. Clean Vanilla Architecture and Anti-Cheat Safety
* **Zero In-Tree Root Hooks:** Contains zero KernelSU hooks, zero syscall wrappers, and zero SusFS strings in `vmlinux`.
* **Zero Anti-Cheat Detection:** Game security systems (Free Fire, Mobile Legends, PUBG Mobile) inspect kernel integrity without detecting unauthorized symbols or modifications.
* **Root Flexibility:** Compatible with standard Magisk or post-flash boot patching via FolkPatch / KernelPatch.

---

## Release Verification

| Package | Size | SHA256 Checksum |
|:---|:---|:---|
| **`DaisyForGaming-v1.0-Gaming-11-01-2026.zip`** | 15.2 MB (15,194,378 bytes) | `9955743854bf4adf9b1fd4ca263940aa9e4cc05dc38c54541f29562a96fe20cc` |

Release assets can be downloaded directly from the [GitHub Releases](https://github.com/bmjubairdadu/DaisyForGaming/releases/tag/v1.0) section.

---

## Installation

### Custom Recovery (TWRP / OrangeFox)
1. Download **`DaisyForGaming-v1.0-Gaming-11-01-2026.zip`** to internal storage or an SD card.
2. Reboot into recovery mode.
3. Recommended: Create a backup of your active `boot` partition.
4. Navigate to **Install**, select the zip archive, and confirm flash.
5. Optional: If root access is desired, flash Magisk or patch the boot image using FolkPatch.
6. Reboot to System.

---

## Building from Source

### Prerequisites
* Linux environment (Ubuntu 22.04 LTS or WSL2)
* LLVM Clang 14.0.0 toolchain and GNU binutils for `aarch64` and `arm`

### Build Procedure
```bash
# Clone the tree
git clone https://github.com/bmjubairdadu/DaisyForGaming.git
cd DaisyForGaming

# Compile kernel Image.gz-dtb
bash dfg_build.sh

# Generate AnyKernel3 flashable zip
bash dfg_zip.sh
```

---

## Maintainer and Credits

* **JUBAIR HOSEN** — Lead Developer and Maintainer
* **osm0sis** — AnyKernel3 universal ramdisk mod script
* **Linux Kernel Community** — Upstream Linux 4.9 codebase

---

## License

This software is distributed under the terms of the **GNU General Public License Version 2 (GPL-2.0)** as published by the Free Software Foundation.
