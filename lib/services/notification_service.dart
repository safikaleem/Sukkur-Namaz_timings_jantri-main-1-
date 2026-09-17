import '../l10n/world_translations.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, visibleForTesting;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) 'notification_stub.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart'
    if (dart.library.html) 'notification_stub.dart';

import '../data/timings_data.dart';
import '../models/namaz_timing.dart';
import '../utils/alert_mode.dart';
import '../utils/azan_data.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  FlutterLocalNotificationsPlugin? _plugin;

  // Keys match the PrayerTime.name values in DayTiming.allTimings
  static const _prefKeys = {
    'Intiha e Sehar': 'notify_subah_sadiq',
    'Fajar': 'notify_fajar',
    'Tulu Aftab': 'notify_tulu_aftab',
    'Ishraq': 'notify_ishraq',
    'Zawal': 'notify_zawal',
    'Zuhar': 'notify_zuhar',
    'Misl Awwal': 'notify_misl_awwal',
    'Asr Hanafi': 'notify_asr_hanafi',
    'Maghrib': 'notify_maghrib',
    'Isha': 'notify_isha',
  };

  static const _urduNames = {
    'Intiha e Sehar': 'انتہائے سحر',
    'Fajar': 'فجر',
    'Tulu Aftab': 'طلوع آفتاب',
    'Ishraq': 'اشراق',
    'Zawal': 'زوال آفتاب',
    'Zuhar': 'ظہر',
    'Misl Awwal': 'مثل اول',
    'Asr Hanafi': 'عصر حنفی',
    'Asr': 'عصر', // calculated world city
    'Maghrib': 'مغرب',
    'Isha': 'عشاء',
  };

  static const _arabicNames = {
    'Intiha e Sehar': 'نهاية السحر',
    'Fajar': 'الفجر',
    'Tulu Aftab': 'الشروق',
    'Ishraq': 'الإشراق',
    'Zawal': 'الزوال',
    'Zuhar': 'الظهر',
    'Misl Awwal': 'المثل الأول',
    'Asr Hanafi': 'العصر',
    'Asr': 'العصر', // calculated world city
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };

  /// First notification id for each prayer; a day's alert is this plus its day
  /// offset, so consecutive entries must stay further apart than
  /// [scheduleHorizonDays]. Exposed so a test can prove that holds.
  @visibleForTesting
  static const baseIds = {
    'Intiha e Sehar': 100,
    'Fajar': 150,
    'Tulu Aftab': 200,
    'Ishraq': 300,
    'Zawal': 400,
    'Zuhar': 450,
    'Misl Awwal': 500,
    'Asr Hanafi': 600,
    'Maghrib': 700,
    'Isha': 800,
  };

  static const _alertModePrefKeys = {
    'Intiha e Sehar': 'alert_mode_subah_sadiq',
    'Fajar': 'alert_mode_fajar',
    'Tulu Aftab': 'alert_mode_tulu_aftab',
    'Ishraq': 'alert_mode_ishraq',
    'Zawal': 'alert_mode_zawal',
    'Zuhar': 'alert_mode_zuhar',
    'Misl Awwal': 'alert_mode_misl_awwal',
    'Asr Hanafi': 'alert_mode_asr_hanafi',
    'Maghrib': 'alert_mode_maghrib',
    'Isha': 'alert_mode_isha',
  };

  // Maps the simple prayer names used by custom reminders to the
  // detailed Jantri timing names (so we get the right time + PM handling).
  static const _reminderPrayerToTiming = {
    'Intiha e Sehar': 'Intiha e Sehar',
    'Fajar': 'Fajar',
    'Tulu Aftab': 'Tulu Aftab',
    'Ishraq': 'Ishraq',
    'Zawal': 'Zawal',
    'Zuhar': 'Zuhar',
    'Misl Awwal': 'Misl Awwal',
    'Asr Hanafi': 'Asr Hanafi',
    'Maghrib': 'Maghrib',
    'Isha': 'Isha',

    // Backward compatibility for old reminders
    'Fajr': 'Intiha e Sehar',
    'Dhuhr': 'Zawal',
    'Asr': 'Asr Hanafi',
  };

  // Notification channel ids - v7 for silent (importance bump: low→default, forces fresh channel on update)
  static const _chSilent = 'namaz_silent_v7';
  static const _chVibrate = 'namaz_vibrate_v6';
  static const _chLoud = 'namaz_loud_bell_v7';
  static const _chReminder = 'namaz_reminder_v6';

  // We will create dynamic azan channels based on the selected azan index.
  static String _getAzanChannelId(int index) => 'namaz_azan_v6_$index';

  Future<void> init() async {
    if (kIsWeb) return;

    // Ensure TimingsData is loaded
    await TimingsData.instance.load();

    tz_data.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    // Some OEM/legacy device ids are absent from the bundled tz database and
    // tz.getLocation() throws — fall back to the app's home timezone so init()
    // never crashes startup.
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    }

    _plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin!.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await _createChannels(android);
  }

  Future<void> requestPermissions() async {
    if (kIsWeb || _plugin == null) return;
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
  }

  // Channels must be created up-front: on Android 8+ the channel's sound
  // (set here) is what plays — per-notification sound is ignored.
  // audioAttributesUsage: AudioAttributesUsage.notification ensures Android
  // routes sound through the notification stream, which the OS automatically
  // mutes/reduces when the phone is in silent or vibrate mode.
  // bypassDnd: false ensures Do-Not-Disturb is also respected.
  Future<void> recreationChannels() async {
    if (kIsWeb || _plugin == null) return;
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await _createChannels(android);
    }
  }

  Future<void> recreateChannels() async {
    await recreationChannels();
  }

  Future<void> _createChannels(
      AndroidFlutterLocalNotificationsPlugin? android) async {
    if (android == null) return;
    const desc = 'سکھر کے نماز کے اوقات کی اطلاع';

    // Delete legacy channels ONCE using a migration key in SharedPreferences.
    // Executing 55+ deleteNotificationChannel IPC calls repeatedly on every launch/schedule
    // causes "Slow Binder call" ANR on Android.
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyCleaned = prefs.getBool('legacy_channels_deleted_v7') ?? false;

    if (!alreadyCleaned) {
      final oldChannels = [
        'namaz_silent', 'namaz_silent_v2', 'namaz_silent_v3', 'namaz_silent_v4', 'namaz_silent_v5',
        'namaz_silent_v6',
        'namaz_vibrate', 'namaz_vibrate_v2', 'namaz_vibrate_v3', 'namaz_vibrate_v4', 'namaz_vibrate_v5',
        'namaz_loud', 'namaz_loud_bell_v1', 'namaz_loud_bell_v2', 'namaz_loud_bell_v3', 'namaz_loud_bell_v4', 'namaz_loud_bell_v5',
        'namaz_reminder', 'namaz_reminder_v1', 'namaz_reminder_v2', 'namaz_reminder_v3', 'namaz_reminder_v4', 'namaz_reminder_v5'
      ];
      for (final id in oldChannels) {
        try {
          await android.deleteNotificationChannel(id);
        } catch (_) {}
      }
      for (int i = 0; i < azanTracks.length; i++) {
        try {
          await android.deleteNotificationChannel('namaz_azan_$i');
          await android.deleteNotificationChannel('namaz_azan_v2_$i');
          await android.deleteNotificationChannel('namaz_azan_v3_$i');
          await android.deleteNotificationChannel('namaz_azan_v4_$i');
          await android.deleteNotificationChannel('namaz_azan_v5_$i');
        } catch (_) {}
      }
      await prefs.setBool('legacy_channels_deleted_v7', true);
    }

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chSilent,
      'نماز خاموش',
      description: desc,
      // Use defaultImportance (not low): Importance.low is aggressively suppressed
      // by Vivo/Samsung OEM battery managers when the screen is off, causing
      // silent-mode prayer notifications to never appear.
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
      audioAttributesUsage: AudioAttributesUsage.notification,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chVibrate,
      'نماز وائبریشن',
      description: desc,
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chLoud,
      'نماز کے اوقات',
      description: desc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
      sound: RawResourceAndroidNotificationSound('mixkit_bell_notification_933'),
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chReminder,
      'ذاتی یاد دہانیاں',
      description: 'آپ کی مقرر کردہ یاد دہانیاں',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
      sound: RawResourceAndroidNotificationSound('mixkit_bell_notification_933'),
    ));

    // Create a channel for each azan track
    for (int i = 0; i < azanTracks.length; i++) {
      await android.createNotificationChannel(AndroidNotificationChannel(
        _getAzanChannelId(i),
        'اذان (${azanTracks[i].urduName})',
        description: 'نماز کے وقت اذان کی آواز',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        sound: RawResourceAndroidNotificationSound(azanTracks[i].androidSound),
      ));
    }

  }

  /// The zone the timings currently on file are expressed in.
  ///
  /// A world city's times are that city's own wall clock, so they have to be
  /// pinned to that city's zone. Reading them as device-local would fire
  /// London's 20:50 Maghrib at 20:50 in Pakistan - four hours early. The Jantri
  /// is always device-local, which is what [tz.local] already gives.
  tz.Location _timingsLocation(SharedPreferences prefs) {
    final isWorld = (prefs.getString('location_mode') ?? 'sukkur') == 'world';
    // The user can ask for a watched city's alerts to land on their own clock
    // instead - see TimingsData.alertTimezoneKey. tz.local is exactly that.
    final followsDevice =
        (prefs.getString(TimingsData.alertTimezoneKey) ?? 'city') == 'device';
    final zone = prefs.getString('city_timezone');
    if (isWorld && !followsDevice && zone != null && zone.isNotEmpty) {
      try {
        return tz.getLocation(zone);
      } catch (_) {
        // Unknown zone id - fall back to the device's own.
      }
    }
    return tz.local;
  }

  /// Reads [prayerDt]'s wall-clock fields as a time *in* [location].
  tz.TZDateTime _atWallClock(tz.Location location, DateTime prayerDt) =>
      tz.TZDateTime(location, prayerDt.year, prayerDt.month, prayerDt.day,
          prayerDt.hour, prayerDt.minute);

  /// How far ahead prayers are scheduled.
  ///
  /// Two weeks rather than one: the WorkManager job that refreshes this is
  /// itself throttled by Doze and OEM battery managers, so a phone that
  /// suppresses it for several days used to run clean out of alarms and go
  /// silent. The horizon now outlasts a long gap between refreshes.
  static const int scheduleHorizonDays = 14;

  /// Every notification id written by the last successful run.
  ///
  /// Rescheduling used to open with `cancelAll()`, which left a window - one
  /// that lasted until the batch finished - where the phone held *no* prayer
  /// alarms at all. On an OEM that kills background work mid-run, that window
  /// never closed and the user simply stopped being notified. Now each id is
  /// overwritten in place (a schedule with an existing id replaces it) and only
  /// ids that this run did not rewrite are cancelled, once it is safely done.
  static const _scheduledIdsKey = 'scheduled_notification_ids';

  /// Notification id for custom reminder [index] on day [dayOffset].
  ///
  /// Reminder ids live above 9000 so they cannot collide with prayers, and are
  /// spaced by 100 so a reminder's later days cannot run into the next
  /// reminder's earlier ones - which is exactly what a 10-wide gap did once the
  /// horizon grew past ten days.
  static int reminderNotificationId(int index, int dayOffset) =>
      9000 + (index * 100) + dayOffset;

  /// Cancels the ids the previous run left behind that this one did not rewrite,
  /// then records the current set for next time.
  Future<void> _dropStaleNotifications(
      SharedPreferences prefs, Set<int> writtenIds) async {
    final previous = (prefs.getStringList(_scheduledIdsKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>();
    for (final id in previous) {
      if (writtenIds.contains(id)) continue;
      try {
        await _plugin!.cancel(id);
      } catch (e) {
        debugPrint('Failed to cancel stale notification $id: $e');
      }
    }
    await prefs.setStringList(
        _scheduledIdsKey, writtenIds.map((id) => '$id').toList());
  }

  Future<void> scheduleWeeklyNotifications() async {
    if (kIsWeb || _plugin == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications_enabled') ?? true)) {
      // Switched off outright - here the clean sweep is the intent.
      await _plugin!.cancelAll();
      await prefs.remove(_scheduledIdsKey);
      return;
    }

    // On Android 12+ exact-alarm permission can be revoked (by the user or an
    // OEM battery manager). Rather than let zonedSchedule throw and abort the
    // whole batch, detect the capability once and fall back to inexact
    // scheduling — notifications still fire, just not to-the-second.
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    // alarmClock mode uses AlarmManager.setAlarmClock() — the same API used
    // by Samsung Clock, Google Clock, and all reliable alarm apps. Unlike
    // setExactAndAllowWhileIdle(), it CANNOT be deferred or canceled by any
    // OEM battery optimizer (Samsung, Vivo, Xiaomi, etc.), ensuring prayer
    // notifications fire exactly on time on ALL Android devices including
    // older ones (Android 9/10/11) that lack USE_EXACT_ALARM protection.
    // Side effect: shows a small ⏰ icon in status bar for next prayer time.
    final scheduleMode = canExact
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.inexactAllowWhileIdle;
    debugPrint('Schedule Mode: ${canExact ? "EXACT" : "INEXACT (Fallback)"}');

    final selectedAzanIndex = prefs.getInt('selected_azan_index') ?? 3;
    final timingsLocation = _timingsLocation(prefs);

    // Ensure TimingsData is loaded (crucial for background task)
    await TimingsData.instance.load();

    // In the timings' own frame, so "has this prayer already passed?" is asked
    // against the same clock the times are written in.
    final now = TimingsData.instance.nowForTimings();
    // Everything this run writes, so the stale ids from the last run - and only
    // those - can be cleared at the end.
    final writtenIds = <int>{};
    int batchCounter = 0;

    for (int dayOffset = 0; dayOffset < scheduleHorizonDays; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final timing = TimingsData.instance.timingFor(date);
      if (timing == null) continue;

      for (final prayer in timing.allTimings) {
        final prefKey = _prefKeys[prayer.name];
        if (prefKey == null) continue;
        if (!(prefs.getBool(prefKey) ?? true)) continue;

        final prayerDt = prayer.toDateTime(date: date);
        if (prayerDt.isBefore(now)) continue;

        final modeStr =
            prefs.getString(_alertModePrefKeys[prayer.name] ?? '') ?? 'loud';
        var mode = AlertMode.values.firstWhere(
          (m) => m.name == modeStr,
          orElse: () => AlertMode.loud,
        );
        if ((prayer.name == 'Intiha e Sehar' || prayer.name == 'Zawal') &&
            mode == AlertMode.azan) {
          mode = AlertMode.loud;
        }

        final tzDateTime = _atWallClock(timingsLocation, prayerDt);
        final notifId = (baseIds[prayer.name] ?? 0) + dayOffset;

        final langCode = prefs.getString('language_code') ?? 'english';
        final isSukkurMode =
            (prefs.getString('location_mode') ?? 'sukkur') == 'sukkur';
        final rawTime = _formatTime12Hour(prayer.time, prayer.isPm).replaceAll(' ', '');

        final alert = prayerAlert(
          prayer: prayer,
          language: langCode,
          isSukkurMode: isSukkurMode,
          rawTime: rawTime,
        );
        final String title = alert.$1;
        final String body = alert.$2;

        // Guard each schedule individually so one bad entry (e.g. a malformed
        // time) skips a single notification instead of aborting the batch and
        // leaving the user with none.
        try {
          await _plugin!.zonedSchedule(
            notifId,
            title,
            body,
            tzDateTime,
            _detailsFor(mode, selectedAzanIndex, isRtl: rtlLanguages.contains(langCode)),
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          writtenIds.add(notifId);
          batchCounter++;
          // Yield to event looper every 5 notifications to process pending touch
          // and window dispatching events, preventing ANR (Input dispatching timed out).
          if (batchCounter % 5 == 0) {
            await Future.delayed(Duration.zero);
          }
        } catch (e) {
          debugPrint('Failed to schedule notification $notifId: $e');
        }
      }
    }

    writtenIds.addAll(
        await _scheduleCustomReminders(prefs, now, scheduleMode));
    writtenIds.addAll(
        await _scheduleWeeklyFridayNotification(prefs, now, scheduleMode));

    // Only now, with every replacement safely in place, drop what this run no
    // longer needs - a prayer switched off, a deleted reminder, a day that has
    // fallen off the end of the horizon.
    await _dropStaleNotifications(prefs, writtenIds);

    // Schedule Auto-Silent alarms
    final autoSilentEnabled = prefs.getBool('auto_silent_enabled') ?? false;
    const nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');
    if (autoSilentEnabled) {
      final autoSilentMode = prefs.getString('auto_silent_mode') ?? 'vibrate';
      final List<Map<String, dynamic>> silentAlarms = [];
      final silentBases = {
        'Fajar': 1000,
        'Zuhar': 3000,
        'Misl Awwal': 3500,
        'Asr Hanafi': 4000,
        'Maghrib': 4500,
        'Isha': 5000,
      };

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final date = now.add(Duration(days: dayOffset));
        final timing = TimingsData.instance.timingFor(date);
        if (timing == null) continue;

        for (final prayer in timing.allTimings) {
          final base = silentBases[prayer.name];
          if (base != null) {
            final isPrayerAutoSilentEnabled = prefs.getBool('auto_silent_enabled_${prayer.name}') ?? true;
            if (!isPrayerAutoSilentEnabled) continue;

            final offset = prefs.getInt('auto_silent_offset_${prayer.name}') ?? (prayer.name == 'Maghrib' ? 5 : 15);
            final duration = prefs.getInt('auto_silent_duration_${prayer.name}') ?? (prayer.name == 'Maghrib' ? 15 : 20);

            final prayerDt = prayer.toDateTime(date: date);
            final startDt = prayerDt.add(Duration(minutes: offset));
            final endDt = startDt.add(Duration(minutes: duration));

            if (startDt.isAfter(now)) {
              silentAlarms.add({
                'id': base + dayOffset,
                'triggerTimeMillis': startDt.millisecondsSinceEpoch,
                'type': 'start',
                'mode': autoSilentMode,
              });
            }
            if (endDt.isAfter(now)) {
              silentAlarms.add({
                'id': base + 100 + dayOffset,
                'triggerTimeMillis': endDt.millisecondsSinceEpoch,
                'type': 'restore',
                'mode': autoSilentMode,
              });
            }
          }
        }
      }

      try {
        if (silentAlarms.isNotEmpty) {
          await nativeChannel.invokeMethod('scheduleAutoSilent', {'alarms': silentAlarms});
        } else {
          await nativeChannel.invokeMethod('cancelAllAutoSilent');
        }
      } catch (e) {
        debugPrint('Failed to schedule Auto-Silent: $e');
      }
    } else {
      try {
        await nativeChannel.invokeMethod('cancelAllAutoSilent');
      } catch (e) {
        debugPrint('Failed to cancel Auto-Silent: $e');
      }
    }
  }

  /// Builds platform notification details for the given alert [mode].
  /// [isRtl] — when true (Urdu / Sindhi) a large icon is included; Android
  /// automatically places it on the RIGHT side for RTL locales, giving a
  /// single icon on the correct side. For English (LTR) no large icon is used.
  NotificationDetails _detailsFor(AlertMode mode, int selectedAzanIndex,
      {bool isRtl = false}) {
    String channelId;
    String channelName;
    bool playSound;
    bool enableVibration;
    Importance importance;
    Priority priority;
    AndroidNotificationSound? androidSound;
    String? iosSound;

    switch (mode) {
      case AlertMode.silent:
        channelId = _chSilent;
        channelName = 'نماز خاموش';
        playSound = false;
        enableVibration = false;
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
      case AlertMode.vibrate:
        channelId = _chVibrate;
        channelName = 'نماز وائبریشن';
        playSound = false;
        enableVibration = true;
        importance = Importance.high;
        priority = Priority.high;
      case AlertMode.loud:
        channelId = _chLoud;
        channelName = 'نماز کے اوقات';
        playSound = true;
        enableVibration = true;
        importance = Importance.high;
        priority = Priority.high;
        androidSound = const RawResourceAndroidNotificationSound('mixkit_bell_notification_933');
      case AlertMode.azan:
        // Use safely bounded index
        final safeIndex =
            (selectedAzanIndex >= 0 && selectedAzanIndex < azanTracks.length)
                ? selectedAzanIndex
                : 0;
        final track = azanTracks[safeIndex];

        channelId = _getAzanChannelId(safeIndex);
        channelName = 'اذان (${track.urduName})';
        playSound = true;
        enableVibration = true;
        importance = Importance.high;
        priority = Priority.high;
        androidSound = RawResourceAndroidNotificationSound(track.androidSound);
        iosSound = track.iosSound;
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'سکھر کے نماز کے اوقات کی اطلاع',
        importance: importance,
        priority: priority,
        playSound: playSound,
        enableVibration: enableVibration,
        sound: androidSound,
        // Small icon (status bar): white monochrome required by Android 5+ rules.
        icon: '@drawable/ic_notification',
        // No largeIcon: Android places largeIcon on the LEFT regardless of RTL.
        // All languages show only the small badge (right side) for a clean look.
        // Brand color — tints the small status-bar icon with the app's teal color.
        color: const Color(0xFF0D6B5E),
        visibility: NotificationVisibility.public,
        styleInformation: const DefaultStyleInformation(true, true),
        // NOTE: fullScreenIntent was removed — it caused the app to open/launch
        // every time the user pressed the power button to unlock the screen.
        // fullScreenIntent is only for alarm-clock apps that replace the lock screen.
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
        sound: iosSound,
      ),
    );
  }

  /// Schedules the weekly Friday 8 AM notification for Surah Al-Kahf, returning
  /// the id it wrote (empty if it could not be scheduled).
  Future<Set<int>> _scheduleWeeklyFridayNotification(
      SharedPreferences prefs, DateTime now, AndroidScheduleMode scheduleMode) async {
    final language = prefs.getString('language_code') ??
        (prefs.getBool('is_sindhi') == true
            ? 'sindhi'
            : (prefs.getBool('is_urdu') == true ? 'urdu' : 'english'));

    String title;
    String subtitle;
    String hadith;

    switch (language) {
      case 'urdu':
        title = 'جمعہ مبارک';
        subtitle = 'آج کے بابرکت دن میں سورۂ کہف کی تلاوت کا اہتمام فرمائیں';
        hadith = 'شروع کی دس آیات: حضرت ابو درداء رضی اللہ عنہ سے روایت ہے کہ رسول اللہ ﷺ نے فرمایا: ”جو شخص سورہ کہف کی ابتدائی دس آیات یاد کرے اور پڑھے گا، وہ دجال کے فتنہ سے محفوظ رہے گا۔“ (صحیح مسلم)\nآخری آیات: ایک اور روایت میں ہے کہ آخری دس آیات پڑھنے والا بھی دجال سے محفوظ رہتا ہے۔';
        break;
      case 'sindhi':
        title = 'جمعي مبارڪ';
        subtitle = 'اڄ جي بابرڪت ڏينهن تي سوره ڪهف جي تلاوت جو اهتمام ڪريو';
        hadith = 'شروع جون ڏهه آيتون: حضرت ابو درداء رضي الله عنه کان روايت آهي ته رسول الله ﷺ فرمايو: ”جيڪو شخص سوره ڪهف جون شروعاتي ڏهه آيتون ياد ڪندو ۽ پڙهندو، اهو دجال جي فتني کان محفوظ رهندو.“ (صحيح مسلم)\nآخري آيتون: هڪ ٻي روايت ۾ آهي ته آخري ڏهه آيتون پڙهڻ وارو به دجال کان محفوظ رهندو آهي.';
        break;
      case 'arabic':
        title = 'جمعة مباركة';
        subtitle = 'في هذا اليوم المبارك، احرص على تلاوة سورة الكهف.';
        hadith = 'وحَدَّثَنَا مُحَمَّدُ بْنُ الْمُثَنَّى ، حَدَّثَنَا مُعَاذُ بْنُ هِشَامٍ ، حَدَّثَنِي أَبِي ، عَنْ قَتَادَةَ ، عَنْ سَالِمِ بْنِ أَبِي الْجَعْدِ الْغَطَفَانِيِّ ، عَنْ مَعْدَانَ بْنِ أَبِي طَلْحَةَ الْيَعْمَرِيِّ ، عَنْ أَبِي الدَّرْدَاءِ ، أَنّ النَّبِيَّ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، قَالَ: " مَنْ حَفِظَ عَشْرَ آيَاتٍ مِنْ أَوَّلِ سُورَةِ الْكَهْف عُصِمَ مِنَ الدَّجَّالِ ".';
        break;
      case 'turkish':
        title = 'Hayırlı Cumalar';
        subtitle = 'Bu mübarek günde Kehf Suresi\'ni okumaya özen gösterin.';
        hadith = 'İlk 10 Ayet: Ebu Derda (RA)\'dan rivayet edildiğine göre Peygamberimiz ﷺ şöyle buyurmuştur: "Kim Kehf Suresi\'nin ilk on ayetini ezberler ve okursa Deccal\'in fitnesinden korunur." (Sahih-i Müslim)\nSon Ayetler: Başka bir rivayette son on ayeti okuyanın da Deccal\'den korunacağı bildirilmektedir.';
        break;
      case 'french':
        title = 'Jummah Mubarak';
        subtitle = 'En ce jour béni, veillez à réciter la sourate Al-Kahf.';
        hadith = 'Les 10 premiers versets : Abu Darda (RA) a rapporté que le Prophète ﷺ a dit : « Quiconque mémorise et récite les dix premiers versets de la sourate Al-Kahf sera protégé de l\'épreuve du Dajjal. » (Sahih Muslim)\nDerniers versets : Une autre narration indique que celui qui récite les dix derniers versets sera également protégé du Dajjal.';
        break;
      case 'hindi':
        title = 'जुम्मा मुबारक';
        subtitle = 'आज के बरकत वाले दिन में सूरह अल-कहफ़ की तिलावत का एहतमाम करें।';
        hadith = 'शुरू की दस आयतें: हज़रत अबू दर्दा (रज़ि.) से रिवायत है कि रसूलल्लाह ﷺ ने फ़रमाया: "जो शख्स सूरह अल-कहफ़ की शुरुआती दस आयतें याद करेगा और पढ़ेगा, वह दज्जाल के फ़ितने से महफ़ूज़ रहेगा।" (सहीह मुस्लिम)\nआखिरी आयतें: एक और रिवायत में है कि आखिरी दस आयतें पढ़ने वाला भी दज्जाल से महफ़ूज़ रहता है।';
        break;
      case 'bengali':
        title = 'জুম্মা মোবারক';
        subtitle = 'আজকের বরকতময় দিনে সূরা আল-কাহাফ তেলাওয়াত করার চেষ্টা করুন।';
        hadith = 'প্রথম ১০ আয়াত: আবু দারদা (রাঃ) থেকে বর্ণিত, রাসূলুল্লাহ ﷺ বলেছেন: "যে ব্যক্তি সূরা আল-কাহাফের প্রথম দশটি আয়াত মুখস্থ করবে এবং পড়বে, সে দাজ্জালের ফিতনা থেকে নিরাপদ থাকবে।" (সহীহ মুসলিম)\nশেষ আয়াতসমূহ: অন্য একটি বর্ণনায় বলা হয়েছে যে, যে ব্যক্তি শেষ দশটি আয়াত পড়বে সেও দাজ্জাল থেকে নিরাপদ থাকবে।';
        break;
      case 'indonesian':
        title = 'Jumat Berkah';
        subtitle = 'Pada hari yang penuh berkah ini, pastikan untuk membaca Surah Al-Kahf.';
        hadith = '10 Ayat Pertama: Abu Darda (RA) meriwayatkan bahwa Nabi ﷺ bersabda: "Barangsiapa menghafal dan membaca sepuluh ayat pertama Surah Al-Kahf akan dilindungi dari fitnah Dajjal." (Sahih Muslim)\nAyat Terakhir: Riwayat lain menyebutkan bahwa barangsiapa membaca sepuluh ayat terakhir juga akan dilindungi dari Dajjal.';
        break;
      case 'persian':
        title = 'جمعه مبارک';
        subtitle = 'در این روز پر برکت، حتماً به تلاوت سوره کهف اهتمام ورزید.';
        hadith = 'ده آیه اول: حضرت ابو درداء (رض) روایت کرده است که پیامبر ﷺ فرمودند: «هر کس ده آیه اول سوره کهف را حفظ کند و بخواند، از فتنه دجال در امان خواهد بود.» (صحیح مسلم)\nآیات آخر: در روایت دیگری آمده است که هر کس ده آیه آخر را بخواند نیز از دجال در امان می‌ماند.';
        break;
      case 'english':
      default:
        title = 'Jummah Mubarak';
        subtitle = 'On this blessed day, make sure to recite Surah Al-Kahf.';
        hadith = 'First 10 Ayahs: Abu Darda (RA) reported that the Prophet ﷺ said: "Whoever memorizes and recites the first ten verses of Surah Al-Kahf will be protected from the trial of Dajjal." (Sahih Muslim)\nLast Ayahs: Another narration states that whoever recites the last ten verses will also be protected from Dajjal.';
        break;
    }

    final isRtl = (language == 'urdu' || language == 'sindhi' || language == 'arabic' || language == 'persian');
    final String bodyHtml = isRtl
        ? '<div dir="rtl" style="text-align: right;"><p>$subtitle</p><p>$hadith</p></div>'
        : '<p>$subtitle</p><p>$hadith</p>';

    final String plainBody = '$subtitle\n\n$hadith';

    // Find the next Friday at 10:00 AM
    int daysUntilFriday = DateTime.friday - now.weekday;
    if (daysUntilFriday < 0) {
      daysUntilFriday += 7;
    }
    DateTime nextFriday = DateTime(now.year, now.month, now.day, 10, 0).add(Duration(days: daysUntilFriday));
    
    // If it's already past 10:00 AM on a Friday, schedule for next week
    if (daysUntilFriday == 0 && now.hour >= 10) {
      nextFriday = nextFriday.add(const Duration(days: 7));
    }

    final tzNextFriday = tz.TZDateTime.from(nextFriday, tz.local);

    try {
      await _plugin!.zonedSchedule(
        8000, // Fixed ID for Friday notification
        isRtl ? '<b>$title</b>' : '<b>$title</b>',
        plainBody,
        tzNextFriday,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _chSilent,
            'Friday Reminders',
            channelDescription: 'Weekly reminders for Jummah',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: false,
            styleInformation: BigTextStyleInformation(
              plainBody,
              htmlFormatBigText: true,
              htmlFormatContent: true,
              htmlFormatContentTitle: true,
              htmlFormatTitle: true,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      return {8000};
    } catch (e) {
      debugPrint('Failed to schedule Friday notification: $e');
      return {};
    }
  }

  /// Reads the user's custom reminders and schedules them across the horizon,
  /// returning every notification id it wrote.
  Future<Set<int>> _scheduleCustomReminders(
      SharedPreferences prefs, DateTime now,
      AndroidScheduleMode scheduleMode) async {
    final written = <int>{};
    final raw = prefs.getString('custom_reminders');
    if (raw == null) return written;

    final reminderLocation = _timingsLocation(prefs);

    List list;
    try {
      list = jsonDecode(raw) as List;
    } catch (_) {
      return written;
    }

    for (int i = 0; i < list.length; i++) {
      final m = list[i];
      if (m is! Map) continue;
      if (!((m['enabled'] as bool?) ?? true)) continue;

      final prayerName = m['prayerName'] as String?;
      final offset = (m['offsetMinutes'] as int?) ?? 0;
      final label = (m['label'] as String?)?.trim();
      final timingName = _reminderPrayerToTiming[prayerName];
      if (timingName == null) continue;

      for (int dayOffset = 0; dayOffset < scheduleHorizonDays; dayOffset++) {
        final date = now.add(Duration(days: dayOffset));
        final timing = TimingsData.instance.timingFor(date);
        if (timing == null) continue;

        PrayerTime? pt;
        for (final p in timing.allTimings) {
          if (p.name == timingName) {
            pt = p;
            break;
          }
        }
        if (pt == null) continue;

        // Built in the timings' own zone before the offset is applied, so a
        // reminder for a world city tracks that city's clock like the prayer
        // itself does. TZDateTime compares as an absolute instant, so the
        // "already passed" check stays correct whatever zone it is in.
        final tzDt = _atWallClock(reminderLocation, pt.toDateTime(date: date))
            .add(Duration(minutes: offset));
        // Against the real instant, not [now]: [now] carries the timings' own
        // wall clock, which for a watched city is not the same point in time.
        if (tzDt.isBefore(DateTime.now())) continue;
        final id = reminderNotificationId(i, dayOffset);

        final reminderLang = prefs.getString('language_code') ?? 'english';
        final String reminderTitle = (label == null || label.isEmpty)
            ? translateFor(reminderLang, 'Reminder', 'یاد دہانی', 'ياد دهاني',
                'تذكير')
            : label;
        final String reminderBodyText =
            _reminderBody(prayerName!, offset, reminderLang);

        try {
        await _plugin!.zonedSchedule(
          id,
          rtlLanguages.contains(reminderLang)
              ? '\u200F$reminderTitle'
              : reminderTitle,
          rtlLanguages.contains(reminderLang)
              ? '\u200F$reminderBodyText'
              : reminderBodyText,
          tzDt,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _chReminder,
              'ذاتی یاد دہانیاں',
              channelDescription: 'آپ کی مقرر کردہ یاد دہانیاں',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@drawable/ic_notification',
              // No largeIcon for any language — keeps single badge on right.
              visibility: NotificationVisibility.public,
              sound: const RawResourceAndroidNotificationSound('mixkit_bell_notification_933'),
              styleInformation: const DefaultStyleInformation(true, true),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        written.add(id);
        } catch (e) {
          debugPrint('Failed to schedule reminder $id: $e');
        }
      }
    }
    return written;
  }

  /// Title and body for a prayer-time alert.
  ///
  /// English in Sukkur mode keeps its long-standing mixed format - the English
  /// prayer name followed by the Urdu suffix - because that pairing belongs to
  /// the Jantri. Every other combination, including English once a world city
  /// is selected, is rendered wholly in the selected language.
  @visibleForTesting
  (String, String) prayerAlert({
    required PrayerTime prayer,
    required String language,
    required bool isSukkurMode,
    required String rawTime,
  }) {
    final isRtl = rtlLanguages.contains(language);
    // U+200F forces RTL layout; U+202A forces LTR, so the large icon stays on
    // the expected side whatever the phone's system language is.
    final mark = isRtl ? '\u200F' : '\u202A';

    final title = '$mark${translateFor(
      language,
      'Sukkur Salah',
      'سکھر صلاۃ',
      'سکر صلاۃ',
      'صلاة سكر',
    )} ($rawTime)';

    if (language == 'english' && isSukkurMode) {
      final legacy = switch (prayer.name) {
        'Tulu Aftab' =>
          '$mark<b>Sunrise</b> | کا وقت شروع ہو گیا ہے\n(نماز کا ممنوع وقت)',
        'Ishraq' =>
          '$mark<b>Ishraq</b> | کا وقت شروع ہو گیا ہے\n(اب نماز پڑھ سکتے ہیں)',
        _ => '$mark<b>${prayer.name}</b> | کا وقت شروع ہو گیا ہے',
      };
      return (title, legacy);
    }

    // Label key, not the preference key: a calculated city says "Asr" where
    // the jantri says "Asr Hanafi".
    final labelKey = prayer.displayName ?? prayer.name;
    final name = switch (language) {
      'urdu' => _urduNames[labelKey] ?? prayer.urduName,
      'arabic' => _arabicNames[labelKey] ?? labelKey,
      'sindhi' => prayer.localizedName('sindhi'),
      'english' => labelKey == 'Tulu Aftab' ? 'Sunrise' : labelKey,
      _ => worldTranslations[language]?[labelKey] ?? labelKey,
    };

    final started = translateFor(
      language,
      '{prayer} time has started',
      '{prayer} کا وقت شروع ہو گیا ہے',
      '{prayer} جو وقت شروع ٿي ويو آهي',
      'بدأ وقت {prayer}',
    ).replaceAll('{prayer}', '<b>$name</b>');

    final suffix = switch (prayer.name) {
      'Tulu Aftab' => '\n${translateFor(
          language,
          '(Forbidden time for prayer)',
          '(نماز کا ممنوع وقت)',
          '(نماز جو ممنوع وقت)',
          '(الوقت الممنوع للصلاة)',
        )}',
      'Ishraq' => '\n${translateFor(
          language,
          '(You can pray now)',
          '(اب نماز پڑھ سکتے ہیں)',
          '(هاڻي نماز پڙهي سگهو ٿا)',
          '(الآن يمكن أداء الصلاة)',
        )}',
      _ => '',
    };

    return (title, '$mark$started$suffix');
  }

  @visibleForTesting
  String reminderBodyForTest(String p, int o, String l) => _reminderBody(p, o, l);

  String _reminderBody(String prayer, int offset, String language) {
    const urdu = {
      'Intiha e Sehar': 'انتہائے سحر',
      'Fajar': 'فجر',
      'Tulu Aftab': 'طلوع آفتاب',
      'Ishraq': 'اشراق',
      'Zawal': 'زوال آفتاب',
      'Zuhar': 'ظہر',
      'Misl Awwal': 'مثل اول',
      'Asr Hanafi': 'عصر حنفی',
      'Maghrib': 'مغرب',
      'Isha': 'عشاء',

      // Backward compatibility
      'Fajr': 'فجر',
      'Dhuhr': 'ظہر',
      'Asr': 'عصر',
    };
    const sindhi = {
      'Intiha e Sehar': 'انتهاءِ سحر',
      'Fajar': 'فجر',
      'Tulu Aftab': 'سج اڀرڻ',
      'Ishraq': 'اشراق',
      'Zawal': 'زوالِ آفتاب',
      'Zuhar': 'ظھر',
      'Misl Awwal': 'مثل اول',
      'Asr Hanafi': 'عصر',
      'Maghrib': 'مغرب',
      'Isha': 'عشاء',

      // Backward compatibility
      'Fajr': 'فجر',
      'Dhuhr': 'ظھر',
      'Asr': 'عصر',
    };
    const arabic = {
      'Intiha e Sehar': 'نهاية السحر',
      'Fajar': 'الفجر',
      'Tulu Aftab': 'الشروق',
      'Ishraq': 'الإشراق',
      'Zawal': 'الزوال',
      'Zuhar': 'الظهر',
      'Misl Awwal': 'المثل الأول',
      'Asr Hanafi': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
    };
    if (language == 'arabic') {
      final p = arabic[prayer] ?? prayer;
      if (offset == 0) return 'عند $p';
      final abs = offset.abs();
      return offset < 0 ? 'قبل $p بـ $abs دقيقة' : 'بعد $p بـ $abs دقيقة';
    }
    if (worldTranslations.containsKey(language)) {
      final p = worldTranslations[language]?[prayer] ?? prayer;
      final abs = offset.abs();
      final template = offset == 0
          ? translateFor(language, 'At {prayer} time', '', '')
          : translateFor(
              language,
              offset < 0
                  ? '{minutes} minutes before {prayer}'
                  : '{minutes} minutes after {prayer}',
              '',
              '');
      return template
          .replaceAll('{prayer}', p)
          .replaceAll('{minutes}', '$abs');
    }
    if (language == 'sindhi') {
      final p = sindhi[prayer] ?? prayer;
      if (offset == 0) return '$p جو وقت';
      final abs = offset.abs();
      return offset < 0 ? '$p کان $abs منٽ اڳيان' : '$p جي $abs منٽ پوء';
    }
    final p = urdu[prayer] ?? prayer;
    if (offset == 0) return '$p کا وقت';
    final abs = offset.abs();
    return offset < 0 ? '$p سے $abs منٹ پہلے' : '$p کے $abs منٹ بعد';
  }

  Future<void> cancelAll() async {
    if (kIsWeb || _plugin == null) return;
    await _plugin!.cancelAll();
  }

  /// Returns false only when the OS has notifications turned off for this app
  /// (e.g. the user tapped "Don't allow" on Android 13+). Used to warn the user
  /// that their enabled prayer alerts won't actually appear. Defaults to true
  /// (don't warn) when the state can't be determined.
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb || _plugin == null) return true;
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  /// Whether Android will honour an exact alarm right now.
  ///
  /// False means every prayer falls back to inexact scheduling, which Android
  /// deliberately batches - the alert still arrives, but late. The permission
  /// can be withdrawn long after onboarding granted it, so this is worth asking
  /// again rather than assuming.
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || _plugin == null) return true;
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? true;
  }

  /// Asks for the exact-alarm permission, sending the user to the system page.
  Future<void> requestExactAlarms() async {
    if (kIsWeb || _plugin == null) return;
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }

  /// Asks for the POST_NOTIFICATIONS permission (Android 13+).
  Future<void> requestNotificationsPermission() async {
    if (kIsWeb || _plugin == null) return;
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Alerts already handed to the OS, soonest first. What the health screen
  /// shows as proof that something really is queued.
  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    if (kIsWeb || _plugin == null) return const [];
    try {
      return await _plugin!.pendingNotificationRequests();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> isPrayerEnabled(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeys[prayerName] ?? '') ?? true;
  }

  Future<void> setPrayerEnabled(String prayerName, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefKeys[prayerName];
    if (key != null) await prefs.setBool(key, value);
  }

  Future<bool> isGlobalEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setGlobalEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (value) {
      await scheduleWeeklyNotifications();
    } else {
      await cancelAll();
    }
  }

  String _formatTime12Hour(String timeStr, bool isPm) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    int hour = int.parse(parts[0]);
    final minuteStr = parts[1];

    String amPm = isPm ? 'PM' : 'AM';

    if (hour > 12) {
      hour -= 12;
      amPm = 'PM';
    } else if (hour == 0) {
      hour = 12;
      amPm = 'AM';
    } else if (hour == 12) {
      amPm = 'PM';
    }

    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr $amPm';
  }

  Future<void> showTestNotification() async {
    if (kIsWeb || _plugin == null) return;
    
    await recreationChannels();
    
    final prefs = await SharedPreferences.getInstance();
    final selectedAzanIndex = prefs.getInt('selected_azan_index') ?? 3;
    
    final modeStr = prefs.getString('alert_mode_zuhar') ?? 'loud';
    var mode = AlertMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => AlertMode.loud,
    );

    final language = prefs.getString('language_code') ?? 'english';
    final isRtl = rtlLanguages.contains(language);
    final mark = isRtl ? '\u200F' : '\u202A';

    final title = '$mark${translateFor(
      language,
      'Test Notification',
      'ٹیسٹ نوٹیفکیشن',
      'ٽيسٽ نوٽيفڪيشن',
      'إشعار تجريبي',
    )} 🔔';
    final body = '$mark${translateFor(
      language,
      'If you see and hear this, your notifications are working perfectly!',
      'اگر آپ یہ دیکھ اور سن رہے ہیں، تو آپ کی اطلاعات بالکل ٹھیک کام کر رہی ہیں!',
      'جيڪڏهن توهان اهو ڏسي ۽ ٻڌي رهيا آهيو، ته توهان جا نوٽيفڪيشن بلڪل صحيح ڪم ڪري رهيا آهن!',
      'إذا رأيت هذا وسمعته، فإن إشعاراتك تعمل بشكل مثالي!',
    )}';
    try {
      await _plugin!.show(
        99999,
        title,
        body,
        _detailsFor(mode, selectedAzanIndex, isRtl: isRtl),
      );
    } catch (e) {
      debugPrint('Failed to show test notification: $e');
    }
  }
}

