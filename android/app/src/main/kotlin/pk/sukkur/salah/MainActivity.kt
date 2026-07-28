package pk.sukkur.salah

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pk.sukkur.salah/native_helper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAutoSilent" -> {
                    val alarms = call.argument<List<Map<String, Any>>>("alarms")
                    if (alarms != null) {
                        cancelAllAutoSilentAlarms(this)
                        for (alarm in alarms) {
                            val id = (alarm["id"] as? Number)?.toInt() ?: continue
                            val triggerTimeMillis = (alarm["triggerTimeMillis"] as? Number)?.toLong() ?: continue
                            val type = alarm["type"] as? String ?: continue
                            val mode = alarm["mode"] as? String ?: "vibrate"
                            scheduleAutoSilentAlarm(this, id, triggerTimeMillis, type, mode)
                        }
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Alarms list is null", null)
                    }
                }
                "cancelAllAutoSilent" -> {
                    cancelAllAutoSilentAlarms(this)
                    result.success(true)
                }
                "checkDndPermission" -> {
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(notificationManager.isNotificationPolicyAccessGranted)
                    } else {
                        result.success(true)
                    }
                }
                "openDndSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "isBatteryOptimizationIgnored" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        // Below Android 6 there is no Doze — always considered ignored.
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // Some OEM ROMs (MIUI, OriginOS) do not support this intent.
                            // Fall back to the general battery settings screen.
                            try {
                                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("BATTERY_SETTINGS_ERROR", e2.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "hasAutoStart" -> {
                    try {
                        val intents = listOf(
                            Intent().setComponent(android.content.ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager")),
                            Intent().setComponent(android.content.ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")),
                            Intent().setComponent(android.content.ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")),
                            Intent().setComponent(android.content.ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity")),
                            Intent().setComponent(android.content.ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.entry.FunctionActivity")).setData(Uri.parse("mobilemanager://function/entry/AutoStart"))
                        )
                        var exists = false
                        for (intent in intents) {
                            if (packageManager.resolveActivity(intent, android.content.pm.PackageManager.MATCH_DEFAULT_ONLY) != null) {
                                exists = true
                                break
                            }
                        }
                        result.success(exists)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "requestAutoStart" -> {
                    try {
                        val intents = listOf(
                            Intent().setComponent(android.content.ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager")),
                            Intent().setComponent(android.content.ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")),
                            Intent().setComponent(android.content.ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")),
                            Intent().setComponent(android.content.ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity")),
                            Intent().setComponent(android.content.ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")),
                            Intent().setComponent(android.content.ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.entry.FunctionActivity")).setData(Uri.parse("mobilemanager://function/entry/AutoStart"))
                        )

                        var opened = false
                        for (intent in intents) {
                            if (packageManager.resolveActivity(intent, android.content.pm.PackageManager.MATCH_DEFAULT_ONLY) != null) {
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                opened = true
                                break
                            }
                        }
                        result.success(opened)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun scheduleAutoSilentAlarm(context: Context, alarmId: Int, triggerTimeMillis: Long, type: String, mode: String) {
        val intent = Intent(context, AutoSilentReceiver::class.java).apply {
            action = "pk.sukkur.salah.ACTION_AUTO_SILENT"
            putExtra("type", type)
            putExtra("mode", mode)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
        }
    }

    private fun cancelAutoSilentAlarm(context: Context, alarmId: Int) {
        val intent = Intent(context, AutoSilentReceiver::class.java).apply {
            action = "pk.sukkur.salah.ACTION_AUTO_SILENT"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    private fun cancelAllAutoSilentAlarms(context: Context) {
        val bases = listOf(500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000)
        for (base in bases) {
            for (day in 0..6) {
                cancelAutoSilentAlarm(context, base + day)
                cancelAutoSilentAlarm(context, base + 100 + day)
            }
        }
    }
}
