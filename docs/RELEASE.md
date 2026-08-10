# Release process

```bash
./scripts/release_kernel.sh
```

or with a custom changelog:

```bash
CHANGELOG="Added zRAM, BBR, fixed proximity sensor bug" ./scripts/release_kernel.sh
```

## What it does

1. Reads `VERSION`/`PATCHLEVEL`/`SUBLEVEL`/`EXTRAVERSION` from `Makefile`
   (currently `4.9.337`) → full name `4.9.337-DaisyForGaming`
2. Builds with the project toolchain (Proton Clang 13, `O=out`,
   `daisy_defconfig`, `make -j$(nproc)`)
3. Packages a flashable **AnyKernel3** ZIP from `pack/ak3` + fresh
   `Image.gz-dtb` → `dist/DaisyForGaming_v4.9.337-DaisyForGaming.zip`
4. Computes SHA-256
5. Creates tag `kernel-v4.9.337-DaisyForGaming` (pushes it)
6. Creates the GitHub Release with the ZIP (changelog = commits since the
   last tag, or the first 12 commits for the very first release)
7. Fetches the **real** `browser_download_url` from the GitHub API
8. Rewrites `kernel_update.json` with real values and commits + pushes it
9. Prints the release summary

## Safety rules

- **No duplicates:** if the tag or release already exists, the script stops.
- **No force-push** anywhere.
- The manifest commit is the only thing pushed to `main`; release code is
  tagged via the lightweight tag, not a force-pushed branch.

## Manual steps for a release (what the script cannot do)

1. `gh auth login` must be valid for `bmjubairdadu`
2. The repo `bmjubairdadu/DaisyForGaming` must exist (create once on GitHub)
3. `pack/ak3` must be the daisy-configured AnyKernel3 template
4. The release ZIP is flashed manually in TWRP by the user — the script only
   publishes it.
