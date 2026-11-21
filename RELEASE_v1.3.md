# DaisyForGaming v1.3 — Gaming Performance, SD Card, Video & Thermal Balance

Official release of the **DaisyForGaming v1.3** custom kernel for the **Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)** based on Linux 4.9.337.

---

## Highlights and Change Summary

### 1. External SD Card Detection & Filesystem Mount Fix
* **Card Detect GPIO Polarity Inversion Fixed:** In `sakura-qrd.dtsi` (included by `msm8953-qrd-sku3-daisy.dts`), the SD card detect GPIO was defined as Active High (`cd-gpios = <&tlmm 133 0x0>`). On hardware, insertion connects GPIO 133 to ground (Active Low). The polarity flag has been corrected to Active Low (`0x1`), restoring automatic SD card detection upon insertion.
* **Universal Filesystem Support:** Enabled native `CONFIG_NTFS_FS=y`, `CONFIG_NTFS_RW=y`, and verified `CONFIG_EXFAT_FS=y` in `daisy_defconfig` so high-capacity SD cards and USB-OTG storage mount seamlessly.

### 2. Video Buffering & Lag Elimination
* **GPU Memory Bus Persistence Restored:** In v1.2, `force_bus_on = 0` caused the memory bus to drop to 0 MB/s between video frames, resulting in SurfaceFlinger memory starvation and micro-stuttering during 60 FPS YouTube and local video playback. Restored `force_bus_on = 1` with a solid 216 MHz clock floor and 80 ms idle timer in `dfg_tune.sh`.
* **TCP Socket Buffer Scaling:** Default TCP window limits (212 KB) caused frequent buffer stalls during 1080p/4K streaming. Scaled `rmem_max` and `wmem_max` to 8 MB, with `tcp_rmem` and `tcp_wmem` auto-tuning up to 8 MB. Enabled `tcp_low_latency = 1`, `tcp_fastopen = 3`, and disabled `tcp_autocorking`.
* **Media Codec Multi-Core CPU Allocation:** Expanded `system-background` cpusets from restricted cluster to all 8 cores (`0-7`), ensuring video extractors and software media codecs never starve.

### 3. Thermal Overheating & Gaming Responsiveness Balance
* **Input Boost Duration Optimization:** Reduced input boost duration from 250 ms to 80 ms (`CONFIG_INPUT_BOOST_DURATION_MS=80` and `input_boost_duration = 80`). Rapid touch interactions in games now maintain immediate 60 FPS responsiveness without indefinitely trapping all 8 cores at maximum clock.
* **Boost on Charging Disabled:** `boost_on_charging = 0` prevents dual-boost thermal runaway when gaming while connected to a fast charger.
* **Schedutil Governor Rate Limiting:** Configured `up_rate_limit_us 500` (instant 0.5 ms frequency ramp for zero frame drops) and `down_rate_limit_us 20000` (smooth 20 ms decay to prevent clock oscillation).
* **Touchscreen IRQ CPU Affinity:** Pinned touchscreen controller interrupts (`goodix`, `focaltech`, `ft5x06`, `synaptics`, `fts`) to CPUs 0-3 for ultra-low touch latency.

### 4. Dynamic Fsync (Option 1)
* **High-Speed Flash Storage I/O:** Sysfs control `/sys/kernel/dyn_fsync/Dyn_fsync_active` set to `1`. Standard `fsync` is deferred while screen is active to accelerate storage write throughput and game asset loading, while automatically flushing dirty pages to NAND when the display turns off, on shutdown, and on panic.

### 5. Wakelock Blocker & Wakeup Suppression (Option 4)
* **Suppression of Rogue Wakeup Sources:** Automatically disables unneeded background wakeups (`wlan_pno`, `wlan_ipa`, `qcom_rx_wakelock`, `IPA_WS`, `wlan_wow_wl`, `wlan_extscan_wl`) via `/sys/class/wakeup/` in `dfg_tune.sh`.
* **Elimination of Idle Drain:** Halts unnecessary CPU wakeups during screen-off deep sleep, preventing overnight battery loss and pocket heat.

### 6. Clean Code & Clang 21 Toolchain Compatibility
* **Zero Code Comments Enforcement:** All modified C sources, DTS nodes, and shell scripts strictly adhere to clean, self-documenting code with zero redundant comment blocks.
* **Modern Clang 21 Compilation:** Added build flags `-Wno-default-const-init-field-unsafe`, `-Wno-default-const-init-var-unsafe`, and `-Wno-deprecated-ofast` in root `Makefile` for zero-warning compiler compatibility.
* **Full Magisk & FolkPatch Compatibility:** Maintained `skip_initramfs` ramdisk retention for seamless root preservation.

---

## Technical Specifications
* **Target Device:** Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)
* **SoC:** Qualcomm Snapdragon 625 (MSM8953)
* **CPU:** 8x Cortex-A53, stock ceiling 2.016 GHz, floor 652.8 MHz
* **GPU:** Adreno 506, 216 MHz floor, 650 MHz max
* **Kernel Version:** `4.9.337-DaisyForGaming #15`
* **Developer:** JUBAIR HOSEN
* **Toolchain:** Clang 21 (Ubuntu clang version 21.1.8) (LLVM + LLD Linker)

---

## Release Artifacts & Checksums
* **Zip File:** `DaisyForGaming-v1.3-Gaming-11-21-2026.zip`
* **File Size:** `17,285,776 bytes` (16.48 MB)
* **SHA256:** `0af0dcd15a39756c20917b6926f54b7c5dee99f5f3f585f0c1aad4ab935a7a13`
* **Build Target:** `out/arch/arm64/boot/Image.gz-dtb` (14,739,181 bytes)

---

## Flashing Instructions
1. Boot into Custom Recovery (TWRP / OrangeFox).
2. Take a backup of your existing `Boot` partition (Recommended).
3. Select `Install` -> choose `DaisyForGaming-v1.3-Gaming-11-21-2026.zip`.
4. Swipe to confirm flash (AnyKernel3 installer will patch boot image and stage `dfg_tune.sh`).
5. Reboot System.
