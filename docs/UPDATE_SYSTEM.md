# UPDATE SYSTEM

How kernel updates are published and how DFG Controller learns about them.

## The chain

```text
release_kernel.sh
      ↓
GitHub Release (tag kernel-v<version>-DaisyForGaming)
      ↓
Kernel ZIP asset  +  SHA-256
      ↓
kernel_update.json  ← committed & pushed to main
      ↓
https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json
      ↓
DFG Controller (app)
      ↓
notification → download → SHA-256 verify
      ↓
user flashes manually in TWRP (never automatic)
```

## The manifest

`kernel_update.json` at the repository root is the single source of truth
for the app-side update check. Current fields:

| Field | Meaning |
| ----- | ------- |
| `kernel_version` | e.g. `4.9.337-DaisyForGaming` (what the kernel reports via `uname -r`) |
| `release_date` | ISO date of the release |
| `download_url` | `browser_download_url` of the GitHub Release ZIP asset |
| `sha256` | SHA-256 of the release ZIP (app verifies downloads against this) |
| `release_url` | GitHub Release page |
| `changelog` | Release notes |
| `mandatory` | `false` today; if set to `true` the app shows a prominent "required update" warning (still never auto-flashes) |

## How DFG Controller checks

The checker module lives in [`DFGController-update-checker/`](../DFGController-update-checker/)
and is designed as a drop-in for the DFG Controller app:

1. **Fetch** the manifest (with connect/read timeouts; failures are handled).
2. **Compare** the remote `kernel_version` against the installed kernel
   version (read from `/proc/version`, cached).
3. **Notify** the user with version, release date, changelog (and a
   `[REQUIRED UPDATE]` banner when `mandatory`).
4. **Download** the ZIP and verify **SHA-256** against the manifest — any
   mismatch deletes the file and warns the user.
5. **Store** the verified ZIP and point the user at the manual TWRP flash.

Scheduling: a **WorkManager** worker runs once per 24h (network-required
constraint), plus a startup check and a manual "Check for kernel updates"
trigger. The last notified version is cached so users are not spammed.

## What is deliberately NOT implemented

- **Automatic flashing** — the app never flashes, never runs root shell
  flashing commands, never writes partitions. The one safety checkpoint
  (user confirming in TWRP) is preserved by design.
- **Auto-download** without user action.
- **Bypassing** checksum verification.

## How a new update reaches users

1. Maintainer runs `./scripts/release_kernel.sh` (see
   [RELEASE_PROCESS.md](RELEASE_PROCESS.md)).
2. It builds, packages, computes SHA-256, creates the GitHub Release with
   the ZIP, and updates + pushes `kernel_update.json`.
3. Within 24h (or on next app launch / manual check) the app notifies users.

## Troubleshooting the update check

| Symptom | Likely cause | Action |
| ------- | ------------ | ------ |
| No notification | No internet, or version unchanged (cache) | Manual "Check for kernel updates" |
| Invalid JSON / manifest error | `kernel_update.json` broken or URL wrong | Verify the raw URL returns valid JSON |
| Download fails | `download_url` stale (asset moved/deleted) | Re-run release script so manifest matches the release |
| Checksum mismatch | Corrupt download or tampered file | App deletes the file and warns; redownload from the release page |
