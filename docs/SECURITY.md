# SECURITY

What this project does (and does not) guarantee about integrity, updates,
and secrets.

## Source integrity

- All source is in the public repository; every change is history-tracked
  on the `main` branch with readable commit messages.
- The repository contains **no credentials, tokens, signing keys, or
  private keys**. The sync tooling actively scans staged content for secret
  patterns and aborts if anything is found
  (`scripts/sync_to_github.sh`).
- CI (`.github/workflows/kernel-build.yml`) uses only the automatic
  `GITHUB_TOKEN` scoped to the workflow run — no secrets are stored in the
  repository settings.

## Release model

- Releases are published as **GitHub Releases** with a version tag
  (`kernel-v<version>-DaisyForGaming`) and the flashable ZIP as an asset.
- Each release ships a **SHA-256** in the release notes and in
  `kernel_update.json`.

## Verifying a release (user side)

```sh
curl -sL -o k.zip https://github.com/bmjubairdadu/DaisyForGaming/releases/download/<tag>/<zip>
sha256sum k.zip          # compare with the manifest's "sha256" field
curl -s https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json
```

## Safe update behavior (DFG Controller)

- The app **only** notifies, downloads, and verifies the SHA-256.
- The app **never** flashes automatically, never runs root shell flashing
  commands, and never writes partitions.
- Flashing is always a manual, user-confirmed TWRP action — the one safety
  checkpoint that prevents an unattended bad flash from bricking the device.
- A `mandatory: true` flag is supported and surfaced as a warning, but it
  never enables automatic flashing.

## Risks

- **Flashing an incompatible kernel** (wrong device, wrong Android base,
  tampered ZIP) can make the device unbootable. The installer device-checks
  for `daisy`, and the app checksum-verifies downloads — but no system can
  protect against a user flashing a modified/broken image deliberately.
- **Backup/rollback is your safety net:** always keep a TWRP Boot backup
  and a known-good boot image before flashing (see
  [INSTALLATION.md](INSTALLATION.md)).

## Reporting vulnerabilities

- Open an issue (mark it private/sensitive if GitHub lets you) or contact
  the maintainer through the repository.
- Include: affected subsystem, kernel version, device, steps, and impact.
- Do **not** post credentials or exploit code publicly in issues.

## What this project does NOT claim

- No code signing of kernel images (this would require storing signing keys,
  which is deliberately avoided).
- No guaranteed resistance to determined tampering of the published ZIPs
  beyond SHA-256 verification against the manifest.
- No guarantee that flashing is safe on untested devices/ROMs.
