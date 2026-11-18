import '../l10n/world_translations.dart';
import '../l10n/world_translations_extra.dart';
import 'dart:async';
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
import '../utils/prayer_state.dart';
import 'jamaat_times_service.dart';
import 'widget_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  /// Debounce timer so rapid settings changes coalesce into one batch.
  Timer? _scheduleDebounce;

  /// Guard flag: prevents a second batch from starting while one is still
  /// writing alarms to the platform, which would double the IPC load.
  bool _scheduleInProgress = false;
  bool _rescheduleRequested = false;

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

  static const _sindhiNames = {
    'Intiha e Sehar': 'انتهاءِ سحر',
    'Fajar': 'فجر',
    'Tulu Aftab': 'سج اڀرڻ',
    'Ishraq': 'اشراق',
    'Zawal': 'زوالِ آفتاب',
    'Zuhar': 'ظھر',
    'Misl Awwal': 'مثل اول',
    'Asr Hanafi': 'عصر احناف',
    'Asr': 'عصر',
    'Maghrib': 'مغرب',
    'Isha': 'عشاء',
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
  static const _chLiveCountdown = 'namaz_live_countdown_v1';
  static const liveCountdownId = 999;

  Timer? _liveTimer;

  // We will create dynamic azan channels based on the selected azan index.
  static String _getAzanChannelId(int index) => 'namaz_azan_v6_$index';

  Future<void> init({bool isBackgroundWorker = false}) async {
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

    if (_plugin == null || isBackgroundWorker) {
      _plugin = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin!.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
    }

    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await _createChannels(android);
    // Unawaited background cleanup: run legacy channel deletions and past due alarm cleanups
    // in an unawaited background task rather than blocking the main isolate / startup.
    unawaited(_deleteLegacyChannels(android));
    if (!isBackgroundWorker) {
      unawaited(_purgePastDueTodayAlarms());
      unawaited(dismissDeliveredNotifications());
    }

    final prefs = await SharedPreferences.getInstance();
    // One-time migration (v3): enable the ongoing prayer countdown status bar by
    // default (including for existing users upgrading from older builds where it
    // defaulted to false) so aggressive OEMs (Infinix XOS, Tecno HiOS, Vivo,
    // Xiaomi, Oppo) recognize Sukkur Salah as an active foreground service and
    // never force-stop its background alarms. Users can still turn it off anytime.
    if (!(prefs.getBool('live_countdown_default_v3') ?? false)) {
      await prefs.setBool('live_countdown_default_v3', true);
      await prefs.setBool('live_countdown_default_v2', true);
      await prefs.setBool('live_countdown_enabled', true);
    }
    if (!isBackgroundWorker) {
      final bool liveEnabled = prefs.getBool('live_countdown_enabled') ?? true;
      if (liveEnabled) {
        startLiveCountdownTimer();
      } else {
        await cancelLiveCountdown();
      }
    }
  }

  /// Deterministic slot in `0 .. scheduleHorizonDays - 1` for a calendar date.
  /// Unlike relative `dayOffset` (which shifts depending on which day the batch
  /// was scheduled), this slot is invariant for any calendar date, allowing
  /// [_purgePastDueTodayAlarms] to cancel today's exact notification ID even
  /// when the schedule was built days ago.
  static int dateSlotFor(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(2026, 1, 1))
          .inDays
          .abs() %
      scheduleHorizonDays;

  /// Disarms any overdue AlarmManager PendingIntents for today via native
  /// [PrayerAlarmGuardian] WITHOUT calling `_plugin!.cancel(id)` (which would
  /// call `NotificationManager.cancel(id)` and erase already-delivered prayer
  /// notifications from the user's lock screen / status bar).
  Future<void> _purgePastDueTodayAlarms() async {
    if (kIsWeb || _plugin == null || _scheduleInProgress) return;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('alarm_batch_in_progress') ?? false) return;
    } catch (_) {}
    try {
      const nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');
      await nativeChannel.invokeMethod('syncPrayerAlarms', {'force': false});
    } catch (_) {
      try {
        await (prefs ?? await SharedPreferences.getInstance()).setInt(
            'alarm_batch_completed_at', DateTime.now().millisecondsSinceEpoch);
      } catch (_) {}
    }
  }

  /// Closes any already-delivered transient prayer/reminder notifications
  /// from the Android status bar / lock screen when opening or resuming the app,
  /// without cancelling future AlarmManager alarms or the ongoing live countdown.
  Future<void> dismissDeliveredNotifications() async {
    if (kIsWeb) return;
    try {
      const nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');
      await nativeChannel.invokeMethod('dismissDeliveredPrayerNotifications');
    } catch (_) {}
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

  Future<void> _deleteLegacyChannels(
      AndroidFlutterLocalNotificationsPlugin? android) async {
    if (android == null) return;
    try {
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
    } catch (_) {}
  }

  Future<void> _createChannels(
      AndroidFlutterLocalNotificationsPlugin? android) async {
    if (android == null) return;
    const desc = 'سکھر کے نماز کے اوقات کی اطلاع';

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chSilent,
      'نماز خاموش',
      description: desc,
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
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: RawResourceAndroidNotificationSound('mixkit_bell_notification_933'),
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chReminder,
      'ذاتی یاد دہانیاں',
      description: 'آپ کی مقرر کردہ یاد دہانیاں',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: RawResourceAndroidNotificationSound('mixkit_bell_notification_933'),
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chLiveCountdown,
      'نماز لائیو کاؤنٹ ڈاؤن',
      description: 'اگلی نماز کا لائیو کاؤنٹ ڈاؤن',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'ch_jamaat_reminders_v2',
      'باجماعت نماز الارم',
      description: 'پسندیدہ مسجد کی باجماعت نماز کی یاد دہانی',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: RawResourceAndroidNotificationSound('mixkit_bell_notification_933'),
    ));

    // Create a channel for each azan track
    for (int i = 0; i < azanTracks.length; i++) {
      await android.createNotificationChannel(AndroidNotificationChannel(
        _getAzanChannelId(i),
        'اذان (${azanTracks[i].urduName})',
        description: 'نماز کے وقت اذان کی آواز',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
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
  ///
  /// [elapsedIds] holds notification IDs for enabled prayers/reminders from
  /// today or yesterday whose time has already passed. We must NOT call
  /// `_plugin!.cancel(id)` on those because `flutter_local_notifications`
  /// calls `NotificationManager.cancel(id)`, which would erase already-delivered
  /// notifications from the user's status bar / lock screen! Native
  /// [PrayerAlarmGuardian] cleans up their AlarmManager PendingIntents directly.
  Future<void> _dropStaleNotifications(
    SharedPreferences prefs,
    Set<int> writtenIds, {
    Set<int> elapsedIds = const {},
  }) async {
    final previous = (prefs.getStringList(_scheduledIdsKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>();
    int cancelCount = 0;
    for (final id in previous) {
      if (writtenIds.contains(id) || elapsedIds.contains(id)) continue;
      try {
        await _plugin!.cancel(id);
        cancelCount++;
        // Yield periodically to keep the event loop responsive.
        if (cancelCount % 3 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      } catch (e) {
        debugPrint('Failed to cancel stale notification $id: $e');
      }
    }
    await prefs.setStringList(
        _scheduledIdsKey, writtenIds.map((id) => '$id').toList());
  }

  final List<Completer<void>> _pendingScheduleCompleters = [];

  /// Called on app startup and lifecycle resume: if a full 14-day schedule was
  /// already completed on the same calendar day within the last 6 hours and the
  /// OS queue is populated, syncs via native [PrayerAlarmGuardian] without
  /// re-running 140 `zonedSchedule` calls on every app open.
  Future<void> scheduleWeeklyNotificationsIfNeeded() async {
    if (kIsWeb || _plugin == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('notifications_enabled') ?? true)) {
        await scheduleWeeklyNotifications();
        return;
      }
      final canExactNow = await canScheduleExactAlarms();
      final notifAllowedNow = await areNotificationsEnabled();
      final lastCanExact =
          prefs.getBool('last_full_schedule_can_exact') ?? false;
      final lastNotifAllowed =
          prefs.getBool('last_full_schedule_notif_allowed') ?? false;
      final now = TimingsData.instance.nowForTimings();
      final todaySlot = dateSlotFor(now);
      final lastSlot = prefs.getInt('last_full_schedule_date_slot') ?? -1;
      final lastCompletedMs =
          prefs.getInt('last_full_schedule_completed_at') ?? 0;
      final ageMs = DateTime.now().millisecondsSinceEpoch - lastCompletedMs;

      if (lastSlot == todaySlot &&
          lastCompletedMs > 0 &&
          ageMs >= 0 &&
          ageMs < 6 * 60 * 60 * 1000 &&
          canExactNow == lastCanExact &&
          notifAllowedNow == lastNotifAllowed) {
        final pending = await pendingNotifications();
        if (pending.length >= 20) {
          await _purgePastDueTodayAlarms();
          return;
        }
      }
    } catch (_) {}
    await scheduleWeeklyNotifications();
  }

  /// Public entry-point: debounces by 500 ms so multiple calls within a short
  /// window (toggling several settings) are coalesced into a single batch.
  Future<void> scheduleWeeklyNotifications({bool immediate = false}) async {
    if (kIsWeb || _plugin == null) return;
    _scheduleDebounce?.cancel();
    if (immediate) {
      try {
        await _doScheduleWeeklyNotifications();
      } catch (e) {
        debugPrint('Error in scheduleWeeklyNotifications: $e');
      }
      return;
    }
    final completer = Completer<void>();
    _pendingScheduleCompleters.add(completer);
    _scheduleDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _doScheduleWeeklyNotifications();
      } catch (e) {
        debugPrint('Error in scheduleWeeklyNotifications: $e');
      } finally {
        final completers = List<Completer<void>>.from(_pendingScheduleCompleters);
        _pendingScheduleCompleters.clear();
        for (final c in completers) {
          if (!c.isCompleted) {
            c.complete();
          }
        }
      }
    });
    return completer.future;
  }

  /// The real scheduling work — runs at most once per debounce window.
  Future<void> _doScheduleWeeklyNotifications() async {
    if (kIsWeb || _plugin == null) return;
    // If a batch is already in flight, mark reschedule requested so the loop reruns
    // with the latest preferences immediately upon completion.
    if (_scheduleInProgress) {
      _rescheduleRequested = true;
      return;
    }
    _scheduleInProgress = true;
    try {
      do {
        _rescheduleRequested = false;
        await _scheduleWeeklyNotificationsCore();
        await updateLiveCountdownNotification();
      } while (_rescheduleRequested);
    } finally {
      _scheduleInProgress = false;
      _rescheduleRequested = false;
    }
  }

  /// Core implementation (no debounce / guard — called by the wrapper above).
  Future<void> _scheduleWeeklyNotificationsCore() async {
    if (kIsWeb || _plugin == null) return;

    final prefs = await SharedPreferences.getInstance();
    const nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');
    if (!(prefs.getBool('notifications_enabled') ?? true)) {
      // Switched off outright - here the clean sweep is the intent.
      await _plugin!.cancelAll();
      await prefs.remove(_scheduledIdsKey);
      try {
        await nativeChannel.invokeMethod('syncPrayerAlarms', {'force': true});
      } catch (_) {}
      return;
    }

    // On Android 12+ exact-alarm permission can be revoked (by the user or an
    // OEM battery manager). Rather than let zonedSchedule throw and abort the
    // whole batch, detect the capability once and fall back to inexact
    // scheduling — notifications still fire, just not to-the-second.
    final android = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    // IMPORTANT: Never pass AndroidScheduleMode.alarmClock directly to
    // flutter_local_notifications (which passes a Broadcast PendingIntent as
    // showIntent and triggers OEM alarm-clock rate limits when called 20+ times).
    // Instead, schedule via exactAllowWhileIdle and let native PrayerAlarmGuardian
    // promote the soonest 4 upcoming alarms (within 18h) to setAlarmClock() with a
    // valid Activity showIntent and chain them automatically in PrayerAlarmReceiver.
    final baseScheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    debugPrint('Schedule Mode: ${canExact ? "EXACT (Native Guardian 4-AlarmClock Chain + ExactIdle)" : "INEXACT (Fallback)"}');

    final selectedAzanIndex = prefs.getInt('selected_azan_index') ?? prefs.getInt('selected_azan') ?? 3;
    final timingsLocation = _timingsLocation(prefs);

    // Ensure TimingsData is loaded (crucial for background task)
    await TimingsData.instance.load();

    // Signal to native MainApplication / PrayerAlarmGuardian that a batch write
    // is in progress so it waits until the entire batch finishes before syncing.
    await prefs.setBool('alarm_batch_in_progress', true);
    await prefs.setInt(
        'alarm_batch_started_at', DateTime.now().millisecondsSinceEpoch);

    // In the timings' own frame, so "has this prayer already passed?" is asked
    // against the same clock the times are written in. Re-sampled on each day
    // iteration so an isolate paused by the OS mid-batch never uses a stale clock.
    var now = TimingsData.instance.nowForTimings();
    // Everything this run writes, so the stale ids from the last run - and only
    // those - can be cleared at the end.
    final writtenIds = <int>{};
    // IDs of enabled prayers/reminders from today or yesterday whose time has
    // already elapsed: skipped by _dropStaleNotifications so delivered
    // notifications in the Android status bar are never wiped out.
    final elapsedIds = <int>{};

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdaySlot = dateSlotFor(yesterday);
    for (final base in baseIds.values) {
      elapsedIds.add(base + yesterdaySlot);
    }

    try {
      for (int dayOffset = 0; dayOffset < scheduleHorizonDays; dayOffset++) {
        // Refresh batch heartbeat and current time on every day iteration so if
        // the app was backgrounded/paused mid-batch and resumed hours later,
        // `now` reflects the real current time and never schedules past prayers.
        await prefs.setInt(
            'alarm_batch_started_at', DateTime.now().millisecondsSinceEpoch);
        now = TimingsData.instance.nowForTimings();

        final date = now.add(Duration(days: dayOffset));
        final timing = TimingsData.instance.timingFor(date);
        if (timing == null) continue;
        final dayScheduleMode = baseScheduleMode;

        for (final prayer in timing.allTimings) {
          final prefKey = _prefKeys[prayer.name];
          if (prefKey == null) continue;
          if (!(prefs.getBool(prefKey) ?? true)) continue;

          final notifId = (baseIds[prayer.name] ?? 0) + dateSlotFor(date);
          final prayerDt = prayer.toDateTime(date: date);
          final liveNow = TimingsData.instance.nowForTimings();
          if (!prayerDt.isAfter(liveNow)) {
            elapsedIds.add(notifId);
            continue;
          }

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
          if (!tzDateTime.isAfter(DateTime.now())) {
            elapsedIds.add(notifId);
            continue;
          }

          final langCode = prefs.getString('language_code') ?? 'english';
          final isSukkurMode =
              (prefs.getString('location_mode') ?? 'sukkur') == 'sukkur';
          final rawTime =
              _formatTime12Hour(prayer.time, prayer.isPm).replaceAll(' ', '');

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
            final scheduled = await _safeZonedSchedule(
              id: notifId,
              title: title,
              body: body,
              scheduledDate: tzDateTime,
              notificationDetails: _detailsFor(mode, selectedAzanIndex,
                  isRtl: rtlLanguages.contains(langCode)),
              scheduleMode: dayScheduleMode,
            );
            if (scheduled) {
              writtenIds.add(notifId);
            } else {
              elapsedIds.add(notifId);
            }
          } catch (e) {
            debugPrint('Failed to schedule notification $notifId: $e');
          }
        }
      }

      now = TimingsData.instance.nowForTimings();
      writtenIds.addAll(await _scheduleCustomReminders(
        prefs,
        now,
        baseScheduleMode,
        elapsedIds: elapsedIds,
      ));
      writtenIds.addAll(await _scheduleWeeklyFridayNotification(
          prefs, TimingsData.instance.nowForTimings(), baseScheduleMode));

      // Only now, with every replacement safely in place, drop what this run no
      // longer needs - a prayer switched off, a deleted reminder, a day that has
      // fallen off the end of the horizon (while preserving already-delivered
      // notifications from today/yesterday in the status bar).
      await _dropStaleNotifications(prefs, writtenIds, elapsedIds: elapsedIds);

      // Keep favorite masjid pre-Jama'at reminders synced alongside prayer notifications
      await scheduleJamaatReminders(syncNative: false);

      final doneNow = TimingsData.instance.nowForTimings();
      final notifAllowed = await areNotificationsEnabled();
      await prefs.setInt('last_full_schedule_date_slot', dateSlotFor(doneNow));
      await prefs.setInt('last_full_schedule_completed_at',
          DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('last_full_schedule_can_exact', canExact);
      await prefs.setBool('last_full_schedule_notif_allowed', notifAllowed);
    } finally {
      await prefs.setBool('alarm_batch_in_progress', false);
      // Hand off all scheduled notifications to native PrayerAlarmGuardian so it
      // replaces raw ScheduledNotificationReceiver PendingIntents with PrayerAlarmReceiver
      // and promotes the soonest 4 upcoming alarms within 18h to AlarmManager.setAlarmClock().
      try {
        await nativeChannel.invokeMethod('syncPrayerAlarms', {'force': true});
      } catch (_) {
        // In WorkManager background isolate (where MainActivity MethodChannel is not attached),
        // signal MainApplication's SharedPreferences listener to run the Guardian sync.
        await prefs.setInt(
            'alarm_batch_completed_at', DateTime.now().millisecondsSinceEpoch);
      }
    }

    // Schedule Auto-Silent alarms
    final autoSilentEnabled = prefs.getBool('auto_silent_enabled') ?? false;
    final customSilentEnabled = prefs.getBool('custom_silent_enabled') ?? false;
    if (autoSilentEnabled || customSilentEnabled) {
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

      if (autoSilentEnabled) {
        for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
          final date = now.add(Duration(days: dayOffset));
          final timing = TimingsData.instance.timingFor(date);
          if (timing == null) continue;

          for (final prayer in timing.allTimings) {
            final base = silentBases[prayer.name];
            if (base != null) {
              final isPrayerAutoSilentEnabled = prefs.getBool('auto_silent_enabled_${prayer.name}') ?? false;
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
      }

      if (customSilentEnabled) {
        final customSilentStartHour = prefs.getInt('custom_silent_start_hour') ?? 13;
        final customSilentStartMinute = prefs.getInt('custom_silent_start_minute') ?? 30;
        final customSilentEndHour = prefs.getInt('custom_silent_end_hour') ?? 14;
        final customSilentEndMinute = prefs.getInt('custom_silent_end_minute') ?? 0;

        for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
          final date = now.add(Duration(days: dayOffset));
          final customStartDt = DateTime(date.year, date.month, date.day, customSilentStartHour, customSilentStartMinute);
          var customEndDt = DateTime(date.year, date.month, date.day, customSilentEndHour, customSilentEndMinute);
          if (customEndDt.isBefore(customStartDt)) {
            customEndDt = customEndDt.add(const Duration(days: 1));
          }

          if (customStartDt.isAfter(now)) {
            silentAlarms.add({
              'id': 7000 + dayOffset,
              'triggerTimeMillis': customStartDt.millisecondsSinceEpoch,
              'type': 'start',
              'mode': autoSilentMode,
            });
          }
          if (customEndDt.isAfter(now)) {
            silentAlarms.add({
              'id': 7100 + dayOffset,
              'triggerTimeMillis': customEndDt.millisecondsSinceEpoch,
              'type': 'restore',
              'mode': autoSilentMode,
            });
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
        importance = Importance.max;
        priority = Priority.max;
        androidSound = const RawResourceAndroidNotificationSound('mixkit_bell_notification_933');
      case AlertMode.azan:
        // Use safely bounded index
        final safeIndex =
            (selectedAzanIndex >= 0 && selectedAzanIndex < azanTracks.length)
                ? selectedAzanIndex
                : 3;
        final track = azanTracks[safeIndex];

        channelId = _getAzanChannelId(safeIndex);
        channelName = 'اذان (${track.urduName})';
        playSound = true;
        enableVibration = true;
        importance = Importance.max;
        priority = Priority.max;
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
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: playSound
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        // Do not set fullScreenIntent: true on targetSdk 36 — Android 14+ blocks unpermitted
        // full-screen activity launches from background, causing OEMs to hold notifications
        // until the app is opened. Importance.max + category alarm already shows heads-up with sound.
        fullScreenIntent: false,
        styleInformation: const DefaultStyleInformation(true, true),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
        sound: iosSound,
        interruptionLevel: InterruptionLevel.timeSensitive,
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
      await _safeZonedSchedule(
        id: 8000,
        title: isRtl ? '<b>$title</b>' : '<b>$title</b>',
        body: plainBody,
        scheduledDate: tzNextFriday,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _chSilent,
            'Friday Reminders',
            channelDescription: 'Weekly reminders for Jummah',
            icon: '@drawable/ic_notification',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: false,
            category: AndroidNotificationCategory.event,
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
        scheduleMode: scheduleMode,
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
    SharedPreferences prefs,
    DateTime now,
    AndroidScheduleMode scheduleMode, {
    Set<int>? elapsedIds,
  }) async {
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

    final yesterdaySlot = dateSlotFor(now.subtract(const Duration(days: 1)));

    for (int i = 0; i < list.length; i++) {
      final m = list[i];
      if (m is! Map) continue;
      if (!((m['enabled'] as bool?) ?? true)) continue;

      final prayerName = m['prayerName'] as String?;
      final offset = (m['offsetMinutes'] as int?) ?? 0;
      final label = (m['label'] as String?)?.trim();
      final timingName = _reminderPrayerToTiming[prayerName];
      if (timingName == null) continue;

      elapsedIds?.add(reminderNotificationId(i, yesterdaySlot));

      for (int dayOffset = 0; dayOffset < scheduleHorizonDays; dayOffset++) {
        final liveNow = TimingsData.instance.nowForTimings();
        final date = liveNow.add(Duration(days: dayOffset));
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

        final id = reminderNotificationId(i, dateSlotFor(date));
        // Built in the timings' own zone before the offset is applied, so a
        // reminder for a world city tracks that city's clock like the prayer
        // itself does. TZDateTime compares as an absolute instant, so the
        // "already passed" check stays correct whatever zone it is in.
        final tzDt = _atWallClock(reminderLocation, pt.toDateTime(date: date))
            .add(Duration(minutes: offset));
        // Against the real instant, not [now]: [now] carries the timings' own
        // wall clock, which for a watched city is not the same point in time.
        if (!tzDt.isAfter(DateTime.now())) {
          elapsedIds?.add(id);
          continue;
        }

        final reminderLang = prefs.getString('language_code') ?? 'english';
        final String reminderTitle = (label == null || label.isEmpty)
            ? translateFor(reminderLang, 'Reminder', 'یاد دہانی', 'ياد دهاني',
                'تذكير')
            : label;
        final String reminderBodyText =
            _reminderBody(prayerName!, offset, reminderLang);

        try {
          final scheduled = await _safeZonedSchedule(
            id: id,
            title: rtlLanguages.contains(reminderLang)
                ? '\u200F$reminderTitle'
                : reminderTitle,
            body: rtlLanguages.contains(reminderLang)
                ? '\u200F$reminderBodyText'
                : reminderBodyText,
            scheduledDate: tzDt,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                _chReminder,
                'ذاتی یاد دہانیاں',
                channelDescription: 'آپ کی مقرر کردہ یاد دہانیاں',
                importance: Importance.max,
                priority: Priority.max,
                icon: '@drawable/ic_notification',
                visibility: NotificationVisibility.public,
                sound: RawResourceAndroidNotificationSound('mixkit_bell_notification_933'),
                audioAttributesUsage: AudioAttributesUsage.alarm,
                fullScreenIntent: false,
                category: AndroidNotificationCategory.alarm,
                styleInformation: DefaultStyleInformation(true, true),
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                interruptionLevel: InterruptionLevel.timeSensitive,
              ),
            ),
            scheduleMode: scheduleMode,
          );
          if (scheduled) {
            written.add(id);
          } else {
            elapsedIds?.add(id);
          }
        } catch (e) {
          debugPrint('Failed to schedule reminder $id: $e');
        }
      }
    }
    return written;
  }

  /// Safely schedules a zoned notification with multi-level schedule mode fallback.
  /// Never passes a past timestamp to `zonedSchedule` (which would cause AlarmManager
  /// to fire `ScheduledNotificationReceiver` immediately when the user opens the app).
  Future<bool> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode scheduleMode,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    var targetDate = scheduledDate;
    final realNow = DateTime.now();
    if (!targetDate.isAfter(realNow)) {
      if (matchDateTimeComponents == DateTimeComponents.dayOfWeekAndTime) {
        while (!targetDate.isAfter(realNow)) {
          targetDate = targetDate.add(const Duration(days: 7));
        }
      } else if (matchDateTimeComponents == DateTimeComponents.time) {
        while (!targetDate.isAfter(realNow)) {
          targetDate = targetDate.add(const Duration(days: 1));
        }
      } else {
        // One-shot alarm whose time has already elapsed (e.g. if the Dart isolate
        // was paused while backgrounded and resumed later): NEVER schedule in the past.
        return false;
      }
    }

    try {
      await _plugin!.zonedSchedule(
        id,
        title,
        body,
        targetDate,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      return true;
    } catch (e) {
      debugPrint('ZonedSchedule primary mode ($scheduleMode) failed for $id: $e');
      if (scheduleMode != AndroidScheduleMode.exactAllowWhileIdle) {
        try {
          await _plugin!.zonedSchedule(
            id,
            title,
            body,
            targetDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: matchDateTimeComponents,
          );
          return true;
        } catch (e2) {
          debugPrint('ZonedSchedule fallback exactAllowWhileIdle failed for $id: $e2');
        }
      }
      // Final resilient fallback: inexactAllowWhileIdle guarantees notification is delivered even if exact alarms are denied by OS
      await _plugin!.zonedSchedule(
        id,
        title,
        body,
        targetDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      return true;
    }
  }

  /// Title and body for a prayer-time alert.
  ///
  /// In Sukkur mode, custom notifications are formatted across all 10 supported
  /// languages with specific rulings and advisories (e.g. Zawal makruh warning,
  /// Intiha-e-Sehar fasting closure, Fajr early azan advisory). In World mode,
  /// standard localized prayer alerts are preserved.
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

    if (isSukkurMode) {
      final (startedText, suffixText) = _sukkurAlertContent(prayer.name, language);
      return (title, '$mark$startedText$suffixText');
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

  /// Sukkur-mode prayer alert phrasing and brackets in all 10 supported languages.
  (String, String) _sukkurAlertContent(String prayerName, String lang) {
    // 1. Specific rulings/brackets for Sukkur mode
    final String suffix = switch (prayerName) {
      'Zawal' => switch (lang) {
          'urdu' => '\n(اس وقت سے 5 منٹ پہلے اور 5 منٹ بعد نماز پڑھنا مکروہ ہے)',
          'sindhi' => '\n(هن وقت کان 5 منٽ اڳ ۽ 5 منٽ پوءِ نماز پڙهڻ مڪروهه آهي)',
          'arabic' => '\n(يُكره أداء الصلاة قبل هذا الوقت بـ 5 دقائق وبعده بـ 5 دقائق)',
          'persian' => '\n(خواندن نماز ۵ دقیقه قبل و ۵ دقیقه بعد از این زمان مکروه است)',
          'hindi' => '\n(इस समय से 5 मिनट पहले और 5 मिनट बाद नमाज़ पढ़ना मकरूह है)',
          'bengali' => '\n(এই সময়ের ৫ মিনিট আগে ও ৫ মিনিট পরে নামায পড়া মাকরূহ)',
          'turkish' => '\n(Bu vakitten 5 dk önce ve 5 dk sonra namaz kılmak mekruhtur)',
          'indonesian' => '\n(Makruh shalat 5 menit sebelum dan 5 menit sesudah waktu ini)',
          'french' => '\n(Il est déconseillé de prier 5 min avant et 5 min après)',
          _ => '\n(Praying is disliked 5 minutes before and 5 minutes after this time)',
        },
      'Intiha e Sehar' => switch (lang) {
          'urdu' => '\n(روزہ بند کر لیجیے)',
          'sindhi' => '\n(روزو بند ڪري وٺو)',
          'arabic' => '\n(أمسكوا عن الطعام وبدء الصيام)',
          'persian' => '\n(روزه را آغاز کرده و از خوردن دست بکشید)',
          'hindi' => '\n(रोज़ा बंद कर लीजिए)',
          'bengali' => '\n(রোজা শুরু করুন / সেহরি বন্ধ করুন)',
          'turkish' => '\n(Oruca başlayınız / yemeyi kesiniz)',
          'indonesian' => '\n(Hentikan makan / mulailah berpuasa)',
          'french' => '\n(Arrêtez de manger / fermez le jeûne)',
          _ => '\n(Please close your fast / stop eating)',
        },
      'Fajar' => switch (lang) {
          'urdu' => '\n(فجر کی اذان اس وقت سے پہلے نہ دی جائے)',
          'sindhi' => '\n(فجر جي اذان هن وقت کان اڳ نه ڏني وڃي)',
          'arabic' => '\n(لا ينبغي رفع أذان الفجر قبل هذا الوقت)',
          'persian' => '\n(اذان صبح نباید پیش از این زمان گفته شود)',
          'hindi' => '\n(फ़ज्र की अज़ान इस समय से पहले न दी जाए)',
          'bengali' => '\n(ফজরের আযান এই সময়ের পূর্বে যেন না দেওয়া হয়)',
          'turkish' => '\n(Sabah ezanı bu vakitten önce okunmamalıdır)',
          'indonesian' => '\n(Adzan Subuh tidak boleh dikumandangkan sebelum waktu ini)',
          'french' => '\n(L\'Adhan de Fajr ne doit pas être prononcé avant cette heure)',
          _ => '\n(Fajr Azan should not be called before this time)',
        },
      'Tulu Aftab' => switch (lang) {
          'urdu' => '\n(نماز کا ممنوع وقت)',
          'sindhi' => '\n(نماز جو ممنوع وقت)',
          'arabic' => '\n(الوقت الممنوع للصلاة)',
          'persian' => '\n(زمان ممنوع برای نماز)',
          'hindi' => '\n(नमाज़ का मना किया गया समय)',
          'bengali' => '\n(নামাযের নিষিদ্ধ সময়)',
          'turkish' => '\n(Namaz için mekruh vakit)',
          'indonesian' => '\n(Waktu terlarang untuk shalat)',
          'french' => '\n(Temps interdit pour la prière)',
          _ => '\n(Forbidden time for prayer)',
        },
      'Ishraq' => switch (lang) {
          'urdu' => '\n(اب نماز پڑھ سکتے ہیں)',
          'sindhi' => '\n(هاڻي نماز پڙهي سگهو ٿا)',
          'arabic' => '\n(الآن يمكن أداء الصلاة)',
          'persian' => '\n(اکنون می‌توانید نماز بخوانید)',
          'hindi' => '\n(अब नमाज़ पढ़ सकते हैं)',
          'bengali' => '\n(এখন নামায পড়া যাবে)',
          'turkish' => '\n(Şimdi namaz kılabilirsiniz)',
          'indonesian' => '\n(Sekarang boleh shalat)',
          'french' => '\n(Vous pouvez prier maintenant)',
          _ => '\n(You can pray now)',
        },
      _ => '',
    };

    // 2. Specific main sentences for Sukkur mode
    final String started = switch (prayerName) {
      'Tulu Aftab' => switch (lang) {
          'urdu' => '<b>طلوع آفتاب</b> ہو گیا ہے',
          'sindhi' => '<b>سج اڀرڻ</b> جو وقت ٿي ويو آهي',
          'arabic' => '<b>شروق الشمس</b> قد حان',
          'persian' => '<b>طلوع آفتاب</b> شد',
          'hindi' => '<b>सूर्योदय</b> हो गया है',
          'bengali' => '<b>সূর্যোদয়</b> হয়েছে',
          'turkish' => '<b>Güneş doğuşu</b> gerçekleşti',
          'indonesian' => '<b>Terbit matahari</b> telah tiba',
          'french' => 'Le <b>lever du soleil</b> a eu lieu',
          _ => '<b>Sunrise</b> has occurred',
        },
      'Ishraq' => switch (lang) {
          'urdu' => '<b>اشراق</b> کا وقت ہو گیا ہے',
          'sindhi' => '<b>اشراق</b> جو وقت ٿي ويو آهي',
          'arabic' => 'حان وقت <b>الإشراق</b>',
          'persian' => 'وقت <b>اشراق</b> فرا رسید',
          'hindi' => '<b>इशराक़</b> का समय हो गया है',
          'bengali' => '<b>ইশরাক</b> এর সময় হয়ে গেছে',
          'turkish' => '<b>İşrak</b> vakti girdi',
          'indonesian' => 'Waktu <b>Isyraq</b> telah tiba',
          'french' => 'L\'heure d\'<b>Ishraq</b> est arrivée',
          _ => '<b>Ishraq</b> time has arrived',
        },
      'Zawal' => switch (lang) {
          'urdu' => '<b>زوال</b> کا وقت ہو گیا ہے',
          'sindhi' => '<b>زوال</b> جو وقت ٿي ويو آهي',
          'arabic' => 'حان وقت <b>الزوال</b>',
          'persian' => 'وقت <b>زوال</b> فرا رسید',
          'hindi' => '<b>ज़वाल</b> का समय हो गया है',
          'bengali' => '<b>যাওয়াল</b> এর সময় হয়ে গেছে',
          'turkish' => '<b>Zeval</b> vakti girdi',
          'indonesian' => 'Waktu <b>Zawal</b> telah tiba',
          'french' => 'L\'heure de <b>Zawal</b> est arrivée',
          _ => '<b>Zawal</b> time has arrived',
        },
      'Intiha e Sehar' => switch (lang) {
          'urdu' => '<b>انتہائے سحر</b> کا وقت ہو چکا ہے',
          'sindhi' => '<b>انتہائے سحر</b> جو وقت ٿي چڪو آهي',
          'arabic' => 'انتهى وقت <b>السحور</b>',
          'persian' => 'زمان <b>پایان سحر</b> فرا رسید',
          'hindi' => '<b>इंतिहा-ए-सहर</b> का समय समाप्त हो गया है',
          'bengali' => '<b>সেহরির শেষ সময়</b> হয়ে গেছে',
          'turkish' => '<b>İmsak / Sahur</b> vakti sona erdi',
          'indonesian' => 'Waktu <b>Imsak / Akhir Sahur</b> telah berakhir',
          'french' => 'La fin du <b>Sahur</b> est arrivée',
          _ => '<b>Intiha-e-Sehar</b> time has ended',
        },
      'Fajar' => switch (lang) {
          'urdu' => '<b>فجر</b> کا وقت شروع ہو گیا ہے',
          'sindhi' => '<b>فجر</b> جو وقت شروع ٿي ويو آهي',
          'arabic' => 'بدأ وقت <b>الفجر</b>',
          'persian' => 'وقت <b>فجر</b> آغاز شد',
          'hindi' => '<b>फ़ज्र</b> का समय शुरू हो गया है',
          'bengali' => '<b>ফজর</b> এর সময় শুরু হয়েছে',
          'turkish' => '<b>Sabah / Fecir</b> vakti başladı',
          'indonesian' => 'Waktu <b>Subuh</b> telah dimulai',
          'french' => 'L\'heure de <b>Fajr</b> a commencé',
          _ => '<b>Fajr</b> time has started',
        },
      _ => () {
          final localizedName = switch (lang) {
            'urdu' => _urduNames[prayerName] ?? prayerName,
            'sindhi' => _sindhiNames[prayerName] ?? prayerName,
            'arabic' => _arabicNames[prayerName] ?? prayerName,
            'english' => prayerName,
            _ => worldTranslations[lang]?[prayerName] ?? prayerName,
          };
          return switch (lang) {
            'urdu' => '<b>$localizedName</b> کا وقت شروع ہو گیا ہے',
            'sindhi' => '<b>$localizedName</b> جو وقت شروع ٿي ويو آهي',
            'arabic' => 'بدأ وقت <b>$localizedName</b>',
            'persian' => 'وقت <b>$localizedName</b> آغاز شد',
            'hindi' => '<b>$localizedName</b> का समय शुरू हो गया है',
            'bengali' => '<b>$localizedName</b> এর সময় শুরু হয়েছে',
            'turkish' => '<b>$localizedName</b> vakti başladı',
            'indonesian' => 'Waktu <b>$localizedName</b> telah dimulai',
            'french' => 'L\'heure de <b>$localizedName</b> a commencé',
            _ => '<b>$localizedName</b> time has started',
          };
        }(),
    };

    return (started, suffix);
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
    try {
      const nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');
      await nativeChannel.invokeMethod('syncPrayerAlarms', {'force': true});
    } catch (_) {}
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
    final selectedAzanIndex = prefs.getInt('selected_azan_index') ?? prefs.getInt('selected_azan') ?? 3;
    
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

  void startLiveCountdownTimer() {
    _liveTimer?.cancel();
    updateLiveCountdownNotification();
    // Native PrayerKeepAliveService transitions at exact prayer boundaries and on
    // SCREEN_ON, while usesChronometer: true ticks every second in SystemUI.
    // A 5-minute periodic sync keeps widgets and timeline topped up with minimal IPC.
    _liveTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      updateLiveCountdownNotification();
    });
  }

  void stopLiveCountdownTimer() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  static String _getOngoingLabel(String lang) {
    switch (lang) {
      case 'urdu': return 'جاری ہے';
      case 'sindhi': return 'جاري آهي';
      case 'arabic': return 'جاري الآن';
      case 'persian': return 'در حال انجام';
      case 'hindi': return 'जारी है';
      case 'bengali': return 'চলমান';
      case 'turkish': return 'Devam Ediyor';
      case 'indonesian': return 'Sedang Berlangsung';
      case 'french': return 'En cours';
      default: return 'Ongoing';
    }
  }

  static String _getRemainingLabel(String lang) {
    switch (lang) {
      case 'urdu': return 'باقی ہے';
      case 'sindhi': return 'باقي آهي';
      case 'arabic': return 'متبقي';
      case 'persian': return 'باقی مانده';
      case 'hindi': return 'शेष है';
      case 'bengali': return 'বাকি আছে';
      case 'turkish': return 'Kaldı';
      case 'indonesian': return 'Tersisa';
      case 'french': return 'Restant';
      default: return 'Remaining';
    }
  }

  Future<void> updateLiveCountdownNotification() async {
    if (kIsWeb || _plugin == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      final bool enabled = prefs.getBool('live_countdown_enabled') ?? false;
      final bool globalEnabled = prefs.getBool('notifications_enabled') ?? true;

      if (!enabled || !globalEnabled) {
        stopLiveCountdownTimer();
        await cancelLiveCountdown();
        return;
      }

      await TimingsData.instance.load();
      final now = TimingsData.instance.nowForTimings();
      final today = TimingsData.instance.timingFor(now);
      if (today == null) return;

      final state = computePrayerState(now, today);
      if (state == null) return;

      final language = prefs.getString('language_code') ??
          (prefs.getBool('is_sindhi') == true
              ? 'sindhi'
              : prefs.getBool('is_urdu') == true
                  ? 'urdu'
                  : 'english');
      final isRtl = rtlLanguages.contains(language);
      final mark = isRtl ? '\u200F' : '\u202A';

      final prayerRawName = state.prayer.name;
      final prayerLocalized = worldTranslations[language]?[prayerRawName] ??
          translateFor(language, prayerRawName, prayerRawName, prayerRawName);

      final nextPrayerHeader = worldTranslations[language]?['Next Prayer'] ??
          translateFor(language, 'Next Prayer', 'اگلی نماز', 'ابلي نماز', 'الصلاة القادمة');
      final currentPrayerHeader = worldTranslations[language]?['Current Prayer'] ??
          translateFor(language, 'Current Prayer', 'موجودہ وقت', 'موجوده وقت', 'الصلاة الحالية');

      final headerText = state.isElapsed ? currentPrayerHeader : nextPrayerHeader;
      final title = '$mark$headerText: $prayerLocalized';

      final timeFormatted = '\u2066${state.prayer.displayTime} ${state.prayer.displayIsPm ? 'PM' : 'AM'}\u2069';

      final channelName = worldTranslations[language]?['Lock Screen Live Countdown'] ??
          translateFor(language, 'Lock Screen Live Countdown', 'لاک اسکرین لائیو کاؤنٹ ڈاؤن', 'لاڪ اسڪرين لائيو ڪائونٽ ڊائون', 'العد التنازلي المباشر للشاشة');

      // Body shows clean prayer time only (status and live countdown are in the header above)
      final body = '$mark$timeFormatted';

      // Start/update the native Android foreground service with a 7-day timeline so
      // aggressive OEMs (Infinix, Tecno, Vivo, Xiaomi, Oppo) treat Sukkur Salah as an
      // active foreground service and do not force-stop its scheduled prayer alarms
      // when swiped from Recents.
      final timelineJson = _buildKeepAliveTimelineJson(
        now: now,
        language: language,
        isRtl: isRtl,
        mark: mark,
        nextPrayerHeader: nextPrayerHeader,
        currentPrayerHeader: currentPrayerHeader,
      );
      // Persist timeline to SharedPreferences first so WorkManager background
      // runs (where MainActivity's MethodChannel is not attached) still trigger
      // MainApplication's SharedPreferences listener to update PrayerKeepAliveService.
      await prefs.setString('keepalive_timeline', timelineJson);
      await prefs.setString('keepalive_channel_name', channelName);
      await prefs.setString('keepalive_stale_title', title);
      await prefs.setString('keepalive_stale_body', body);

      try {
        const nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');
        await nativeChannel.invokeMethod<bool>(
          'startKeepAlive',
          {
            'timeline': timelineJson,
            'channelName': channelName,
            'staleTitle': title,
            'staleBody': body,
          },
        );
      } catch (_) {
        // In WorkManager background isolate, MainApplication's listener on
        // 'flutter.keepalive_sync_requested_at' handles updating PrayerKeepAliveService.
        try {
          await prefs.setInt('keepalive_sync_requested_at',
              DateTime.now().millisecondsSinceEpoch);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Failed to update live countdown notification: $e');
    }

    WidgetService.updateWidget();
  }

  /// Builds a 48-hour JSON timeline of prayer countdown/elapsed segments for the
  /// native [PrayerKeepAliveService], so the status-bar notification transitions
  /// accurately even while the Flutter engine is not running.
  String _buildKeepAliveTimelineJson({
    required DateTime now,
    required String language,
    required bool isRtl,
    required String mark,
    required String nextPrayerHeader,
    required String currentPrayerHeader,
  }) {
    final int epochDeltaMs =
        DateTime.now().millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    final horizonEnd = now.add(const Duration(days: 7));

    final candidates = <DateTime>{now};
    for (int d = 0; d <= 7; d++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: d));
      final dayTiming = TimingsData.instance.timingFor(date);
      if (dayTiming == null) continue;
      candidates.add(DateTime(date.year, date.month, date.day, 0, 0, 1));
      candidates.add(DateTime(date.year, date.month, date.day, 9, 30, 1));
      for (final p in dayTiming.allTimings) {
        final dt = p.toDateTime(date: date);
        candidates.add(dt.subtract(const Duration(minutes: 40)));
        candidates.add(dt.subtract(const Duration(minutes: 30)));
        candidates.add(dt);
        candidates.add(dt.add(const Duration(minutes: 3)));
        candidates.add(dt.add(const Duration(minutes: 7)));
      }
    }

    final sorted = candidates
        .where((t) => !t.isBefore(now) && !t.isAfter(horizonEnd))
        .toList()
      ..sort();

    final segments = <Map<String, dynamic>>[];
    String? lastKey;

    for (final probe in sorted) {
      final dayTiming = TimingsData.instance.timingFor(probe);
      if (dayTiming == null) continue;
      final state = computePrayerState(probe, dayTiming);
      if (state == null) continue;

      final segKey = '${state.prayer.name}_${state.isElapsed}_${probe.day}';
      if (segKey == lastKey) continue;
      lastKey = segKey;

      final prayerRawName = state.prayer.name;
      final prayerLocalized = worldTranslations[language]?[prayerRawName] ??
          translateFor(language, prayerRawName, prayerRawName, prayerRawName);
      final headerText =
          state.isElapsed ? currentPrayerHeader : nextPrayerHeader;
      final segTitle = '$mark$headerText: $prayerLocalized';
      final timeFormatted =
          '\u2066${state.prayer.displayTime} ${state.prayer.displayIsPm ? 'PM' : 'AM'}\u2069';
      final segBody = '$mark$timeFormatted';
      final sign = state.isElapsed ? '+' : '-';
      final statusLabel = state.isElapsed
          ? _getOngoingLabel(language)
          : _getRemainingLabel(language);
      final segSubText =
          isRtl ? '\u202A$statusLabel $sign\u202C' : '$statusLabel $sign';

      final int whenMs = (state.isElapsed
                  ? probe.subtract(state.duration)
                  : probe.add(state.duration))
              .millisecondsSinceEpoch +
          epochDeltaMs;

      segments.add({
        'start': probe.millisecondsSinceEpoch + epochDeltaMs,
        'title': segTitle,
        'body': segBody,
        'sub': segSubText,
        'when': whenMs,
        'down': !state.isElapsed,
      });
    }

    return jsonEncode(segments);
  }

  Future<void> cancelLiveCountdown() async {
    if (kIsWeb || _plugin == null) return;
    try {
      stopLiveCountdownTimer();
      try {
        const nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');
        await nativeChannel.invokeMethod('stopKeepAlive');
      } catch (_) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('keepalive_sync_requested_at',
              DateTime.now().millisecondsSinceEpoch);
        } catch (_) {}
      }
      await _plugin!.cancel(liveCountdownId);
    } catch (_) {}
  }

  static const int jamaatBaseId = 70000;

  Future<void> cancelJamaatReminders() async {
    if (kIsWeb || _plugin == null) return;
    try {
      for (int i = 0; i < 10; i++) {
        await _plugin!.cancel(jamaatBaseId + i);
      }
    } catch (_) {}
  }

  Future<void> scheduleJamaatReminders({bool syncNative = true}) async {
    if (kIsWeb || _plugin == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool enabled = prefs.getBool('jamaat_reminders_enabled') ?? false;
      final String favoriteId = prefs.getString('favorite_masjid_id') ?? '';
      final masjid = favoriteId.isNotEmpty
          ? JamaatTimesService.instance.findMasjidById(favoriteId)
          : null;

      if (!enabled || favoriteId.isEmpty || masjid == null) {
        await cancelJamaatReminders();
        if (syncNative) {
          try {
            const nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');
            await nativeChannel.invokeMethod('syncPrayerAlarms', {'force': true});
          } catch (_) {
            try {
              await prefs.setInt('alarm_batch_completed_at',
                  DateTime.now().millisecondsSinceEpoch);
            } catch (_) {}
          }
        }
        return;
      }

      final canExact = await canScheduleExactAlarms();
      final jamaatScheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final int offsetMins = prefs.getInt('jamaat_reminder_offset_mins') ?? 15;
      final String language = prefs.getString('language_code') ?? 'english';

      final timing = JamaatTimesService.instance.getTimingFor(masjid);
      final dynamicName = masjid.getNameFor(language);
      final masjidName = (dynamicName.isNotEmpty && dynamicName != masjid.nameKey)
          ? dynamicName
          : translateFor(
              language,
              masjid.nameKey,
              masjid.getNameFor('urdu'),
              masjid.getNameFor('sindhi'),
              masjid.getNameFor('arabic'),
            );

      final Map<String, String> prayerTimes = {
        'Fajr': timing.fajr,
        'Zuhar': timing.zuhar,
        'Asar': timing.asar,
        'Maghrib': timing.maghrib,
        'Isha': timing.isha,
      };

      int idOffset = 0;
      for (final entry in prayerTimes.entries) {
        final prayerRaw = entry.key;
        final timeStr = entry.value;

        try {
          final clean = timeStr.replaceAll('PM', '').replaceAll('AM', '').trim();
          final parts = clean.split(':');
          if (parts.length >= 2) {
            int h = int.parse(parts[0]);
            int m = int.parse(parts[1]);
            final isPm = timeStr.contains('PM');
            if (isPm && h < 12) h += 12;
            if (!isPm && h == 12) h = 0;

            final now = DateTime.now();
            var jamaatTime = DateTime(now.year, now.month, now.day, h, m);
            var triggerTime = jamaatTime.subtract(Duration(minutes: offsetMins));

            while (!triggerTime.isAfter(now)) {
              jamaatTime = jamaatTime.add(const Duration(days: 1));
              triggerTime = triggerTime.add(const Duration(days: 1));
            }

            final bool isRtl = rtlLanguages.contains(language);
            final String mark = isRtl ? '\u200F' : '\u202A';

            final prayerName = translateFor(language, prayerRaw, prayerRaw, prayerRaw);
            final titleText = additionalTranslations[language]?["Pre-Jama'at Reminder"] ??
                worldTranslations[language]?["Pre-Jama'at Reminder"] ??
                translateFor(
                  language,
                  'Pre-Jama\'at Reminder',
                  'قبل از جماعت یاد دہانی',
                  'جماعت کان اڳ ياد دهاني',
                  'تنبيه قبل الجماعة',
                );
            final String title = isRtl ? '$mark🕌 $titleText' : '🕌 $titleText';

            final String timeFormatted = isRtl ? '\u2066$timeStr\u2069' : timeStr;
            final String body;

            switch (language) {
              case 'urdu':
                body = '$mark$masjidName میں $prayerName کی جماعت $offsetMins منٹ میں ($timeFormatted) پر ہوگی۔';
                break;
              case 'sindhi':
                body = '$mark$masjidName ۾ $prayerName جي جماعت $offsetMins منٽن ۾ ($timeFormatted) تي ٿيندي.';
                break;
              case 'arabic':
                body = '$markصلاة $prayerName جماعة في $masjidName بعد $offsetMins دقيقة ($timeFormatted).';
                break;
              case 'persian':
                body = '$markنماز جماعت $prayerName در $masjidName $offsetMins دقیقه دیگر ($timeFormatted) برگزار می‌شود.';
                break;
              case 'bengali':
                body = '$masjidName-এ $offsetMins মিনিটের মধ্যে ($timeFormatted) $prayerName জামাত অনুষ্ঠিত হবে।';
                break;
              case 'indonesian':
                body = 'Jama\'ah $prayerName di $masjidName dalam $offsetMins menit ($timeFormatted).';
                break;
              case 'turkish':
                body = '$masjidName bünyesinde $prayerName cemaati $offsetMins dakika içinde ($timeFormatted).';
                break;
              case 'french':
                body = 'Jama\'at de $prayerName à $masjidName dans $offsetMins min ($timeFormatted).';
                break;
              case 'hindi':
                body = '$masjidName में $prayerName की जमात $offsetMins मिनट में ($timeFormatted) होगी।';
                break;
              default:
                body = '$prayerName Jama\'at at $masjidName in $offsetMins mins ($timeFormatted).';
            }

            const androidDetails = AndroidNotificationDetails(
              'ch_jamaat_reminders_v2',
              'باجماعت نماز الارم',
              channelDescription: 'پسندیدہ مسجد کی باجماعت نماز کی یاد دہانی',
              importance: Importance.max,
              priority: Priority.max,
              icon: '@drawable/ic_notification',
              color: Color(0xFF0D6B5E),
              visibility: NotificationVisibility.public,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              sound: RawResourceAndroidNotificationSound('mixkit_bell_notification_933'),
              fullScreenIntent: false,
              playSound: true,
              enableVibration: true,
            );

            const iosDetails = DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.timeSensitive,
            );

            const details = NotificationDetails(
              android: androidDetails,
              iOS: iosDetails,
            );

            final scheduledTz = tz.TZDateTime.from(triggerTime, tz.local);

            await _safeZonedSchedule(
              id: jamaatBaseId + idOffset,
              title: title,
              body: body,
              scheduledDate: scheduledTz,
              notificationDetails: details,
              scheduleMode: jamaatScheduleMode,
              matchDateTimeComponents: DateTimeComponents.time,
            );
          }
        } catch (_) {}
        idOffset++;
      }

      if (syncNative) {
        try {
          const nativeChannel = MethodChannel('pk.sukkur.salah/native_helper');
          await nativeChannel.invokeMethod('syncPrayerAlarms', {'force': true});
        } catch (_) {
          try {
            await prefs.setInt('alarm_batch_completed_at',
                DateTime.now().millisecondsSinceEpoch);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Failed to schedule Jamaat reminders: $e');
    }
  }
}

