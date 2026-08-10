package com.daisyforgaming.controller.update

import android.content.Context
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/**
 * Fetches the kernel update manifest, verifies downloads, and tracks
 * the last known version to avoid duplicate notifications.
 *
 * The app NEVER flashes anything automatically. This class only informs
 * the user and prepares a verified ZIP; flashing happens manually in TWRP.
 */
class KernelUpdateRepository(private val context: Context) {

    private val prefs = context.getSharedPreferences("kernel_update", Context.MODE_PRIVATE)

    var manifestUrl: String = DEFAULT_MANIFEST_URL

    /** Last kernel version the user was notified about. */
    var lastNotifiedVersion: String?
        get() = prefs.getString(KEY_LAST_VERSION, null)
        set(value) = prefs.edit().putString(KEY_LAST_VERSION, value).apply()

    /** Version the app considers "installed" (read from the kernel, cached). */
    var installedKernelVersion: String?
        get() = prefs.getString(KEY_INSTALLED, null)
        set(value) = prefs.edit().putString(KEY_INSTALLED, value).apply()

    /**
     * Result of a check. NEVER triggers flashing.
     */
    sealed class CheckResult {
        data class UpdateAvailable(val manifest: KernelUpdateManifest) : CheckResult()
        object UpToDate : CheckResult()
        object NoInternet : CheckResult()
        object InvalidManifest : CheckResult()
        object ServerError(val code: Int) : CheckResult()
    }

    fun checkForUpdate(): CheckResult {
        val raw = httpGet(manifestUrl) ?: return CheckResult.NoInternet
        val manifest = KernelUpdateManifest.fromJson(raw)
            ?.takeIf { it.downloadUrl.isNotBlank() }
            ?: return CheckResult.InvalidManifest

        val installed = installedKernelVersion ?: KernelUtils.readProcVersion()
        return if (VersionComparator.isNewer(manifest.kernelVersion, installed)) {
            CheckResult.UpdateAvailable(manifest)
        } else {
            CheckResult.UpToDate
        }
    }

    sealed class DownloadResult {
        data class Success(val file: File, val sha256: String) : DownloadResult()
        data class Error(val message: String) : DownloadResult()
        object Cancelled : DownloadResult()
        object InsufficientStorage : DownloadResult()
    }

    /**
     * Downloads the release ZIP and verifies its SHA-256 against the
     * manifest. Cancellable via [isCancelled]. Never flashes.
     */
    fun downloadVerifiedZip(
        manifest: KernelUpdateManifest,
        isCancelled: () -> Boolean = { false },
        onProgress: (bytesRead: Long, totalBytes: Long) -> Unit = { _, _ -> },
    ): DownloadResult {
        if (manifest.sha256.isBlank()) {
            return DownloadResult.Error("Manifest has no sha256; refusing unverifiable download")
        }
        val dest = File(context.cacheDir, "DFG_kernel_update.zip")
        try {
            val conn = URL(manifest.downloadUrl).openConnection() as HttpURLConnection
            conn.connectTimeout = 15000
            conn.readTimeout = 30000
            conn.instanceFollowRedirects = true
            if (conn.responseCode != HttpURLConnection.HTTP_OK) {
                conn.disconnect()
                return DownloadResult.Error("HTTP ${conn.responseCode}")
            }
            val total = conn.contentLengthLong
            val available = File(context.cacheDir.parentFile ?: context.cacheDir).usableSpace
            if (total > available) return DownloadResult.InsufficientStorage

            conn.inputStream.use { input ->
                FileOutputStream(dest).use { output ->
                    val digest = MessageDigest.getInstance("SHA-256")
                    val buf = ByteArray(64 * 1024)
                    var read: Int
                    var done = 0L
                    while (input.read(buf).also { read = it } != -1) {
                        if (isCancelled()) return DownloadResult.Cancelled
                        output.write(buf, 0, read)
                        digest.update(buf, 0, read)
                        done += read
                        onProgress(done, total)
                    }
                    val actual = digest.digest().joinToString("") { "%02x".format(it) }
                    if (!actual.equals(manifest.sha256, ignoreCase = true)) {
                        dest.delete()
                        return DownloadResult.Error(
                            "SHA-256 mismatch\nmanifest: ${manifest.sha256}\nactual:   $actual"
                        )
                    }
                    return DownloadResult.Success(dest, actual)
                }
            }
        } catch (e: IOException) {
            dest.delete()
            return DownloadResult.Error(e.message ?: "IO error")
        }
    }

    private fun httpGet(url: String): String? {
        return try {
            val conn = URL(url).openConnection() as HttpURLConnection
            conn.connectTimeout = 15000
            conn.readTimeout = 15000
            conn.setRequestProperty("Accept", "application/json")
            if (conn.responseCode != HttpURLConnection.HTTP_OK) return null
            conn.inputStream.use { it.readBytes().toString(Charsets.UTF_8) }
        } catch (e: Exception) {
            null
        }
    }

    companion object {
        const val DEFAULT_MANIFEST_URL =
            "https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json"
        private const val KEY_LAST_VERSION = "last_notified_version"
        private const val KEY_INSTALLED = "installed_kernel_version"
    }
}
