# FAQ

### What is DaisyForGaming?

A custom Android kernel for the Xiaomi Mi A2 Lite (`daisy`) built for gaming
performance, based on Linux 4.9.337 with verified additions: TCP BBR + FQ,
BFQ scheduler (default), KALLSYMS_HARDENED, dynamic fsync toggle, a gaming
charge toggle, the interactive governor, and zRAM (lz4).

### Which devices are supported?

The Xiaomi Mi A2 Lite (`daisy`). The installer device-checks for
`daisy` / `Mi_A2_Lite` and refuses everything else.

### Which Android versions?

Android 11 is the base this kernel is built for (upstream base branch
`eleven`). Other Android versions are untested.

### What kernel base is used?

Linux 4.9.337 (from the source `Makefile`), forked from
`Couchpotato-sauce/kernel_xiaomi_sleepy`.

### What does the device report as its version?

`4.9.337-DaisyForGaming` (`CONFIG_LOCALVERSION="-DaisyForGaming"`).

### What compiler is required?

Proton Clang 13 (`clang-13`, `ld.lld`, LLVM binutils) plus
`aarch64-linux-gnu-` / `arm-linux-gnueabi-` cross tools.

### How do I build it?

See [BUILD.md](BUILD.md). In short: `./scripts/build_kernel.sh` after
installing the toolchain.

### How do I install it?

TWRP only. See [INSTALLATION.md](INSTALLATION.md): backup first, install the
release ZIP, swipe to confirm, reboot.

### How do I update?

DFG Controller checks `kernel_update.json` daily and notifies you when a
newer kernel exists. You download the ZIP (SHA-256 verified by the app),
then flash it manually in TWRP. There is **no automatic flashing**.

### How does DFG Controller detect updates?

It fetches
`https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json`,
compares `kernel_version` with the installed version, and notifies if newer.
See [UPDATE_SYSTEM.md](UPDATE_SYSTEM.md).

### Where are releases hosted?

GitHub Releases:
https://github.com/bmjubairdadu/DaisyForGaming/releases
Tag format: `kernel-v<version>-DaisyForGaming`.

### How do I verify a release?

```sh
curl -sL -o k.zip <download_url from the manifest>
sha256sum k.zip   # must equal the sha256 field in kernel_update.json
```

### What should I do after a bootloop?

Boot to TWRP and restore your Boot backup, or re-flash the previous
known-good kernel ZIP, or `fastboot flash boot boot.img` with a stock image.
See [INSTALLATION.md](INSTALLATION.md#6-after-a-bootloop).

### Can I turn BBR on?

Yes: `sysctl net.ipv4.tcp_congestion_control=bbr` (root). Cubic stays the
default by design; both are compiled in.

### What are the feature toggles?

- Dynamic fsync: `/sys/kernel/dyn_fsync/dyn_fsync` (`1` on, `0` off)
- Gaming charge: provided by the `qpnp-smbcharger_d1a` driver (see
  [FEATURES.md](FEATURES.md))

### How can I report a bug?

Open an issue using the [bug report template](../.github/ISSUE_TEMPLATE/bug_report.md)
with kernel version, device, ROM, recovery, steps, and logs.
