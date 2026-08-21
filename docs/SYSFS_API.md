# DFG sysfs API (user-facing)

All DFG tunables live under `/sys/devices/platform/dfg/` and are
writable by root (or the DFG-Controller app under its SELinux policy).

## Nodes

| Node | Mode | Meaning |
| ---- | ---- | ------- |
| `profile` | rw | `performance` \| `balanced` \| `battery` (default at boot: `performance` on DFG builds) |
| `cpu_min_freq` | rw | CPU min frequency in kHz (all policies) |
| `cpu_max_freq` | rw | CPU max frequency in kHz (all policies) |
| `governor` | rw | cpufreq governor name (all policies) |
| `io_scheduler` | rw | I/O scheduler of the boot disk |
| `thermal_override` | rw | 0/1; lift the soft thermal cap (hard cap always applies) |
| `boost_ms` | rw | one-shot boost duration in ms (0-60000, 0 = cancel) |
| `deep_idle` | rw | 0/1; disable deep cpuidle states (gaming mode, drains battery) |
| `thermal_events` | ro | last 16 thermal events (newest first) |
| `thermal_limits` | ro | soft/hard limits, state, max temp, override flag |
| `vendor_compat` | ro | platform check result |

## Profiles

| Profile | Governor | Min (kHz) | Max (kHz) | I/O scheduler |
| ------- | -------- | --------- | --------- | ------------- |
| performance | schedutil | 1401600 | 2016000 | noop |
| balanced | schedutil | 652800 | 2016000 | bfq |
| battery | schedutil | 300000 | 1401600 | cfq |

Values are compile-time defaults (Kconfig) - the defconfig pins them;
each can be overridden at runtime via the corresponding node.

## Thermal behavior

* Soft limit (50 C): without `thermal_override=1` the CPU max is capped
  at 1401 MHz. With the override, the profile is kept (event
  `OVERRIDE_ACTIVE` is logged).
* Hard limit (60 C): the cap is forced to safe values (max 1401 MHz /
  min 652.8 MHz), `thermal_override` is reset, and the override stays
  refused until temperature drops below 57 C (hysteresis). This cannot
  be disabled from userspace. The stock kernel thermal framework
  (tsens/limiter) remains fully active on top.
* All transitions are logged to dmesg (`dfg:`) and to `thermal_events`.

## Example adb commands

```sh
adb root

# default performance profile after first boot
adb shell cat /sys/devices/platform/dfg/profile        # -> performance
adb shell cat /sys/devices/platform/dfg/cpu_min_freq   # -> 1401600

# switch profile
adb shell "echo battery > /sys/devices/platform/dfg/profile"
adb shell "echo performance > /sys/devices/platform/dfg/profile"

# manual tuning
adb shell "echo 1612800 > /sys/devices/platform/dfg/cpu_min_freq"
adb shell "echo interactive > /sys/devices/platform/dfg/governor"
adb shell "echo bfq > /sys/devices/platform/dfg/io_scheduler"

# boost for a game launch
adb shell "echo 5000 > /sys/devices/platform/dfg/boost_ms"

# thermal override (unsafe beyond soft limit; hard limit still enforced)
adb shell "echo 1 > /sys/devices/platform/dfg/thermal_override"
adb shell "cat /sys/devices/platform/dfg/thermal_limits"
adb shell "cat /sys/devices/platform/dfg/thermal_events"
```

## Security

* Kernel: write nodes are root-owned (mode 0644); non-root writes fail
  with `EACCES`.
* SELinux: DFG-Controller runs as `dfg_controller_app`; merge
  `sepolicy/dfg_controller.te` + `dfg_controller_contexts` into the
  device policy to allow `read/write/open/getattr` on `sysfs_dfg`.

## Verification checklist

```sh
adb root
adb shell "[ -d /sys/devices/platform/dfg ] && echo interface-ok"
adb shell "cat /sys/devices/platform/dfg/profile"      # performance on first boot
adb shell "cat /sys/devices/platform/dfg/thermal_events"
adb shell "dmesg | grep 'dfg:' | tail -20"
```