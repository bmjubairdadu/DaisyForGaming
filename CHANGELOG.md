# Changelog

All notable changes to the **DaisyForGaming** kernel for the Xiaomi Mi A2 Lite (`daisy`) are documented here.

## v1.17 — Final (2026-10-05)

### 🧪 Full on-device verification first
The flashed v1.16-FolkPatch-Magisk kernel was deep-checked on the phone before
this release: Magisk root working, touch boost live (1401/1689 MHz, 300 ms,
sched boost on input), top-app schedtune boost=10 + prefer_idle=1, zRAM lz4
with 2 GB swap active, vm sysctls applied, deadline scheduler default, dmesg
clean (only stock camera/wlan noise). **No kernel bug was found** — the kernel
binaries in v1.17 are byte-identical to the verified v1.16 ones.

### 🔧 The one real (harmless) issue, fixed
- `99-dfg-tune.sh`'s zram `swapon` raced the ROM's own zram init (~44 s after
  kernel boot): the script logged "swapon FAILED" while the ROM successfully
  mounted the same swap 0.3 s later. The script now retries for up to 2 minutes
  (12 attempts × 10 s), detects when the ROM has already enabled swap, and
  logs the final swap/governor/fsync state for diagnostics.
- `dfg_tune.sh` is now a single source file in the repo used by both zips
  (previously duplicated as heredocs in each zip script).

### 📦 Shipping zips (final)
- **`DaisyForGaming-v1.17-KSU.zip`** — built-in KernelSU v0.9.5 + SusFS
  (`daisy_defconfig`). Root via KernelSU Manager or Magisk.
- **`DaisyForGaming-v1.17-FolkPatch-Magisk.zip`** — no in-kernel root
  (`daisy_fp_defconfig`, vanilla shape) for FolkPatch (KP ≥ 0.13.8 required on
  4.9) or plain Magisk.
- Both uname as plain `4.9.337-DaisyForGaming`. Same gaming feature set:
  CPU touch boost (1401/1689 MHz, 300 ms, WALT sched boost), top-app schedtune
  lift, zRAM lz4 + writeback, deadline IO, fq_codel + BBR, IPA, PM8953 thermal.
- Packaging: one parameterized script (`dfg_zip117.sh ksu|fp`) over the fresh
  AnyKernel3 base; superseded v1.16 zips and scripts removed.

## v1.16 — Two fresh builds: KSU and FolkPatch/Magisk (2026-10-05)

### 🔁 Direction change
- **APatch dropped** (both the -APatch kernel variant and its files): the user
  moved to **FolkPatch** (`LyraVoid/FolkPatch`), an APatch/KernelPatch fork
  whose V6 Sol release syncs **KernelPatch 0.13.9** — the exact KP version
  verified to boot on this 4.9 kernel (0.13.8 fixed the 4.9 x29 boot-hang).

### 📦 Two shipping zips
- **`DaisyForGaming-v1.16-KSU.zip`** — built-in **KernelSU v0.9.5 + SusFS**
  (`daisy_defconfig`). Root via KernelSU Manager or Magisk. Same verified
  kernel binary as v1.15 (no code change; repackaging + cleanup only).
- **`DaisyForGaming-v1.16-FolkPatch-Magisk.zip`** — **no in-kernel root**
  (`daisy_fp_defconfig`: `CONFIG_KSU=n`, SusFS off) — a vanilla-shaped kernel
  so FolkPatch can patch the boot image cleanly; Magisk works normally
  (ramdisk-based). Both kernels report the same uname
  `4.9.337-DaisyForGaming` (no variant suffix, per user request).
- Every gaming feature ships in both: CPU touch boost (1401/1689 MHz, 300 ms,
  WALT sched boost on input), top-app schedtune lift (boot script), zRAM lz4 +
  writeback, deadline IO, fq_codel + BBR, IPA, PM8953 thermal.

### 🧹 Project cleanup
- Removed superseded release zips (v1.10–v1.15), all per-version build/zip
  helper scripts, old debug artifacts and logs, the unused top-level KernelSU
  git clone, and the whole APatch variant (defconfig, out-apatch, debug imgs).
