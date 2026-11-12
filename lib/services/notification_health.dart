import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

const MethodChannel _native = MethodChannel('pk.sukkur.salah/native_helper');
const String _kAutoStartConfirmedKey = 'oem_autostart_configured_v1';

/// Why a prayer alert might not arrive when it should.
///
/// The app asks for all three of these during onboarding, but every one of them
/// can be taken away afterwards - by the user, by an OS upgrade, or by an OEM
/// battery manager that resets its own settings on update. Nothing re-checked
/// them, so an app that had quietly dropped to late (or silent) delivery looked
/// exactly like one that was working.
enum NotificationBlocker {
  /// Android 13+ POST_NOTIFICATIONS refused: nothing appears at all.
  notificationsBlocked,

  /// No exact-alarm permission, so scheduling falls back to inexact and Android
  /// batches the alert - typically minutes late, sometimes far worse in Doze.
  exactAlarmsBlocked,

  /// The app is still under battery optimisation, so the OS may defer both the
  /// alarm and the background job that keeps the schedule topped up.
  batteryRestricted,

  /// Aggressive OEM ROM (Infinix XOS, Tecno HiOS, Vivo, Xiaomi, Oppo) where the
  /// user has not yet opened the OEM Autostart screen to whitelist the app.
  autoStartNotConfigured,
}

class NotificationHealth {
  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;
  final bool batteryUnrestricted;

  /// Whether this device even offers an autostart screen. Only the OEMs that
  /// need it (Infinix, Tecno, Xiaomi, Oppo, Vivo, Huawei, Asus) have one.
  final bool hasAutoStartScreen;

  /// Whether the user has opened and confirmed the OEM autostart setting.
  final bool autoStartConfigured;

  const NotificationHealth({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
    required this.batteryUnrestricted,
    required this.hasAutoStartScreen,
    this.autoStartConfigured = true,
  });

  /// Treated as healthy until proven otherwise, so a platform that cannot
  /// answer never nags the user.
  static const unknown = NotificationHealth(
    notificationsAllowed: true,
    exactAlarmsAllowed: true,
    batteryUnrestricted: true,
    hasAutoStartScreen: false,
    autoStartConfigured: true,
  );

  List<NotificationBlocker> get blockers => [
        if (!notificationsAllowed) NotificationBlocker.notificationsBlocked,
        if (!exactAlarmsAllowed) NotificationBlocker.exactAlarmsBlocked,
        if (!batteryUnrestricted) NotificationBlocker.batteryRestricted,
        if (hasAutoStartScreen && !autoStartConfigured)
          NotificationBlocker.autoStartNotConfigured,
      ];

  bool get isHealthy => blockers.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationHealth &&
          runtimeType == other.runtimeType &&
          notificationsAllowed == other.notificationsAllowed &&
          exactAlarmsAllowed == other.exactAlarmsAllowed &&
          batteryUnrestricted == other.batteryUnrestricted &&
          hasAutoStartScreen == other.hasAutoStartScreen &&
          autoStartConfigured == other.autoStartConfigured;

  @override
  int get hashCode => Object.hash(
        notificationsAllowed,
        exactAlarmsAllowed,
        batteryUnrestricted,
        hasAutoStartScreen,
        autoStartConfigured,
      );

  /// Nothing will arrive at all - worth saying plainly, because it is a
  /// different message from "these will be late".
  bool get isSilenced => !notificationsAllowed;

  static bool? _cachedHasAutoStart;

  /// Reads the live state. Never throws: a device that refuses to answer is
  /// reported as healthy rather than shown a warning it cannot act on.
  static Future<NotificationHealth> check() async {
    if (kIsWeb) return unknown;

    Future<bool> ask(String method, {bool fallback = true}) async {
      try {
        return await _native.invokeMethod<bool>(method) ?? fallback;
      } catch (_) {
        return fallback;
      }
    }

    try {
      final prefsFuture = SharedPreferences.getInstance();
      final results = await Future.wait([
        NotificationService.instance.areNotificationsEnabled().catchError((_) => true),
        NotificationService.instance.canScheduleExactAlarms().catchError((_) => true),
        ask('isBatteryOptimizationIgnored'),
        _cachedHasAutoStart != null
            ? Future.value(_cachedHasAutoStart!)
            : ask('hasAutoStart', fallback: false).then((val) => _cachedHasAutoStart = val),
      ]);
      final prefs = await prefsFuture;
      final hasAutoStart = results[3];
      final autoStartDone =
          !hasAutoStart || (prefs.getBool(_kAutoStartConfirmedKey) ?? false);

      return NotificationHealth(
        notificationsAllowed: results[0],
        exactAlarmsAllowed: results[1],
        batteryUnrestricted: results[2],
        hasAutoStartScreen: hasAutoStart,
        autoStartConfigured: autoStartDone,
      );
    } catch (_) {
      return unknown;
    }
  }

  /// Opens the system page that fixes [blocker]. Each one lives somewhere
  /// different, and no single settings screen covers them.
  static Future<void> fix(NotificationBlocker blocker) async {
    switch (blocker) {
      case NotificationBlocker.notificationsBlocked:
        await NotificationService.instance.requestNotificationsPermission();
      case NotificationBlocker.exactAlarmsBlocked:
        await NotificationService.instance.requestExactAlarms();
      case NotificationBlocker.batteryRestricted:
        try {
          await _native.invokeMethod('requestIgnoreBatteryOptimization');
        } catch (_) {
          // Some OEM ROMs have no such intent; the native side already tries a
          // general fallback, so there is nothing further to do here.
        }
      case NotificationBlocker.autoStartNotConfigured:
        await openAutoStart();
    }
  }

  /// Opens the OEM autostart list, where one exists, and marks it configured.
  static Future<void> openAutoStart() async {
    try {
      await _native.invokeMethod('requestAutoStart');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAutoStartConfirmedKey, true);
    } catch (_) {
      // Not available on this ROM.
    }
  }
}
