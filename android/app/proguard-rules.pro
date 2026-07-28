# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep notification-related classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep home widget classes
-keep class es.antonborri.home_widget.** { *; }

# Keep native helper classes
-keep class pk.sukkur.salah.** { *; }

# Timezone data
-keep class org.threeten.** { *; }

# Ignore missing Play Core classes for deferred components
-dontwarn com.google.android.play.core.**
