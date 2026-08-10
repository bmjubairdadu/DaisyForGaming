# RELEASE PROCESS

How kernel releases are created and published.

## Automated: `scripts/release_kernel.sh`

```bash
./scripts/release_kernel.sh
```

or with a custom changelog:

```bash
CHANGELOG="my release notes" ./scripts/release_kernel.sh
```

### What it does, step by step

1. **Version** — reads `VERSION`/`PATCHLEVEL`/`SUBLEVEL`/`EXTRAVERSION`
   from `Makefile` (currently `4.9.337`) and appends the brand
   `-DaisyForGaming` → `4.9.337-DaisyForGaming`.
2. **Preflight** — requires `gh` authenticated as `bmjubairdadu`, the
   Proton Clang 13 toolchain, and that the release **does not already
   exist** (no duplicates; stops otherwise).
3. **Build** — `make O=out daisy_defconfig` (if needed) + `make -j$(nproc)
   O=out` with `CC=clang-13`, LLVM tools, `ld.lld`, cross prefixes.
4. **Verify** — checks `out/arch/arm64/boot/Image.gz-dtb` exists and prints
   the `Linux version` banner.
5. **Package** — copies `Image.gz-dtb` into `pack/ak3/` (AnyKernel3) and
   zips → `dist/DaisyForGaming_v4.9.337-DaisyForGaming.zip`.
6. **SHA-256** — `sha256sum` of the ZIP.
7. **Changelog** — commits since the last release tag (kernel-source-only),
   or the last 12 commits for the first release; override with `CHANGELOG=`.
8. **Release** — `gh release create kernel-v4.9.337-DaisyForGaming` with the
   ZIP and notes. The tag is created by `gh` itself (the script never
   force-pushes or clobbers tags).
9. **Real URLs** — fetches `html_url` and the asset's
   `browser_download_url` from the GitHub API.
10. **Manifest** — rewrites `kernel_update.json` (version, release date,
    download URL, SHA-256, release URL, changelog, `mandatory: false`),
    commits it, and pushes to `main` (never force).
11. **Summary** — prints release URL, ZIP URL, SHA-256, manifest URL.

### Safety properties

- Refuses to create a duplicate tag/release.
- No force-push anywhere; manifest push rejects safely if the remote moved.
- The kernel source is never modified by the script (build is O=out).

## Manual release fallback

If you cannot use the script (e.g. no `gh` on another machine):

```bash
# 1. build
./scripts/build_kernel.sh

# 2. package
mkdir -p dist && rm -rf .pkg && cp -r pack/ak3 .pkg
cp out/arch/arm64/boot/Image.gz-dtb .pkg/Image.gz-dtb
(cd .pkg && zip -r9q ../dist/DaisyForGaming_v4.9.337-DaisyForGaming.zip .)

# 3. checksum
sha256sum dist/DaisyForGaming_v4.9.337-DaisyForGaming.zip

# 4. release (tag exactly kernel-v4.9.337-DaisyForGaming)
gh release create kernel-v4.9.337-DaisyForGaming \
  dist/DaisyForGaming_v4.9.337-DaisyForGaming.zip \
  --title "DaisyForGaming kernel 4.9.337-DaisyForGaming" --notes "..."

# 5. update kernel_update.json with the real download URL + sha256,
#    commit, push (no force)
```

## Naming rules

- Release tag: `kernel-v<version>-<brand>` e.g. `kernel-v4.9.337-DaisyForGaming`
- ZIP: `DaisyForGaming_v<version>.zip`
- Kernel version reported on device: `<version>-DaisyForGaming` (from
  `CONFIG_LOCALVERSION`)

## CI releases (optional)

`.github/workflows/kernel-build.yml` runs a full build on every push to
`main` (validation) and, when a `kernel-v*` tag is pushed, can build and
publish a release with the CI-produced ZIP. The local
`release_kernel.sh` remains the primary, canonical release path.
