# TROUBLESHOOTING

Common problems and verified fixes.

## Building

### "ld: /lib/x86_64-linux-gnu/libc.so.6: unknown type [0x13] section `.relr.dyn'"

The Clang toolchain was **prepended** to `PATH`, so kconfig/host tools are
linked with the old bundled `ld` instead of the system linker.
Fix: append the toolchain instead — `export PATH="$PATH:/opt/toolchains/proton-clang-13/bin"`
(the project scripts already do this).

### "Cannot use CONFIG_LTO_CLANG: requires clang 5.0 or later"

The kernel was built with gcc, not clang. `export CC=clang-13` alone is
ignored — the kernel Makefile assigns `CC = $(CROSS_COMPILE)gcc`, which
overrides environment variables. Pass it on the make command line:

```bash
make O=out CC=clang-13 ...
```

### "llvm-ar: not found"

The LTO build path invokes unversioned LLVM tool names. Use a toolchain that
provides them (proton-clang provides `llvm-ar`, `ld.lld`, ... in its `bin/`),
or symlink them.

### "No rule to make target 'include/config/auto.conf'"

`out/` is stale or incomplete. Remove it and rebuild:

```bash
rm -rf out
./scripts/build_kernel.sh
```

### "fatal: detected dubious ownership in repository"

The repo is root-owned (typical for WSL `/opt` builds) and you run git as
another user. Fix:

```bash
git config --global --add safe.directory /opt/kernel/daisy-build
```

### Missing cross compiler

```bash
sudo apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
  gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi
```

## Packaging

### "zip error: Could not create output file"

The `dist/` directory does not exist — `mkdir -p dist` first
(`release_kernel.sh` does this; `pack/ak3` never needs editing).

### ZIP has no `Image.gz-dtb` / tiny ZIP

`Image.gz-dtb` was not copied into the package before zipping. Re-run the
packaging steps in order (see [RELEASE_PROCESS.md](RELEASE_PROCESS.md)).

## Installing / after flash

### Installer aborts with a device-check error

You are trying to flash on a device other than `daisy` / `Mi_A2_Lite`.
This is intentional — this kernel only supports the Xiaomi Mi A2 Lite.

### Bootloop after flashing

1. Force-reboot into recovery (Power + Volume Down — device-specific).
2. Restore your **Boot** backup (TWRP → Restore).
3. If no backup: flash the previous known-good kernel ZIP, or the stock
   `boot.img` via fastboot (`fastboot flash boot boot.img`).
4. Only flash again once you have a known-good boot image backed up.

### Device boots but `uname -r` shows the old version

The boot image was not actually replaced (e.g. TWRP reported success but
the partition was A/B-shadowed, or the ZIP was flashed into the wrong
slot). Re-flash in TWRP and verify with `uname -r` after boot. Expected:
`4.9.337-DaisyForGaming`.

### `/proc/version` shows the new version but Magisk is gone

Reinstall Magisk (or re-patch the boot image). Note: the installer uses
magiskboot to preserve Magisk; if your recovery handled the flash
differently, re-patching is the fix.

## Update system

### App shows no update notification

- No internet — check connectivity (the check fails silently and retries
  next cycle).
- You were already notified for that version (cached) — nothing new to show.
- Use the manual **"Check for kernel updates"** action.

### "Invalid manifest" / parse error in the app

The raw manifest URL must return valid JSON:
`https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json`

### Checksum mismatch after download

The app deletes the file and warns. Redownload from the GitHub Release page
and compare `sha256sum` with the value in the manifest/release notes. If the
release was re-uploaded, the maintainer must re-run
`scripts/release_kernel.sh` so the manifest's SHA-256 matches the actual ZIP.

### Manifest lists a version but the release page 404s

The `download_url` points at a deleted/renamed asset. Fix by re-running the
release script (it refreshes the manifest from the real release).

## General

### How do I report a bug?

Use the [bug report template](../.github/ISSUE_TEMPLATE/bug_report.md).
Include: kernel version (`uname -r`), device, ROM, recovery, installation
method, reproduction steps, logs (`dmesg` / logcat if available), and the
last known working version.
