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
| KALLSYMS_HARDENED | ✅ Implemented | `kernel/kallsyms.c` (guarded by `CONFIG_KALLSYMS_HARDENED`) | Symbol addresses in `/proc/kallsyms` are masked (`0000000000000000`) for unprivileged readers, reducing kernel address leakage. |
| Dynamic fsync toggle | ✅ Implemented | `fs/sync.c` (`dyn_fsync_show/store`, kobject `dyn_fsync`) | Default on (`1`). Write `0` to `/sys/kernel/dyn_fsync/dyn_fsync` to make fsync a no-op for better write performance at your own risk of data loss on power cut. |
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
- Display/touch modifications
- Audio modifications
- Camera modifications
- Kernel-based wakelock control (other than stock power management)
- Module packages (all relevant drivers are built-in; the ZIP ships no modules — `do.modules=0`)

If you believe one of these should be listed, verify it in the source first
and open a pull request updating this table.
