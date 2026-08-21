# Migration notes: previous DaisyForGaming kernels -> 4.9.337 + DFG

These notes are for users upgrading from earlier DaisyForGaming builds
(input boost / gaming charge / dyn_fsync era) to the DFG-integrated
4.9.337 base.

## What is new

| Area | Previous kernels | This build |
| ---- | ---------------- | ---------- |
| Base | 4.9.x (varied) | 4.9.337 (final 4.9 LTS, Android 11 `android-4.9-q` compatible) |
| Default boot profile | interactive/stock governor | **performance** (`schedutil`, min 1401 MHz) via `CONFIG_DFG_DEFAULT_PERF` |
| Control interface | scattered sysfs nodes | unified `/sys/devices/platform/dfg/` |
| Thermal policy | stock only | DFG soft/hard watchdog on top of tsens; `thermal_override` + `thermal_events` |
| Scheduler | stock | schedutil + input boost (unchanged defaults) + DFG profiles |
| I/O | BFQ default | per-profile scheduler (performance=noop, balanced=bfq, battery=cfq) |

## What is kept (unchanged)

* `/sys/module/input_boost/parameters/{enabled, boost_freq, boost_duration_ms}`
* `/sys/kernel/mm/swappiness`, `/sys/kernel/mm/lmk_aggressive`
* `/sys/kernel/dyn_fsync/dyn_fsync`
* Gaming charge toggle (qpnp-smbcharger)
* TCP BBR + FQ, BFQ compiled in, zRAM (lz4), KCAL, HZ=300

Nothing from previous releases is removed or renamed.

## Behavior changes to expect

1. **Boot profile is now performance.** First boot keeps CPU min at
   1401 MHz (`/sys/devices/platform/dfg/cpu_min_freq`). To boot balanced
   instead, either rebuild with `CONFIG_DFG_DEFAULT_PERF=n` or run
   `echo balanced > /sys/devices/platform/dfg/profile` (applies at every
   boot until you add an init.d/`fstab`-style hook or use DFG-Controller).
2. **Deep idle is NOT disabled by default** (`CONFIG_DFG_PERF_DISABLE_DEEP_IDLE=n`).
   If you want the old "no deep sleep" behavior, enable the Kconfig option
   or write `1` to `/sys/devices/platform/dfg/deep_idle` at runtime.
3. **Thermal override is opt-in.** `thermal_override=1` only lifts the
   *soft* cap (50 C). Above 60 C the kernel clamps to safe frequencies and
   resets the override regardless of userspace.
4. **Governor switching** now goes through `dfg/governor` (applies to all
   policies). The old per-policy `scaling_governor` files still work.

## DFG-Controller app

The app should stop writing the old nodes it managed directly and use the
DFG interface:

* read/write `/sys/devices/platform/dfg/profile`
* `thermal_events` (last 16 events) replaces any log parsing
* `thermal_limits` exposes the effective caps for UI display

See `sepolicy/dfg_controller.te` for the required SELinux policy (domain
`dfg_controller_app`, node type `sysfs_dfg`). Merge it into the device
sepolicy tree (`system/sepolicy` or the vendor policy dir) and add the
file contexts from `sepolicy/dfg_controller_contexts` before granting the
app write access.

## Downgrade

This kernel is a drop-in for previous DaisyForGaming/stock Android 11
kernels. Any previous flashable ZIP can be re-flashed over it; no data or
partition layout changes are made.

## Risk notes

* The msm8953 vendor BSP stays on 4.9 (see the base commit message). If a
  vendor blob ever requires a newer kernel ABI, a compat shim is required;
  this tree keeps vendor files at their 4.9 baseline.
* `deep_idle=1` increases idle power draw; keep it off on battery unless
  you are gaming while plugged in.