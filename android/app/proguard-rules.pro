# Flutter Local Notifications & Gson
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.** { *; }
-dontwarn com.google.gson.**

# WorkManager background worker
-keep class dev.fluttercommunity.workmanager.** { *; }

# Home widget
-keep class es.antonborri.home_widget.** { *; }

# In-app updates
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-dontwarn com.google.android.play.core.**

# Native entry points & receivers
-keep class pk.sukkur.salah.MainActivity { *; }
-keep class pk.sukkur.salah.AutoSilentReceiver { *; }
-keep class pk.sukkur.salah.BootReceiver { *; }
-keep class pk.sukkur.salah.PrayerWidget*Provider { *; }

# SQLite & Net warnings
-keep class com.tekartik.sqflite.** { *; }
-dontwarn okio.**
-dontwarn okhttp3.**
