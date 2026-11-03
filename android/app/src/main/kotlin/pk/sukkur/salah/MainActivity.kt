package pk.sukkur.salah

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "pk.sukkur.salah/native_helper"

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    private fun getAutoStartIntents(): List<Intent> {
        return listOf(
            // Infinix / Tecno / Itel (Transsion XOS & HiOS Phone Master)
            Intent().setComponent(ComponentName("com.transsion.phonemanager", "com.itel.autobootmanager.activity.AutoBootMgrActivity")),
            Intent().setComponent(ComponentName("com.transsion.phonemanager", "com.transsion.phonemanager.settings.AutoStartActivity")),
            Intent().setComponent(ComponentName("com.transsion.phonemanager", "com.transsion.phonemanager.MainActivity")),
            Intent().setComponent(ComponentName("com.transsion.itel.launcher", "com.itel.autobootmanager.activity.AutoBootMgrActivity")),
            // Vivo / iQOO (FuntouchOS / OriginOS)
            Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")),
            Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager")),
            Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")),
            // Xiaomi / Redmi / POCO (MIUI / HyperOS)
            Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")),
            // Oppo / Realme / OnePlus (ColorOS / RealmeUI / OxygenOS)
            Intent().setComponent(ComponentName("com.oplus.safecenter", "com.oplus.safecenter.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")),
            // Huawei / Honor (EMUI / MagicOS)
            Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity")),
            Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")),
            // Asus
            Intent().setComponent(ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.entry.FunctionActivity"))
                .setData(Uri.parse("mobilemanager://function/entry/AutoStart"))
        )
    }

    private fun isAggressiveOemBrand(): Boolean {
        val brand = "${Build.MANUFACTURER} ${Build.BRAND}".lowercase()
        return brand.contains("infinix") ||
            brand.contains("tecno") ||
            brand.contains("itel") ||
            brand.contains("transsion") ||
            brand.contains("xiaomi") ||
            brand.contains("redmi") ||
            brand.contains("poco") ||
            brand.contains("vivo") ||
            brand.contains("iqoo") ||
            brand.contains("oppo") ||
            brand.contains("realme") ||
            brand.contains("oneplus") ||
            brand.contains("huawei") ||
            brand.contains("honor") ||
            brand.contains("asus")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAutoSilent" -> {
                    val alarms = call.argument<List<Map<String, Any>>>("alarms")
                    if (alarms != null) {
                        // Run heavy AlarmManager IPC off the main thread to avoid ANR.
                        CoroutineScope(Dispatchers.IO).launch {
                            cancelAllAutoSilentAlarms(this@MainActivity)
                            for (alarm in alarms) {
                                val id = (alarm["id"] as? Number)?.toInt() ?: continue
                                val triggerTimeMillis = (alarm["triggerTimeMillis"] as? Number)?.toLong() ?: continue
                                val type = alarm["type"] as? String ?: continue
                                val mode = alarm["mode"] as? String ?: "vibrate"
                                scheduleAutoSilentAlarm(this@MainActivity, id, triggerTimeMillis, type, mode)
                            }
                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Alarms list is null", null)
                    }
                }
                "cancelAllAutoSilent" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        cancelAllAutoSilentAlarms(this@MainActivity)
                        withContext(Dispatchers.Main) {
                            result.success(true)
                        }
                    }
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
                            // Some OEM ROMs (MIUI, OriginOS, XOS) do not support this direct intent.
                            // Fall back to the general battery optimization settings screen.
                            try {
                                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                                result.success(true)
                            } catch (e2: Exception) {
                                try {
                                    startActivity(
                                        Intent(
                                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                            Uri.parse("package:$packageName")
                                        )
                                    )
                                    result.success(true)
                                } catch (e3: Exception) {
                                    result.error("BATTERY_SETTINGS_ERROR", e3.message, null)
                                }
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "hasAutoStart" -> {
                    try {
                        var exists = isAggressiveOemBrand()
                        if (!exists) {
                            for (intent in getAutoStartIntents()) {
                                if (packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) != null) {
                                    exists = true
                                    break
                                }
                            }
                        }
                        result.success(exists)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "requestAutoStart" -> {
                    try {
                        var opened = false
                        for (intent in getAutoStartIntents()) {
                            if (packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY) != null) {
                                try {
                                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    startActivity(intent)
                                    opened = true
                                    break
                                } catch (_: Exception) {
                                    // Activity might require system permission on some ROM builds; try next fallback.
                                }
                            }
                        }
                        if (!opened) {
                            // Fallback 1: Launch OEM Phone Manager / Security Center main screen (e.g. Infinix Phone Master)
                            val managerPackages = listOf(
                                "com.transsion.phonemanager",
                                "com.miui.securitycenter",
                                "com.iqoo.secure",
                                "com.oplus.safecenter",
                                "com.coloros.safecenter",
                                "com.huawei.systemmanager"
                            )
                            for (pkg in managerPackages) {
                                val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                                if (launchIntent != null) {
                                    try {
                                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                        startActivity(launchIntent)
                                        opened = true
                                        break
                                    } catch (_: Exception) {}
                                }
                            }
                        }
                        if (!opened) {
                            // Fallback 2: Open App Info where Battery / Background limits live on Android 12–16
                            val appDetails = Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:$packageName")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(appDetails)
                            opened = true
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
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
            }
        } catch (se: SecurityException) {
            try {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Failed to schedule auto-silent alarm: $e")
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Unexpected error scheduling alarm: $e")
        }
    }

    private fun cancelAutoSilentAlarm(context: Context, alarmId: Int) {
        try {
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
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to cancel auto-silent alarm: $e")
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
