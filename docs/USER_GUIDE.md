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
