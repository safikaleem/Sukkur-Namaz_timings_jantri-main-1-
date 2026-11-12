package pk.sukkur.salah

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Handles device boot, package updates, time/timezone changes, screen unlock,
 * and live-countdown boundary ticks:
 * 1. Purges any past-due prayer alarms first so stale notifications NEVER fire
 *    on boot, update, or unlock.
 * 2. Re-arms upcoming prayer alarms on [PrayerAlarmReceiver] and promotes the
 *    soonest 4 upcoming alarms within 18 hours to AlarmManager.setAlarmClock().
 * 3. Keeps the ongoing live-countdown status bar updated at exact prayer boundaries,
 *    bootstraps it after Play Store updates (`MY_PACKAGE_REPLACED`), and restores it
 *    if accidentally swiped away on Android 13+.
 * 4. Restores the user's previous ringer mode if the device rebooted during an
 *    active Jama'at auto-silent window.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val appContext = context.applicationContext ?: context

        if (action == Intent.ACTION_USER_PRESENT) {
            // Mark active user interaction immediately on unlock so any OEM-deferred
            // alarm older than 60s is disarmed instead of dumping when unlocking/opening the phone.
            PrayerAlarmGuardian.markAppOpened()
        }

        if (action == PrayerKeepAliveService.ACTION_KEEPALIVE_TICK ||
            action == PrayerKeepAliveService.ACTION_KEEPALIVE_DISMISSED
        ) {
            val pendingResult = goAsync()
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val unlocked = PrayerAlarmGuardian.isUserUnlocked(appContext)
                    PrayerAlarmGuardian.purgeStaleAndPromoteUpcoming(
                        appContext,
                        forceReschedule = false,
                        purgeOverdueAfterMs = PrayerAlarmGuardian.MAX_BACKGROUND_LATENESS_MS
                    )
                    if (unlocked) {
                        // Launch attempts startForegroundService (allowed when woken by an exact alarm on Android 12+)
                        // and automatically falls back to refreshNotificationStatic if restricted.
                        PrayerKeepAliveService.launch(appContext)
                    }
                } finally {
                    try {
                        pendingResult.finish()
                    } catch (_: Exception) {
                    }
                }
            }
            return
        }

        val isBootOrReplace = action.contains("BOOT", ignoreCase = true) ||
            action.contains("POWERON", ignoreCase = true) ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED"
        val isTimeOrUnlock = action == Intent.ACTION_TIME_CHANGED ||
            action == "android.intent.action.TIME_SET" ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_DATE_CHANGED ||
            action == Intent.ACTION_USER_PRESENT

        if (!isBootOrReplace && !isTimeOrUnlock) {
            return
        }

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val unlocked = PrayerAlarmGuardian.isUserUnlocked(appContext)

                // Purge any stale past-due alarms and re-arm upcoming alarms (including Direct Boot
                // LOCKED_BOOT_COMPLETED via Device-Protected Storage mirror, OEM boot & time changes).
                if (isBootOrReplace ||
                    action == Intent.ACTION_TIME_CHANGED ||
                    action == "android.intent.action.TIME_SET" ||
                    action == Intent.ACTION_TIMEZONE_CHANGED
                ) {
                    PrayerAlarmGuardian.rescheduleAllSavedAlarms(appContext)
                } else {
                    val overdueCutoff = if (action == Intent.ACTION_USER_PRESENT) {
                        PrayerAlarmGuardian.APP_OPEN_OVERDUE_MS
                    } else {
                        PrayerAlarmGuardian.MAX_BACKGROUND_LATENESS_MS
                    }
                    PrayerAlarmGuardian.purgeStaleAndPromoteUpcoming(
                        appContext,
                        forceReschedule = false,
                        purgeOverdueAfterMs = overdueCutoff
                    )
                }

                if (!unlocked) return@launch

                // Bootstrap or refresh the foreground countdown service after reboot / app update,
                // or refresh its notification directly on time/unlock events.
                if (isBootOrReplace) {
                    PrayerKeepAliveService.syncFromFlutterPrefs(appContext)
                    if (PrayerKeepAliveService.isEnabled(appContext)) {
                        PrayerKeepAliveService.launch(appContext)
                    }
                } else if (PrayerKeepAliveService.isEnabled(appContext)) {
                    PrayerKeepAliveService.refreshIfRunning(appContext)
                }

                if (!isBootOrReplace) return@launch

                val prefs = appContext.getSharedPreferences("auto_silent_prefs", Context.MODE_PRIVATE)
                val appliedMode = prefs.getInt("applied_ringer_mode", -1)
                if (appliedMode == -1) return@launch // no window was active — nothing to unstick

                val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val currentMode = audioManager.ringerMode
                // Only revert if the phone is still in the mode we set (the user may have
                // changed it manually after the reboot).
                if (currentMode == appliedMode) {
                    val prevMode = prefs.getInt("previous_ringer_mode", AudioManager.RINGER_MODE_NORMAL)
                    try {
                        audioManager.ringerMode = prevMode
                        Log.d("BootReceiver", "Restored ringer mode to $prevMode after boot")
                    } catch (e: Exception) {
                        Log.e("BootReceiver", "Failed to restore ringer mode after boot: $e")
                    }
                }
                prefs.edit().remove("applied_ringer_mode").apply()
            } finally {
                try {
                    pendingResult.finish()
                } catch (_: Exception) {
                }
            }
        }
    }
}
