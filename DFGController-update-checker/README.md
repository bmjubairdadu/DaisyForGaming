# DFG Controller - kernel update checker module

Drop-in module for the **DFG Controller** Android app. Checks the kernel update
manifest, notifies the user, downloads + verifies the ZIP. **Never flashes.**

Manifest:
https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json

## Files

| File | Purpose |
|---|---|
| `KernelUpdateManifest.kt` | Manifest data class + JSON parser (org.json, no extra deps) |
| `KernelUpdateRepository.kt` | Fetch/compare, SHA-256 verified download, last-version cache |
| `KernelUtils.kt` | `/proc/version` reader + version comparison |
| `KernelUpdateWorker.kt` | WorkManager worker: periodic 24h check + notification |

## Integration

1. Copy the 4 files into your app (e.g. `com.daisyforgaming.controller.update`).
2. Add dependencies in `build.gradle`:
   ```gradle
   implementation "androidx.work:work-runtime-ktx:2.9.1"
   implementation "androidx.core:core-ktx:1.13.1"
   ```
3. Add a `KernelUpdateActivity` (or point `UPDATE_SCREEN_ACTIVITY_CLASS` at your
   existing settings/update screen).
4. Schedule checks (startup + manual + periodic are all supported):
   ```kotlin
   // once at app startup (Application.onCreate or MainActivity.onCreate):
   KernelUpdateWorker.schedule(this)   // periodic 24h
   KernelUpdateWorker.checkNow(this)   // immediate one-shot

   // manual "Check for kernel updates" button tap:
   KernelUpdateWorker.checkNow(this)
   ```
5. In-app card (manual flow, no WorkManager needed):
   ```kotlin
   val repo = KernelUpdateRepository(applicationContext)
   when (val r = repo.checkForUpdate()) {
       is KernelUpdateRepository.CheckResult.UpdateAvailable -> showCard(r.manifest)
       KernelUpdateRepository.CheckResult.UpToDate -> showUpToDate()
       else -> showError()
   }

   // user taps "Download & verify":
   when (val d = repo.downloadVerifiedZip(manifest)) {
       is KernelUpdateRepository.DownloadResult.Success -> {
           // verified ZIP at d.file — offer the guided flash steps:
           //   1. backup boot:  dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/DFG_backups/boot_backup.img
           //   2. copy zip to /sdcard/DFG_kernel_update.zip
           //   3. reboot to recovery and flash via TWRP Install (manual swipe)
       }
       is KernelUpdateRepository.DownloadResult.Error -> warn(d.message)
       KernelUpdateRepository.DownloadResult.InsufficientStorage -> warn("Not enough storage")
       KernelUpdateRepository.DownloadResult.Cancelled -> Unit
   }
   ```

## Behavior / safety contract

- Checks are throttled: periodic worker runs once per 24h; the last notified
  version is cached so you never get duplicate notifications.
- All errors handled: no internet, invalid JSON, HTTP errors, missing sha256,
  cancelled download, insufficient storage, SHA-256 mismatch (file deleted).
- `mandatory: true` in the manifest adds a prominent warning to the
  notification/card — but still never auto-flashes.
- Nothing here executes shell commands, requests root, or writes to any
  partition. Flashing remains a fully manual TWRP action by the user.
