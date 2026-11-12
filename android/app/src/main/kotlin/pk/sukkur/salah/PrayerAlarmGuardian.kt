package pk.sukkur.salah

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.os.UserManager
import android.util.Log
import androidx.core.app.AlarmManagerCompat
import com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

/**
 * Native alarm guardian that solves the root causes of missed, delayed, and
 * "only arrives when opening the app" prayer notifications on Android:
 *
 * 1. Intercepts all alarms via [PrayerAlarmReceiver] instead of [ScheduledNotificationReceiver]:
 *    - Cancels raw [ScheduledNotificationReceiver] PendingIntents created by
 *      flutter_local_notifications and replaces upcoming ones with [PrayerAlarmReceiver],
 *      which enforces a strict staleness filter and holds a 10s partial WakeLock for Azan audio.
 *    - Protects on-time alarms that are currently firing (within the grace window) so cold-start
 *      [MainApplication.onCreate], [PrayerKeepAliveService], or SCREEN_ON ticks NEVER cancel an
 *      alarm right as it is waking the CPU.
 *    - Cancels overdue alarms via AlarmManager.cancel() ONLY (never NotificationManager.cancel()),
 *      so already-delivered notifications in the user's status bar / lock screen are never erased.
 *
 * 2. Capped Rolling Window + Chained AlarmClock Promotion:
 *    - Registering 140 simultaneous alarms in AlarmManager triggers OEM alarm-quota throttling
 *      on Xiaomi (MIUI/HyperOS), Vivo, Oppo/Realme (ColorOS), Samsung, and Infinix/Tecno.
 *    - Here, only the soonest 20 upcoming alarms (~48 hours) are armed in the OS kernel at once:
 *      the soonest 4 within 24 hours via AlarmManagerCompat.setAlarmClock() (with a valid
 *      Activity showIntent), and the next 16 via setExactAndAllowWhileIdle() with
 *      Intent.FLAG_RECEIVER_FOREGROUND for high-priority foreground broadcast delivery.
 *    - All 14 days (~140 entries) remain persisted in SharedPreferences; as each prayer fires in
 *      [PrayerAlarmReceiver], the rolling window and 4-alarm AlarmClock chain advance automatically.
 */
object PrayerAlarmGuardian {
    private const val TAG = "PrayerAlarmGuardian"
    private const val SCHEDULED_PREFS = "scheduled_notifications"
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val GUARDIAN_PREFS = "prayer_guardian_prefs"
    private const val KEY_ARMED_IDS = "armed_ids"
    private const val KEY_ARMED_SIGNATURES = "armed_signatures"
    private const val KEY_LAST_LEGACY_SWEEP_HASH = "last_legacy_sweep_hash"
    private const val NOTIFICATION_DETAILS_EXTRA = "notificationDetails"

    /**
     * Maximum lateness (15 minutes) allowed when an alarm wakes the device in the background
     * while the screen is locked and the user is NOT unlocking/opening the app.
     */
    const val MAX_BACKGROUND_LATENESS_MS = 15L * 60L * 1000L
    const val MAX_STALE_LATENESS_MS = MAX_BACKGROUND_LATENESS_MS

    /**
     * Maximum lateness (3 minutes) for playing loud Azan audio in the background.
     * If a background alarm is delayed by 3–15 minutes due to extreme OEM Doze or inexact mode,
     * the visual/vibrate notification is still delivered, but loud Azan audio is muted so Azan
     * never rings at the wrong time.
     */
    const val MAX_AZAN_AUDIO_LATENESS_MS = 3L * 60L * 1000L

    /** Tighter overdue threshold (60 seconds) used when the user unlocks the phone or opens the app. */
    const val APP_OPEN_OVERDUE_MS = 60L * 1000L

    /**
     * Maximum window (60 seconds) after a prayer minute boundary during which an un-armed
     * notification in `scheduled_notifications` may be armed for immediate (`now + 500ms`) delivery
     * (e.g. when a Dart batch write finishes 1–3 seconds after the minute boundary).
     */
    private const val ON_TIME_CATCHUP_WINDOW_MS = 60L * 1000L

    /**
     * Minimum remaining one-shot alarms (~3 days) before native self-healing rolls fired alarms
     * forward so the schedule never runs dry if an OEM blocks WorkManager for >11 days.
     */
    private const val MIN_SELF_HEALING_QUEUE_SIZE = 30

