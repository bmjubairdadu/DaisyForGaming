# FEATURES

Every entry below is verified from the committed source, the committed
`arch/arm64/configs/daisy_defconfig`, or the build scripts. Nothing here is
assumed or aspirational.

Status legend: ✅ Implemented (verified) · 🟡 Partial · 🚧 Planned · ❓ Unknown

| Feature | Status | Source / Config | Explanation |
| ------- | ------ | --------------- | ----------- |
| TCP BBR congestion control | ✅ Implemented | `net/ipv4/tcp_bbr.c`, `CONFIG_TCP_CONG_BBR=y` | Google BBR is compiled in. Because Cubic is also compiled in and is the default (`CONFIG_DEFAULT_TCP_CONG="cubic"`), you can switch at runtime: `sysctl net.ipv4.tcp_congestion_control=bbr` (root). BBR targets higher throughput and lower latency on lossy links. |
| FQ (Fair Queue) qdisc | ✅ Implemented | `CONFIG_TCP_CONG_BBR=y` commit `net: enable TCP BBR + FQ qdisc` | FQ packet scheduling is enabled alongside BBR as the recommended queue discipline pairing. |
| BFQ I/O scheduler (default) | ✅ Implemented | `block/bfq-iosched.c` + merged objects, `CONFIG_IOSCHED_BFQ=y`, `CONFIG_DEFAULT_BFQ=y` | BFQ (Budget Fair Queueing) is built and set as the **default** elevator, replacing CFQ/deadline defaults for better interactive performance. Backported from the 4.9-era legacy split and fixed for the 4.9.337 API. |
| KALLSYMS_HARDENED | 🟡 Partially implemented | `kernel/kallsyms.c` (guarded by `CONFIG_KALLSYMS_HARDENED`), option added in `init/Kconfig` | The code and Kconfig option exist and mask symbol addresses in `/proc/kallsyms` for unprivileged readers — **but `CONFIG_KALLSYMS_HARDENED` is not enabled in `daisy_defconfig`**, so it is dormant by default. Enable it (`CONFIG_KALLSYMS_HARDENED=y`) if you want the hardening active. |
| Dynamic fsync toggle | ✅ Implemented | `fs/sync.c` (`dyn_fsync_show/store`, kobject `dyn_fsync`) | Default on (`1`). Write `0` to `/sys/kernel/dyn_fsync/dyn_fsync` to make fsync a no-op for better write performance at your own risk of data loss on power cut. |
| CPU input boost | ✅ Implemented | `drivers/cpufreq/input_boost.c`, `CONFIG_CPU_INPUT_BOOST=y` | On touch/input events the CPU min frequency is briefly raised (default **1.4 GHz / 60 ms**) so the first frames after a touch render without waiting for the governor to ramp from idle. Does not touch max frequency or sustained performance. Controls: `/sys/module/input_boost/parameters/enabled` (0/1, default 1), `boost_freq` (clamped to a safe sub-maximum ≈ 80 % of the policy max), `boost_duration_ms` (clamp 20–150, default 60). Suppressed while the screen is off. |
| lmk_aggressive toggle | ✅ Implemented | `drivers/staging/android/lowmemorykiller.c` (`daisy_lmk_set_aggressive`), `CONFIG_ANDROID_LOW_MEMORY_KILLER=y`, `drivers/misc/daisy_mm.c` | `/sys/kernel/mm/lmk_aggressive` (0/1, default 0). **Dormant until enabled** (`enable_lmk=0` by default — zero behavior change at stock boot). On enable it applies a moderate 6-level minfree table (32/40/48/64/80/96 MB with adj 0/100/200/300/900/906) so background/empty apps are reclaimed somewhat sooner under pressure; on disable the previous table (snapshot) is restored. Deliberately not maximally aggressive to avoid app reload churn. |
| Swappiness control | ✅ Implemented | `drivers/misc/daisy_mm.c`, `mm/vmscan.c` (`int vm_swappiness`) | `/sys/kernel/mm/swappiness` (clamp 0–200, **boot default 100**, kernel baked default is 60). zRAM-appropriate moderate value: with lz4 zRAM as swap, anon pages reclaim cheaply, while 130+ tends to thrash on a 3 GB device. ROM init may override at boot; the sysfs node re-applies it anytime (root). |
| Gaming charge toggle | ✅ Implemented | `drivers/power/supply/qcom/qpnp-smbcharger_d1a.c` | Sysfs-controlled charging profile for gaming: restricts charge current (FCC) and float voltage while the toggle is on. Includes a charger-present interlock (auto-off when no charger online) and automatic restore of saved vfloat settings. |
| Interactive CPU governor | ✅ Implemented | `CONFIG_CPU_FREQ_GOV_INTERACTIVE=y`, `drivers/cpufreq/cpufreq_interactive.c` (build fix `linux/irq_work.h`) | Interactive governor is compiled in for the msm8953 platform, with a fix so it builds cleanly on 4.9.337. |
| zRAM | ✅ Implemented | `CONFIG_ZRAM=y`, `CONFIG_ZRAM_DEFAULT_COMP_ALGORITHM="lz4"`, `CONFIG_SWAP=y` | Compressed RAM swap device (lz4). This is a configuration-level feature; zRAM itself ships in the kernel and is ready for ROM/init use. |
| Clang LTO | ✅ Implemented | `CONFIG_LTO=y`, `CONFIG_LTO_CLANG=y` | The whole kernel is built with Clang link-time optimization (single `vmlinux.o` LTO pass). |
| Version branding | ✅ Implemented | `CONFIG_LOCALVERSION="-DaisyForGaming"` in `daisy_defconfig` | The running kernel reports `4.9.337-DaisyForGaming`. The compiler string no longer embeds upstream vendor git hashes. |
| Vendor-wins baseline | ✅ Implemented | commits `DaisyForGaming: vendor-wins merge rule`, `... restore real vendor defconfig` | Files that daisy's vendor tree customizes stay at the vendor baseline where they conflict with upstream 4.9.337; upstream-pure files track 4.9.337. Examples in history: `hexdump.c`, `event_timer.c`, `random32.c`, `early_random.c`, `drbg.h`, fuse ACLs, `kvm_host.h`, `hw_random/handle.c`, `fixmap.h`. |
| AnyKernel3 packaging | ✅ Implemented | `pack/ak3/anykernel.sh` | TWRP-flashable ZIP with device check (`daisy`/`Mi_A2_Lite`), magiskboot patching, boot-partition-only flashing. |

## Not claimed

The following are **not** claimed as features of this kernel because they are
not verified in the current source/config:

- Custom CPU frequency tables or thermal policies
- GPU overclock/underclock
- Display or touch panel modifications (input boost tuning only — no panel, sensitivity, or calibration changes)
- Audio modifications
- Camera modifications
- Kernel-based wakelock control (other than stock power management)
- Module packages (all relevant drivers are built-in; the ZIP ships no modules — `do.modules=0`)

If you believe one of these should be listed, verify it in the source first
and open a pull request updating this table.
