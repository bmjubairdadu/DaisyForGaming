# Changelog

All notable changes to the **DaisyForGaming** kernel for the Xiaomi Mi A2 Lite (`daisy`) are documented here.

## v1.1 - Bug-fix release (2026-09-28)

Source-tree maintenance release based on the project KNOWN-BUGS list:

- **pn533 (NFC USB):** backported stable fix 35529d6b827ee (4.14.303) - wait
  for out_urb completion in `pn533_usb_send_frame()` to prevent a
  use-after-free when in_urb completes first (adapted to the 4.9 driver
  shape, which has no dedicated ack_urb).
- **rbd (Ceph block device):** backported stable fix 71da2a151ed1a (4.14.308) -
  `rbd_dev_create()` no longer transfers ownership of rbdc/spec/opts before
  it can fail, fixing a use-after-free in `do_rbd_add()`.
- Both drivers remain disabled in the shipping `daisy_defconfig`
  (`CONFIG_NFC=n`, `CONFIG_BLK_DEV_RBD=n`), so there is no runtime behavior
  change on device; this release ships a clean, fixed source tree and a
  refreshed AnyKernel3 package (v1.1-bugfix).

## v1.0 — Initial public release (2026-09-26)

First stable public release, based on **TogoFire r54 (Linux 4.9.337)**.

### 🎮 Gaming & Performance
- Enabled **CPU Input Boost** with touch + fingerprint-unlock boost for instant responsiveness.
- **Adreno Idler** GPU tuning for the Adreno 506.
- **schedutil** default CPU governor.
- Low-latency **HZ = 300** + **PREEMPT** configuration.
- **Deadline** I/O scheduler set as default for lower storage latency.

### 🌐 Network
- **BBR** TCP congestion control enabled and set as the default.
- **FQ** (Fair Queue) packet scheduler enabled.

### 🔋 Charging & Battery
- Tuned charging device tree: fast-charge current set to **2000 mA**.
- Relaxed thermal-mitigation steps (`2000 / 1000 / 700 / 0` mA) for faster charging at normal temperatures while keeping safety cutoffs.
- Float voltage kept at the safe stock **4400 mV** (no over-voltage).
- **Power-efficient workqueues** enabled to reduce idle battery drain.
- Charging-control sysfs nodes remain writable for advanced / bypass-charging use.

### 💾 Memory
- **zRAM** with **writeback** enabled for improved multitasking.

### 🔓 Root
- **KernelSU-ready:** `CONFIG_KPROBES` enabled (kprobe-based hooks, no source patch needed).
- **OverlayFS** enabled for KernelSU modules.
- Unsigned kernel-module loading allowed.

### 🧱 Stability
- Conservative, bug-free tuning — no aggressive undervolt or overclock.
- Verified device tree (charger values) and kernel configuration.
- Reproducible build straight from `make daisy_defconfig`.