    /**
     * Promote the soonest 4 upcoming alarms within 24 hours to hardware RTC AlarmClock.
     * Staying at 4 avoids OEM setAlarmClock() rate-limiting on MIUI, ColorOS, Vivo & Transsion,
     * while PrayerAlarmReceiver automatically chains the next alarm as each prayer fires.
     */
    private const val MAX_ALARM_CLOCK_COUNT = 4
    private const val ALARM_CLOCK_HORIZON_MS = 24L * 60L * 60L * 1000L

    /** Maximum total alarms armed in the OS AlarmManager kernel at one time (~48 hours). */
    private const val MAX_KERNEL_ARMED_ALARMS = 24

    /** Tracks the last JSON written/verified by the guardian so MainApplication's listener ignores self-writes. */
    @Volatile
    var lastGuardianJson: String? = null

    /** True while PrayerAlarmReceiver is actively dispatching an alarm so MainApplication ignores intermediate Gson writes. */
    @Volatile
    var isReceiverDispatching: Boolean = false

    /** Timestamp (elapsedRealtime) when the user last opened/resumed/paused MainActivity. */
    @Volatile
    private var lastAppOpenElapsedMs: Long = 0L

    /** Number of currently started (visible) Activities so foreground state never expires after 15s while using the app. */
    @Volatile
    private var activeActivityCount: Int = 0

    /** In-memory signature cache ("mode:epochMs:hash") to avoid redundant AlarmManager binder calls on SCREEN_ON. */
    private val lastArmedSignature = HashMap<Int, String>()

    private data class UpcomingEntry(
        val id: Int,
        val epochMs: Long,
        val isRepeating: Boolean,
        val detailsJson: String,
    )

    fun markAppOpened() {
        lastAppOpenElapsedMs = SystemClock.elapsedRealtime()
    }

    fun onActivityStarted() {
        activeActivityCount = (activeActivityCount + 1).coerceAtLeast(1)
        lastAppOpenElapsedMs = SystemClock.elapsedRealtime()
    }

    fun onActivityStopped() {
        activeActivityCount = (activeActivityCount - 1).coerceAtLeast(0)
        lastAppOpenElapsedMs = SystemClock.elapsedRealtime()
    }

    fun isAppRecentlyOpened(): Boolean {
        if (activeActivityCount > 0) return true
        val last = lastAppOpenElapsedMs
        return last > 0L && (SystemClock.elapsedRealtime() - last) < 15_000L
    }

    /** Returns true while Dart's _scheduleWeeklyNotificationsCore loop is actively mid-flight writing alarms. */
    fun isDartBatchInProgress(context: Context): Boolean {
        return try {
            val fp = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val inProgress = fp.getBoolean("flutter.alarm_batch_in_progress", false)
            if (!inProgress) return false
            val startedAt = fp.getLong("flutter.alarm_batch_started_at", 0L)
            // Dart updates alarm_batch_started_at on every day iteration; if >3s elapsed,
            // the Dart isolate was paused/backgrounded so Guardian must not wait.
            startedAt > 0L && (System.currentTimeMillis() - startedAt) < 3_000L
        } catch (_: Exception) {
            false
        }
    }

