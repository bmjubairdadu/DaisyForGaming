# DaisyForGaming - Project Memory & Context Tracking

## User Preferences & Rules
- **Language**: বাংলা (Bengali exclusively for all discussions, explanations, and planning).
- **Code Style**: Zero comments in code (pure self-documenting code across all languages).
- **Session Memory**: Full retention of decisions, past edits, and ongoing development tasks.

## Active Workspace & Target
- Project: DaisyForGaming (msm8953 Android Kernel for Xiaomi Mi A2 Lite / daisy)
- Branch: main (HEAD: e6532df9 - feat(release): v1.2)
- Target Version: v1.3 (Gaming, Video, SD Card & Thermal Balance Release)

## Identified Issues & Solutions for v1.3
1. **SD Card Hardware Detection Failure**:
   - Cause: `sakura-qrd.dtsi` inverted Card Detect to Active High (`cd-gpios = <&tlmm 133 0x0>`).
   - Fix: Correct to Active Low (`cd-gpios = <&tlmm 133 0x1>`), enable NTFS & exFAT in defconfig.
2. **Video Playback Lag & Network Buffering**:
   - Cause: `force_bus_on = 0` caused GPU DDR memory bus starvation during SurfaceFlinger composition; restricted cpusets delayed media codecs; default 212KB TCP buffers caused streaming buffer stalls.
   - Fix: `force_bus_on = 1` with 216MHz floor, multi-core `system-background` cpusets (0-7), TCP buffers scaled to 8MB.
3. **Gaming Overheating**:
   - Cause: Unthrottled dual-boost holding max frequencies indefinitely on continuous touch; thermal trip points set at 125°C.
   - Fix: Optimize input boost duration to 80ms, ensure smooth governor step-down at 70°C without aggressive FPS drops.
4. **Dynamic Fsync & Wakelock Blocker (User Requested Options 1 & 4)**:
   - Dynamic Fsync: Integrated `/sys/kernel/dyn_fsync/Dyn_fsync_active 1` to accelerate storage I/O and UI fluidity during screen-on while auto-flushing on suspend and shutdown.
   - Wakelock Blocker: Wakeup suppression for excessive Wi-Fi/Qualcomm wakeups (`wlan_pno`, `wlan_ipa`, `qcom_rx_wakelock`, `IPA_WS`, `wlan_wow_wl`, `wlan_extscan_wl`) via `/sys/class/wakeup/` to stop idle heating and battery drain.

## Build #15 Metrics & Verification (v1.3)
- **Status:** Completed Successfully
- **Kernel Image:** `out/arch/arm64/boot/Image.gz-dtb` (14,739,181 bytes)
- **Recovery Zip:** `DaisyForGaming-v1.3-Gaming-11-21-2026.zip` (17,285,776 bytes)
- **SHA256:** `0af0dcd15a39756c20917b6926f54b7c5dee99f5f3f585f0c1aad4ab935a7a13`
- **Compiler:** Clang 21.1.8 + LLD Linker
- **Banner:** `Linux version 4.9.337-DaisyForGaming (JUBAIR_HOSEN@DaisyForGaming) #15`
- **Verification:** 0 warnings, 0 KSU strings, 0 SusFS strings, input boost active, clean code with zero comments throughout.

---

## Identified Issues & Solutions for v1.4 (Ultra-Smooth & Cold-App-Launch Release)
1. **CPU Frequency Pinning (8 Cores Locked at 2016 MHz at Idle & Severe Heating)**:
   - Root Cause: In `drivers/cpufreq/cpu-boost.c`, `boost_mode = 2` hardcoded `input_boost_ms = 250` and `sched_boost_on_input = 1`, which activated `sched_set_boost(1)`. This pegged WALT scheduler load to 100% on every touch event. Concurrently, `schedutil` governor had `down_rate_limit_us = 20000` (20 ms), preventing cores from ever stepping down between touch samples.
   - Fix: Lowered `input_boost_ms` to 80 ms, disabled permanent scheduler boost (`sched_boost_on_input = 0`), set governor defaults `up_rate_limit_us = 500` and `down_rate_limit_us = 3000` directly in `kernel/sched/cpufreq_schedutil.c` and `dfg_tune.sh`. All 8 cores now rest at 652 MHz floor when idle.
2. **App Launch Stutter & Cold Start Delay**:
   - Root Cause: In `kernel/fork.c`, `_do_fork()` only invoked `devfreq_boost_kick_max(DEVFREQ_MSM_CPUBW, period)` on zygote forking, omitting `cpu_input_boost_kick_max(period)`. As a result, newly spawned application processes received memory bus bandwidth but zero CPU frequency boost during initial DEX/APK loading.
   - Fix: Added `cpu_input_boost_kick_max(period)` (150 ms) to `_do_fork()`, enhanced `task_is_zygote()` in `fs/exec.c` to match process names (`zygote`, `zygote64`, `main`), reduced eMMC storage `read_ahead_kb` from 1024 KB to 256 KB to eliminate read queue starvation on small DEX reads, and set VM `vfs_cache_pressure` and `swappiness` to 60.

## Build #16 Metrics & Verification (v1.4)
- **Status:** Completed Successfully
- **Kernel Image:** `out/arch/arm64/boot/Image.gz-dtb` (14,739,385 bytes)
- **Recovery Zip:** `DaisyForGaming-v1.4-Gaming-11-22-2026.zip` (17,283,612 bytes)
- **SHA256:** `f077e3464e32d14c20ee1229dccbabfd77c0f89894db73e4c5abc9943a4d40e4`
- **Compiler:** Clang 21.1.8 + LLD Linker
- **Banner:** `Linux version 4.9.337-DaisyForGaming (JUBAIR_HOSEN@DaisyForGaming) #16 SMP PREEMPT Sun Nov 22 13:00:00 +06 2026`
- **Verification:** 0 warnings, 0 errors, 0 KSU strings, 0 SusFS strings, single banner in AnyKernel3, zygote app-launch boost active, zero comments throughout codebase.
