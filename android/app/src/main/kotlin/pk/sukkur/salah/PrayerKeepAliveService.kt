package pk.sukkur.salah

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.AlarmManagerCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray

/**
 * Foreground service that keeps the "next prayer" countdown in the status bar.
 *
 * Why it exists: on Infinix / Tecno (XOS, HiOS), Vivo, Xiaomi and Oppo, an app
 * with no running foreground component is routinely force-stopped when swiped
 * away from Recents. A force-stopped app has ALL of its AlarmManager alarms
 * deleted by Android, so prayer notifications stop until the app is opened
 * again - the exact "notification only comes when I open the app" complaint.
 * A foreground service makes the OS treat the app like the other prayer apps
 * that keep a persistent notification, so it is not frozen or killed.
 *
 * In addition to Handler callbacks while the screen is on, this service arms
 * an AlarmManager boundary tick (ACTION_KEEPALIVE_TICK) so transitions happen
 * on the exact minute even while the CPU is in deep Doze sleep, and attaches a
 * deleteIntent (ACTION_KEEPALIVE_DISMISSED) so accidental swipe-dismissals on
 * Android 13+ automatically restore the ongoing notification.
 */
class PrayerKeepAliveService : Service() {

    companion object {
        private const val TAG = "PrayerKeepAlive"

        /** Same id the Dart countdown used, so the old notification is replaced, never duplicated. */
        const val NOTIF_ID = 999
        const val CHANNEL_ID = "namaz_live_countdown_v1"
        private const val BOUNDARY_ALARM_REQ_CODE = 99901
        private const val DISMISS_REQ_CODE = 99902

        const val ACTION_KEEPALIVE_TICK = "pk.sukkur.salah.ACTION_KEEPALIVE_TICK"
        const val ACTION_KEEPALIVE_DISMISSED = "pk.sukkur.salah.ACTION_KEEPALIVE_DISMISSED"

        private const val PREFS = "prayer_keepalive_prefs"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_TIMELINE = "timeline"
        private const val KEY_CHANNEL_NAME = "channel_name"
        private const val KEY_STALE_TITLE = "stale_title"
        private const val KEY_STALE_BODY = "stale_body"

        fun isEnabled(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_ENABLED, false)

        /** Saves the timeline and (re)starts the service. Returns false if the OS refused. */
        fun start(
            context: Context,
            timelineJson: String,
            channelName: String,
            staleTitle: String,
            staleBody: String,
        ): Boolean {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_ENABLED, true)
                .putString(KEY_TIMELINE, timelineJson)
                .putString(KEY_CHANNEL_NAME, channelName)
                .putString(KEY_STALE_TITLE, staleTitle)
                .putString(KEY_STALE_BODY, staleBody)
                .apply()
            scheduleNextBoundaryAlarmStatic(context)
            return launch(context)
        }

        /**
         * Syncs keep-alive state written by Dart (including from WorkManager background isolate
         * where MainActivity's MethodChannel is not attached).
         */
        fun syncFromFlutterPrefs(context: Context) {
            try {
                val fp = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
                val globalEnabled = fp.getBoolean("flutter.notifications_enabled", true)
                val liveEnabled = fp.getBoolean("flutter.live_countdown_enabled", true)
                if (!globalEnabled || !liveEnabled) {
                    stop(context)
                    return
                }
                val timeline = fp.getString("flutter.keepalive_timeline", null)
                val channelName = fp.getString("flutter.keepalive_channel_name", null) ?: "نماز لائیو کاؤنٹ ڈاؤن"
                val staleTitle = fp.getString("flutter.keepalive_stale_title", null) ?: "Sukkur Salah"
                val staleBody = fp.getString("flutter.keepalive_stale_body", null) ?: ""
                if (!timeline.isNullOrEmpty()) {
                    start(context, timeline, channelName, staleTitle, staleBody)
                } else if (isEnabled(context)) {
                    refreshNotificationStatic(context)
                } else {
                    // Bootstrap after Play Store update from v1.4.8 before Dart has written a timeline
                    start(context, "[]", channelName, staleTitle, staleBody)
                }
            } catch (e: Exception) {
                Log.w(TAG, "syncFromFlutterPrefs failed: $e")
            }
        }

        /** Starts the service using the saved timeline (used after boot / app update / exact alarm wake). */
        fun launch(context: Context): Boolean {
            if (!isEnabled(context)) return false
            return try {
                ContextCompat.startForegroundService(
                    context, Intent(context, PrayerKeepAliveService::class.java)
                )
                true
            } catch (e: Exception) {
                // Android 12+ ForegroundServiceStartNotAllowedException when called from
                // a restricted background context: still update the notification and boundary alarm directly!
                Log.w(TAG, "Foreground start restricted in background, updating notification directly: $e")
                refreshNotificationStatic(context)
                false
            }
        }