    /** Returns false while the device is still on the post-reboot PIN/Pattern lock screen (Direct Boot). */
    fun isUserUnlocked(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val um = context.getSystemService(Context.USER_SERVICE) as? UserManager
            return um?.isUserUnlocked ?: true
        }
        return true
    }

    /**
     * Returns Device-Protected Storage context on Android 7.0+ so we can mirror the schedule cache
     * and arm Fajr / upcoming alarms during Direct Boot (LOCKED_BOOT_COMPLETED) after overnight reboots.
     */
    private fun deviceProtectedContext(context: Context): Context {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            context.applicationContext.createDeviceProtectedStorageContext()
        } else {
            context.applicationContext
        }
    }

    private fun mirrorToDeviceProtectedStorage(
        context: Context,
        scheduleJson: String?,
        armedSet: Set<String>?,
        sigSet: Set<String>? = null,
        legacySweepHash: Int? = null,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        try {
            val dpCtx = deviceProtectedContext(context)
            if (scheduleJson != null) {
                dpCtx.getSharedPreferences(SCHEDULED_PREFS, Context.MODE_PRIVATE)
                    .edit()
                    .putString(SCHEDULED_PREFS, scheduleJson)
                    .apply()
            }
            if (armedSet != null || sigSet != null || legacySweepHash != null) {
                val ed = dpCtx.getSharedPreferences(GUARDIAN_PREFS, Context.MODE_PRIVATE).edit()
                if (armedSet != null) ed.putStringSet(KEY_ARMED_IDS, armedSet)
                if (sigSet != null) ed.putStringSet(KEY_ARMED_SIGNATURES, sigSet)
                if (legacySweepHash != null) ed.putInt(KEY_LAST_LEGACY_SWEEP_HASH, legacySweepHash)
                ed.apply()
            }
        } catch (_: Exception) {
        }
    }

    /** Extracts the scheduled epoch milliseconds from a notificationDetails JSON string. */
    fun extractEpochMsFromDetailsJson(detailsJson: String?): Long? {
        if (detailsJson.isNullOrEmpty()) return null
        return try {
            parseScheduledEpochMs(JSONObject(detailsJson))
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Called by [PrayerAlarmReceiver] after an alarm has been displayed.
     *
     * [preDispatchScheduleJson] is the snapshot of `scheduled_notifications` taken right before
     * `ScheduledNotificationReceiver.onReceive()` ran, so we are completely immune to
     * `FlutterLocalNotificationsPlugin` mutating or deleting entries during `onReceive`.
     */
    @Synchronized
    fun onAlarmDispatched(
        context: Context,
        targetId: Int,
        isRepeating: Boolean,
        preDispatchScheduleJson: String? = null,
    ) {
        lastArmedSignature.remove(targetId)
        val unlocked = isUserUnlocked(context)
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            cancelLegacyPendingAlarm(context, alarmManager, targetId)
            cancelGuardianPendingAlarm(context, alarmManager, targetId)

            val storageCtx = if (unlocked) context else deviceProtectedContext(context)
            val prefs = storageCtx.getSharedPreferences(SCHEDULED_PREFS, Context.MODE_PRIVATE)
            val raw = preDispatchScheduleJson ?: prefs.getString(SCHEDULED_PREFS, null) ?: return
            val arr = JSONArray(raw)
            val kept = JSONArray()
            val now = System.currentTimeMillis()
            val shouldSelfHealOneShot = !isRepeating && arr.length() <= MIN_SELF_HEALING_QUEUE_SIZE
            var changed = false

            for (i in 0 until arr.length()) {
                val item = arr.optJSONObject(i) ?: continue
                if (item.optInt("id", -1) == targetId) {
                    changed = true
                    if (isRepeating) {
                        // Advance repeating alarm by at least now + 60s so even if triggered
                        // slightly early, it always rolls to tomorrow / next week.
                        rollRepeatingDateTimeForward(item, now + 60_000L)
                        kept.put(item)
                    } else if (shouldSelfHealOneShot) {
                        // Fallback self-healing when OEM blocked WorkManager for >11 days:
                        // roll this prayer slot forward by +3 days so the queue never runs dry.
                        val rolled = rollOneShotDateTimeForwardDays(item, now, 3)
                        if (rolled != null) {
                            kept.put(item)
                        }
                    }
                    continue
                }
                kept.put(item)
            }
            if (changed || preDispatchScheduleJson != null) {
                val newJson = kept.toString()
                lastGuardianJson = newJson
                prefs.edit().putString(SCHEDULED_PREFS, newJson).apply()
                if (unlocked) {
                    mirrorToDeviceProtectedStorage(context, newJson, null)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "onAlarmDispatched failed for $targetId: $e")
        }
    }

    /** Called by [PrayerAlarmReceiver] after a one-shot alarm has been displayed on time. */
    @Synchronized
    fun onOneShotAlarmDispatched(context: Context, targetId: Int) {
        onAlarmDispatched(context, targetId, isRepeating = false, preDispatchScheduleJson = null)
    }

    fun snapshotScheduleJson(context: Context): String? {
        return try {
            val storageCtx = if (isUserUnlocked(context)) context else deviceProtectedContext(context)
            storageCtx.getSharedPreferences(SCHEDULED_PREFS, Context.MODE_PRIVATE)
                .getString(SCHEDULED_PREFS, null)
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Immediately disarms the most recently appended [ScheduledNotificationReceiver] PendingIntent
     * from [AlarmManager] as each `zonedSchedule` write lands in `scheduled_notifications`.
     *
     * Why this is critical: `FlutterLocalNotificationsPlugin.zonedSchedule()` appends each new
     * notification at the end of the JSON array and arms a raw [ScheduledNotificationReceiver]
     * alarm in [AlarmManager]. Disarming that raw alarm on the spot ensures the OS kernel NEVER
     * accumulates 140+ simultaneous alarms during a batch loop (which would trigger OEM
     * alarm-quota throttling on Xiaomi, Oppo/Realme, Vivo, and Samsung).
     */
    fun disarmLatestLegacyAlarmFromJson(context: Context, rawJson: String?) {
        if (rawJson.isNullOrEmpty()) return
        try {
            val tailStart = (rawJson.length - 2048).coerceAtLeast(0)
            val tail = rawJson.substring(tailStart)
            val keyIdx = tail.lastIndexOf("\"id\":")
            if (keyIdx < 0) return
            var i = keyIdx + 5
            while (i < tail.length && tail[i].isWhitespace()) i++
            val numStart = i
            while (i < tail.length && tail[i].isDigit()) i++
            if (i > numStart) {
                val id = tail.substring(numStart, i).toIntOrNull() ?: return
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                cancelLegacyPendingAlarm(context, alarmManager, id)
            }
        } catch (_: Exception) {
        }
    }

    /** Removes a single notification ID from the scheduled_notifications cache and cancels its PendingIntents. */
    @Synchronized
    fun removeAlarmFromCache(context: Context, targetId: Int) {
        val unlocked = isUserUnlocked(context)
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            cancelLegacyPendingAlarm(context, alarmManager, targetId)
            cancelGuardianPendingAlarm(context, alarmManager, targetId)
            lastArmedSignature.remove(targetId)

            val storageCtx = if (unlocked) context else deviceProtectedContext(context)
            val prefs = storageCtx.getSharedPreferences(SCHEDULED_PREFS, Context.MODE_PRIVATE)
            val raw = prefs.getString(SCHEDULED_PREFS, null) ?: return
            val arr = JSONArray(raw)
            val kept = JSONArray()
            var changed = false
            for (i in 0 until arr.length()) {
                val item = arr.optJSONObject(i) ?: continue
                if (item.optInt("id", -1) == targetId) {
                    changed = true
                    continue
                }
                kept.put(item)
            }
            if (changed) {
                val newJson = kept.toString()
                lastGuardianJson = newJson
                prefs.edit().putString(SCHEDULED_PREFS, newJson).apply()
                if (unlocked) {
                    mirrorToDeviceProtectedStorage(context, newJson, null)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "removeAlarmFromCache failed for $targetId: $e")
        }
    }

    /**
     * Purges one-shot prayer alarms that are overdue by more than [purgeOverdueAfterMs],
     * migrates upcoming alarms from [ScheduledNotificationReceiver] to [PrayerAlarmReceiver],
     * and arms the soonest 32 upcoming alarms in AlarmManager (with the top 16 within 24 hours
     * promoted to setAlarmClock()).
     *
     * Alarms that are currently due (`0 <= now - epochMs <= purgeOverdueAfterMs`) are kept if
     * already armed on [PrayerAlarmReceiver], or armed immediately if they were just written by
     * Dart or restored after reboot/time-change so no boundary prayer is ever lost.
     */
    @Synchronized
    fun purgeStaleAndPromoteUpcoming(
        context: Context,
        forceReschedule: Boolean = false,
        purgeOverdueAfterMs: Long = MAX_BACKGROUND_LATENESS_MS,
        ignoreBatchInProgress: Boolean = false,
    ) {
        val unlocked = isUserUnlocked(context)
        if (unlocked) {
            val app = context.applicationContext as? MainApplication
            app?.registerScheduleWatcher()

            // Do not read/mutate scheduled_notifications while Dart is actively mid-loop writing 140 alarms,
            // unless called from onStop/receiver where immediate promotion is required before process freeze.
            if (!forceReschedule && !ignoreBatchInProgress && isDartBatchInProgress(context)) {
                return
            }
        }

        try {
            val storageCtx = if (unlocked) context else deviceProtectedContext(context)
            val prefs = storageCtx.getSharedPreferences(SCHEDULED_PREFS, Context.MODE_PRIVATE)
            val guardianPrefs = storageCtx.getSharedPreferences(GUARDIAN_PREFS, Context.MODE_PRIVATE)
            val previouslyArmedIds = (guardianPrefs.getStringSet(KEY_ARMED_IDS, emptySet()) ?: emptySet())
                .mapNotNull { it.toIntOrNull() }
                .toSet()

            // Hydrate in-memory signature map after process restart so non-forced syncs
            // (e.g. SCREEN_ON / USER_PRESENT) do not redundantly re-arm all 24 kernel alarms.
            if (lastArmedSignature.isEmpty()) {
                val savedSigs = guardianPrefs.getStringSet(KEY_ARMED_SIGNATURES, emptySet()) ?: emptySet()
                for (entryStr in savedSigs) {
                    val eqIdx = entryStr.indexOf('=')
                    if (eqIdx > 0) {
                        val idKey = entryStr.substring(0, eqIdx).toIntOrNull()
                        if (idKey != null) {
                            lastArmedSignature[idKey] = entryStr.substring(eqIdx + 1)
                        }
                    }
                }
            }

            val raw = prefs.getString(SCHEDULED_PREFS, null)
            val rawHash = raw?.hashCode() ?: 0
            val lastLegacySweepHash = guardianPrefs.getInt(KEY_LAST_LEGACY_SWEEP_HASH, 0)
            val arr = if (raw.isNullOrEmpty()) JSONArray() else JSONArray(raw)

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                alarmManager.canScheduleExactAlarms()
            } else {
                true
            }

            val now = System.currentTimeMillis()
            val appOpenOrUnlocked = isAppRecentlyOpened()
            val effectivePurgeOverdueMs = if (appOpenOrUnlocked) {
                minOf(purgeOverdueAfterMs, APP_OPEN_OVERDUE_MS)
            } else {
                purgeOverdueAfterMs
            }
            // When the user is unlocking or opening the app, only synthesize an immediate catch-up
            // alarm if the prayer minute literally just started within the last 15 seconds.
            val effectiveCatchupWindowMs = if (appOpenOrUnlocked) 15_000L else ON_TIME_CATCHUP_WINDOW_MS
            val kept = JSONArray()
            val upcoming = ArrayList<UpcomingEntry>()
            val inFlightDueIds = HashSet<Int>()
            val allScheduledIds = HashSet<Int>()
            var dirty = false

            for (i in 0 until arr.length()) {
                val item = arr.optJSONObject(i) ?: continue
                val id = item.optInt("id", -1)
                val isRepeating = item.has("repeatInterval") ||
                    item.has("repeatIntervalMilliseconds") ||
                    item.has("matchDateTimeComponents") ||
                    item.has("scheduledNotificationRepeatFrequency")

                var epochMs = parseScheduledEpochMs(item)

                if (epochMs != null && !isRepeating && epochMs <= now) {
                    val overdueMs = now - epochMs
                    if (overdueMs > effectivePurgeOverdueMs) {
                        // Alarm is past the allowed grace window: cancel PendingIntents (never NotificationManager)
                        // and remove from scheduled_notifications so it never dumps on app open.
                        if (id >= 0) {
                            cancelLegacyPendingAlarm(context, alarmManager, id)
                            cancelGuardianPendingAlarm(context, alarmManager, id)
                            lastArmedSignature.remove(id)
                        }
                        dirty = true
                        continue
                    } else {
                        // Alarm is within effectivePurgeOverdueMs:
                        // Always disarm the disabled ScheduledNotificationReceiver PendingIntent.
                        if (id >= 0) {
                            cancelLegacyPendingAlarm(context, alarmManager, id)
                        }
                        val alreadyArmedOnGuardian = id >= 0 &&
                            (id in previouslyArmedIds || lastArmedSignature.containsKey(id)) &&
                            hasGuardianPendingAlarm(context, id)

                        if (alreadyArmedOnGuardian) {
                            // Already armed on PrayerAlarmReceiver and currently waking the CPU in background: keep intact!
                            kept.put(item)
                            allScheduledIds.add(id)
                            inFlightDueIds.add(id)
                        } else if (overdueMs <= effectiveCatchupWindowMs) {
                            // Prayer time literally just arrived within the catch-up window (e.g. Dart batch finished
                            // 1–3s after the minute boundary): arm for immediate delivery!
                            kept.put(item)
                            if (id >= 0) {
                                allScheduledIds.add(id)
                                upcoming.add(
                                    UpcomingEntry(
                                        id = id,
                                        epochMs = now + 500L,
                                        isRepeating = false,
                                        detailsJson = item.toString()
                                    )
                                )
                            }
                        } else {
                            // Overdue beyond the catch-up window and NOT armed in AlarmManager: purge instead of
                            // synthesizing a late alarm on screen unlock (USER_PRESENT) or app open.
                            if (id >= 0) {
                                cancelGuardianPendingAlarm(context, alarmManager, id)
                                lastArmedSignature.remove(id)
                            }
                            dirty = true
                        }
                        continue
                    }
                }

                // If a repeating alarm (e.g. Friday Kahf or daily Jamaat) fell behind while the device was off,
                // roll its scheduledDateTime forward into the future so it does not fire stale on boot.
                if (epochMs != null && isRepeating && epochMs <= now) {
                    val rolled = rollRepeatingDateTimeForward(item, now + 60_000L)
                    if (rolled != null) {
                        epochMs = rolled
                        dirty = true
                    }
                }

                // Ensure flutter_local_notifications never uses its broken alarmClock mode internally
                val currentMode = item.optString("scheduleMode", "")
                if (currentMode == "alarmClock") {
                    item.put("scheduleMode", if (canExact) "exactAllowWhileIdle" else "inexactAllowWhileIdle")
                    dirty = true
                }

                kept.put(item)
                if (id >= 0 && epochMs != null && epochMs > now) {
                    allScheduledIds.add(id)
                    upcoming.add(
                        UpcomingEntry(
                            id = id,
                            epochMs = epochMs,
                            isRepeating = isRepeating,
                            detailsJson = item.toString()
                        )
                    )
                }
            }

            // Sort upcoming alarms chronologically:
            // - Top 4 within 24h -> AlarmClock (hardware RTC wake + Doze exemption, chained on every prayer fire)
            // - Next 20 (up to 24 total in kernel) -> ExactAllowWhileIdle
            // - Remaining ~116 in 14-day horizon -> stored in SharedPreferences, promoted as earlier ones fire
            upcoming.sortBy { it.epochMs }
            val kernelWindowEntries = upcoming.take(MAX_KERNEL_ARMED_ALARMS)
            val kernelWindowIds = kernelWindowEntries.map { it.id }.toSet()

            val alarmClockHorizon = now + ALARM_CLOCK_HORIZON_MS
            val alarmClockIds = HashSet<Int>()
            if (canExact) {
                for (entry in kernelWindowEntries) {
                    if (entry.epochMs <= alarmClockHorizon && alarmClockIds.size < MAX_ALARM_CLOCK_COUNT) {
                        alarmClockIds.add(entry.id)
                    } else {
                        break
                    }
                }
            }

            // Only sweep raw ScheduledNotificationReceiver PendingIntents across all 140 entries when
            // the schedule JSON actually changed or forceReschedule is requested, avoiding ~250 redundant
            // Binder IPC calls on every SCREEN_ON / USER_PRESENT / boundary tick.
            val needsFullLegacySweep = forceReschedule || rawHash != lastLegacySweepHash
            if (needsFullLegacySweep) {
                for (entry in upcoming) {
                    cancelLegacyPendingAlarm(context, alarmManager, entry.id)
                }
            }

            // Cancel any previously armed guardian alarms that were removed/disabled or fell out of the 24-alarm window
            for (oldId in previouslyArmedIds) {
                if (oldId !in kernelWindowIds && oldId !in inFlightDueIds) {
                    cancelLegacyPendingAlarm(context, alarmManager, oldId)
                    cancelGuardianPendingAlarm(context, alarmManager, oldId)
                    lastArmedSignature.remove(oldId)
                }
            }
            lastArmedSignature.keys.retainAll(kernelWindowIds + inFlightDueIds)

            // Arm the rolling 24-alarm kernel window on PrayerAlarmReceiver
            for (entry in kernelWindowEntries) {
                if (!needsFullLegacySweep) {
                    cancelLegacyPendingAlarm(context, alarmManager, entry.id)
                }
                val targetMode = when {
                    entry.id in alarmClockIds -> "clock"
                    canExact -> "exact"
                    else -> "inexact"
                }
                val sig = "$targetMode:${entry.epochMs}:${entry.detailsJson.hashCode()}"
                val needsArm = forceReschedule ||
                    lastArmedSignature[entry.id] != sig ||
                    !hasGuardianPendingAlarm(context, entry.id)

                if (needsArm) {
                    armGuardianAlarm(
                        context = context,
                        alarmManager = alarmManager,
                        entry = entry,
                        targetMode = targetMode
                    )
                    lastArmedSignature[entry.id] = sig
                }
            }

            val currentRawAfter = prefs.getString(SCHEDULED_PREFS, null)
            val changedExternally = currentRawAfter != raw
            val finalJson: String?
            // Only write back to scheduled_notifications if Dart hasn't mutated it or started a batch in the meantime
            if (dirty && !changedExternally && (!unlocked || ignoreBatchInProgress || !isDartBatchInProgress(context))) {
                val keptJson = kept.toString()
                lastGuardianJson = keptJson
                prefs.edit().putString(SCHEDULED_PREFS, keptJson).apply()
                finalJson = keptJson
            } else {
                finalJson = currentRawAfter
                if (!changedExternally) {
                    lastGuardianJson = finalJson
                }
            }
            if (unlocked && !changedExternally && !isDartBatchInProgress(context)) {
                (context.applicationContext as? MainApplication)?.cancelPendingScheduleSync()
            }

            val finalSweepHash = finalJson?.hashCode() ?: 0
            val armedSet = (kernelWindowIds + inFlightDueIds).map { it.toString() }.toSet()
            val sigSet = lastArmedSignature.entries.map { "${it.key}=${it.value}" }.toSet()
            guardianPrefs.edit()
                .putStringSet(KEY_ARMED_IDS, armedSet)
                .putStringSet(KEY_ARMED_SIGNATURES, sigSet)
                .putInt(KEY_LAST_LEGACY_SWEEP_HASH, finalSweepHash)
                .apply()

            if (unlocked) {
                mirrorToDeviceProtectedStorage(context, finalJson, armedSet, sigSet, finalSweepHash)
            }
        } catch (e: Exception) {
            Log.w(TAG, "purgeStaleAndPromoteUpcoming failed: $e")
        }
    }

    /**
     * Re-arms saved upcoming alarms after purging any stale ones (used on boot and time/timezone changes).
     */
    @Synchronized
    fun rescheduleAllSavedAlarms(context: Context) {
        purgeStaleAndPromoteUpcoming(
            context,
            forceReschedule = true,
            purgeOverdueAfterMs = APP_OPEN_OVERDUE_MS
        )
    }

    private fun parseScheduledEpochMs(item: JSONObject): Long? {
        return try {
            val dtStr = item.optString("scheduledDateTime", "")
            val tzStr = item.optString("timeZoneName", "")
            if (dtStr.isNotEmpty() && tzStr.isNotEmpty()) {
                val ldt = LocalDateTime.parse(dtStr)
                val zdt = ZonedDateTime.of(ldt, ZoneId.of(tzStr))
                zdt.toInstant().toEpochMilli()
            } else if (item.has("millisecondsSinceEpoch")) {
                item.optLong("millisecondsSinceEpoch")
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun rollRepeatingDateTimeForward(item: JSONObject, nowMs: Long): Long? {
        return try {
            val dtStr = item.optString("scheduledDateTime", "")
            val tzStr = item.optString("timeZoneName", "")
            if (dtStr.isEmpty() || tzStr.isEmpty()) return null
            val zoneId = ZoneId.of(tzStr)
            var ldt = LocalDateTime.parse(dtStr)
            var epochMs = ZonedDateTime.of(ldt, zoneId).toInstant().toEpochMilli()
            val matchComp = item.optString("matchDateTimeComponents", "")
            val isWeekly = matchComp.equals("DayOfWeekAndTime", ignoreCase = true) || matchComp == "1"
            var guard = 0
            while (epochMs <= nowMs && guard < 400) {
                ldt = if (isWeekly) ldt.plusWeeks(1) else ldt.plusDays(1)
                epochMs = ZonedDateTime.of(ldt, zoneId).toInstant().toEpochMilli()
                guard++
            }
            item.put("scheduledDateTime", DateTimeFormatter.ISO_LOCAL_DATE_TIME.format(ldt))
            epochMs
        } catch (_: Exception) {
            null
        }
    }

    private fun rollOneShotDateTimeForwardDays(item: JSONObject, nowMs: Long, stepDays: Long): Long? {
        return try {
            val dtStr = item.optString("scheduledDateTime", "")
            val tzStr = item.optString("timeZoneName", "")
            if (dtStr.isEmpty() || tzStr.isEmpty()) return null
            val zoneId = ZoneId.of(tzStr)
            var ldt = LocalDateTime.parse(dtStr)
            var epochMs = ZonedDateTime.of(ldt, zoneId).toInstant().toEpochMilli()
            var guard = 0
            while (epochMs <= nowMs && guard < 100) {
                ldt = ldt.plusDays(stepDays)
                epochMs = ZonedDateTime.of(ldt, zoneId).toInstant().toEpochMilli()
                guard++
            }
            item.put("scheduledDateTime", DateTimeFormatter.ISO_LOCAL_DATE_TIME.format(ldt))
            epochMs
        } catch (_: Exception) {
            null
        }
    }

    private fun cancelLegacyPendingAlarm(context: Context, alarmManager: AlarmManager, id: Int) {
        try {
            val intent = Intent(context, ScheduledNotificationReceiver::class.java)
            val flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            val pi = PendingIntent.getBroadcast(context, id, intent, flags)
            if (pi != null) {
                alarmManager.cancel(pi)
                pi.cancel()
            }
        } catch (_: Exception) {
        }
    }

    private fun cancelGuardianPendingAlarm(context: Context, alarmManager: AlarmManager, id: Int) {
        try {
            val intent = Intent(context, PrayerAlarmReceiver::class.java)
            val flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            val pi = PendingIntent.getBroadcast(context, id, intent, flags)
            if (pi != null) {
                alarmManager.cancel(pi)
                pi.cancel()
            }
        } catch (_: Exception) {
        }
    }

    private fun hasGuardianPendingAlarm(context: Context, id: Int): Boolean {
        return try {
            val intent = Intent(context, PrayerAlarmReceiver::class.java)
            val flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            PendingIntent.getBroadcast(context, id, intent, flags) != null
        } catch (_: Exception) {
            false
        }
    }

    private fun armGuardianAlarm(
        context: Context,
        alarmManager: AlarmManager,
        entry: UpcomingEntry,
        targetMode: String,
    ) {
        try {
            val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
                putExtra(NOTIFICATION_DETAILS_EXTRA, entry.detailsJson)
                putExtra(PrayerAlarmReceiver.EXTRA_SCHEDULED_EPOCH_MS, entry.epochMs)
                putExtra(PrayerAlarmReceiver.EXTRA_NOTIFICATION_ID, entry.id)
                putExtra(PrayerAlarmReceiver.EXTRA_IS_REPEATING, entry.isRepeating)
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val pi = PendingIntent.getBroadcast(context, entry.id, intent, flags)

            when (targetMode) {
                "clock" -> {
                    // The 3rd parameter of setAlarmClock (showIntent) MUST be an Activity PendingIntent.
                    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                        this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    val showIntent = if (launchIntent != null) {
                        PendingIntent.getActivity(context, entry.id, launchIntent, flags)
                    } else {
                        pi
                    }
                    AlarmManagerCompat.setAlarmClock(alarmManager, entry.epochMs, showIntent, pi)
                }
                "exact" -> {
                    AlarmManagerCompat.setExactAndAllowWhileIdle(
                        alarmManager,
                        AlarmManager.RTC_WAKEUP,
                        entry.epochMs,
                        pi
                    )
                }
                else -> {
                    AlarmManagerCompat.setAndAllowWhileIdle(
                        alarmManager,
                        AlarmManager.RTC_WAKEUP,
                        entry.epochMs,
                        pi
                    )
                }
            }
        } catch (se: SecurityException) {
            try {
                val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                    addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
                    putExtra(NOTIFICATION_DETAILS_EXTRA, entry.detailsJson)
                    putExtra(PrayerAlarmReceiver.EXTRA_SCHEDULED_EPOCH_MS, entry.epochMs)
                    putExtra(PrayerAlarmReceiver.EXTRA_NOTIFICATION_ID, entry.id)
                    putExtra(PrayerAlarmReceiver.EXTRA_IS_REPEATING, entry.isRepeating)
                }
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                val pi = PendingIntent.getBroadcast(context, entry.id, intent, flags)
                AlarmManagerCompat.setAndAllowWhileIdle(
                    alarmManager,
                    AlarmManager.RTC_WAKEUP,
                    entry.epochMs,
                    pi
                )
            } catch (e2: Exception) {
                Log.w(TAG, "Fallback armGuardianAlarm failed for ${entry.id}: $e2")
            }
        } catch (e: Exception) {
            Log.w(TAG, "armGuardianAlarm failed for ${entry.id}: $e")
        }
    }
}
