# USER GUIDE

Everything a user needs to know about running DaisyForGaming.

## After flashing (first boot)

1. Verify the kernel:
   ```sh
   uname -r          # → 4.9.337-DaisyForGaming
   cat /proc/version
   ```
2. Verify feature availability:
   ```sh
   cat /sys/kernel/dyn_fsync/dyn_fsync                    # 1 = fsync on
   grep -o 'bbr' /proc/sys/net/ipv4/tcp_available_congestion_control
   ```

## Feature toggles

### CPU input boost

Automatic — no action needed. On touch events the CPU min frequency is
briefly raised (default **1.4 GHz / 60 ms**) so the first frames after a
touch render immediately. Controls (root, `/sys/module/input_boost/parameters/`):

- `enabled` — `0/1`, default `1`
- `boost_freq` — clamped to a safe sub-maximum (≈ 80 % of the policy max);
  default `1401600` (1.4 GHz)
- `boost_duration_ms` — clamp `20–150`, default `60`

The boost does not change the max frequency or sustained performance and is
suppressed while the screen is off.

### Memory pressure (not gaming-only, general multitasking)

- **lmk_aggressive** — `/sys/kernel/mm/lmk_aggressive` (`0/1`, default `0`).
  Dormant until enabled; when enabled it applies a moderate 6-level minfree
  table (32/40/48/64/80/96 MB) so background apps are reclaimed somewhat
  sooner under pressure. Disable restores the previous table. Combined with
  Android's userspace lmkd — deliberately not maximally aggressive, so apps
  don't reload from scratch when you switch back.
- **swappiness** — `/sys/kernel/mm/swappiness` (clamp `0–200`, boot default
  `100`; the kernel-baked value is `60`). zRAM-appropriate: with lz4 zRAM as
  swap, a moderately higher swappiness smooths multitasking on a 3 GB device.
  The ROM may override it at boot; re-apply from this node anytime:
  ```sh
  echo 100 > /sys/kernel/mm/swappiness     # requires root
  ```

### Verify zRAM is actually used as swap

zRAM is compiled in, but **only helps if the ROM mounts it as swap**:
```sh
cat /proc/swaps            # look for /dev/block/zram0 with a nonzero size
cat /proc/sys/vm/swappiness
```
If `/proc/swaps` lists no `zram0` device, the kernel cannot activate swap
itself — support from the ROM's init or a root app is required.

### Dynamic fsync

- Default: **on** (`1`) — safe, standard behavior.
- Off (performance, higher data-loss risk on sudden power cut):
  ```sh
  echo 0 > /sys/kernel/dyn_fsync/dyn_fsync     # requires root
  ```
- Back on:
  ```sh
  echo 1 > /sys/kernel/dyn_fsync/dyn_fsync
  ```
- The toggle resets to `1` on reboot (it is a sysfs setting, not persistent).

### Gaming charge

The daisy charger driver exposes a gaming charge toggle that restricts the
charge profile while gaming. It includes a charger-present interlock
(auto-off when no charger is connected) and auto-restores the saved float
voltage when disabled. Enable it only while gaming and plugged in; the
exact sysfs path is provided by the
`qpnp-smbcharger_d1a` driver (see [FEATURES.md](FEATURES.md)).

### TCP BBR

Cubic is the default congestion control; BBR is compiled in and can be
enabled per-boot (root):

```sh
sysctl net.ipv4.tcp_congestion_control=bbr
```

Make it persistent via your root app's init script or `sysctl.conf`
(`net.ipv4.tcp_congestion_control=bbr`).

## Updating the kernel

1. Let DFG Controller notify you, or manually check for updates in the app.
2. The app downloads and verifies the SHA-256 of the release ZIP.
3. Reboot to TWRP and **Install** the ZIP (manual swipe to confirm).
4. Reboot and verify with `uname -r`.

There is **no automatic flashing** — the app never installs kernels by itself.

## Backups

Before every flash:

- TWRP → Backup → **Boot** (+ System if you like).
- Keep the ZIP of the current known-good kernel.

## Rollback

- TWRP → Restore → your Boot backup → reboot.
- Or flash the previous release ZIP.
- Or `fastboot flash boot boot.img` with a stock image.

## Reporting problems

Open a bug report with: `uname -r`, device, ROM, recovery, install method,
steps to reproduce, logs (`dmesg`), and the last working version. Use the
[bug report template](../.github/ISSUE_TEMPLATE/bug_report.md).
