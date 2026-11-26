# DaisyForGaming v1.5 Release Notes

## Overview
**DaisyForGaming v1.5** is a comprehensive stability, storage hardware, and video streaming buffer fix release for the **Xiaomi Mi A2 Lite (daisy / daisy_sprout)** on Qualcomm Snapdragon 625 (MSM8953).

---

## 🚀 Key Highlights & Changes in v1.5

### 1. Video Playback & Streaming Buffer Lag Fix
- Tuned TCP network streaming buffers (`rmem_max` and `wmem_max` to 6 MB, `tcp_rmem` to 6 MB, `tcp_wmem` to 4 MB) with Google BBR congestion control and `fq` packet pacing.
- Disabled `tcp_slow_start_after_idle` (`= 0`) and enabled `tcp_mtu_probing` (`= 1`) to eliminate sudden buffer depletion and freeze during video playback on Facebook, YouTube, TikTok, and web streams.
- Reverted problematic `tcp_low_latency` and `tcp_fastopen` settings that caused frequent connection resets during media streaming.

### 2. External SD Card Hardware Detection
- Fixed SD Card Detect (CD) GPIO polarity in `msm8953-qrd-sku3-daisy.dts` and `sakura-qrd.dtsi` (`cd-gpios = <&tlmm 133 0x0>`), properly configured DDR50 bus speed.
- MicroSD cards now mount cleanly on boot and inside custom recovery (OrangeFox / TWRP) without failure.

### 3. Thermal Zone & Battery Temperature Monitoring
- Enabled PMIC PM8953 thermal zone driver (`pm8953_tz`) in Device Tree, providing accurate battery/PMIC temperature reporting (`thermal_zone2` active).

### 4. Guaranteed Data Integrity & Safe Fsync
- Completely disabled unsafe `CONFIG_DYNAMIC_FSYNC` and restored stock Linux 4.9 `fsync()`, `fdatasync()`, and `sync_file_range()` system calls in `fs/sync.c`.
- Eliminates risk of file zero-byte corruption during unexpected shutdowns or reboot events.

### 5. Multi-Core Process & Memory Enhancements
- Optimized `prlmk` process reclaim filtering and `cpu_boost` duration (80 ms input boost, 20 ms schedutil down-rate limit).
- All 8 Cortex-A53 cores idle smoothly at 652 MHz floor and scale dynamically up to 2.016 GHz under load.

---

## 📦 Release Asset Verification
- **File Name:** `DaisyForGaming-v1.5-Gaming-11-26-2026.zip`
- **File Size:** 17,286,715 bytes (~16.5 MB)
- **SHA-256:** `28d5b8b318effda182d9926c514f78a98686a9da60eb1c497fd07e9540ae3a27`
- **Build Banner:** `Linux version 4.9.337-DaisyForGaming (JUBAIR_HOSEN@DaisyForGaming) #18 SMP PREEMPT Thu Nov 26 10:05:00 +06 2026`
- **AnyKernel3:** Automated A/B slot detection, Magisk root preservation.
