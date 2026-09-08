package pk.sukkur.salah

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import pk.sukkur.salah.R
import org.json.JSONObject
import java.io.InputStreamReader
import java.util.Calendar

open class PrayerWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TICK = "pk.sukkur.salah.ACTION_TICK"
    }

    protected open fun buildViews(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews =
        buildSmallWidget(context, data, isNight, language)

    override fun onReceive(context: Context, intent: Intent) {
        try {
            super.onReceive(context, intent)
            val action = intent.action
            if (action == Intent.ACTION_DATE_CHANGED ||
                action == Intent.ACTION_TIMEZONE_CHANGED ||
                action == Intent.ACTION_USER_PRESENT ||
                action == Intent.ACTION_TIME_CHANGED ||
                action == "android.intent.action.TIME_SET" ||
                action == ACTION_TICK
            ) {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisAppWidget = ComponentName(context.packageName, javaClass.name)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget)
                onUpdate(context, appWidgetManager, appWidgetIds)

                if (action == ACTION_TICK || action == Intent.ACTION_USER_PRESENT || action == "android.intent.action.TIME_SET" || action == Intent.ACTION_TIME_CHANGED) {
                    scheduleNextTick(context)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("PrayerWidget", "FATAL CRASH in onReceive: $e")
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        try {
            val language = resolveLanguage(context)
            val data = loadPrayerData(context, language)
            val isNight = isNightMode(context)
            for (widgetId in appWidgetIds) {
                appWidgetManager.updateAppWidget(widgetId, buildViews(context, data, isNight, language))
            }
        } catch (e: Exception) {
            android.util.Log.e("PrayerWidget", "FATAL CRASH in onUpdate: $e")
        }
        scheduleNextTick(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleNextTick(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        if (!hasAnyActiveWidgets(context)) {
            cancelTick(context)
        }
    }

    private fun scheduleNextTick(context: Context) {
        val providers = arrayOf(
            PrayerWidgetSmallProvider::class.java,
            PrayerWidgetMediumProvider::class.java,
            PrayerWidgetLargeProvider::class.java,
            PrayerWidgetTinyProvider::class.java,
            PrayerWidgetSlimProvider::class.java,
            PrayerWidgetCircleProvider::class.java,
            PrayerWidgetVerticalProvider::class.java
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val calendar = Calendar.getInstance()

        // Battery optimization: tick every second only if screen is on.
        // Otherwise, tick only at the turn of the minute.
        val pm = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        val isScreenOn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
            pm.isInteractive
        } else {
            @Suppress("DEPRECATION")
            pm.isScreenOn
        }

        val msToNextTick = 60000 - (calendar.get(Calendar.SECOND) * 1000 + calendar.get(Calendar.MILLISECOND))
        val triggerTime = System.currentTimeMillis() + msToNextTick

        for (providerClass in providers) {
            val comp = ComponentName(context, providerClass)
            val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(comp)
            if (ids.isEmpty()) continue

            val intent = Intent(context, providerClass).apply {
                action = ACTION_TICK
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val requestCode = providerClass.hashCode()
            val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    try {
                        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                    } catch (se: SecurityException) {
                        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                    }
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                }
            } catch (e: Exception) {
                try {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                } catch (e2: Exception) {}
            }
        }
    }

    private fun cancelTick(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val providers = arrayOf(
            PrayerWidgetSmallProvider::class.java,
            PrayerWidgetMediumProvider::class.java,
            PrayerWidgetLargeProvider::class.java,
            PrayerWidgetTinyProvider::class.java,
            PrayerWidgetSlimProvider::class.java,
            PrayerWidgetCircleProvider::class.java,
            PrayerWidgetVerticalProvider::class.java
        )
        for (providerClass in providers) {
            val intent = Intent(context, providerClass).apply {
                action = ACTION_TICK
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val requestCode = providerClass.hashCode()
            val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)
            alarmManager.cancel(pendingIntent)
        }
    }

    private fun hasAnyActiveWidgets(context: Context): Boolean {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val providers = arrayOf(
            PrayerWidgetSmallProvider::class.java,
            PrayerWidgetMediumProvider::class.java,
            PrayerWidgetLargeProvider::class.java,
            PrayerWidgetTinyProvider::class.java,
            PrayerWidgetSlimProvider::class.java,
            PrayerWidgetCircleProvider::class.java,
            PrayerWidgetVerticalProvider::class.java
        )
        for (providerClass in providers) {
            val comp = ComponentName(context, providerClass)
            val ids = appWidgetManager.getAppWidgetIds(comp)
            if (ids.isNotEmpty()) return true
        }
        return false
    }

    private fun formatRelativeTime(targetMins: Int, nowSecs: Int): String {
        if (targetMins < 0) return ""
        val targetSecs = targetMins * 60
        val diff = nowSecs - targetSecs
        val isElapsed = diff >= 0
        val absDiff = if (isElapsed) diff else -diff
        val h = absDiff / 3600
        val m = (absDiff % 3600) / 60
        val s = absDiff % 60
        val sign = if (isElapsed) "+" else "-"
        return "$sign$h:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}"
    }

    private fun formatCountdown(durSecs: Int, isElapsed: Boolean): String {
        val total = if (durSecs < 0) 0 else durSecs
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        val sign = if (isElapsed) "+" else "-"
        return "$sign$h:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}"
    }

    private fun isNightMode(context: Context): Boolean {
        val nightMode = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return nightMode == Configuration.UI_MODE_NIGHT_YES
    }

    // ── Colors ────────────────────────────────────────────────────────────
    private fun primaryText(isNight: Boolean)   = if (isNight) Color.WHITE                 else Color.parseColor("#1A1A2E")
    private fun secondaryText(isNight: Boolean) = if (isNight) Color.parseColor("#CCCCCC") else Color.parseColor("#555577")
    private fun mutedText(isNight: Boolean)     = if (isNight) Color.parseColor("#AAAAAA") else Color.parseColor("#888899")
    private fun accentColor(isNight: Boolean)   = if (isNight) Color.parseColor("#FDB813") else Color.parseColor("#1565C0")
    private fun lineColor(isNight: Boolean)     = if (isNight) 0x33FFFFFF.toInt()          else Color.parseColor("#C0C4D0")

    // ── Data loading: read today's times from the bundled asset and compute
    //    the current prayer + countdown ourselves (never stale). ────────────
    protected fun loadPrayerData(context: Context, language: String): PrayerData {
        return try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val mode = prefs.getString("flutter.location_mode", "sukkur")
            
            val jsonText = if (mode == "world") {
                prefs.getString("flutter.world_timings_cache", null) ?: java.io.InputStreamReader(context.assets.open("flutter_assets/assets/data/timings.json")).readText()
            } else {
                java.io.InputStreamReader(context.assets.open("flutter_assets/assets/data/timings.json")).readText()
            }
            
            val json   = JSONObject(jsonText)
            val cal    = Calendar.getInstance()
            val month  = cal.get(Calendar.MONTH) + 1
            val day    = cal.get(Calendar.DAY_OF_MONTH)

            val days = json.getJSONObject("months")
                          .getJSONObject(month.toString())
                          .getJSONArray("days")

            var d: JSONObject? = null
            for (i in 0 until days.length()) {
                val candidate = days.getJSONObject(i)
                if (candidate.getInt("day") == day) { d = candidate; break }
            }
            if (d == null) return PrayerData.empty()

            val subahRaw   = d.optString("subah_sadiq", "")
            val tuluRaw    = d.optString("tulu_aftab", "")
            val ishraqRaw  = d.optString("ishraq", "")
            val zawalRaw   = d.optString("zawal_aftab", d.optString("zawal", ""))
            val mislRaw    = d.optString("misl_e_awwal", "")
            val asrRaw     = d.optString("asr_hanafi", "")
            val maghribRaw = d.optString("maghrib", "")
            val ishaRaw    = d.optString("isha", "")

            // A world-city cache is written in 24-hour form and says so. Two
            // Jantri conventions have to stand down for it, both of which would
            // otherwise put the widget minutes or hours away from the app.
            val src24 = json.optBoolean("is_24h", false)

            // "+6" and "+5" are Sukkur conventions; a calculated city already
            // holds its own Fajr and Zuhr, exactly as DayTiming.worldTimings does.
            val fajarRaw   = if (src24) subahRaw else addMinutes(subahRaw, 6)
            val zuharRaw   = if (src24) zawalRaw else addMinutes(zawalRaw, 5)

            // isPm flags mirror the Flutter model: AM for subah/fajar/tulu/ishraq, PM for the rest.
            // That fixed meridiem is the other one: a calculated Isha can fall
            // after midnight, and reading "00:35" as PM would land at lunchtime.
            fun pm(flag: Boolean) = flag && !src24

            val is24 = resolveIs24(context)
            val nowMins = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
            val nowSecs = nowMins * 60 + cal.get(Calendar.SECOND)

            val subahM = toMins(subahRaw,   false)
            val fajarM = toMins(fajarRaw,   false)
            val tuluM = toMins(tuluRaw,    false)
            val ishraqM = toMins(ishraqRaw,  false)
            val zawalM = toMins(zawalRaw,   pm(true))
            val zuharM = toMins(zuharRaw,   pm(true))
            val mislM = toMins(mislRaw,    pm(true))
            val asrM = toMins(asrRaw,     pm(true))
            val maghribM = toMins(maghribRaw, pm(true))
            val ishaM = toMins(ishaRaw,    pm(true))

            val isWorld = mode == "world"

            val state = if (isWorld) {
                computeCalculatedState(
                    fajar   = fajarM,
                    tulu    = tuluM,
                    zuhar   = zuharM,
                    asr     = asrM,
                    maghrib = maghribM,
                    isha    = ishaM,
                    now     = nowMins
                )
            } else {
                computeState(
                    subah   = subahM,
                    fajar   = fajarM,
                    tulu    = tuluM,
                    ishraq  = ishraqM,
                    zawal   = zawalM,
                    zuhar   = zuharM,
                    misl    = mislM,
                    asr     = asrM,
                    maghrib = maghribM,
                    isha    = ishaM,
                    now     = nowMins
                )
            }

            val prayerTime = when (state.highlightKey) {
                "Subah"   -> fmt(subahRaw,   false, is24)
                "Fajar"   -> fmt(fajarRaw,   false, is24)
                "Tulu"    -> fmt(tuluRaw,    false, is24)
                "Ishraq"  -> fmt(ishraqRaw,  false, is24)
                "Zawal"   -> fmt(zawalRaw,   pm(true), is24)
                "Zuhar"   -> fmt(zuharRaw,   pm(true), is24)
                "Misl"    -> fmt(mislRaw,    pm(true), is24)
                "Asr"     -> fmt(asrRaw,     pm(true), is24)
                "Maghrib" -> fmt(maghribRaw, pm(true), is24)
                "Isha"    -> fmt(ishaRaw,    pm(true), is24)
                else      -> "--:--"
            }

            val stateName = translatePrayerName(state.displayName, language)

            val activeMins = when (state.highlightKey) {
                "Subah"   -> subahM
                "Fajar"   -> fajarM
                "Tulu"    -> tuluM
                "Ishraq"  -> ishraqM
                "Zawal"   -> zawalM
                "Zuhar"   -> zuharM
                "Misl"    -> mislM
                "Asr"     -> asrM
                "Maghrib" -> maghribM
                "Isha"    -> ishaM
                else      -> -1
            }

            val countdownStr = if (activeMins >= 0) {
                val targetSecs = activeMins * 60
                val diff = if (state.isElapsed) nowSecs - targetSecs else targetSecs - nowSecs
                val absDiff = if (diff >= 0) diff else 0
                formatCountdown(absDiff, state.isElapsed)
            } else {
                "--:--:--"
            }

            val relativeTimes = mapOf(
                "Subah"   to formatRelativeTime(subahM, nowSecs),
                "Fajar"   to formatRelativeTime(fajarM, nowSecs),
                "Tulu"    to formatRelativeTime(tuluM, nowSecs),
                "Ishraq"  to formatRelativeTime(ishraqM, nowSecs),
                "Zawal"   to formatRelativeTime(zawalM, nowSecs),
                "Zuhar"   to formatRelativeTime(zuharM, nowSecs),
                "Misl"    to formatRelativeTime(mislM, nowSecs),
                "Asr"     to formatRelativeTime(asrM, nowSecs),
                "Maghrib" to formatRelativeTime(maghribM, nowSecs),
                "Isha"    to formatRelativeTime(ishaM, nowSecs)
            )

            PrayerData(
                stateName    = stateName,
                prayerTime   = prayerTime,
                gregorian    = gregorianDate(language),
                countdown    = countdownStr,
                isElapsed    = state.isElapsed,
                mainKey      = state.highlightKey,
                hijri        = hijriDate(context, language, nowMins, maghribM),
                sunrise      = fmt(tuluRaw, false, is24),
                subah   = fmt(subahRaw,   false, is24),
                fajar   = fmt(fajarRaw,   false, is24),
                tulu    = fmt(tuluRaw,    false, is24),
                ishraq  = fmt(ishraqRaw,  false, is24),
                zawal   = fmt(zawalRaw,   pm(true), is24),
                zuhar   = fmt(zuharRaw,   pm(true), is24),
                misl    = fmt(mislRaw,    pm(true), is24),
                asr     = fmt(asrRaw,     pm(true), is24),
                maghrib = fmt(maghribRaw, pm(true), is24),
                isha    = fmt(ishaRaw,    pm(true), is24),
                relativeTimes = relativeTimes,
                activeMins = activeMins,
                subahM = subahM,
                fajarM = fajarM,
                tuluM = tuluM,
                ishraqM = ishraqM,
                zawalM = zawalM,
                zuharM = zuharM,
                mislM = mislM,
                asrM = asrM,
                maghribM = maghribM,
                ishaM = ishaM
            )
        } catch (e: Exception) {
            PrayerData.empty()
        }
    }

    private fun addMinutes(timeStr: String, minutes: Int): String {
        if (timeStr.isEmpty()) return ""
        return try {
            val parts = timeStr.split(":")
            val h = parts[0].toInt()
            val m = parts[1].toInt()
            val totalMins = h * 60 + m + minutes
            val newH = totalMins / 60
            val newM = totalMins % 60
            String.format("%02d:%02d", newH, newM)
        } catch (e: Exception) { "" }
    }

    // "HH:MM" (+ isPm) → minutes since midnight, or -1 if missing/invalid.
    private fun toMins(raw: String, isPm: Boolean): Int {
        if (raw.isEmpty()) return -1
        return try {
            val parts = raw.split(":")
            var hour = parts[0].toInt()
            val minute = parts[1].toInt()
            if (isPm && hour < 12) hour += 12
            hour * 60 + minute
        } catch (e: Exception) { -1 }
    }

    // Resolve 12/24h: honor the app's in-app TimeFormat setting (0=system, 1=12h,
    // 2=24h) saved by shared_preferences; fall back to the device setting.
    private fun resolveIs24(context: Context): Boolean {
        val deviceIs24 = android.text.format.DateFormat.is24HourFormat(context)
        return try {
            val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
            if (widgetData.contains("time_format")) {
                val tf = try {
                    widgetData.getLong("time_format", -1L).toInt()
                } catch (e: Exception) {
                    try { widgetData.getInt("time_format", -1) } catch (e2: Exception) { -1 }
                }
                when (tf) {
                    1 -> return false       // h12
                    2 -> return true        // h24
                }
            }
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            if (!prefs.contains("flutter.time_format")) return deviceIs24
            val tf = try {
                prefs.getLong("flutter.time_format", -1L).toInt()
            } catch (e: Exception) {
                try { prefs.getInt("flutter.time_format", -1) } catch (e2: Exception) { -1 }
            }
            when (tf) {
                1 -> false       // h12
                2 -> true        // h24
                else -> deviceIs24  // system (or unknown)
            }
        } catch (e: Exception) { deviceIs24 }
    }

    // Resolve Urdu language setting saved by shared_preferences in Flutter app.
    private fun resolveLanguage(context: Context): String {
        return try {
            val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
            val lang = widgetData.getString("language_code", null)
            if (lang != null) {
                return lang
            }
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.getString("flutter.language_code", if (prefs.getBoolean("flutter.is_urdu", false)) "urdu" else "english") ?: "english"
        } catch (e: Exception) {
            "english"
        }
    }

    // "HH:MM" (+ isPm) → "h:mm AM/PM" (12h) or "HH:mm" (24h), per resolved setting.
    private fun fmt(raw: String, isPm: Boolean, is24: Boolean): String {
        val m = toMins(raw, isPm)
        if (m < 0) return "--:--"
        val hour24 = m / 60
        val minute = m % 60
        if (is24) {
            return "${hour24.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}"
        }
        val period = if (hour24 >= 12) "PM" else "AM"
        val h = if (hour24 % 12 == 0) 12 else hour24 % 12
        return "$h:${minute.toString().padStart(2, '0')} $period"
    }

    private fun splitTimeAndPeriod(timeStr: String): Pair<String, String> {
        if (timeStr.isEmpty()) return Pair("--:--", "")
        val parts = timeStr.trim().split(" ")
        if (parts.size >= 2) {
            return Pair(parts[0], parts[1])
        }
        return Pair(timeStr, "")
    }

    private val hijriMonths = arrayOf(
        "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
        "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
        "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
    )

    private val hijriMonthsUrdu = arrayOf(
        "محرم", "سفر", "ربیع الاول", "ربیع الثانی",
        "جمادی الاول", "جمادی الثانی", "رجب", "شعبان",
        "رمضان", "شوال", "ذوالقعدہ", "ذوالحجہ"
    )

    private fun toArabicNumerals(n: Int): String {
        val w = charArrayOf('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
        val a = charArrayOf('۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹')
        var s = n.toString()
        for (i in 0..9) {
            s = s.replace(w[i], a[i])
        }
        return s
    }

    private fun getGregorianMonthName(monthIdx: Int, language: String): String {
        val eng = arrayOf("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
        val urdu = arrayOf("جنوری", "فروری", "مارچ", "اپریل", "مئی", "جون", "جولائی", "اگست", "ستمبر", "اکتوبر", "نومبر", "دسمبر")
        val sindhi = arrayOf("جنوري", "فبروري", "مارچ", "اپريل", "مئي", "جون", "جولاءِ", "آگسٽ", "سيپٽمبر", "آڪٽوبر", "نومبر", "ڊسمبر")
        val arabic = arrayOf("يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر")
        val persian = arrayOf("ژانویه", "فوریه", "مارس", "آوریل", "مه", "ژوئن", "ژوئیه", "اوت", "سپتامبر", "اکتبر", "نوامبر", "دسامبر")
        val turkish = arrayOf("Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık")
        val french = arrayOf("Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre")
        val hindi = arrayOf("जनवरी", "फ़रवरी", "मार्च", "अप्रैल", "मई", "जून", "जुलाई", "अगस्त", "सितंबर", "अक्टूबर", "नवंबर", "दिसंबर")
        val bengali = arrayOf("জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর")
        val indonesian = arrayOf("Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember")

        if (monthIdx !in 0..11) return ""
        return when (language) {
            "urdu" -> urdu[monthIdx]
            "sindhi" -> sindhi[monthIdx]
            "arabic" -> arabic[monthIdx]
            "persian" -> persian[monthIdx]
            "turkish" -> turkish[monthIdx]
            "french" -> french[monthIdx]
            "hindi" -> hindi[monthIdx]
            "bengali" -> bengali[monthIdx]
            "indonesian" -> indonesian[monthIdx]
            else -> eng[monthIdx]
        }
    }

    private fun getHijriMonthName(monthIdx: Int, language: String): String {
        val eng = arrayOf("Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani", "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah")
        val urdu = arrayOf("محرم", "صفر", "ربیع الاول", "ربیع الثانی", "جمادی الاول", "جمادی الثانی", "رجب", "شعبان", "رمضان", "شوال", "ذوالقعدہ", "ذوالحجہ")
        val sindhi = arrayOf("محرم", "صفر", "ربيع الاول", "ربيع الثاني", "جمادي الاول", "جمادي الثاني", "رجب", "شعبان", "رمضان", "شوال", "ذوالقعده", "ذوالحجه")
        val arabic = arrayOf("محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة")
        val persian = arrayOf("محرم", "صفر", "ربیع‌الاول", "ربیع‌الثانی", "جمادی‌الاول", "جمادی‌الثانی", "رجب", "شعبان", "رمضان", "شوال", "ذی‌القعده", "ذی‌الحجه")
        val turkish = arrayOf("Muharrem", "Safer", "Rebiülevvel", "Rebiülahir", "Cemaziyelevvel", "Cemaziyelahir", "Recep", "Şaban", "Ramazan", "Şevval", "Zilkade", "Zilhicce")
        val french = arrayOf("Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani", "Joumada al-Awwal", "Joumada al-Thani", "Rajab", "Cha'bane", "Ramadan", "Chawwal", "Dhou al-Qi'da", "Dhou al-Hijja")
        val hindi = arrayOf("मुहर्रम", "सफ़र", "रबी अल-अव्वल", "रबी अल-थानी", "जुमादा अल-अव्वल", "जुमादा अल-थानी", "रजब", "शाबान", "रमज़ान", "शव्वाल", "ज़ुल-क़ादा", "ज़ुल-हिज्जा")
        val bengali = arrayOf("মুহাররম", "সফর", "রবিউল আউয়াল", "রবিউস সানি", "জমাদিউল আউয়াল", "জমাদিউস সানি", "রজব", "শাবান", "রমজান", "শাওয়াল", "জিলকদ", "জিলহজ")
        val indonesian = arrayOf("Muharram", "Safar", "Rabiul Awal", "Rabiul Akhir", "Jumadil Awal", "Jumadil Akhir", "Rajab", "Sya'ban", "Ramadhan", "Syawal", "Dzulqa'dah", "Dzulhijjah")

        if (monthIdx !in 0..11) return ""
        return when (language) {
            "urdu" -> urdu[monthIdx]
            "sindhi" -> sindhi[monthIdx]
            "arabic" -> arabic[monthIdx]
            "persian" -> persian[monthIdx]
            "turkish" -> turkish[monthIdx]
            "french" -> french[monthIdx]
            "hindi" -> hindi[monthIdx]
            "bengali" -> bengali[monthIdx]
            "indonesian" -> indonesian[monthIdx]
            else -> eng[monthIdx]
        }
    }

    private fun toLocalizedNumerals(num: Int, language: String): String {
        return toLocalizedNumerals(num.toString(), language)
    }

    private fun toLocalizedNumerals(s: String, language: String): String {
        if (language == "urdu" || language == "sindhi" || language == "arabic" || language == "persian") {
            val w = arrayOf("0","1","2","3","4","5","6","7","8","9")
            val a = arrayOf("۰","۱","۲","۳","۴","۵","۶","۷","۸","۹")
            var res = s
            for (i in 0..9) { res = res.replace(w[i], a[i]) }
            return res
        } else if (language == "bengali") {
            val w = arrayOf("0","1","2","3","4","5","6","7","8","9")
            val b = arrayOf("০","১","২","৩","৪","৫","৬","৭","৮","৯")
            var res = s
            for (i in 0..9) { res = res.replace(w[i], b[i]) }
            return res
        } else if (language == "hindi") {
            val w = arrayOf("0","1","2","3","4","5","6","7","8","9")
            val h = arrayOf("०","१","२","३","४","५","६","७","८","९")
            var res = s
            for (i in 0..9) { res = res.replace(w[i], h[i]) }
            return res
        }
        return s
    }

    private val hijriMonthsSindhi = arrayOf(
        "محرم", "سفر", "ربيع الاول", "ربيع الثاني",
        "جمادي الاول", "جمادي الثاني", "رجب", "شعبان",
        "رمضان", "شوال", "ذوالقعده", "ذوالحجه"
    )

    private fun gregorianDate(language: String): String {
        return try {
            val locale = when (language) {
                "urdu" -> java.util.Locale("ur")
                "arabic" -> java.util.Locale("ar")
                "sindhi" -> java.util.Locale("sd")
                "hindi" -> java.util.Locale("hi")
                "bengali" -> java.util.Locale("bn")
                "persian" -> java.util.Locale("fa")
                else -> java.util.Locale.ENGLISH
            }
            val df = java.text.SimpleDateFormat("d MMMM yyyy", locale)
            val dateStr = df.format(java.util.Date())
            toLocalizedNumerals(dateStr, language)
        } catch (e: Exception) {
            ""
        }
    }

    private fun hijriDate(context: Context, language: String, nowMins: Int, maghribM: Int): String {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val baseAdjustment = prefs.getLong("flutter.hijri_adjustment", 0L).toInt()
                val maghribRollover = if (nowMins >= maghribM) 1 else 0
                val adjustment = baseAdjustment + maghribRollover
                
                val ic = android.icu.util.IslamicCalendar()
                ic.add(Calendar.DAY_OF_MONTH, adjustment)
                val day = ic.get(Calendar.DAY_OF_MONTH)
                val mIdx = ic.get(Calendar.MONTH)
                val year = ic.get(Calendar.YEAR)
                val name = getHijriMonthName(mIdx, language)
                "${toLocalizedNumerals(day, language)} $name ${toLocalizedNumerals(year, language)}"
            } else ""
        } catch (e: Exception) { "" }
    }

    // ── Prayer-state machine ported from lib/utils/prayer_state.dart ────────
    private data class State(
        val displayName: String,
        val isElapsed: Boolean,
        val durationMins: Int,
        val highlightKey: String
    )

    private fun computeCalculatedState(
        fajar: Int, tulu: Int, zuhar: Int, asr: Int, maghrib: Int, isha: Int, now: Int
    ): State {
        val calculatedLead = 40
        val prayers = listOf(
            Pair("Fajar", fajar),
            Pair("Tulu Aftab", tulu),
            Pair("Zuhar", zuhar),
            Pair("Asr", asr),
            Pair("Maghrib", maghrib),
            Pair("Isha", isha)
        ).filter { it.second >= 0 }.sortedBy { it.second }

        if (prayers.isEmpty()) return State("Fajar", false, 0, "Fajar")

        for (next in prayers) {
            if (now >= next.second) continue

            val past = prayers.filter { it.second <= now }
            val untilNext = next.second - now

            val last = if (past.isNotEmpty()) past.last() else null
            
            // Special rule for Sunrise -> Zuhar (Continue Sunrise plus time until 09:30 AM)
            if (last != null && last.first == "Tulu Aftab" && next.first == "Zuhar") {
                val nineThirtyAm = 9 * 60 + 30
                if (now < nineThirtyAm) {
                    val key = "Tulu"
                    return State(last.first, true, now - last.second, key)
                } else {
                    val key = "Zuhar"
                    return State(next.first, false, untilNext, key)
                }
            }

            if (past.isEmpty() || untilNext <= calculatedLead) {
                val key = when (next.first) {
                    "Fajar" -> "Fajar"
                    "Tulu Aftab" -> "Tulu"
                    "Zuhar" -> "Zuhar"
                    "Asr" -> "Asr"
                    "Maghrib" -> "Maghrib"
                    "Isha" -> "Isha"
                    else -> "Fajar"
                }
                return State(next.first, false, untilNext, key)
            }
            
            
            val lastPrayer = past.last()
            val key = when (lastPrayer.first) {
                "Fajar" -> "Fajar"
                "Tulu Aftab" -> "Tulu"
                "Zuhar" -> "Zuhar"
                "Asr" -> "Asr"
                "Maghrib" -> "Maghrib"
                "Isha" -> "Isha"
                else -> "Fajar"
            }
            return State(lastPrayer.first, true, now - lastPrayer.second, key)
        }

        // Past Isha
        val last = prayers.last()
        val key = when (last.first) {
            "Fajar" -> "Fajar"
            "Tulu Aftab" -> "Tulu"
            "Zuhar" -> "Zuhar"
            "Asr" -> "Asr"
            "Maghrib" -> "Maghrib"
            "Isha" -> "Isha"
            else -> "Fajar"
        }
        return State(last.first, true, now - last.second, key)
    }

    private fun computeState(
        subah: Int, fajar: Int, tulu: Int, ishraq: Int, zawal: Int, zuhar: Int,
        misl: Int, asr: Int, maghrib: Int, isha: Int, now: Int
    ): State {
        val nineThirtyAm = 9 * 60 + 30
        val nextMidnight = 24 * 60

        fun remaining(name: String, target: Int, key: String) =
            State(name, false, target - now, key)
        fun elapsed(name: String, start: Int, key: String) =
            State(name, true, now - start, key)

        // 00:00 → Subah Sadiq
        if (subah >= 0 && now < subah) return remaining("Intiha e Sehar", subah, "Subah")
        
        // Subah Sadiq → Subah Sadiq + 3 min: elapsed from Subah Sadiq
        val subahPlus3 = if (subah >= 0) subah + 3 else -1
        if (subah >= 0 && now >= subah && now < subahPlus3) return elapsed("Intiha e Sehar", subah, "Subah")
        
        // Subah Sadiq + 3 min → Fajar
        if (fajar >= 0 && subahPlus3 >= 0 && now >= subahPlus3 && now < fajar) return remaining("Fajar", fajar, "Fajar")
        
        // Fajar → Tulu−40
        if (fajar >= 0 && tulu >= 0 && now >= fajar && now < tulu - 40) return elapsed("Fajar", fajar, "Fajar")
        
        // (no Fajar) Subah Sadiq + 3 min → Tulu−40
        if (fajar < 0 && subahPlus3 >= 0 && tulu >= 0 && now >= subahPlus3 && now < tulu - 40) return elapsed("Intiha e Sehar", subah, "Subah")

        // Tulu−40 → Tulu
        if (tulu >= 0 && now >= tulu - 40 && now < tulu) return remaining("Tulu Aftab", tulu, "Tulu")
        // Tulu → Tulu+7
        if (tulu >= 0 && now >= tulu && now < tulu + 7) return elapsed("Tulu Aftab", tulu, "Tulu")
        // Tulu+7 → Ishraq
        if (ishraq >= 0 && tulu >= 0 && now >= tulu + 7 && now < ishraq) return remaining("Ishraq", ishraq, "Ishraq")
        // Ishraq → 09:30
        if (ishraq >= 0 && now >= ishraq && now < nineThirtyAm) return elapsed("Ishraq", ishraq, "Ishraq")
        // 09:30 → Zawal
        if (zawal >= 0 && now >= nineThirtyAm && now < zawal) return remaining("Zawal", zawal, "Zawal")
        
        // Zawal → Zawal + 3 min: elapsed from Zawal
        val zawalPlus3 = if (zawal >= 0) zawal + 3 else -1
        if (zawal >= 0 && now >= zawal && now < zawalPlus3) return elapsed("Zawal", zawal, "Zawal")
        
        // Zawal + 3 min → Zuhar
        if (zuhar >= 0 && zawalPlus3 >= 0 && now >= zawalPlus3 && now < zuhar) return remaining("Zuhar", zuhar, "Zuhar")
        
        // Zuhar → Misl−30
        if (zuhar >= 0 && misl >= 0 && now >= zuhar && now < misl - 30) return elapsed("Zuhar", zuhar, "Zuhar")
        
        // (no Zuhar) Zawal + 3 min → Misl−30
        if (zuhar < 0 && zawalPlus3 >= 0 && misl >= 0 && now >= zawalPlus3 && now < misl - 30) return elapsed("Zawal", zawal, "Zawal")

        // Misl−30 → Misl
        if (misl >= 0 && now >= misl - 30 && now < misl) return remaining("Misl Awwal", misl, "Misl")
        // Misl → Asr−30
        if (misl >= 0 && asr >= 0 && now >= misl && now < asr - 30) return elapsed("Misl Awwal", misl, "Misl")
        // Asr−30 → Asr
        if (asr >= 0 && now >= asr - 30 && now < asr) return remaining("Asr", asr, "Asr")
        // Asr → Maghrib−40
        if (asr >= 0 && maghrib >= 0 && now >= asr && now < maghrib - 40) return elapsed("Asr", asr, "Asr")
        // Maghrib−40 → Maghrib
        if (maghrib >= 0 && now >= maghrib - 40 && now < maghrib) return remaining("Maghrib", maghrib, "Maghrib")
        // Maghrib → Isha−40
        if (maghrib >= 0 && isha >= 0 && now >= maghrib && now < isha - 40) return elapsed("Maghrib", maghrib, "Maghrib")
        // Isha−40 → Isha
        if (isha >= 0 && now >= isha - 40 && now < isha) return remaining("Isha", isha, "Isha")
        // Isha → 00:00
        if (isha >= 0 && now >= isha && now < nextMidnight) return elapsed("Isha", isha, "Isha")

        return State("Intiha e Sehar", false, 0, "Subah")
    }

    private fun translatePrayerName(name: String, language: String): String {
        if (language == "sindhi") {
            return when (name) {
                "Intiha e Sehar" -> "انتهاءِ سحر"
                "Fajar"       -> "فجر"
                "Tulu Aftab"  -> "سج اڀرڻ"
                "Ishraq"      -> "اشراق"
                "Zawal"       -> "زوالِ آفتاب"
                "Zuhar"       -> "ظھر"
                "Misl Awwal"  -> "مثل اول"
                "Asr"         -> "عصر"
                "Maghrib"     -> "مغرب"
                "Isha"        -> "عشاء"
                else          -> name
            }
        }
        if (language == "arabic") {
            return when (name) {
                "Intiha e Sehar" -> "نهاية السحر"
                "Fajar"       -> "الفجر"
                "Tulu Aftab"  -> "الشروق"
                "Ishraq"      -> "الإشراق"
                "Zawal"       -> "الزوال"
                "Zuhar"       -> "الظهر"
                "Misl Awwal"  -> "المثل الأول"
                "Asr"         -> "العصر"
                "Maghrib"     -> "المغرب"
                "Isha"        -> "العشاء"
                else          -> name
            }
        }
        if (language == "bengali") {
            return when (name) {
                "Intiha e Sehar" -> "ইন্তিহায়ে সেহর"
                "Fajar"       -> "ফজর"
                "Tulu Aftab"  -> "সূর্যোদয়"
                "Ishraq"      -> "ইশরাক"
                "Zawal"       -> "যাওয়াল"
                "Zuhar"       -> "যোহর"
                "Misl Awwal"  -> "মিসલ আওয়াল"
                "Asr"         -> "আসর"
                "Maghrib"     -> "মাগরিব"
                "Isha"        -> "এশা"
                else          -> name
            }
        }
        if (language == "hindi") {
            return when (name) {
                "Intiha e Sehar" -> "इंतिहा ए सहर"
                "Fajar"       -> "फ़ज्र"
                "Tulu Aftab"  -> "सूर्योदय"
                "Ishraq"      -> "इशराक़"
                "Zawal"       -> "ज़वाल"
                "Zuhar"       -> "ज़ुहर"
                "Misl Awwal"  -> "मिसल अव्वल"
                "Asr"         -> "अस्र"
                "Maghrib"     -> "मग़रिब"
                "Isha"        -> "ईशा"
                else          -> name
            }
        }
        if (language == "turkish") {
            return when (name) {
                "Intiha e Sehar" -> "İmsak Bitişi"
                "Fajar"       -> "Sabah"
                "Tulu Aftab"  -> "Güneş"
                "Ishraq"      -> "İşrak"
                "Zawal"       -> "Zeval"
                "Zuhar"       -> "Öğle"
                "Misl Awwal"  -> "Asr-ı Evvel"
                "Asr"         -> "İkindi"
                "Maghrib"     -> "Akşam"
                "Isha"        -> "Yatsı"
                else          -> name
            }
        }
        if (language == "indonesian") {
            return when (name) {
                "Intiha e Sehar" -> "Akhir Sahur"
                "Fajar"       -> "Subuh"
                "Tulu Aftab"  -> "Terbit"
                "Ishraq"      -> "Isyraq"
                "Zawal"       -> "Zawal"
                "Zuhar"       -> "Dzuhur"
                "Misl Awwal"  -> "Misl Awal"
                "Asr"         -> "Ashar"
                "Maghrib"     -> "Maghrib"
                "Isha"        -> "Isya"
                else          -> name
            }
        }
        if (language == "persian") {
            return when (name) {
                "Intiha e Sehar" -> "پایان سحر"
                "Fajar"       -> "فجر"
                "Tulu Aftab"  -> "طلوع آفتاب"
                "Ishraq"      -> "اشراق"
                "Zawal"       -> "زوال"
                "Zuhar"       -> "ظهر"
                "Misl Awwal"  -> "مثل اول"
                "Asr"         -> "عصر"
                "Maghrib"     -> "مغرب"
                "Isha"        -> "عشاء"
                else          -> name
            }
        }
        if (language == "french") {
            return when (name) {
                "Intiha e Sehar" -> "Fin du Suhoor"
                "Fajar"       -> "Fajr"
                "Tulu Aftab"  -> "Lever"
                "Ishraq"      -> "Ishraq"
                "Zawal"       -> "Zawal"
                "Zuhar"       -> "Dhuhr"
                "Misl Awwal"  -> "Misl Awwal"
                "Asr"         -> "Asr"
                "Maghrib"     -> "Maghrib"
                "Isha"        -> "Isha"
                else          -> name
            }
        }
        if (language != "urdu") return name
        return when (name) {
            "Intiha e Sehar" -> "انتہائے سحر"
            "Fajar"       -> "فجر"
            "Tulu Aftab"  -> "طلوع آفتاب"
            "Ishraq"      -> "اشراق"
            "Zawal"       -> "زوال"
            "Zuhar"       -> "ظہر"
            "Misl Awwal"  -> "مثل اول"
            "Asr"         -> "عصر"
            "Maghrib"     -> "مغرب"
            "Isha"        -> "عشاء"
            else          -> name
        }
    }

    private fun getPrayerLabelText(key: String, language: String, multiLine: Boolean): String {
        if (language == "sindhi") {
            return when (key) {
                "Subah"   -> if (multiLine) "انتهاءِ\nسحر" else "انتهاءِ سحر"
                "Fajar"   -> "فجر"
                "Tulu"    -> if (multiLine) "سج\nاڀرڻ" else "سج اڀرڻ"
                "Ishraq"  -> "اشراق"
                "Zawal"   -> "زوالِ آفتاب"
                "Zuhar"       -> "ظھر"
                "Misl"    -> if (multiLine) "مثل\nاول" else "مثل اول"
                "Asr"     -> "عصر"
                "Maghrib" -> "مغرب"
                "Isha"    -> "عشاء"
                else      -> key
            }
        }
        if (language == "urdu") {
            return when (key) {
                "Subah"   -> if (multiLine) "انتہائے\nسحر" else "انتہائے سحر"
                "Fajar"   -> "فجر"
                "Tulu"    -> if (multiLine) "طلوع\nآفتاب" else "طلوع آفتاب"
                "Ishraq"  -> "اشراق"
                "Zawal"   -> "زوال"
                "Zuhar"   -> "ظہر"
                "Misl"    -> if (multiLine) "مثل\nاول" else "مثل اول"
                "Asr"     -> "عصر"
                "Maghrib" -> "مغرب"
                "Isha"    -> "عشاء"
                else      -> key
            }
        }
        if (language == "arabic") {
            return when (key) {
                "Subah"   -> if (multiLine) "نهاية\nالسحر" else "نهاية السحر"
                "Fajar"   -> "الفجر"
                "Tulu"    -> if (multiLine) "الشروق" else "الشروق"
                "Ishraq"  -> "الإشراق"
                "Zawal"   -> "الزوال"
                "Zuhar"   -> "الظهر"
                "Misl"    -> if (multiLine) "المثل\nالأول" else "المثل الأول"
                "Asr"     -> "العصر"
                "Maghrib" -> "المغرب"
                "Isha"    -> "العشاء"
                else      -> key
            }
        }
        if (language == "bengali") {
            return when (key) {
                "Subah"   -> "ইন্তিহায়ে সেহর"
                "Fajar"   -> "ফজর"
                "Tulu"    -> "সূর্যোদয়"
                "Ishraq"  -> "ইশরাক"
                "Zawal"   -> "যাওয়াল"
                "Zuhar"   -> "যোহর"
                "Misl"    -> "মিসલ আওয়াল"
                "Asr"     -> "আসর"
                "Maghrib" -> "মাগরিব"
                "Isha"    -> "এশা"
                else      -> key
            }
        }
        if (language == "hindi") {
            return when (key) {
                "Subah"   -> "इंतिहा ए सहर"
                "Fajar"   -> "फ़ज्र"
                "Tulu"    -> "सूर्योदय"
                "Ishraq"  -> "इशराक़"
                "Zawal"   -> "ज़वाल"
                "Zuhar"   -> "ज़ुहर"
                "Misl"    -> "मिसल अव्वल"
                "Asr"     -> "अस्र"
                "Maghrib" -> "मग़रिब"
                "Isha"    -> "ईशा"
                else      -> key
            }
        }
        if (language == "turkish") {
            return when (key) {
                "Subah"   -> "İmsak Bitişi"
                "Fajar"   -> "Sabah"
                "Tulu"    -> "Güneş"
                "Ishraq"  -> "İşrak"
                "Zawal"   -> "Zeval"
                "Zuhar"   -> "Öğle"
                "Misl"    -> "Asr-ı Evvel"
                "Asr"     -> "İkindi"
                "Maghrib" -> "Akşam"
                "Isha"    -> "Yatsı"
                else      -> key
            }
        }
        if (language == "indonesian") {
            return when (key) {
                "Subah"   -> "Akhir Sahur"
                "Fajar"   -> "Subuh"
                "Tulu"    -> "Terbit"
                "Ishraq"  -> "Isyraq"
                "Zawal"   -> "Zawal"
                "Zuhar"   -> "Dzuhur"
                "Misl"    -> "Misl Awal"
                "Asr"     -> "Ashar"
                "Maghrib" -> "Maghrib"
                "Isha"    -> "Isya"
                else      -> key
            }
        }
        if (language == "persian") {
            return when (key) {
                "Subah"   -> "پایان سحر"
                "Fajar"   -> "فجر"
                "Tulu"    -> "طلوع"
                "Ishraq"  -> "اشراق"
                "Zawal"   -> "زوال"
                "Zuhar"   -> "ظهر"
                "Misl"    -> "مثل اول"
                "Asr"     -> "عصر"
                "Maghrib" -> "مغرب"
                "Isha"    -> "عشاء"
                else      -> key
            }
        }
        if (language == "french") {
            return when (key) {
                "Subah"   -> "Fin du Suhoor"
                "Fajar"   -> "Fajr"
                "Tulu"    -> "Lever"
                "Ishraq"  -> "Ishraq"
                "Zawal"   -> "Zawal"
                "Zuhar"   -> "Dhuhr"
                "Misl"    -> "Misl Awwal"
                "Asr"     -> "Asr"
                "Maghrib" -> "Maghrib"
                "Isha"    -> "Isha"
                else      -> key
            }
        }
        return when (key) {
            "Subah"   -> if (multiLine) "Intiha\ne Sehar" else "Intiha e Sehar"
            "Fajar"   -> "Fajar"
            "Tulu"    -> if (multiLine) "Tulu\nAftab" else "Tulu Aftab"
            "Ishraq"  -> "Ishraq"
            "Zawal"   -> "Zawal"
            "Zuhar"   -> "Zuhar"
            "Misl"    -> if (multiLine) "Misl\nAwwal" else "Misl Awwal"
            "Asr"     -> "Asr"
            "Maghrib" -> "Maghrib"
            "Isha"    -> "Isha"
            else      -> key
        }
    }

    private fun formatNextPrayerLabel(language: String, isElapsed: Boolean, prayerName: String): String {
        if (language == "sindhi") {
            val label = if (isElapsed) "کان" else "تائين"
            return "$prayerName $label"
        }
        if (language == "urdu") {
            val label = if (isElapsed) "سے" else "تک"
            return "$prayerName $label"
        }
        if (language == "arabic") {
            val label = if (isElapsed) "منذ" else "حتى"
            return "$label $prayerName"
        }
        if (language == "persian") {
            val label = if (isElapsed) "از" else "تا"
            return "$prayerName $label"
        }
        if (language == "bengali") {
            val label = if (isElapsed) "থেকে" else "পর্যন্ত"
            return "$prayerName $label"
        }
        if (language == "hindi") {
            val label = if (isElapsed) "से" else "तक"
            return "$prayerName $label"
        }
        if (language == "turkish") {
            val label = if (isElapsed) "geçti" else "kaldı"
            return "$prayerName'a $label"
        }
        if (language == "indonesian") {
            val label = if (isElapsed) "sejak" else "menuju"
            return "$label $prayerName"
        }
        if (language == "french") {
            val label = if (isElapsed) "depuis" else "avant"
            return "$label $prayerName"
        }
        val label = if (isElapsed) "since" else "until"
        return "$label $prayerName"
    }

    // Languages written right to left. Persian belongs here for the same
    // reason Urdu and Arabic do - it is written in Arabic script.
    private fun isRtlLanguage(language: String): Boolean =
        language == "urdu" || language == "sindhi" ||
        language == "arabic" || language == "persian"

    private fun getDayName(dayOfWeek: Int, language: String): String {
        if (language == "sindhi") {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "سومر"
                Calendar.TUESDAY   -> "اڱارو"
                Calendar.WEDNESDAY -> "اربع"
                Calendar.THURSDAY  -> "خميس"
                Calendar.FRIDAY    -> "جمعو"
                Calendar.SATURDAY  -> "ڇنڇر"
                Calendar.SUNDAY    -> "آچر"
                else               -> ""
            }
        }
        if (language == "urdu") {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "پیر"
                Calendar.TUESDAY   -> "منگل"
                Calendar.WEDNESDAY -> "بدھ"
                Calendar.THURSDAY  -> "جمعرات"
                Calendar.FRIDAY    -> "جمعہ"
                Calendar.SATURDAY  -> "ہفتہ"
                Calendar.SUNDAY    -> "اتوار"
                else               -> ""
            }
        }
        if (language == "arabic") {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "الإثنين"
                Calendar.TUESDAY   -> "الثلاثاء"
                Calendar.WEDNESDAY -> "الأربعاء"
                Calendar.THURSDAY  -> "الخميس"
                Calendar.FRIDAY    -> "الجمعة"
                Calendar.SATURDAY  -> "السبت"
                Calendar.SUNDAY    -> "الأحد"
                else               -> ""
            }
        }
        if (language == "persian") {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "دوشنبه"
                Calendar.TUESDAY   -> "سه‌شنبه"
                Calendar.WEDNESDAY -> "چهارشنبه"
                Calendar.THURSDAY  -> "پنج‌شنبه"
                Calendar.FRIDAY    -> "جمعه"
                Calendar.SATURDAY  -> "شنبه"
                Calendar.SUNDAY    -> "یکشنبه"
                else               -> ""
            }
        }
        if (language == "bengali") {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "সোমবার"
                Calendar.TUESDAY   -> "মঙ্গলবার"
                Calendar.WEDNESDAY -> "বুধবার"
                Calendar.THURSDAY  -> "বৃহস্পতিবার"
                Calendar.FRIDAY    -> "শুক্রবার"
                Calendar.SATURDAY  -> "শনিবার"
                Calendar.SUNDAY    -> "রবিবার"
                else               -> ""
            }
        }
        if (language == "hindi") {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "सोमवार"
                Calendar.TUESDAY   -> "मंगलवार"
                Calendar.WEDNESDAY -> "बुधवार"
                Calendar.THURSDAY  -> "गुरुवार"
                Calendar.FRIDAY    -> "शुक्रवार"
                Calendar.SATURDAY  -> "शनिवार"
                Calendar.SUNDAY    -> "रविवार"
                else               -> ""
            }
        }
        if (language == "turkish") {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "Pazartesi"
                Calendar.TUESDAY   -> "Salı"
                Calendar.WEDNESDAY -> "Çarşamba"
                Calendar.THURSDAY  -> "Perşembe"
                Calendar.FRIDAY    -> "Cuma"
                Calendar.SATURDAY  -> "Cumartesi"
                Calendar.SUNDAY    -> "Pazar"
                else               -> ""
            }
        }
        if (language == "indonesian") {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "Senin"
                Calendar.TUESDAY   -> "Selasa"
                Calendar.WEDNESDAY -> "Rabu"
                Calendar.THURSDAY  -> "Kamis"
                Calendar.FRIDAY    -> "Jumat"
                Calendar.SATURDAY  -> "Sabtu"
                Calendar.SUNDAY    -> "Minggu"
                else               -> ""
            }
        }
        if (language == "french") {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "Lundi"
                Calendar.TUESDAY   -> "Mardi"
                Calendar.WEDNESDAY -> "Mercredi"
                Calendar.THURSDAY  -> "Jeudi"
                Calendar.FRIDAY    -> "Vendredi"
                Calendar.SATURDAY  -> "Samedi"
                Calendar.SUNDAY    -> "Dimanche"
                else               -> ""
            }
        } else {
            return when (dayOfWeek) {
                Calendar.MONDAY    -> "Monday"
                Calendar.TUESDAY   -> "Tuesday"
                Calendar.WEDNESDAY -> "Wednesday"
                Calendar.THURSDAY  -> "Thursday"
                Calendar.FRIDAY    -> "Friday"
                Calendar.SATURDAY  -> "Saturday"
                Calendar.SUNDAY    -> "Sunday"
                else               -> ""
            }
        }
    }

    private fun setLayoutDirection(views: RemoteViews, rootId: Int, language: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            val dir = if (isRtlLanguage(language)) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
            views.setInt(rootId, "setLayoutDirection", dir)
        }
    }

    private fun bindChronometer(
        views: RemoteViews,
        viewId: Int,
        targetMins: Int,
        isElapsed: Boolean,
        language: String
    ) {
        if (targetMins < 0) {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        views.setViewVisibility(viewId, View.VISIBLE)

        val nowMs = System.currentTimeMillis()
        val targetCal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, targetMins / 60)
            set(Calendar.MINUTE, targetMins % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val targetMs = targetCal.timeInMillis
        val delayMs = targetMs - nowMs
        val baseTime = android.os.SystemClock.elapsedRealtime() + delayMs

        val format = if (isElapsed) "\u200E+%s" else "\u200E-%s"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            views.setChronometerCountDown(viewId, !isElapsed)
        }
        views.setChronometer(viewId, baseTime, format, true)
    }

    // ── Small widget ───────────────────────────────────────────────────────
    protected fun buildSmallWidget(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews {
        val layoutId = if (language != "english") R.layout.prayer_widget_small_urdu else R.layout.prayer_widget_small
        val views = RemoteViews(context.packageName, layoutId)
        setLayoutDirection(views, R.id.widget_root_small, language)
        views.setTextViewText(R.id.widget_prayer_name, translatePrayerName(data.stateName, language))
        views.setTextViewText(R.id.widget_prayer_time, data.prayerTime)   // actual clock time
        bindChronometer(views, R.id.widget_countdown, data.activeMins, data.isElapsed, language)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val loc = prefs.getString("flutter.location_string", "Sukkur") ?: "Sukkur"
        views.setTextViewText(R.id.widget_location, loc)

        views.setTextColor(R.id.widget_prayer_name, primaryText(isNight))
        views.setTextColor(R.id.widget_prayer_time, primaryText(isNight))
        views.setTextColor(R.id.widget_countdown,   accentColor(isNight))

        setupLaunchIntent(context, views, R.id.widget_root_small)
        return views
    }

    // ── Medium widget (compact timeline) ───────────────────────────────────
    protected fun buildMediumWidget(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews {
        val layoutId = if (language != "english") R.layout.prayer_widget_medium_urdu else R.layout.prayer_widget_medium
        val views = RemoteViews(context.packageName, layoutId)
        setLayoutDirection(views, R.id.widget_root_medium, language)
        val cal   = Calendar.getInstance()
        
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val loc = prefs.getString("flutter.location_string", "Sukkur") ?: "Sukkur"
        views.setTextViewText(R.id.widget_location, loc)

        views.setTextViewText(R.id.widget_day_number,      toLocalizedNumerals(cal.get(Calendar.DAY_OF_MONTH), language))
        views.setTextViewText(R.id.widget_day_name,        getDayName(cal.get(Calendar.DAY_OF_WEEK), language))
        views.setTextViewText(R.id.widget_hijri,           data.hijri)
        bindChronometer(views, R.id.widget_countdown_med, data.activeMins, data.isElapsed, language)
        views.setTextViewText(R.id.widget_next_prayer_med, formatNextPrayerLabel(language, data.isElapsed, translatePrayerName(data.stateName, language)))
        val subahParts = splitTimeAndPeriod(data.subah)
        views.setTextViewText(R.id.widget_m_subah,   subahParts.first)
        views.setTextViewText(R.id.widget_m_subah_ap, subahParts.second)

        val fajarParts = splitTimeAndPeriod(data.fajar)
        views.setTextViewText(R.id.widget_m_fajar,   fajarParts.first)
        views.setTextViewText(R.id.widget_m_fajar_ap, fajarParts.second)

        val tuluParts = splitTimeAndPeriod(data.tulu)
        views.setTextViewText(R.id.widget_m_tulu,    tuluParts.first)
        views.setTextViewText(R.id.widget_m_tulu_ap, tuluParts.second)

        val ishraqParts = splitTimeAndPeriod(data.ishraq)
        views.setTextViewText(R.id.widget_m_ishraq,  ishraqParts.first)
        views.setTextViewText(R.id.widget_m_ishraq_ap, ishraqParts.second)

        val zawalParts = splitTimeAndPeriod(data.zawal)
        views.setTextViewText(R.id.widget_m_zawal,   zawalParts.first)
        views.setTextViewText(R.id.widget_m_zawal_ap, zawalParts.second)

        val zuharParts = splitTimeAndPeriod(data.zuhar)
        views.setTextViewText(R.id.widget_m_zuhar,   zuharParts.first)
        views.setTextViewText(R.id.widget_m_zuhar_ap, zuharParts.second)

        val mislParts = splitTimeAndPeriod(data.misl)
        views.setTextViewText(R.id.widget_m_misl,    mislParts.first)
        views.setTextViewText(R.id.widget_m_misl_ap, mislParts.second)

        val asrParts = splitTimeAndPeriod(data.asr)
        views.setTextViewText(R.id.widget_m_asr,     asrParts.first)
        views.setTextViewText(R.id.widget_m_asr_ap, asrParts.second)

        val maghribParts = splitTimeAndPeriod(data.maghrib)
        views.setTextViewText(R.id.widget_m_maghrib, maghribParts.first)
        views.setTextViewText(R.id.widget_m_maghrib_ap, maghribParts.second)

        val ishaParts = splitTimeAndPeriod(data.isha)
        views.setTextViewText(R.id.widget_m_isha,    ishaParts.first)
        views.setTextViewText(R.id.widget_m_isha_ap, ishaParts.second)

        views.setTextColor(R.id.widget_day_number,      primaryText(isNight))
        views.setTextColor(R.id.widget_day_name,        secondaryText(isNight))
        views.setTextColor(R.id.widget_hijri,           mutedText(isNight))
        views.setTextColor(R.id.widget_countdown_med,   accentColor(isNight))
        views.setTextColor(R.id.widget_next_prayer_med, mutedText(isNight))
        views.setInt(R.id.widget_med_line, "setBackgroundColor", lineColor(isNight))

        applyTimeline(
            views, data, isNight, language,
            dotIds   = intArrayOf(R.id.dot_m_subah, R.id.dot_m_fajar, R.id.dot_m_tulu, R.id.dot_m_ishraq, R.id.dot_m_zawal, R.id.dot_m_zuhar, R.id.dot_m_misl, R.id.dot_m_asr, R.id.dot_m_maghrib, R.id.dot_m_isha),
            lblIds   = intArrayOf(R.id.lbl_m_subah, R.id.lbl_m_fajar, R.id.lbl_m_tulu, R.id.lbl_m_ishraq, R.id.lbl_m_zawal, R.id.lbl_m_zuhar, R.id.lbl_m_misl, R.id.lbl_m_asr, R.id.lbl_m_maghrib, R.id.lbl_m_isha),
            timeIds  = intArrayOf(R.id.widget_m_subah, R.id.widget_m_fajar, R.id.widget_m_tulu, R.id.widget_m_ishraq, R.id.widget_m_zawal, R.id.widget_m_zuhar, R.id.widget_m_misl, R.id.widget_m_asr, R.id.widget_m_maghrib, R.id.widget_m_isha),
            apIds    = intArrayOf(R.id.widget_m_subah_ap, R.id.widget_m_fajar_ap, R.id.widget_m_tulu_ap, R.id.widget_m_ishraq_ap, R.id.widget_m_zawal_ap, R.id.widget_m_zuhar_ap, R.id.widget_m_misl_ap, R.id.widget_m_asr_ap, R.id.widget_m_maghrib_ap, R.id.widget_m_isha_ap)
        )

        val isWorld = prefs.getString("flutter.location_mode", "sukkur") == "world"
        if (isWorld) {
            views.setViewVisibility(R.id.box_m_subah, View.GONE)
            views.setViewVisibility(R.id.dot_m_subah, View.GONE)
            views.setViewVisibility(R.id.box_m_ishraq, View.GONE)
            views.setViewVisibility(R.id.dot_m_ishraq, View.GONE)
            views.setViewVisibility(R.id.box_m_zawal, View.GONE)
            views.setViewVisibility(R.id.dot_m_zawal, View.GONE)
            views.setViewVisibility(R.id.box_m_misl, View.GONE)
            views.setViewVisibility(R.id.dot_m_misl, View.GONE)
        } else {
            views.setViewVisibility(R.id.box_m_subah, View.VISIBLE)
            views.setViewVisibility(R.id.dot_m_subah, View.VISIBLE)
            views.setViewVisibility(R.id.box_m_ishraq, View.VISIBLE)
            views.setViewVisibility(R.id.dot_m_ishraq, View.VISIBLE)
            views.setViewVisibility(R.id.box_m_zawal, View.VISIBLE)
            views.setViewVisibility(R.id.dot_m_zawal, View.VISIBLE)
            views.setViewVisibility(R.id.box_m_misl, View.VISIBLE)
            views.setViewVisibility(R.id.dot_m_misl, View.VISIBLE)
        }

        setupLaunchIntent(context, views, R.id.widget_root_medium)
        return views
    }

    // ── Large widget (full timeline, hijri + sunrise) ──────────────────────
    protected fun buildLargeWidget(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews {
        val layoutId = if (language != "english") R.layout.prayer_widget_large_urdu else R.layout.prayer_widget_large
        val views = RemoteViews(context.packageName, layoutId)
        setLayoutDirection(views, R.id.widget_root_large, language)
        val cal   = Calendar.getInstance()
        val dayStr = "${getDayName(cal.get(Calendar.DAY_OF_WEEK), language)} " +
                     "${toLocalizedNumerals(cal.get(Calendar.DAY_OF_MONTH), language)}-" +
                     "${toLocalizedNumerals(cal.get(Calendar.MONTH) + 1, language)}-${toLocalizedNumerals(cal.get(Calendar.YEAR), language)}"

        views.setTextViewText(R.id.widget_large_day_number, toLocalizedNumerals(cal.get(Calendar.DAY_OF_MONTH), language))
        views.setTextViewText(R.id.widget_large_day_name,   dayStr)
        views.setTextViewText(R.id.widget_large_hijri,      data.hijri)
        views.setViewVisibility(R.id.widget_large_countdown, View.GONE)
        views.setTextViewText(R.id.widget_l_subah,   data.subah)
        views.setTextViewText(R.id.widget_l_fajar,   data.fajar)
        views.setTextViewText(R.id.widget_l_tulu,    data.tulu)
        views.setTextViewText(R.id.widget_l_ishraq,  data.ishraq)
        views.setTextViewText(R.id.widget_l_zawal,   data.zawal)
        views.setTextViewText(R.id.widget_l_zuhar,   data.zuhar)
        views.setTextViewText(R.id.widget_l_misl,    data.misl)
        views.setTextViewText(R.id.widget_l_asr,     data.asr)
        views.setTextViewText(R.id.widget_l_maghrib, data.maghrib)
        views.setTextViewText(R.id.widget_l_isha,    data.isha)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val loc = prefs.getString("flutter.location_string", "Sukkur") ?: "Sukkur"
        views.setTextViewText(R.id.widget_location, loc)

        views.setTextColor(R.id.widget_large_day_number, primaryText(isNight))
        views.setTextColor(R.id.widget_large_day_name,   secondaryText(isNight))
        views.setTextColor(R.id.widget_large_hijri,      mutedText(isNight))
        views.setTextColor(R.id.widget_large_countdown,  accentColor(isNight))
        views.setInt(R.id.widget_l_line, "setBackgroundColor", lineColor(isNight))

        applyTimeline(
            views, data, isNight, language,
            dotIds  = intArrayOf(R.id.dot_l_subah, R.id.dot_l_fajar, R.id.dot_l_tulu, R.id.dot_l_ishraq, R.id.dot_l_zawal, R.id.dot_l_zuhar, R.id.dot_l_misl, R.id.dot_l_asr, R.id.dot_l_maghrib, R.id.dot_l_isha),
            lblIds  = intArrayOf(R.id.lbl_l_subah, R.id.lbl_l_fajar, R.id.lbl_l_tulu, R.id.lbl_l_ishraq, R.id.lbl_l_zawal, R.id.lbl_l_zuhar, R.id.lbl_l_misl, R.id.lbl_l_asr, R.id.lbl_l_maghrib, R.id.lbl_l_isha),
            timeIds = intArrayOf(R.id.widget_l_subah, R.id.widget_l_fajar, R.id.widget_l_tulu, R.id.widget_l_ishraq, R.id.widget_l_zawal, R.id.widget_l_zuhar, R.id.widget_l_misl, R.id.widget_l_asr, R.id.widget_l_maghrib, R.id.widget_l_isha),
            cdIds   = intArrayOf(R.id.cd_l_subah, R.id.cd_l_fajar, R.id.cd_l_tulu, R.id.cd_l_ishraq, R.id.cd_l_zawal, R.id.cd_l_zuhar, R.id.cd_l_misl, R.id.cd_l_asr, R.id.cd_l_maghrib, R.id.cd_l_isha)
        )

        val isWorld = prefs.getString("flutter.location_mode", "sukkur") == "world"
        if (isWorld) {
            views.setViewVisibility(R.id.box_l_subah, View.GONE)
            views.setViewVisibility(R.id.box_l_ishraq, View.GONE)
            views.setViewVisibility(R.id.box_l_zawal, View.GONE)
            views.setViewVisibility(R.id.box_l_misl, View.GONE)
        } else {
            views.setViewVisibility(R.id.box_l_subah, View.VISIBLE)
            views.setViewVisibility(R.id.box_l_ishraq, View.VISIBLE)
            views.setViewVisibility(R.id.box_l_zawal, View.VISIBLE)
            views.setViewVisibility(R.id.box_l_misl, View.VISIBLE)
        }

        setupLaunchIntent(context, views, R.id.widget_root_large)
        return views
    }

    // ── Tiny widget (1x1 current prayer + countdown) ───────────────────────
    protected fun buildTinyWidget(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews {
        val layoutId = if (language != "english") R.layout.prayer_widget_tiny_urdu else R.layout.prayer_widget_tiny
        val views = RemoteViews(context.packageName, layoutId)
        setLayoutDirection(views, R.id.widget_root_tiny, language)
        views.setTextViewText(R.id.tiny_prayer_name, translatePrayerName(data.stateName, language))
        bindChronometer(views, R.id.tiny_countdown, data.activeMins, data.isElapsed, language)
        
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val loc = prefs.getString("flutter.location_string", "Sukkur") ?: "Sukkur"
        views.setTextViewText(R.id.widget_location, loc)

        views.setTextColor(R.id.tiny_prayer_name, primaryText(isNight))
        views.setTextColor(R.id.tiny_countdown,   accentColor(isNight))

        setupLaunchIntent(context, views, R.id.widget_root_tiny)
        return views
    }

    // ── Slim widget (2x1 current prayer + start time + countdown) ──────────
    protected fun buildSlimWidget(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews {
        val layoutId = if (language != "english") R.layout.prayer_widget_slim_urdu else R.layout.prayer_widget_slim
        val views = RemoteViews(context.packageName, layoutId)
        setLayoutDirection(views, R.id.widget_root_slim, language)
        views.setTextViewText(R.id.slim_prayer_name, translatePrayerName(data.stateName, language))
        views.setTextViewText(R.id.slim_label,       formatNextPrayerLabel(language, data.isElapsed, translatePrayerName(data.stateName, language)))
        views.setTextViewText(R.id.slim_prayer_time, data.prayerTime)
        bindChronometer(views, R.id.slim_countdown, data.activeMins, data.isElapsed, language)
        
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val loc = prefs.getString("flutter.location_string", "Sukkur") ?: "Sukkur"
        views.setTextViewText(R.id.widget_location, loc)

        views.setTextColor(R.id.slim_prayer_name, primaryText(isNight))
        views.setTextColor(R.id.slim_label,       mutedText(isNight))
        views.setTextColor(R.id.slim_prayer_time, primaryText(isNight))
        views.setTextColor(R.id.slim_countdown,   accentColor(isNight))

        setupLaunchIntent(context, views, R.id.widget_root_slim)
        return views
    }

    // Highlight the active prayer dot/label/time across the 8-prayer timeline.
    private fun applyTimeline(
        views: RemoteViews, data: PrayerData, isNight: Boolean, language: String,
        dotIds: IntArray, lblIds: IntArray, timeIds: IntArray,
        cdIds: IntArray? = null,
        apIds: IntArray? = null
    ) {
        val keys = arrayOf("Subah", "Fajar", "Tulu", "Ishraq", "Zawal", "Zuhar", "Misl", "Asr", "Maghrib", "Isha")
        for (i in keys.indices) {
            val active = keys[i] == data.mainKey
            views.setImageViewResource(dotIds[i], if (active) R.drawable.dot_active else R.drawable.dot_inactive)
            views.setTextColor(lblIds[i],  if (active) accentColor(isNight) else secondaryText(isNight))
            views.setTextColor(timeIds[i], if (active) accentColor(isNight) else primaryText(isNight))
            views.setTextViewText(lblIds[i], getPrayerLabelText(keys[i], language, false))
            if (apIds != null && i < apIds.size) {
                views.setTextColor(apIds[i], if (active) accentColor(isNight) else primaryText(isNight))
            }

            if (cdIds != null && i < cdIds.size) {
                if (active) {
                    val targetMins = when (keys[i]) {
                        "Subah"   -> data.subahM
                        "Fajar"   -> data.fajarM
                        "Tulu"    -> data.tuluM
                        "Ishraq"  -> data.ishraqM
                        "Zawal"   -> data.zawalM
                        "Zuhar"   -> data.zuharM
                        "Misl"    -> data.mislM
                        "Asr"     -> data.asrM
                        "Maghrib" -> data.maghribM
                        "Isha"    -> data.ishaM
                        else      -> -1
                    }
                    bindChronometer(views, cdIds[i], targetMins, data.isElapsed, language)
                    views.setTextColor(cdIds[i], accentColor(isNight))
                } else {
                    views.setViewVisibility(cdIds[i], View.GONE)
                }
            }
        }
    }

    data class PrayerData(
        val stateName:  String,
        val prayerTime: String,
        val countdown:  String,
        val isElapsed:  Boolean,
        val mainKey:    String,
        val gregorian:  String,
        val hijri:      String,
        val sunrise:    String,
        val subah:   String,
        val fajar:   String,
        val tulu:    String,
        val ishraq:  String,
        val zawal:   String,
        val zuhar:   String,
        val misl:    String,
        val asr:     String,
        val maghrib: String,
        val isha:    String,
        val relativeTimes: Map<String, String>,
        val activeMins: Int,
        val subahM: Int,
        val fajarM: Int,
        val tuluM: Int,
        val ishraqM: Int,
        val zawalM: Int,
        val zuharM: Int,
        val mislM: Int,
        val asrM: Int,
        val maghribM: Int,
        val ishaM: Int
    ) {
        companion object {
            fun empty() = PrayerData(
                "Intiha e Sehar", "--:--", "--:--", false, "Subah", "", "", "--:--",
                "--:--", "--:--", "--:--", "--:--", "--:--", "--:--", "--:--", "--:--", "--:--", "--:--",
                emptyMap(), -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
            )
        }
    }

    protected fun buildCircleWidget(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews {
        val layoutId = if (language != "english") R.layout.prayer_widget_circle_urdu else R.layout.prayer_widget_circle
        val views = RemoteViews(context.packageName, layoutId)

        val cal = Calendar.getInstance()
        val dayName = getDayName(cal.get(Calendar.DAY_OF_WEEK), language)
        val day = cal.get(Calendar.DAY_OF_MONTH)
        val monthStr = getGregorianMonthName(cal.get(Calendar.MONTH), language)

        val gregStr = "${toLocalizedNumerals(day, language)} $monthStr $dayName"

        views.setTextViewText(R.id.widget_circle_gregorian, gregStr)
        views.setTextViewText(R.id.widget_circle_hijri, data.hijri)

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val style = prefs.getString("flutter.circle_widget_style", "digital")

        if (style == "analog") {
            views.setViewVisibility(R.id.widget_circle_analog_box, View.VISIBLE)
            views.setViewVisibility(R.id.widget_circle_clock_analog, View.VISIBLE)
            // Hide the whole digital row so the AM/PM marker goes with it.
            views.setViewVisibility(R.id.widget_circle_digital_box, View.GONE)
            views.setViewVisibility(R.id.widget_circle_clock_digital, View.GONE)
            try {
                val dialBitmap = getClockDialBitmap(context)
                views.setImageViewBitmap(R.id.widget_circle_clock_dial_dynamic, dialBitmap)
                views.setViewVisibility(R.id.widget_circle_clock_dial_dynamic, View.VISIBLE)
            } catch (e: Exception) {}
        } else {
            // The whole 85dp box has to go, not just its children - otherwise it
            // leaves an empty gap in the middle of the circle.
            views.setViewVisibility(R.id.widget_circle_analog_box, View.GONE)
            views.setViewVisibility(R.id.widget_circle_clock_analog, View.GONE)
            views.setViewVisibility(R.id.widget_circle_digital_box, View.VISIBLE)
            views.setViewVisibility(R.id.widget_circle_clock_digital, View.VISIBLE)
            views.setViewVisibility(R.id.widget_circle_clock_dial_dynamic, View.GONE)
        }

        val loc = prefs.getString("flutter.location_string", "Sukkur") ?: "Sukkur"
        views.setTextViewText(R.id.widget_circle_location, loc)

        views.setTextViewText(R.id.widget_circle_prayer_name, translatePrayerName(data.stateName, language))
        views.setTextViewText(R.id.widget_circle_prayer_time, data.prayerTime)
        
        val labelStr = if (data.isElapsed) {
            when (language) {
                "urdu" -> "وقت گزر چکا ہے"
                "sindhi" -> "وقت گذر چڪو آهي"
                "arabic" -> "الوقت المنقضي"
                "persian" -> "زمان سپری‌شده"
                "bengali" -> "সময় অতিবাহিত"
                "hindi" -> "बीता हुआ समय"
                "turkish" -> "Geçen süre"
                "indonesian" -> "Waktu berlalu"
                "french" -> "Temps écoulé"
                else -> "Time elapsed"
            }
        } else {
            when (language) {
                "urdu" -> "باقی وقت"
                "sindhi" -> "باقي وقت"
                "arabic" -> "الوقت المتبقي"
                "persian" -> "زمان باقی‌مانده"
                "bengali" -> "বাকি সময়"
                "hindi" -> "शेष समय"
                "turkish" -> "Kalan süre"
                "indonesian" -> "Sisa waktu"
                "french" -> "Temps restant"
                else -> "Time remaining"
            }
        }
        views.setTextViewText(R.id.widget_circle_elapsed_label, labelStr)

        bindChronometer(views, R.id.widget_circle_countdown, data.activeMins, data.isElapsed, language)

        setupLaunchIntent(context, views, R.id.widget_root_circle)
        return views
    }

    private fun getClockDialBitmap(context: Context): Bitmap {
        val size = (110 * context.resources.displayMetrics.density).toInt()
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        val cx = size / 2f
        val cy = size / 2f
        val radius = size / 2f - 4f

        paint.color = Color.WHITE
        paint.style = Paint.Style.FILL
        canvas.drawCircle(cx, cy, radius, paint)

        paint.color = Color.parseColor("#2196F3")
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 4f * context.resources.displayMetrics.density
        canvas.drawCircle(cx, cy, radius, paint)

        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        textPaint.color = Color.BLACK
        textPaint.textSize = 14f * context.resources.displayMetrics.density
        textPaint.textAlign = Paint.Align.CENTER
        textPaint.typeface = Typeface.DEFAULT_BOLD

        val tickPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        tickPaint.color = Color.parseColor("#666666")
        tickPaint.style = Paint.Style.STROKE
        tickPaint.strokeWidth = 2f * context.resources.displayMetrics.density

        val fontMetrics = textPaint.fontMetrics
        val textOffset = (fontMetrics.descent + fontMetrics.ascent) / 2

        for (i in 1..12) {
            val angle = Math.PI / 6 * (i - 3)
            // Western digits on the dial, like every other time in the widgets -
            // the prayer times, the countdown and AM/PM are all 0-9 regardless of
            // language. Only the dates read in the language's own numerals.
            val numStr = i.toString()

            val tickOuter = radius
            val tickInner = radius - 8f * context.resources.displayMetrics.density
            val startX = (cx + tickOuter * Math.cos(angle)).toFloat()
            val startY = (cy + tickOuter * Math.sin(angle)).toFloat()
            val endX = (cx + tickInner * Math.cos(angle)).toFloat()
            val endY = (cy + tickInner * Math.sin(angle)).toFloat()
            canvas.drawLine(startX, startY, endX, endY, tickPaint)

            val textRadius = radius - 20f * context.resources.displayMetrics.density
            val textX = (cx + textRadius * Math.cos(angle)).toFloat()
            val textY = (cy + textRadius * Math.sin(angle)).toFloat() - textOffset
            canvas.drawText(numStr, textX, textY, textPaint)
        }

        return bitmap
    }

    protected fun buildVerticalWidget(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews {
        val layoutId = if (language == "urdu" || language == "sindhi" || language == "arabic" || language == "persian") 
            R.layout.prayer_widget_vertical_urdu 
        else 
            R.layout.prayer_widget_vertical
            
        val views = RemoteViews(context.packageName, layoutId)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val mode = prefs.getString("flutter.location_mode", "sukkur")
        val isWorld = mode == "world"

        val prayers = listOf(
            "subah" to data.subah,
            "fajar" to data.fajar,
            "tulu" to data.tulu,
            "ishraq" to data.ishraq,
            "zawal" to data.zawal,
            "zuhar" to data.zuhar,
            "misl" to data.misl,
            "asr" to data.asr,
            "maghrib" to data.maghrib,
            "isha" to data.isha
        )

        // Background is already set in XML, no need to overwrite unless needed
        
        val textColor = if (isNight) Color.parseColor("#E0E0E0") else Color.parseColor("#1A1A2E")
        val mutedColor = if (isNight) Color.parseColor("#A0A0A0") else Color.parseColor("#888899")
        val highlightColor = if (isNight) Color.parseColor("#64B5F6") else Color.parseColor("#2196F3")

        views.setTextColor(R.id.widget_clock, textColor)
        views.setTextColor(R.id.widget_gregorian, mutedColor)
        views.setTextViewText(R.id.widget_gregorian, data.gregorian)
        views.setTextColor(R.id.widget_hijri, mutedColor)
        views.setTextViewText(R.id.widget_hijri, data.hijri)

        // Set city name
        val cityName = if (isWorld) {
            prefs.getString("flutter.city_name", "Unknown City") ?: "Unknown City"
        } else {
            when (language) {
                "urdu", "sindhi", "arabic", "persian", "pashto" -> "سکھر"
                "bengali" -> "সুক্কুর"
                "hindi" -> "सुक्कुर"
                else -> "Sukkur"
            }
        }
        views.setTextViewText(R.id.widget_city_name, cityName)
        views.setTextColor(R.id.widget_city_name, highlightColor)

        val activeKey = data.mainKey.lowercase()

        prayers.forEach { (key, timeStr) ->
            val rowId = context.resources.getIdentifier("row_$key", "id", context.packageName)
            val nameId = context.resources.getIdentifier("name_$key", "id", context.packageName)
            val timeId = context.resources.getIdentifier("time_$key", "id", context.packageName)
            val dotId = context.resources.getIdentifier("dot_$key", "id", context.packageName)

            if (rowId != 0) {
                // Determine if this prayer should be visible
                val shouldShow = !isWorld || key in listOf("fajar", "tulu", "zuhar", "asr", "maghrib", "isha")
                if (!shouldShow || timeStr == "--:--") {
                    views.setViewVisibility(rowId, View.GONE)
                } else {
                    views.setViewVisibility(rowId, View.VISIBLE)
                    
                    // Translate name
                    val translatedName = translatePrayerName(getEnglishNameForKey(key), language)
                    views.setTextViewText(nameId, translatedName)
                    views.setTextViewText(timeId, timeStr)

                    if (key == activeKey) {
                        views.setTextColor(nameId, highlightColor)
                        views.setTextColor(timeId, highlightColor)
                        views.setInt(dotId, "setColorFilter", highlightColor)
                    } else {
                        views.setTextColor(nameId, mutedColor)
                        views.setTextColor(timeId, mutedColor)
                        views.setInt(dotId, "setColorFilter", mutedColor)
                    }
                }
            }
        }

        // Countdown Line
        val activeNameTrans = translatePrayerName(data.stateName, language)
        val label = formatNextPrayerLabel(language, data.isElapsed, activeNameTrans)
        views.setTextViewText(R.id.widget_next_prayer_line, label)
        views.setTextColor(R.id.widget_next_prayer_line, textColor)
        
        bindChronometer(views, R.id.widget_countdown_line, data.activeMins, data.isElapsed, language)
        views.setTextColor(R.id.widget_countdown_line, textColor)
        
        setupLaunchIntent(context, views, R.id.widget_root_vertical)

        return views
    }


    protected fun setupLaunchIntent(context: Context, views: RemoteViews, rootId: Int) {
        val intent = Intent(context, Class.forName("pk.sukkur.salah.MainActivity"))
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
        views.setOnClickPendingIntent(rootId, pendingIntent)
    }

    protected fun getEnglishNameForKey(key: String): String {
        return when (key) {
            "subah" -> "Intiha e Sehar"
            "fajar" -> "Fajar"
            "tulu" -> "Tulu Aftab"
            "ishraq" -> "Ishraq"
            "zawal" -> "Zawal"
            "zuhar" -> "Zuhar"
            "misl" -> "Misl Awwal"
            "asr" -> "Asr"
            "maghrib" -> "Maghrib"
            "isha" -> "Isha"
            else -> "Fajar"
        }
    }
}

class PrayerWidgetSmallProvider : PrayerWidgetProvider()

class PrayerWidgetMediumProvider : PrayerWidgetProvider() {
    override fun buildViews(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews =
        buildMediumWidget(context, data, isNight, language)
}

class PrayerWidgetLargeProvider : PrayerWidgetProvider() {
    override fun buildViews(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews =
        buildLargeWidget(context, data, isNight, language)
}

class PrayerWidgetTinyProvider : PrayerWidgetProvider() {
    override fun buildViews(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews =
        buildTinyWidget(context, data, isNight, language)
}

class PrayerWidgetSlimProvider : PrayerWidgetProvider() {
    override fun buildViews(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews =
        buildSlimWidget(context, data, isNight, language)
}

class PrayerWidgetCircleProvider : PrayerWidgetProvider() {
    override fun buildViews(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews =
        buildCircleWidget(context, data, isNight, language)
}

class PrayerWidgetVerticalProvider : PrayerWidgetProvider() {
    override fun buildViews(context: Context, data: PrayerData, isNight: Boolean, language: String): RemoteViews =
        buildVerticalWidget(context, data, isNight, language)
}




