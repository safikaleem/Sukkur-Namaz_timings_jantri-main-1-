package pk.sukkur.salah

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.text.Html
import android.util.Log
import androidx.core.app.NotificationCompat
import com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject

/**
 * Native alarm receiver that intercepts all scheduled prayer and reminder alarms.
 *
 * Why this exists instead of sending AlarmManager intents directly to
 * [ScheduledNotificationReceiver]:
 * 1. Partial WakeLock + goAsync(): acquires a 30-second CPU wake lock on alarm wake
 *    and uses [goAsync] so Android 12–16 Cached App Freezer and deep Doze cannot
 *    suspend or freeze the process while SystemServer / RingtonePlayer loads and
 *    plays the Azan audio and chains the next alarm.
 * 2. Smart staleness & app-open filter:
 *    - When the user is actively opening/unlocking the phone ([PrayerAlarmGuardian.isAppRecentlyOpened]),
 *      any overdue alarm >60s old is suppressed so OEM-deferred alarms never dump on app open.
 *    - When waking in the background (phone locked / in pocket), notifications delayed up to
 *      15 minutes by OEM Doze or inexact fallback are delivered; if delayed >3 minutes, Azan
 *      audio is automatically downgraded to vibrate so an Azan never rings late.
 * 3. Direct Boot support: if the phone restarted overnight and is still on the post-reboot
 *    PIN/Pattern lock screen (LOCKED_BOOT_COMPLETED), posts the Fajr notification directly
 *    without touching credential-encrypted SharedPreferences.
 * 4. Native alarm-clock chaining: as soon as an alarm fires, the next upcoming prayer
 *    alarm in the queue is immediately promoted into the 4-slot AlarmManager.setAlarmClock()
 *    window in native Kotlin, so the 14-day schedule continues firing on time even if
 *    Flutter/WorkManager is never allowed to run in the background.
 */
class PrayerAlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "PrayerAlarmReceiver"

        const val EXTRA_SCHEDULED_EPOCH_MS = "scheduledEpochMs"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_IS_REPEATING = "is_repeating"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext ?: context
        val pm = appContext.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = pm?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "sukkursalah:prayer_alarm_wakelock"
        )?.apply {
            setReferenceCounted(false)
            // Hold CPU awake for 30 seconds so NotificationManager / RingtonePlayer
            // can start and sustain Azan audio playback before Doze can re-suspend the device.
            acquire(30_000L)
        }
        val pendingResult = goAsync()

        CoroutineScope(Dispatchers.IO).launch {
            var releaseImmediately = false
            try {
                val detailsJson = intent.getStringExtra("notificationDetails")
                val id = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
                val isRepeating = intent.getBooleanExtra(EXTRA_IS_REPEATING, false)
                val realScheduledEpochMs = PrayerAlarmGuardian.extractEpochMsFromDetailsJson(detailsJson)
                    ?: intent.getLongExtra(EXTRA_SCHEDULED_EPOCH_MS, -1L).takeIf { it > 0L }
                    ?: -1L

                val now = System.currentTimeMillis()
                val latenessMs = if (realScheduledEpochMs > 0L) (now - realScheduledEpochMs) else 0L
                val appOpen = PrayerAlarmGuardian.isAppRecentlyOpened()
                val maxAllowedLatenessMs = if (appOpen) {
                    PrayerAlarmGuardian.APP_OPEN_OVERDUE_MS
                } else {
                    PrayerAlarmGuardian.MAX_BACKGROUND_LATENESS_MS
                }

                if (realScheduledEpochMs > 0L && latenessMs > maxAllowedLatenessMs) {
                    Log.w(
                        TAG,
                        "Suppressing stale prayer alarm id=$id repeating=$isRepeating appOpen=$appOpen (late by ${latenessMs / 1000}s)"
                    )
                    releaseImmediately = true
                    if (id >= 0) {
                        PrayerAlarmGuardian.onAlarmDispatched(appContext, id, isRepeating)
                    }
                    PrayerAlarmGuardian.purgeStaleAndPromoteUpcoming(
                        appContext,
                        forceReschedule = false,
                        ignoreBatchInProgress = true
                    )
                    return@launch
                }

                // Prepare the display intent for ScheduledNotificationReceiver:
                // 1. Strip repeating keys from the display-only copy of notificationDetails so
                //    FlutterLocalNotificationsPlugin.scheduleNextNotification() NEVER calls
                //    zonedScheduleNotification() in Java (which would arm a raw legacy alarm or
                //    delete the repeating reminder on ExactAlarmPermissionException).
                // 2. If a background alarm was delayed >3m (up to 15m) by OEM Doze,
                //    downgrade loud Azan audio to vibrate so the alert arrives without late Azan audio.
                val downgradeToVibrate = !isRepeating && latenessMs > PrayerAlarmGuardian.MAX_AZAN_AUDIO_LATENESS_MS
                val effectiveIntent = prepareDisplayIntent(intent, detailsJson, downgradeToVibrate)

                val unlocked = PrayerAlarmGuardian.isUserUnlocked(appContext)
                PrayerAlarmGuardian.isReceiverDispatching = true
                try {
                    // Snapshot scheduled_notifications BEFORE ScheduledNotificationReceiver.onReceive()
                    // runs so its internal removeNotificationFromCache() Gson write cannot race with Guardian.
                    val preDispatchScheduleJson = if (unlocked) {
                        PrayerAlarmGuardian.snapshotScheduleJson(appContext)
                    } else {
                        null
                    }

                    if (unlocked) {
                        ScheduledNotificationReceiver().onReceive(appContext, effectiveIntent)
                    } else {
                        // Direct Boot mode (phone rebooted overnight and is still on the lock screen):
                        // post notification directly without credential-encrypted SharedPreferences.
                        postDirectBootNotification(appContext, id, effectiveIntent.getStringExtra("notificationDetails"))
                    }

                    if (id >= 0) {
                        PrayerAlarmGuardian.onAlarmDispatched(
                            context = appContext,
                            targetId = id,
                            isRepeating = isRepeating,
                            preDispatchScheduleJson = preDispatchScheduleJson
                        )
                    }

                    // Immediately promote the next upcoming prayer into the setAlarmClock() window
                    PrayerAlarmGuardian.purgeStaleAndPromoteUpcoming(
                        appContext,
                        forceReschedule = false,
                        ignoreBatchInProgress = true
                    )
                } finally {
                    PrayerAlarmGuardian.isReceiverDispatching = false
                }

                // Refresh (or restart under exact-alarm FGS exemption) the live countdown service
                if (unlocked && PrayerKeepAliveService.isEnabled(appContext)) {
                    PrayerKeepAliveService.launch(appContext)
                }
            } catch (e: Exception) {
                releaseImmediately = true
                Log.e(TAG, "Error handling prayer alarm: $e")
            } finally {
                if (releaseImmediately) {
                    try {
                        if (wakeLock?.isHeld == true) {
                            wakeLock.release()
                        }
                    } catch (_: Exception) {
                    }
                }
                try {
                    pendingResult.finish()
                } catch (_: Exception) {
                }
            }
        }
    }

    private fun prepareDisplayIntent(
        originalIntent: Intent,
        detailsJson: String?,
        downgradeToVibrate: Boolean,
    ): Intent {
        if (detailsJson.isNullOrEmpty()) return originalIntent
        return try {
            val obj = JSONObject(detailsJson)
            // Prevent FlutterLocalNotificationsPlugin.scheduleNextNotification() from re-scheduling
            // or deleting repeating notifications in Java; PrayerAlarmGuardian.onAlarmDispatched()
            // exclusively manages repeating and one-shot schedule state.
            obj.remove("matchDateTimeComponents")
            obj.remove("scheduledNotificationRepeatFrequency")
            obj.remove("repeatInterval")
            obj.remove("repeatIntervalMilliseconds")

            if (downgradeToVibrate) {
                obj.put("playSound", false)
                obj.put("enableVibration", true)
                obj.put("channelId", "namaz_vibrate_v6")
                obj.put("channelName", "نماز وائبریشن")
                obj.remove("sound")
            }
            Intent(originalIntent).apply {
                putExtra("notificationDetails", obj.toString())
            }
        } catch (_: Exception) {
            originalIntent
        }
    }

    private fun postDirectBootNotification(context: Context, fallbackId: Int, detailsJson: String?) {
        if (detailsJson.isNullOrEmpty()) return
        try {
            val obj = JSONObject(detailsJson)
            val notifId = obj.optInt("id", fallbackId).takeIf { it >= 0 } ?: return
            val rawTitle = obj.optString("title", "Sukkur Salah")
            val rawBody = obj.optString("body", "")
            val channelId = obj.optString("channelId", "namaz_loud_bell_v7")
            val channelName = obj.optString("channelName", "نماز کے اوقات")
            val playSound = obj.optBoolean("playSound", true)
            val soundName = obj.optString("sound", "mixkit_bell_notification_933")

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(channelId) == null) {
                val ch = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH).apply {
                    enableVibration(true)
                    if (playSound && soundName.isNotEmpty()) {
                        val uri = Uri.parse("android.resource://${context.packageName}/raw/$soundName")
                        val attrs = AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .build()
                        setSound(uri, attrs)
                    }
                }
                nm.createNotificationChannel(ch)
            }

            val titleSeq = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                Html.fromHtml(rawTitle, Html.FROM_HTML_MODE_LEGACY)
            } else {
                @Suppress("DEPRECATION")
                Html.fromHtml(rawTitle)
            }
            val bodySeq = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                Html.fromHtml(rawBody, Html.FROM_HTML_MODE_LEGACY)
            } else {
                @Suppress("DEPRECATION")
                Html.fromHtml(rawBody)
            }

            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.drawable.ic_notification)
                .setColor(0xFF0D6B5E.toInt())
                .setContentTitle(titleSeq)
                .setContentText(bodySeq)
                .setStyle(NotificationCompat.BigTextStyle().bigText(bodySeq))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)

            nm.notify(notifId, builder.build())
        } catch (e: Exception) {
            Log.e(TAG, "postDirectBootNotification failed: $e")
        }
    }
}
