import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'notification_service.dart';

const MethodChannel _native = MethodChannel('pk.sukkur.salah/native_helper');

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
}

class NotificationHealth {
  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;
  final bool batteryUnrestricted;

  /// Whether this device even offers an autostart screen. Only the OEMs that
  /// need it (Xiaomi, Oppo, Vivo, Huawei, Asus) have one.
  final bool hasAutoStartScreen;

  const NotificationHealth({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
    required this.batteryUnrestricted,
    required this.hasAutoStartScreen,
  });

  /// Treated as healthy until proven otherwise, so a platform that cannot
  /// answer never nags the user.
  static const unknown = NotificationHealth(
    notificationsAllowed: true,
    exactAlarmsAllowed: true,
    batteryUnrestricted: true,
    hasAutoStartScreen: false,
  );

  List<NotificationBlocker> get blockers => [
        if (!notificationsAllowed) NotificationBlocker.notificationsBlocked,
        if (!exactAlarmsAllowed) NotificationBlocker.exactAlarmsBlocked,
        if (!batteryUnrestricted) NotificationBlocker.batteryRestricted,
      ];

  bool get isHealthy => blockers.isEmpty;

  /// Nothing will arrive at all - worth saying plainly, because it is a
  /// different message from "these will be late".
  bool get isSilenced => !notificationsAllowed;

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

    bool notifications = true;
    bool exact = true;
    try {
      notifications = await NotificationService.instance.areNotificationsEnabled();
      exact = await NotificationService.instance.canScheduleExactAlarms();
    } catch (_) {
      // Plugin not ready (init failed, or a background isolate) - say nothing.
      return unknown;
    }

    return NotificationHealth(
      notificationsAllowed: notifications,
      exactAlarmsAllowed: exact,
      batteryUnrestricted: await ask('isBatteryOptimizationIgnored'),
      hasAutoStartScreen: await ask('hasAutoStart', fallback: false),
    );
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
    }
  }

  /// Opens the OEM autostart list, where one exists.
  static Future<void> openAutoStart() async {
    try {
      await _native.invokeMethod('requestAutoStart');
    } catch (_) {
      // Not available on this ROM.
    }
  }
}
