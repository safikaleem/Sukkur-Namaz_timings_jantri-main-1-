# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep notification-related classes and Gson serialization
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat** { *; }
-keep class androidx.core.app.AlarmManagerCompat** { *; }
-dontwarn com.google.gson.**

# Keep home widget classes
-keep class es.antonborri.home_widget.** { *; }

# Keep native helper classes
-keep class pk.sukkur.salah.** { *; }

# Timezone data
-keep class org.threeten.** { *; }

# Keep WorkManager background worker classes
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class androidx.work.** { *; }

# Keep Audioplayers classes
-keep class xyz.luan.audioplayers.** { *; }

# Keep Geolocator and Geocoding classes
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }

# Keep SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep Image Cache & SQLite (used by cached_network_image)
-keep class com.tekartik.sqflite.** { *; }
-dontwarn okio.**
-dontwarn okhttp3.**

# Ignore missing Play Core classes for deferred components
-dontwarn com.google.android.play.core.**
