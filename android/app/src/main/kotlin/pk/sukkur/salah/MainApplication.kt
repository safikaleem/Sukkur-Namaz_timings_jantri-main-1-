package pk.sukkur.salah

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainApplication : Application() {
    private val mainHandler = Handler(Looper.getMainLooper())
    // Strong references to SharedPreferences instances AND listeners so Android's
    // WeakHashMap inside SharedPreferencesImpl never garbage-collects our listeners.
    private var scheduledPrefs: SharedPreferences? = null
    private var flutterPrefs: SharedPreferences? = null
    private var scheduledPrefsListener: SharedPreferences.OnSharedPreferenceChangeListener? = null
    private var flutterPrefsListener: SharedPreferences.OnSharedPreferenceChangeListener? = null

    private val syncRunnable = object : Runnable {
        override fun run() {
            // If Dart's _scheduleWeeklyNotificationsCore is still mid-loop writing 140 alarms,
            // wait until the batch finishes so we never clobber SharedPreferences mid-write.
            if (PrayerAlarmGuardian.isDartBatchInProgress(applicationContext)) {
                mainHandler.postDelayed(this, 600L)
                return
            }
            CoroutineScope(Dispatchers.IO).launch {
                PrayerAlarmGuardian.purgeStaleAndPromoteUpcoming(
                    applicationContext,
                    forceReschedule = true
                )
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        // Register ActivityLifecycleCallbacks at Application level so foreground state & markAppOpened()
        // are tracked for the entire time any Activity is visible (plus 15s after open/close).
        registerActivityLifecycleCallbacks(object : ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                PrayerAlarmGuardian.markAppOpened()
            }
            override fun onActivityStarted(activity: Activity) {
                PrayerAlarmGuardian.onActivityStarted()
            }
            override fun onActivityResumed(activity: Activity) {
                PrayerAlarmGuardian.markAppOpened()
            }
            override fun onActivityPaused(activity: Activity) {
                PrayerAlarmGuardian.markAppOpened()
            }
            override fun onActivityStopped(activity: Activity) {
                PrayerAlarmGuardian.onActivityStopped()
            }
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityDestroyed(activity: Activity) {}
        })

        // Do NOT call purgeStaleAndPromoteUpcoming blindly in Application.onCreate() before
        // MainActivity.onCreate() or PrayerAlarmReceiver.onReceive() runs, because Application.onCreate()
        // runs before ActivityLifecycleCallbacks fire on cold start. Each entry point (MainActivity,
        // PrayerAlarmReceiver, BootReceiver, PrayerKeepAliveService) invokes Guardian with its exact mode.
        if (PrayerAlarmGuardian.isUserUnlocked(this)) {
            registerScheduleWatcher()
        }
    }

    fun cancelPendingScheduleSync() {
        mainHandler.removeCallbacks(syncRunnable)
    }

    fun registerScheduleWatcher() {
        if (scheduledPrefsListener == null) {
            try {
                val prefs = getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE)
                scheduledPrefs = prefs
                val listener = SharedPreferences.OnSharedPreferenceChangeListener { sp, key ->
                    if (key == "scheduled_notifications" && !PrayerAlarmGuardian.isReceiverDispatching) {
                        val current = sp.getString("scheduled_notifications", null)
                        if (current != PrayerAlarmGuardian.lastGuardianJson) {
                            // Immediately disarm the raw ScheduledNotificationReceiver alarm just
                            // created by flutter_local_notifications so AlarmManager never spikes
                            // to 140+ simultaneous kernel alarms during a batch loop.
                            PrayerAlarmGuardian.disarmLatestLegacyAlarmFromJson(applicationContext, current)
                            mainHandler.removeCallbacks(syncRunnable)
                            mainHandler.postDelayed(syncRunnable, 900L)
                        }
                    }
                }
                prefs.registerOnSharedPreferenceChangeListener(listener)
                scheduledPrefsListener = listener
            } catch (_: Exception) {
            }
        }

        if (flutterPrefsListener == null) {
            try {
                val fPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                flutterPrefs = fPrefs
                val fListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
                    when (key) {
                        "flutter.alarm_batch_completed_at" -> {
                            // Triggered at the exact end of scheduleWeeklyNotifications() in both
                            // foreground and WorkManager background isolates. Promote synchronously
                            // on IO without a postDelayed gap so WorkManager never exits before
                            // PrayerAlarmReceiver alarms are armed in the OS kernel.
                            mainHandler.removeCallbacks(syncRunnable)
                            CoroutineScope(Dispatchers.IO).launch {
                                PrayerAlarmGuardian.purgeStaleAndPromoteUpcoming(
                                    applicationContext,
                                    forceReschedule = true,
                                    ignoreBatchInProgress = true
                                )
                            }
                        }
                        "flutter.keepalive_sync_requested_at" -> {
                            // Allows WorkManager background isolate to update or stop
                            // PrayerKeepAliveService even when MainActivity is not running.
                            CoroutineScope(Dispatchers.IO).launch {
                                PrayerKeepAliveService.syncFromFlutterPrefs(applicationContext)
                            }
                        }
                    }
                }
                fPrefs.registerOnSharedPreferenceChangeListener(fListener)
                flutterPrefsListener = fListener
            } catch (_: Exception) {
            }
        }
    }
}
