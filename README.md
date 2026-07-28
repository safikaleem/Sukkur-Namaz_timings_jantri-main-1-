# Sukkur Salah

Offline Islamic prayer-timings (jantri) app for Sukkur, Sindh.

## Features

- **Offline prayer times** — a full 366-day jantri (all prayer times keyed by
  month/day) bundled in the app; no internet required and it never expires.
- **Azan notifications** — per-prayer alerts with selectable azan sounds and
  per-prayer alert modes (silent / vibrate / loud / azan).
- **Auto-silent** — automatically silences the phone during Jama'at windows and
  restores the previous ringer mode afterward.
- **Custom reminders** — user-defined reminders offset from any prayer.
- **Qibla compass** — location-based Qibla direction with a live magnetometer
  compass and a static-bearing fallback for devices without a sensor.
- **Home-screen widgets** — multiple sizes that recompute prayer state natively.
- **Tasbeeh counter**, monthly view, analog clock styles, and a Hidayat screen.
- **Trilingual UI** — English, Urdu, and Sindhi with full RTL support.

## Tech stack

- Flutter (Dart SDK `>=3.0.0 <4.0.0`)
- State management: `provider`
- Notifications: `flutter_local_notifications` + `timezone`
- Location / Qibla: `geolocator`, `flutter_qiblah`
- Local storage: `shared_preferences`
- Home widgets: `home_widget` (Android) + native Kotlin providers

## Project structure

```
lib/
  data/         Loads the bundled timings.json
  models/       DayTiming / PrayerTime
  providers/    SettingsProvider (language, theme, alert modes, etc.)
  screens/      One file per tab + settings screens
  services/     Notifications, announcements, home-widget bridge
  utils/        Prayer-state math, Hijri conversion, theming, strings
  widgets/      Reusable UI (analog clock, drawer, banners, …)
assets/
  data/timings.json   The 366-day prayer schedule for Sukkur
  *.mp3               Azan audio tracks
android/app/src/main/kotlin/pk/sukkur/salah/
  MainActivity.kt         Native method channel (auto-silent, DND)
  AutoSilentReceiver.kt   Applies/restores ringer mode
  BootReceiver.kt         Restores ringer after a reboot mid-window
  PrayerWidget*Provider   Home-screen widget providers
```

## Building

```bash
flutter pub get
flutter build appbundle --release   # for Google Play
```

Release signing reads `android/key.properties` (not committed). Create it with:

```
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-your-keystore.jks>
```

## Running tests

```bash
flutter test
```

Includes `test/timings_data_test.dart`, which validates that every day in
`timings.json` has all prayer times in valid `HH:MM` form.
