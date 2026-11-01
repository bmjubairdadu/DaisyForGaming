# DaisyForGaming v1.0 — Performance, Recovery Fix and Sound Boost

Official release of the **DaisyForGaming** custom kernel for the **Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)** based on Linux 4.9.337.

---

## Highlights and Change Summary

### 1. Recovery Decryption and Critical Power-Off Safeguards
* **Fixed Automatic Power-Off in Recovery:** In `msm8953-thermal.dtsi`, trip point `modem_trip2` on sensor `pm8953_vadc 0x13` (`case_therm`) was previously configured with `type = "critical"` at 75 deg C. Under multi-core cryptographic load during recovery storage decryption, the thermistor reached 75 deg C, causing `thermal_core.c` to issue `orderly_poweroff(true)` and shut down the phone. Reclassified `modem_trip2` to passive at 80 deg C and placed the critical trip point at 95 deg C.
* **Qualcomm Hardware Entropy Routing:** Enabled `CONFIG_HW_RANDOM=y` and `CONFIG_HW_RANDOM_MSM_LEGACY=y` in `daisy_defconfig`. Character nodes `/dev/hw_random` and `/dev/msm-rng` now initialize properly, enabling Keymaster HAL (`android.hardware.keymaster@3.0/4.0-service`) to securely communicate with Qualcomm TrustZone during recovery decryption without SIGABRT abort loops.
* **Storage Checkpoints:** Enabled `CONFIG_DM_BOW=y` (Backup on Write) and `CONFIG_CRYPTO_TWOFISH=y` for Android FBE storage decryption checkpoints.

### 2. Sustained Eight-Core Gaming Performance and Thermal Stability
* **Elimination of Core Isolation:** Disabled `sched_isolate_cpu()` routines in `cpu_cooling.c`. Frequency scaling is clamped to 1.68 GHz and 1.4 GHz floors under thermal regulation, guaranteeing all eight Cortex-A53 cores stay online during intensive gameplay.
* **True Hardware AC Bypass Charging:** When Free Fire (`com.dts.freefireth` / `com.dts.freefiremax`) is active in `top-app` on charger power, battery charging is suspended (`battery_charging_enabled = 0`, `constant_charge_current_max = 0`) while system logic runs directly on external power, eliminating battery heat.
* **Calibrated Fast Charge:** Fast charging current is set to 1500 mA on micro-USB to keep battery temperature below 38–40 deg C.
* **Frame Pacing and GPU Scaling:** Schedutil rate limits (500 us up, 20 ms down) and Adreno 506 minimum floor (216 MHz) with `adreno_idler` disabled eliminate micro-stutter in 60 FPS video playback and 3D games.

### 3. Audio Loudness and Mixer Controls
* **Restored ALSA Digital Volume Controls:** Removed `#ifndef CONFIG_SOUND_CONTROL` wrappers in `msm-digital-cdc-legacy.c`. `RX1`, `RX2`, `RX3 Digital Volume` and `DEC1`, `DEC2 Volume` registers are now fully exposed to the ALSA mixer interface, enabling Android Audio HAL (`audio.primary.msm8953.so` / `mixer_paths.xml`) to drive full dynamic range without artificial digital attenuation.
* **Autonomous Sysfs Gain Boosts:**
  - **Speaker Gain:** +4 dB for louder, distortion-free loudspeaker output.
  - **Headphone Gain:** +4 dB (Left/Right) for full-range analog audio output.
  - **Microphone Gain:** +2 dB for crisp communication in Discord, cellular, and in-game calls.
  - **Earpiece Gain:** +3 dB for clear voice call audio.

### 4. Clean Vanilla Architecture and Anti-Cheat Safety
* **Zero In-Tree Root Hooks:** Contains zero KernelSU hooks, zero syscall wrappers, and zero SusFS strings in `vmlinux`.
* **Zero Anti-Cheat Detection:** Anti-cheat systems (Free Fire, Mobile Legends, PUBG Mobile) inspect kernel integrity without detecting unauthorized modifications.
* **Root Flexibility:** Compatible with standard Magisk or post-flash boot patching via FolkPatch / KernelPatch.

---

## Technical Specifications
* **Target Device:** Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)
* **SoC:** Qualcomm Snapdragon 625 (MSM8953)
* **Kernel Version:** Linux 4.9.337-DaisyForGaming
* **Developer:** JUBAIR HOSEN
* **Toolchain:** Clang 14.0.0 (LLVM + LLD Linker)

---

## Verification and Checksums

| Package | Size | SHA256 Checksum |
|:---|:---|:---|
| **`DaisyForGaming-v1.0-Gaming-11-01-2026.zip`** | 15.2 MB (15,194,646 bytes) | `3bff8637c814a410d074fdf48eca2258151b8778e48102fda02ce1940c9d42f2` |

### Installation Instructions
1. Download `DaisyForGaming-v1.0-Gaming-11-01-2026.zip` to device storage.
2. Boot into custom recovery (TWRP or OrangeFox).
3. Recommended: Back up current `boot` partition.
4. Flash `DaisyForGaming-v1.0-Gaming-11-01-2026.zip`.
5. Optional: Flash Magisk or patch the boot partition with FolkPatch if root is desired.
6. Reboot to System.
