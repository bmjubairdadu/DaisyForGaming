package com.daisyforgaming.controller.update

import org.json.JSONObject

/**
 * Kernel update manifest served at:
 * https://raw.githubusercontent.com/bmjubairdadu/DaisyForGaming/main/kernel_update.json
 */
data class KernelUpdateManifest(
    val kernelVersion: String,
    val releaseDate: String,
    val downloadUrl: String,
    val sha256: String,
    val releaseUrl: String,
    val changelog: String,
    val mandatory: Boolean,
) {
    companion object {
        fun fromJson(raw: String): KernelUpdateManifest? = try {
            val o = JSONObject(raw)
            KernelUpdateManifest(
                kernelVersion = o.optString("kernel_version", ""),
                releaseDate = o.optString("release_date", ""),
                downloadUrl = o.optString("download_url", ""),
                sha256 = o.optString("sha256", ""),
                releaseUrl = o.optString("release_url", ""),
                changelog = o.optString("changelog", ""),
                mandatory = o.optBoolean("mandatory", false),
            )
        } catch (e: Exception) {
            null
        }
    }
}
