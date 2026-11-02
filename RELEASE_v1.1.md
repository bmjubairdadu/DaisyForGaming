# DaisyForGaming v1.1 — Video Lag Elimination, Instant App Boost, and Sustained Eight-Core Performance

Official release of the **DaisyForGaming v1.1** custom kernel for the **Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)** based on Linux 4.9.337.

---

## Highlights and Change Summary

### 1. Video Playback Stutter Elimination & GPU DDR Bus Bandwidth
* **Adreno 506 Bus Bandwidth Scaling Restored:** In `drivers/gpu/msm/adreno.c`, GPU DDR memory bus voting cap was previously restricted to 350 MB/s. Restored full 1400 MB/s bus bandwidth ceiling (`.bus.max = 1400`), completely eliminating memory starvation during SurfaceFlinger UI rendering and 60 FPS video playback (YouTube 1080p60, VP9/AVC, local media).
* **Adreno 506 Clock Floor & Idler Bypass:** GPU floor locked at 216 MHz (`msm-adreno-tz` governor with `adreno_idler` disabled and `force_bus_on = 1`), preventing the GPU from dropping to 133 MHz during video playback or UI transitions.

### 2. Instant App Launch & Touch Input Boost
* **Multi-Core Input Boost System:** Restored full DFG input boost engine in `drivers/cpufreq/cpu-boost.c`. On every touch event, little cluster (CPU0-3) instantly ramps to 1401 MHz and big cluster (CPU4-7) ramps to 1689 MHz for 250 ms (`input_boost_ms = 250`), with WALT scheduler boost enabled (`sched_boost_on_input = 1`).
* **CPU Scaling Frequency Floor:** Set minimum CPU scaling floor to 1036 MHz (`scaling_min_freq = 1036800`) across all 8 cores, eliminating the 652 MHz low-frequency sluggishness when launching applications or scrolling.
* **Locked Eight-Core Availability:** Configured Qualcomm Core Control (`core_ctl min_cpus = 4` across clusters), keeping all eight Cortex-A53 cores permanently online and eliminating the 50–100 ms hotplug wake penalty when tapping apps.
* **Foreground & Top-App Responsiveness:** Increased `top-app schedtune.boost` to 25 and `foreground schedtune.boost` to 5. Broadened `system-background` cpusets to all eight cores (0-7), providing media extraction and codec services full multi-core throughput.

### 3. Storage I/O Throughput & Cache Retention
* **VFS Inode & Dentry Caching:** Lowered `vfs_cache_pressure` from 100 to 60, keeping file system metadata in RAM so application APK, DEX, and shared library access does not stall on eMMC reads.
* **Storage Read-Ahead:** Configured `read_ahead_kb = 1024` and `nr_requests = 128` across eMMC block devices (`mmcblk0` and `dm-*`) with `deadline` I/O scheduling.

### 4. Verified Vanilla Architecture & Safety
* **Zero In-Tree Root Hooks:** Contains zero KernelSU hooks, zero syscall wrappers, and zero SusFS strings in `vmlinux`.
* **Anti-Cheat Safe:** Fully compatible with Free Fire, Mobile Legends, and PUBG Mobile without triggering kernel integrity flags.
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
| **`DaisyForGaming-v1.1-Gaming-11-02-2026.zip`** | 17.3 MB (17,343,511 bytes) | `5598efb2d7cbc25a76df371d462e02fb4d26529d797c6220215e3a3f47f2f1dc` |

### Installation Instructions
1. Download `DaisyForGaming-v1.1-Gaming-11-02-2026.zip` to device storage.
2. Boot into custom recovery (TWRP or OrangeFox).
3. Recommended: Back up current `boot` partition.
4. Flash `DaisyForGaming-v1.1-Gaming-11-02-2026.zip`.
5. Optional: Flash Magisk or patch the boot partition with FolkPatch if root is desired.
6. Reboot to System.

