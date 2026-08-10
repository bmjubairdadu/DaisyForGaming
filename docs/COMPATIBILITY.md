# COMPATIBILITY

## Supported devices

| Device | Codename | SoC | Architecture | Android base | Status |
| ------ | -------- | --- | ------------ | ------------ | ------ |
| Xiaomi Mi A2 Lite | `daisy` | Snapdragon 625 (msm8953) | arm64 | Android 11 | ✅ Supported (installer device-checked) |

The kernel and its device trees come from the `msm8953-qrd-sku3` platform
definition, which this project inherits from the upstream
`Couchpotato-sauce/kernel_xiaomi_sleepy` base (branch `eleven`).

## What this means

- The **AnyKernel3 installer** (`pack/ak3/anykernel.sh`) only accepts
  `daisy` / `Mi_A2_Lite` and aborts elsewhere (`do.devicecheck=1`).
- The **kernel image** (`Image.gz-dtb`) is built with the device trees for
  both `msm8953-qrd-sku3-daisy` and `msm8953-qrd-sku3-sakura`, inherited
  from the upstream platform tree. Only daisy is the supported, tested,
  installer-validated device of this project.

## Known limitations

- Android 11 is the tested target (base branch `eleven`). Flashing on
  Android 10 or 12+ images is **untested** — this kernel was not built
  against those vendor configs.
- No kernel modules are shipped (`do.modules=0`); all required drivers are
  built-in.
- The installer writes only the boot partition; if your ROM expects
  coordinated boot/vendor/dtbo updates (e.g. some newer ROMs), this kernel
  may be incompatible.
- BBR is compiled in but **not** the default; you must switch it at runtime
  (`sysctl net.ipv4.tcp_congestion_control=bbr`).
- The dynamic fsync toggle is default-ON; turning it off (`echo 0 >
  /sys/kernel/dyn_fsync/dyn_fsync`) trades data safety for performance.

## Incompatible configurations (known)

- Devices other than `daisy` (installer aborts — do not bypass).
- Boot images that require encrypted/signed kernel chains not supported by
  your recovery.
- Custom ROMs that ship their own kernel modifications incompatible with
  this tree.