        /**
         * Updates the ongoing status-bar notification and arms the next boundary alarm
         * directly without requiring startForegroundService() (safe from any BroadcastReceiver
         * on Android 12–16 even when background service starts are restricted).
         */
        fun refreshIfRunning(context: Context) {
            if (!isEnabled(context)) return
            refreshNotificationStatic(context)
        }

        fun refreshNotificationStatic(context: Context) {
            if (!isEnabled(context)) return
            try {
                ensureChannelStatic(context)
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIF_ID, buildNotificationStatic(context, currentSegmentStatic(context)))
                scheduleNextBoundaryAlarmStatic(context)
            } catch (e: Exception) {
                Log.w(TAG, "refreshNotificationStatic failed: $e")
            }
        }

        fun stop(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_ENABLED, false)
                .apply()
            cancelBoundaryAlarmStatic(context)
            try {
                context.stopService(Intent(context, PrayerKeepAliveService::class.java))
            } catch (_: Exception) {
            }
            try {
                (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                    .cancel(NOTIF_ID)
            } catch (_: Exception) {
            }
        }

        private fun loadTimelineStatic(context: Context): List<Segment> {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_TIMELINE, null) ?: return emptyList()
            return try {
                val arr = JSONArray(raw)
                (0 until arr.length()).map { i ->
                    val o = arr.getJSONObject(i)
                    Segment(
                        startMs = o.getLong("start"),
                        title = o.optString("title"),
                        body = o.optString("body"),
                        subText = o.optString("sub"),
                        whenMs = o.getLong("when"),
                        countDown = o.optBoolean("down", true),
                    )
                }.sortedBy { it.startMs }
            } catch (e: Exception) {
                Log.w(TAG, "Bad timeline: $e")
                emptyList()
            }
        }

        private fun currentSegmentStatic(context: Context): Segment? {
            val now = System.currentTimeMillis()
            val timeline = loadTimelineStatic(context)
            if (timeline.isEmpty() || now >= timeline.last().startMs + 6L * 60L * 60L * 1000L) return null
            return timeline.lastOrNull { it.startMs <= now }
        }

        private fun scheduleNextBoundaryAlarmStatic(context: Context) {
            try {
                val now = System.currentTimeMillis()
                val next = loadTimelineStatic(context).firstOrNull { it.startMs > now } ?: return
                // Schedule +4s after the boundary so PrayerAlarmReceiver fires first without collision
                val triggerAtMs = next.startMs + 4000L
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val intent = Intent(context, BootReceiver::class.java).apply {
                    action = ACTION_KEEPALIVE_TICK
                    addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
                }
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                val pi = PendingIntent.getBroadcast(context, BOUNDARY_ALARM_REQ_CODE, intent, flags)
                val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    alarmManager.canScheduleExactAlarms()
                } else {
                    true
                }
                if (canExact) {
                    AlarmManagerCompat.setExactAndAllowWhileIdle(
                        alarmManager,
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMs,
                        pi
                    )
                } else {
                    AlarmManagerCompat.setAndAllowWhileIdle(
                        alarmManager,
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMs,
                        pi
                    )
                }
            } catch (e: Exception) {
                Log.w(TAG, "scheduleNextBoundaryAlarmStatic failed: $e")
            }
        }

        private fun cancelBoundaryAlarmStatic(context: Context) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val intent = Intent(context, BootReceiver::class.java).apply {
                    action = ACTION_KEEPALIVE_TICK
                }
                val flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                val pi = PendingIntent.getBroadcast(context, BOUNDARY_ALARM_REQ_CODE, intent, flags)
                if (pi != null) {
                    alarmManager.cancel(pi)
                    pi.cancel()
                }
            } catch (_: Exception) {
            }
        }

        private fun ensureChannelStatic(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) != null) return
            val name = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_CHANNEL_NAME, null) ?: "نماز لائیو کاؤنٹ ڈاؤن"
            val channel = NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_LOW).apply {
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            nm.createNotificationChannel(channel)
        }

        private fun buildNotificationStatic(context: Context, segment: Segment?): Notification {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val contentIntent = launch?.let {
                PendingIntent.getActivity(
                    context, 0, it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

            // On Android 13+, users can swipe away ongoing notifications. Attach a deleteIntent
            // so if the notification is dismissed while live countdown is still enabled, it restores itself.
            val deleteIntent = Intent(context, BootReceiver::class.java).apply {
                action = ACTION_KEEPALIVE_DISMISSED
                addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
            }
            val deletePendingIntent = PendingIntent.getBroadcast(
                context,
                DISMISS_REQ_CODE,
                deleteIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setColor(0xFF0D6B5E.toInt())
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                .setDeleteIntent(deletePendingIntent)

            if (contentIntent != null) builder.setContentIntent(contentIntent)

            if (segment != null) {
                builder.setContentTitle(segment.title)
                    .setContentText(segment.body)
                    .setShowWhen(true)
                    .setWhen(segment.whenMs)
                    .setUsesChronometer(true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    builder.setChronometerCountDown(segment.countDown)
                }
                if (segment.subText.isNotEmpty()) builder.setSubText(segment.subText)
            } else {
                builder.setContentTitle(prefs.getString(KEY_STALE_TITLE, null) ?: "Sukkur Salah")
                    .setContentText(prefs.getString(KEY_STALE_BODY, null) ?: "")
                    .setShowWhen(false)
            }
            return builder.build()
        }
    }

    private data class Segment(
        val startMs: Long,
        val title: String,
        val body: String,
        val subText: String,
        val whenMs: Long,
        val countDown: Boolean,
    )

    private val handler = Handler(Looper.getMainLooper())
    private val refreshRunnable = Runnable { refresh() }
    private var screenReceiverRegistered = false

    // Screen-on / time changes: Handler delays pause in deep sleep, so refresh
    // whenever the user can actually see the notification.
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == Intent.ACTION_USER_PRESENT) {
                PrayerAlarmGuardian.markAppOpened()
            }
            refresh()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureChannelStatic(this)
        try {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_USER_PRESENT)
                addAction(Intent.ACTION_TIME_CHANGED)
                addAction(Intent.ACTION_TIMEZONE_CHANGED)
                addAction(Intent.ACTION_DATE_CHANGED)
            }
            ContextCompat.registerReceiver(
                this, screenReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED
            )
            screenReceiverRegistered = true
        } catch (e: Exception) {
            Log.w(TAG, "Screen receiver registration failed: $e")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isEnabled(this)) {
            // Must still call startForeground before stopping, or Android crashes the app.
            goForeground(buildNotificationStatic(this, currentSegmentStatic(this)))
            stopSelf()
            return START_NOT_STICKY
        }
        goForeground(buildNotificationStatic(this, currentSegmentStatic(this)))
        scheduleNext()
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // Re-verify and arm all upcoming prayer alarms right as the user swipes the app from Recents
        PrayerAlarmGuardian.purgeStaleAndPromoteUpcoming(applicationContext, forceReschedule = true)
        if (isEnabled(this)) {
            refreshNotificationStatic(applicationContext)
            try {
                // Schedule a broadcast tick (NOT PendingIntent.getService, which throws
                // BackgroundServiceStartNotAllowedException on Android 8+) 2 seconds after swipe-away.
                val tickIntent = Intent(applicationContext, BootReceiver::class.java).apply {
                    action = ACTION_KEEPALIVE_TICK
                    addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
                }
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                val pendingIntent = PendingIntent.getBroadcast(
                    applicationContext,
                    BOUNDARY_ALARM_REQ_CODE,
                    tickIntent,
                    flags
                )
                val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                if (alarmManager != null) {
                    val triggerAt = System.currentTimeMillis() + 2000L
                    val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            alarmManager.canScheduleExactAlarms()
                        } catch (_: Exception) {
                            false
                        }
                    } else {
                        true
                    }
                    if (canExact) {
                        AlarmManagerCompat.setExactAndAllowWhileIdle(
                            alarmManager,
                            AlarmManager.RTC_WAKEUP,
                            triggerAt,
                            pendingIntent
                        )
                    } else {
                        AlarmManagerCompat.setAndAllowWhileIdle(
                            alarmManager,
                            AlarmManager.RTC_WAKEUP,
                            triggerAt,
                            pendingIntent
                        )
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "onTaskRemoved broadcast schedule failed: $e")
            }
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(refreshRunnable)
        if (screenReceiverRegistered) {
            try {
                unregisterReceiver(screenReceiver)
            } catch (_: Exception) {
            }
            screenReceiverRegistered = false
        }
        super.onDestroy()
    }

    private fun goForeground(notification: Notification) {
        try {
            val type = if (Build.VERSION.SDK_INT >= 34)
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0
            ServiceCompat.startForeground(this, NOTIF_ID, notification, type)
        } catch (e: Exception) {
            Log.w(TAG, "startForeground failed: $e")
            stopSelf()
        }
    }

    private fun refresh() {
        if (!isEnabled(this)) {
            stopSelf()
            return
        }
        val appContext = applicationContext
        // Promote upcoming alarms to AlarmClock and purge any stale ones off the main thread
        CoroutineScope(Dispatchers.IO).launch {
            val overdueCutoff = if (PrayerAlarmGuardian.isAppRecentlyOpened()) {
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
        refreshNotificationStatic(this)
        scheduleNext()
    }

    private fun scheduleNext() {
        handler.removeCallbacks(refreshRunnable)
        val now = System.currentTimeMillis()
        val next = loadTimelineStatic(this).firstOrNull { it.startMs > now } ?: return
        // +2s so the boundary minute is definitely reached; capped so we self-correct regularly.
        val delay = (next.startMs - now + 2000L).coerceIn(2000L, 30L * 60L * 1000L)
        handler.postDelayed(refreshRunnable, delay)
        scheduleNextBoundaryAlarmStatic(this)
    }
}
