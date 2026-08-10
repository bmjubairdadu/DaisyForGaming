package com.daisyforgaming.controller.update

/** Helpers: reading the running kernel version and comparing versions. */
object KernelUtils {

    /** e.g. "Linux version 4.9.337-DaisyForGaming (builder@host) ..." -> "4.9.337-DaisyForGaming" */
    fun readProcVersion(): String? = try {
        val raw = java.io.File("/proc/version").readText()
        Regex("Linux version ([\\w.+-]+)").find(raw)?.groupValues?.get(1)
    } catch (e: Exception) {
        null
    }
}

object VersionComparator {

    /** True when [candidate] is strictly newer than [installed]. Tolerant of missing parts. */
    fun isNewer(candidate: String, installed: String?): Boolean {
        if (installed.isNullOrBlank()) return true
        val c = parse(candidate)
        val i = parse(installed)
        val len = maxOf(c.size, i.size)
        for (n in 0 until len) {
            val cv = c.getOrNull(n) ?: 0
            val iv = i.getOrNull(n) ?: 0
            if (cv != iv) return cv > iv
        }
        return false
    }

    /** "4.9.337-DaisyForGaming" -> [4, 9, 337, 0(DaisyForGaming)] */
    private fun parse(v: String): List<Int> =
        v.split("-", ".", "_")
            .mapNotNull { it.toIntOrNull() }
            .filterIndexed { index, _ -> index < 4 }
            .let { if (it.isEmpty()) listOf(0) else it }
}
