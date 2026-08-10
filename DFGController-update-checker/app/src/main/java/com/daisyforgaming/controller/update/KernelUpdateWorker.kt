package com.daisyforgaming.controller.update

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Daily kernel update check (WorkManager, once per 24h, network-required).
 * Only notifies — it never downloads/flashes automatically.
 */
class KernelUpdateWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val repo = KernelUpdateRepository(applicationContext)
        when (val result = repo.checkForUpdate()) {
            is KernelUpdateRepository.CheckResult.UpdateAvailable -> {
                if (repo.lastNotifiedVersion != result.manifest.kernelVersion) {
                    repo.lastNotifiedVersion = result.manifest.kernelVersion
                    showNotification(result.manifest)
                }
            }
            else -> { /* no update / transient failure - try again next cycle */ }
        }
        return Result.success()
    }

    private fun showNotification(manifest: KernelUpdateManifest) {
        val nm = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "Kernel updates", NotificationManager.IMPORTANCE_HIGH)
            )
        }
        val openApp = PendingIntent.getActivity(
            applicationContext, 0, Intent(applicationContext, UPDATE_SCREEN_ACTIVITY_CLASS),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val mandatory = if (manifest.mandatory) "\n[REQUIRED UPDATE - please update soon]" else ""
        val n = NotificationCompat.Builder(applicationContext, CHANNEL)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle("Kernel update: ${manifest.kernelVersion}")
            .setContentText("New kernel ${manifest.kernelVersion} (${manifest.releaseDate})$mandatory")
            .setStyle(NotificationCompat.BigTextStyle().bigText(manifest.changelog.ifBlank { "See release notes." }))
            .setAutoCancel(true)
            .setContentIntent(openApp)
            .build()
        nm.notify(1001, n)
    }

    companion object {
        private const val CHANNEL = "kernel_updates"
        private const val WORK_NAME = "dfg_kernel_update_check"

        /** Point this at your activity that shows the update card. */
        private val UPDATE_SCREEN_ACTIVITY_CLASS: Class<*> = Class.forName(
            "com.daisyforgaming.controller.KernelUpdateActivity"
        )

        fun schedule(context: Context) {
            val req = PeriodicWorkRequestBuilder<KernelUpdateWorker>(24, TimeUnit.HOURS)
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, req)
        }

        /** Run once now (app launch / manual "Check for updates"). */
        fun checkNow(context: Context) {
            WorkManager.getInstance(context).enqueue(OneTimeWorkRequestBuilder())
        }
    }
}

private fun OneTimeWorkRequestBuilder(): androidx.work.OneTimeWorkRequest.Builder =
    androidx.work.OneTimeWorkRequestBuilder<KernelUpdateWorker>()