- Packaging now uses a fresh **AnyKernel3** base (`_ak3base/`) instead of
  old zip templates. New canonical scripts: `dfg_v116_fp_build.sh`,
  `dfg_zip116_ksu.sh`, `dfg_zip116_fp.sh`, `dfg_boot_rebuild.py` (swaps a boot
  image's kernel blob keeping header + ramdisk byte-identical).
- FolkPatch tooling extracted from the v6 APK into `_folkpatch_tools/`
  (`kpimg` = KP 0.13.9, `libkptools.so`, `libbootctl.so`, `libbusybox.so`,
  `boot_template.img`).

### 📌 Root-stack rules
- v1.16-KSU → KernelSU Manager / Magisk. NEVER patch its boot with FolkPatch.
- v1.16-FolkPatch-Magisk → flash the zip, then patch the resulting boot with
  FolkPatch Manager (KP ≥ 0.13.8 required for 4.9), or use plain Magisk.
- The two stacks must never be mixed on one kernel.

## v1.15-APatch — APatch (KernelPatch) companion build (2026-10-05)

### 🐛 Problem
Flashing an APatch-patched boot image on top of the stock DaisyForGaming
kernel **bootlooped the device**. Research (APatch/KernelPatch issue trackers,
device-specific threads) shows this is the documented failure mode for running
KernelPatch on a kernel that already ships **in-kernel KernelSU**: KernelPatch
installs its own hooks on the execve path (that is how its superkey/su
interception works), and v1.0–v1.15 kernels hook the exact same path from
in-tree KernelSU (`do_execveat_common` in `fs/exec.c`, plus `faccessat`,
`vfs_read`, `vfs_fstatat`, devpts, input). Two root stacks on one kernel →
panic at first execve → bootloop.

### ✅ Fix — a second, kpatch-safe build
- New defconfig `arch/arm64/configs/daisy_apatch_defconfig`: identical to
  `daisy_defconfig` (every gaming feature included) except
  **`CONFIG_KSU=n` + all `CONFIG_KSU_SUSFS_*` off**, and
  `CONFIG_LOCALVERSION="-DaisyForGaming-APatch"` so `uname -a` clearly shows
  which build is running.
- All KSU hook sites are `#ifdef CONFIG_KSU`-guarded (fs/exec.c, fs/open.c,
  fs/read_write.c, fs/stat.c, fs/devpts/inode.c, drivers/input/input.c), and
  SusFS (`fs/susfs.o`) is only built under `CONFIG_KSU_SUSFS`, so the APatch
  build produces a vanilla-shaped kernel — exactly what KernelPatch expects.
- KernelPatch's hard requirements are already met by both builds:
  `CONFIG_KALLSYMS=y` + `CONFIG_KALLSYMS_ALL=y` + `KPROBES`; KASLR
  (`CONFIG_RANDOMIZE_BASE`), KPTI (`UNMAP_KERNEL_AT_EL0`) and
  `ARM64_SW_TTBR0_PAN` are off, which are the other known kpatch breakers.
- Zip: `DaisyForGaming-v1.15-APatch-FINAL.zip` (AnyKernel3, same device/ROM
  checks). Built via `dfg_v115_apatch_build.sh` + `dfg_zip115_apatch.sh`
  (separate `out-apatch` object tree; the KSU build stays untouched).

### 📌 Usage rules (do not mix stacks)
- **v1.15** = built-in KernelSU (+ SusFS) → use KernelSU Manager / Magisk.
  NEVER patch its boot with APatch.
- **v1.15-APatch** = no in-kernel root → flash the zip first, then dump the
  new boot, patch it in APatch Manager, and test with `fastboot boot` before
  flashing permanently. Keep a backup of the pre-APatch boot.img (flashing the
  APatch boot removes the Magisk ramdisk patch).

### 🐛 Update (same day) — logo-hang after patching, fixed with kpatch ≥ 0.13.8
- After flashing the v1.15-APatch kernel and patching boot with a community
  TWRP "APatch Boot Image Patcher" (kpimg **d03**, built 2026-08-05), the phone
  **hung at the boot logo** (no ADB, kernel-level hang).
- Bisect via `fastboot boot` RAM-tests proved the clean v1.15-APatch kernel
  boots fine and the hang is kpimg-side. Root cause found in the KernelPatch
  release notes: **kpatch 0.13.8 (2026-08-30) fixed a 4.9-specific boot hang** —
  the patched tail return set `x29 = P` instead of restoring the caller's
  frame pointer, so the 4.9 kernel walked x29-relative locals in
  `setup_arch` after `paging_init()` and hung. kpimg d03 predates that fix.
- Fix: patched the clean boot image with **kptools + kpimg 0.13.9 (d09)** and a
  proper superkey (`kptools -p -i boot.img -k kpimg-android -s <key> -o out.img`
  — 0.13.9 kptools patches ANDROID! boot images in one step; the WSL glibc is
  too old for kptools-linux, the bundled `kptools-msys2-win` build runs on
  Windows). Verified by RAM-boot: full Android boot, `sys.boot_completed=1`,
  KernelSU/SusFS strings absent, Magisk ramdisk intact.
- **Rule: any future APatch patching of this kernel must use kpimg ≥ 0.13.8.**
  The working image ships as `APatch_0139_boot.img`; a clean-kernel backup as
  `clean_APatch_boot.img` (built by `_apatch_debug/rebuild_boot.py`, which
  swaps the kernel blob of a boot image while preserving header + ramdisk).

## v1.15 — Input boost that actually works + tuning upgrade (2026-10-05)

### 🎮 Gaming & Performance
- **CPU touch/input boost is now ON by default.** v1.0–v1.14 compiled `cpu_boost`
  but booted with every input-boost parameter at 0 (`input_boost_freq = 0:0 …`,
  `input_boost_ms = 40`, `sched_boost_on_input = 0`), so the flagship v1.0
  feature never boosted anything at runtime. The driver now seeds its per-CPU
  table at boot (`drivers/cpufreq/cpu-boost.c`):
  - little cluster (cpu0–3): **1401600 kHz**
  - big cluster (cpu4–7): **1689600 kHz**
  - hold time **300 ms** (was 40 ms), re-triggered on every input ≥100 ms apart
  - **WALT full-throttle scheduler boost on every input** — foreground tasks
    migrate to the big cluster instantly (was off)
- New Kconfig symbols: `INPUT_BOOST_FREQ_BIG` (1689600) and `INPUT_BOOST_SCHED`
  (1); `INPUT_BOOST_FREQ`'s Kconfig default fixed (was 0, ignored by the driver).
  `CONFIG_INPUT_BOOST_DURATION_MS` 100 → 300. Everything stays runtime-tunable
  in `/sys/module/cpu_boost/parameters/`.
- **top-app schedtune boost** shipped via the boot script: `top-app/schedtune.boost=10`
  and `prefer_idle=1`, so the foreground app group keeps scheduler preference
  even when the ROM never raises a boost itself.
- **zRAM default compression zstd → lz4** (lowest CPU overhead while gaming;
  zstd/lzo remain available at runtime). Writeback stays on.
- Boot script (`99-dfg-tune.sh`, Magisk service.d) upgraded: re-asserts the
  input-boost values (also rescues older kernels), lifts top-app schedtune,
  enables zram lz4 swap, and applies vm sysctls (page-cluster 0,
  vfs_cache_pressure 20, swappiness 30, dirty_background_ratio 5). Logs to
  `/data/local/tmp/dfg_tune.log`.

### 🧹 Defconfig cleanup
- Single-sourced the IO scheduler block (deadline default; cfq/noop still
  compiled) and zRAM block (lz4 + writeback) — the file carried conflicting
  duplicates from the v1.0 overlay that only worked because the last block won.

### ✅ Verified on device — already fine, left untouched
- DDR/bus devfreq input boost (`CONFIG_DEVFREQ_BOOST=y`, boost freq 3221 =
  the 422.4 MHz SVS entry of the cpubw table) — active, no change needed.
- fsync toggle at `/sys/module/sync/parameters/fsync_enabled` (default on) — present.
- deadline IO scheduler default and active on mmcblk0; fq_codel qdisc + BBR — active.
- Adreno idler + msm-adreno-tz, GPU max 650 MHz — unchanged. No CPU/GPU
  overclock on purpose: sustained thermal headroom beats a paper spec, and the
  v1.2 thermal-trip fixes are what keep long gaming sessions fast.

### ⚙️ Packaging
- Same proven AnyKernel3 flow as v1.14 (device check `daisy`/`daisy_sprout`,
  Android 11 gate, Magisk service.d staging, kloder cleanup). Sideload:
  `adb reboot sideload` → `adb sideload DaisyForGaming-v1.15-FINAL.zip`.

## v1.3 — Root stack + full gaming pack (2026-09-30)

### 🔓 KernelSU + APatch + SusFS
- **KernelSU v0.9.5** integrated into the kernel tree at `drivers/kernelsu/`
  (the last KernelSU release with non-GKI / kernel 4.9 support), wired via
  `drivers/Kconfig` (`source "drivers/kernelsu/Kconfig"`) and
  `drivers/Makefile` (`obj-$(CONFIG_KSU) += kernelsu/`).
- **Manual (non-kprobe) hook integration.** KernelSU's kprobe hooks are
  force-disabled in this tree (`#if defined(CONFIG_KPROBES) && 0`) because
  they are unreliable on 4.9. All six hook points are patched directly:

  | File | Hook |
  |------|------|
  | `fs/exec.c` | `ksu_handle_execveat` / `..._sucompat` |
  | `fs/open.c` | `ksu_handle_faccessat` (in `faccessat`) |
  | `fs/read_write.c` | `ksu_handle_vfs_read` (in `vfs_read`) |
  | `fs/stat.c` | `ksu_handle_stat` (in `vfs_fstatat`) |
  | `fs/devpts/inode.c` | `ksu_handle_devpts` (in `devpts_get_priv`) |
  | `drivers/input/input.c` | `ksu_handle_input_handle_event` |

  This is what makes su, `pm` and module unmounting actually work without
  kprobes.
- **SusFS** (`susfs4ksu`, `kernel-4.9` branch, v1.5.5) kernel patch applied
  across 18 files plus the new `fs/susfs.c` / `fs/sus_su.c`. Provides:
  sus-path / sus-mount / sus-kstat hiding, `uname` + `/proc/cmdline`
  spoofing, KSU/SusFS symbol hiding from `/proc/kallsyms`, try-umount on
  Magic Mount & bind mounts, and open-redirect.
- **APatch / KernelPatch** needs no source integration — it patches the boot
  image externally and only needs `CONFIG_KALLSYMS=y`, which is enabled.
- **KernelSU Safe Mode** available (triple-tap Volume Down at boot) so a bad
  hook can never hard-brick into a bootloop.
- `CONFIG_KSU_DEBUG` and `CONFIG_KSU_SUSFS_ENABLE_LOG` left **off** in
  shipping builds (no log leaks, no debug overhead).

### 🎮 Gaming & Performance
- **All six CPU governors** compiled in (performance, powersave, schedutil,
  interactive, simpleondemand, userspace) plus `GOV_ATTR_SET`, so any tuning
  script works out of the box.
- **WALT** scheduler (`CONFIG_SCHED_WALT`) with full-node awareness.
- **Adreno tz + Adreno Idler** for sustained GPU clocks under load without
  letting the GPU idle hot.
- **CPUBOOST** for burst clocks.
- **ZRAM with zstd** compression + writeback, `ZSMALLOC` for large allocations,
  **SWAP**, **COMPACTION**, **KSM/UKSM** for RAM reclaim.
- **MMU_NOTIFIER** for cleaner per-process teardown.

### 🎬 Display & Media
- DRM + DRM KMS helper + videomode, media support, USB configfs `f_fs` (ADB
  gadget) and devtmpfs — the prerequisites for hardware-composited video
  decode, so 1080p60 / 2K / 4K playback stays smooth.

### 🔥 Thermal (anti-heat)
- All thermal governors including `THERMAL_DEFAULT_GOV_USER_SPACE` and
  `THERMAL_GOV_LOW_LIMITS`, plus QPNP thermal — so limits are tunable at
  runtime and the device idles cooler under sustained load.

### 🔋 Charging
- Fast-charge paths enabled: SMB1351 / SMB135X / QPNP SMB charger D1A / SMB5
  and QPNP fuel gauge + QG, so charging current is tunable at runtime.

### 🧹 Cleanup
- Removed **24 unused architecture trees** (alpha, arc, avr32, blackfin, c6x,
  cris, frv, h8300, hexagon, ia64, m32r, m68k, metag, microblaze, nios2,
  openrisc, parisc, score, sh, sparc, tile, um, unicore32, xtensa) — none are
  referenced by `Kconfig` (`source "arch/$SRCARCH/Kconfig"` only pulls arm64)
  nor by any build config used for this device.
- Removed `*.dfgbak` backup files, the unused loader template script, and the
  non-compiled documentation trees (translations, sphinx, devicetree).

### 🐛 Compile fixes found during verification
- `drivers/input/input.c` — added the file-scope `extern bool ksu_input_hook`
  / `ksu_handle_input_handle_event()` declarations required by the KSU input
  hook (they were missing, so the hook call failed to build).
- `fs/read_write.c` — moved the `ksu_vfs_read_hook` / `ksu_handle_vfs_read()`
  `extern` declarations to file scope; a function-local `__read_mostly`
  declaration is rejected by GCC with *"section attribute cannot be specified
  for local variables"*.
- `fs/proc/task_mmu.c` — added the missing
  `#include <linux/susfs_def.h>` needed by the SusFS `SUS_KSTAT` code path in
  `show_map_vma()`; without it `INODE_STATE_SUS_KSTAT` was undeclared.

### ⚙️ Build tooling
- **Toolchain requirement fixed.** The daisy tree is a **Clang + LLD** build —
  `out/include/generated/compile.h` records `Ubuntu clang 14` / `Ubuntu LLD 14`,
  and the stock `build.sh` clones a vendor Clang and passes `CC`, `LD`, `AR`,
  `AS`, `NM`, `OBJCOPY`, `OBJDUMP`, `STRIP` as absolute paths together with
  `LLVM=1 LLVM_IAS=1`. Both `full_build.sh` and `build_check.sh` now do the
  same. Setting only `LLVM=1` is **not** enough on this 4.9 Makefile: `CC` still
  falls back to `aarch64-linux-gnu-gcc`, and the build then dies at
  `prepare-compiler-check` with
  `Cannot use CONFIG_CC_STACKPROTECTOR_STRONG`.
  Set `DFG_CLANG_ROOT=<path-to-clang-dir>` to use a vendor toolchain cloned by
  `build.sh`; otherwise the system `clang`/`ld.lld` are used.
- **GCC cannot build this tree.** With `CROSS_COMPILE=aarch64-linux-gnu-`
  (gcc 11) two hard failures appear:
  * `mm/vmscan.c:2378` — `implicit declaration of 'DIV64_U64_ROUND_UP'`.
    The macro is absent from this tree's `include/linux/math64.h`; upstream
    added it in 4.11 and this vendor tree never backported it.
  * `arch/arm64/include/asm/jump_label.h:31` (via
    `arch/arm64/kernel/cpufeature.c`) — `error: impossible constraint in 'asm'`
    from the `asm goto` jump-table encoding.
  Because toolchains are mixed into the object tree, a stray GCC build also
  poisons the incremental state; the README documents the one-liner that lists
  and deletes GCC-produced objects.
- Added `.scmversion` (contents: `DaisyForGaming-v1.3.0`). `scripts/setlocalversion`
  runs an unconditional `git rev-parse`/`git describe` walk even with
  `CONFIG_LOCALVERSION_AUTO` off, which stalled the build for over a minute on
  every `kernel.release` regeneration when the tree lives on a Windows DrvFS
  mount. The `.scmversion` file short-circuits that walk.
- Added `full_build.sh` — one-liner reproducible build (regenerates
  `daisy_defconfig`, builds with `-j$(nproc)`, prints the artifacts).
- `build_check.sh` now logs through `tee` so progress and errors stream
  line-by-line instead of being buffered by a pipeline tail.

### ✅ Verification status
`fs/`, `drivers/input/` and `drivers/kernelsu/` compile clean with **0 errors**,
reporting `-- KernelSU version: 11872` and `-- SUSFS_VERSION: v1.5.5`. The same
check still passes after the cleanup above.

## v1.2 — SusFS kernel patch (2026-09-29)

- Applied the `susfs4ksu` kernel-4.9 patch (18 files) to the tree.

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
