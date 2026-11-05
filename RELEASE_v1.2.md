# DaisyForGaming v1.2 — Thermal, Memory and SystemUI Stability

Official release of the **DaisyForGaming v1.2** custom kernel for the **Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)** based on Linux 4.9.337.

---

## Highlights and Change Summary

### 1. CPU Thermal Cap at Stock 2.016 GHz
* **Overclocked OPPs Removed:** The 2.150 GHz and 2.208 GHz entries were deleted from `qcom,cpufreq-table` in `msm8953.dtsi` and from the scheduler energy-cost tables in `msm8953-cpu.dtsi`. Live `time_in_state` showed roughly 14% residency at 2.208 GHz, which was the dominant heat source under gaming and video load. The clock driver tables are untouched, but cpufreq can no longer select the overclocked rates.
* **Max Boost Capped:** `CONFIG_MAX_BOOST_FREQ` is now `2016000` instead of `2208000`, so app-launch and input boosts cannot jump past the stock ceiling.
* **Reclaim Boost Kick Removed:** The `cpu_input_boost_kick_max(100)` call was removed from the direct-reclaim retry path in `mm/page_alloc.c`. That path runs repeatedly under memory pressure and was pinning the CPU at the highest OPP for hundreds of milliseconds per second. The memory-bus boost is kept.
* **Boot Tuning Conservative:** The boot service no longer forces a 1.036 GHz minimum. The floor is 652 MHz, the ceiling is 2.016 GHz, the governor is `schedutil`, input boost is 1401 MHz for 150 ms, and `boost_on_charging` is disabled so charging heat does not stack on top of input boosts.
* **GPU Bus Forcing Disabled:** `force_bus_on = 0`; the GPU keeps `msm-adreno-tz` with the stock 216 MHz floor and 80 ms idle timer.

### 2. Memory Pressure and App Launch Stability
* **Swappiness 10 → 100:** With 2 GB of zram and only 2.8 GB of RAM, swappiness 10 kept anonymous pages resident and evicted file cache instead, producing the major-fault stalls behind the SystemUI and app ANRs. Swapping anon pages into zram keeps app code and dex resident. `page-cluster` stays 0 and `vfs_cache_pressure` stays 100.

### 3. SystemUI and system_server Restart Fix
* **Charging Sounds Disabled:** The GSI's `BatteryService$PlayChargedSound` builds a `Ringtone` from a missing URI and throws `IllegalStateException` in `MediaPlayer._setDataSource`, killing `system_server` and restarting zygote (SystemUI and every running app went down with it). The boot service disables charging sounds on every boot.
* **Boot Service Now Executes:** `/data/adb/service.d/99-dfg-tune.sh` inherited the `adb_data_file` SELinux label, which `magiskd` cannot `execve`. The installer applies `u:object_r:system_file:s0` after copying the script, and the service now runs and logs to `/data/local/tmp/dfg_tune.log`.

### 4. Root Preservation
* **`skip_initramfs` Ignored:** This device keeps Magisk's `magiskinit` in the boot ramdisk. The first v1.2 build honored `skip_initramfs`, so the kernel discarded the ramdisk, `magiskd` never started, and `su` disappeared after flashing. The parameter is still parsed, but the initramfs is kept; `magiskinit` reads the flag itself and chain-loads the system init on a normal boot. Root now survives the flash.

### 5. Included from v1.1
* Adreno 5xx preemption, ringbuffer and IOMMU backports; `adreno_get_ucode_version`; WALT and schedutil fixes; jump-label and binder restorations. The previous test kernel on the device predated these fixes, so v1.2 is the first build that actually carries them.

---

## Technical Specifications
* **Target Device:** Xiaomi Mi A2 Lite (`daisy` / `daisy_sprout`)
* **SoC:** Qualcomm Snapdragon 625 (MSM8953)
* **CPU:** 8x Cortex-A53, stock ceiling 2.016 GHz
* **GPU:** Adreno 506, 216 MHz floor, 650 MHz max
* **Kernel Version:** `4.9.337-DaisyForGaming #14 SMP PREEMPT Thu Nov 5 19:30:00 +06 2026`
* **Developer:** JUBAIR HOSEN
* **Toolchain:** Clang 14.0.0 (LLVM + LLD Linker)

---

## Verification and Checksums

| Package | Size | SHA256 Checksum |
|:---|:---|:---|
| **`DaisyForGaming-v1.2-Gaming-11-05-2026.zip`** | 16.5 MiB (17,343,635 bytes) | `7d7b3b0e369cdc50bbb82f2c5877c190b056b1b8316168018a9163848d2b1459` |

Build verification:
* `out/.config`: `CONFIG_MAX_BOOST_FREQ=2016000`, `CONFIG_LOCALVERSION="-DaisyForGaming"`.
* Decompiled `msm8953-qrd-sku3-daisy.dtb`: `qcom,cpufreq-table` ends at `0x1ec300` (2,016,000 kHz).
* ZIP integrity: `unzip -t` reports no errors; the embedded `Image.gz-dtb` SHA256 matches the build output.
* Root artifacts: 0 KernelSU strings, 0 SusFS strings in `vmlinux`.

On-device verification (Xiaomi Mi A2 Lite, crDroid 7.13 GSI):
* `uname -a` reports `4.9.337-DaisyForGaming #14 SMP PREEMPT Thu Nov 5 19:30:00 +06 2026`.
* Boot log shows `Unpacking initramfs...` / `Freeing initrd memory: 22152K`, and `magiskd` runs as PID 511 under `init`, so root survives the flash.
* `/proc/sys/vm/swappiness` reads `100`; `scaling_available_frequencies` ends at `2016000` and `scaling_max_freq` is `2016000`.
* `/data/local/tmp/dfg_tune.log` logs `VM: swappiness=100` and `max: 2016000` on the first boot.

### Installation Instructions
1. Download `DaisyForGaming-v1.2-Gaming-11-05-2026.zip` to device storage.
2. Boot into custom recovery (TWRP or OrangeFox).
3. Recommended: Back up the current `boot` partition.
4. Flash `DaisyForGaming-v1.2-Gaming-11-05-2026.zip`.
5. Optional: Flash Magisk or patch the boot partition with FolkPatch if root is desired.
6. Reboot to System.

---

## Known Issue
* The `media.swcodec` SIGABRT (`__cfi_check_fail` inside `libcodec2_soft_hevcdec.so`) is a userspace GSI bug in the software HEVC decoder. It is not caused by the kernel and is not fixed by this release.
