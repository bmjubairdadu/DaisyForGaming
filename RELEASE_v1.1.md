# DaisyForGaming v1.1 — Performance, Recovery Fix & Sound Boost 🎮

A major stability, thermal, and audio update for the **Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)** on Linux 4.9.337!

---

## 🚀 Highlights & What's Fixed in v1.1

### 🔓 1. Recovery Storage Decryption & Auto-Shutdown Fix
* **Fixed Automatic Power-Off in Recovery:** In `msm8953-thermal.dtsi`, trip point `modem_trip2` on the motherboard thermistor (`pm8953_vadc 0x13`) was mistakenly configured with `type = "critical"` at 75°C. During storage decryption in recovery (TWRP/OrangeFox), all 8 CPU cores run crypto algorithms at peak clock speed, causing the thermistor to hit 75°C. Linux `thermal_core.c` immediately called `orderly_poweroff(true)`, instantly shutting down the phone.
  - Reclassified `modem_trip2` to `type = "passive"` at 80°C to throttle the modem PA without turning off the phone.
  - Set a true emergency critical trip `case_crit` at 95°C (95000 m°C).
  - Storage decryption in TWRP/OrangeFox now completes smoothly with zero shutdowns!
* **Qualcomm Hardware Entropy (`/dev/hw_random` & `/dev/msm-rng`):** Enabled `CONFIG_HW_RANDOM=y` and `CONFIG_HW_RANDOM_MSM_LEGACY=y` in `daisy_defconfig`. Keymaster HAL (`android.hardware.keymaster@3.0/4.0-service`) now initializes hardware entropy with Qualcomm TrustZone properly in recovery, fixing Keymaster SIGABRT crashes and preventing automatic recovery reboot loops into system.
* **Storage Decryption Checkpoints:** Enabled `CONFIG_DM_BOW=y` (Backup on Write) and `CONFIG_CRYPTO_TWOFISH=y` for Android FBE storage decryption checkpoints.

---

### ⚡ 2. Anti-Lag Performance & Overheating Elimination
* **Zero Core-Isolation (All 8 Cores Stay Online):** Disabled `sched_isolate_cpu()` core-killing mechanism in `cpu_cooling.c`. Replaced with graceful frequency clamping to 1.68 GHz / 1.4 GHz floors. Big cluster cores (CPU4–CPU7) never shut down or drop to 652 MHz during thermal load.
* **Smooth 60FPS Video & App Launching (`dfg_tune.sh`):**
  - **Schedutil Frame Pacing:** `up_rate_limit_us 500` (0.5ms instant ramp) and `down_rate_limit_us 20000` (20ms hold down), guaranteeing smooth 60fps frame pacing and eliminating video/gaming micro-stutters.
  - **SchedTune:** `top-app/schedtune.boost 10` with `prefer_idle 1` for instantaneous, zero-lag application launches.
  - **Input Touch Boost:** Boosts all 8 cores to 1401 MHz for 60ms with `sched_boost_on_input 1` for immediate UI touch response.
  - **Adreno 506 GPU Floor:** Set to 216 MHz minimum floor with an 80ms idle timer and disabled `adreno_idler` for rock-solid 60fps video playback and gaming.

---

### 🔊 3. Audio Quality & Volume Boost
* **Restored ALSA Digital Volume Controls:** Removed `#ifndef CONFIG_SOUND_CONTROL` block in `msm-digital-cdc-legacy.c`. `RX1`, `RX2`, `RX3 Digital Volume` and `DEC1`, `DEC2 Volume` are now properly exposed to ALSA mixer. Android's Audio HAL (`audio.primary.msm8953.so` / `mixer_paths.xml`) can now seamlessly adjust digital volume across the full dynamic range.
* **Autonomous Sysfs Sound Boost (`dfg_tune.sh`):**
  - **Headphone Gain:** `+4dB` (L/R) for punchy, clear bass and treble without distortion.
  - **Speaker Gain:** `+4dB` for louder, clear media and ringtone playback without speaker rattling.
  - **Mic Gain:** `+2dB` for crisp voice pickup during in-game calls (Free Fire, PUBG, Discord) and cellular calls.
  - **Earpiece Gain:** `+3dB` for loud, clear phone call audio.

---

## 📱 Device & Build Compatibility
* **Target Device:** Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)
* **SoC:** Qualcomm Snapdragon 625 (MSM8953)
* **Kernel Version:** Linux 4.9.337-DaisyForGaming
* **Toolchain:** Clang 14.0.0 + LLVM Assembler + LLD Linker
* **Root Compatibility:** FolkPatch / KernelPatch (patch boot after flash) **or** Magisk. Clean vanilla kernel structure (0 KSU hooks, 0 SusFS strings in `vmlinux`) for maximum anti-cheat safety!

---

## 📦 Download & Verification

| File | Size | SHA256 Checksum |
|---|---|---|
| **`DaisyForGaming-v1.1-Gaming-11-01-2026.zip`** | 18.3 MB (18,306,798 bytes) | `2f5a4cf220c3ef97050b4e2e8b091ddef3e3a9fe60711d91cc0f2fc6ee614018` |

### 🛠️ Installation Instructions:
1. Boot device into custom recovery (TWRP or OrangeFox).
2. Take a backup of your current `boot` partition (recommended).
3. Flash `DaisyForGaming-v1.1-Gaming-11-01-2026.zip`.
4. (Optional) If rooted with Magisk, flash Magisk zip or patch boot via FolkPatch / KernelPatch.
5. Reboot to System and enjoy butter smooth 60fps gaming and crystal-clear audio!
