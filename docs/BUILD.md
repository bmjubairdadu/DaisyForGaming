# BUILD

How to build DaisyForGaming on Linux (WSL included).

## Requirements

- **OS:** any Linux that can run Clang 13 and the cross binutils
  (Ubuntu 22.04/24.04 or WSL recommended)
- **Compiler:** Proton Clang 13 at `/opt/toolchains/proton-clang-13`
  (`clang-13`, `ld.lld`, LLVM binutils — the project toolchain)
- **Cross tools (apt packages):**
  - `gcc-aarch64-linux-gnu` + `binutils-aarch64-linux-gnu`
  - `gcc-arm-linux-gnueabi` + `binutils-arm-linux-gnueabi`
- **Host tools:** `make`, `zip`, `python3`, `git`, `bc`
  (kernel build prerequisites: `libssl-dev`, `libncurses-dev` are needed for
  some config/build paths; install if `make` complains)

The kernel is built out-of-tree into `out/` — the source tree stays clean.

## Build with the project script

```bash
git clone https://github.com/bmjubairdadu/DaisyForGaming.git
cd DaisyForGaming

./scripts/build_kernel.sh
```

`scripts/build_kernel.sh`:

```bash
#!/bin/bash
# O=out build with the project toolchain
export ARCH=arm64
export PATH="$PATH:/opt/toolchains/proton-clang-13/bin"
[ -f out/.config ] || make O=out daisy_defconfig
make -j"$(nproc)" O=out \
  CC="clang-13" AR="llvm-ar" AS="llvm-as" NM="llvm-nm" LD="ld.lld" \
  STRIP="llvm-strip" OBJCOPY="llvm-objcopy" OBJDUMP="llvm-objdump" \
  OBJSIZE="llvm-size" READELF="llvm-readelf" \
  CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
```

Important details (already handled by the script):

- Toolchain is **appended** to `PATH`, not prepended — kconfig/host tools
  must link with the system `ld`. Prepending the toolchain breaks host
  linking with newer glibc (`.relr.dyn` error).
- All tool variables (`CC`, `AR`, `LD`, ...) are passed **on the make command
  line**. Environment variables are overridden by the kernel Makefile
  (`CC = $(CROSS_COMPILE)gcc`), so `export CC=clang-13` alone does NOT work.
- The build is LTO (Clang) — `CONFIG_LTO_CLANG=y`.

## Manual build (equivalent)

```bash
export ARCH=arm64
export PATH="$PATH:/opt/toolchains/proton-clang-13/bin"
make O=out daisy_defconfig
make -j$(nproc) O=out \
  CC=clang-13 AR=llvm-ar AS=llvm-as NM=llvm-nm LD=ld.lld \
  STRIP=llvm-strip OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
  OBJSIZE=llvm-size READELF=llvm-readelf \
  CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
```

## Build output

| Artifact | Path |
| -------- | ---- |
| Config | `out/.config` |
| Kernel image (ELF) | `out/vmlinux` |
| Kernel image (arm64) | `out/arch/arm64/boot/Image` |
| Compressed | `out/arch/arm64/boot/Image.gz` |
| Compressed + DTB | `out/arch/arm64/boot/Image.gz-dtb` ← used for flashing |
| Device trees | `out/arch/arm64/boot/dts/qcom/msm8953-qrd-sku3-{daisy,sakura}.dtb` |
| Flashable ZIP | `dist/DaisyForGaming-<version>-<dd-mm-yyyy>.zip` (via `release_kernel.sh`) |
| Build log | terminal output (or `tee` to a file) |

Verify the banner:

```bash
gzip -dc out/arch/arm64/boot/Image.gz-dtb | strings | grep -m1 'Linux version [0-9]'
# Linux version 4.9.337-DaisyForGaming (root@host) (Proton clang version 13.0.0 ...)
```

## Packaging

Packaging is part of `scripts/release_kernel.sh` (see
[RELEASE_PROCESS.md](RELEASE_PROCESS.md)):

1. Copy `out/arch/arm64/boot/Image.gz-dtb` into `pack/ak3/` (AnyKernel3).
2. `zip -r9` the template → `dist/DaisyForGaming-4.9.337-10-08-2026.zip`.
3. `sha256sum` the ZIP.

To package manually:

```bash
mkdir -p dist && rm -rf .pkg && cp -r pack/ak3 .pkg
cp out/arch/arm64/boot/Image.gz-dtb .pkg/Image.gz-dtb
(cd .pkg && zip -r9q ../dist/DaisyForGaming_local.zip .)
sha256sum dist/DaisyForGaming_local.zip
```

## Common build failures

| Symptom | Cause | Fix |
| ------- | ----- | --- |
| `ld: /lib/x86_64-linux-gnu/libc.so.6: unknown type [0x13] section \`.relr.dyn'` (host tools) | Toolchain first in `PATH`; host kconfig links with old lld | Append toolchain to PATH (`export PATH="$PATH:.../bin"`) |
| `Cannot use CONFIG_LTO_CLANG: requires clang 5.0 or later` | `CC` not actually clang (env var overridden by Makefile) | Pass `CC=clang-13` on the make command line |
| `llvm-ar: not found` | LTO path calls unversioned names | Use a toolchain where `llvm-ar` etc. resolve (proton-clang provides them) |
| `No rule to make target 'include/config/auto.conf'` | `out/` is stale/broken | `rm -rf out` and rebuild |
| `fatal: detected dubious ownership` | Root-owned repo on WSL | `git config --global --add safe.directory /opt/kernel/daisy-build` |
| Missing cross compiler | packages not installed | `apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi` |
