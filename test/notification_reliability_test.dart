import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/services/notification_health.dart';
import 'package:sukkur_prayer_timings/services/notification_service.dart';

void main() {
  final horizon = NotificationService.scheduleHorizonDays;

  group('notification ids', () {
    test('no two prayers collide anywhere in the horizon', () {
      final seen = <int, String>{};
      for (final entry in NotificationService.baseIds.entries) {
        for (var day = 0; day < horizon; day++) {
          final id = entry.value + day;
          expect(seen.containsKey(id), isFalse,
              reason: '${entry.key} day $day (id $id) collides with '
                  '${seen[id]} - one alert would silently replace the other');
          seen[id] = '${entry.key} day $day';
        }
      }
    });

    test('no two custom reminders collide anywhere in the horizon', () {
      // Well past any plausible number of reminders.
      const reminderCount = 40;
      final seen = <int>{};
      for (var i = 0; i < reminderCount; i++) {
        for (var day = 0; day < horizon; day++) {
          final id = NotificationService.reminderNotificationId(i, day);
          expect(seen.add(id), isTrue,
              reason: 'reminder $i day $day produced a duplicate id $id');
        }
      }
    });

    test('reminders never stray into the prayer id range', () {
      final prayerMax = NotificationService.baseIds.values
              .reduce((a, b) => a > b ? a : b) +
          horizon;
      expect(NotificationService.reminderNotificationId(0, 0),
          greaterThan(prayerMax));
    });

    test('the horizon outlasts a long gap between background refreshes', () {
      // The refresh job runs every 6 hours but is throttled by Doze and OEM
      // battery managers; a week of suppression must not empty the queue.
      expect(horizon, greaterThanOrEqualTo(14));
    });
  });

  group('notification health', () {
    NotificationHealth build({
      bool notifications = true,
      bool exact = true,
      bool battery = true,
    }) =>
        NotificationHealth(
          notificationsAllowed: notifications,
          exactAlarmsAllowed: exact,
          batteryUnrestricted: battery,
          hasAutoStartScreen: false,
        );

    test('all permissions granted is healthy and quiet', () {
      final health = build();
      expect(health.isHealthy, isTrue);
      expect(health.isSilenced, isFalse);
      expect(health.blockers, isEmpty);
    });

    test('blocked notifications read as silenced, not merely late', () {
      final health = build(notifications: false);
      expect(health.isHealthy, isFalse);
      expect(health.isSilenced, isTrue);
      expect(health.blockers,
          contains(NotificationBlocker.notificationsBlocked));
    });

    test('missing exact alarms means late, not silent', () {
      final health = build(exact: false);
      expect(health.isHealthy, isFalse);
      expect(health.isSilenced, isFalse,
          reason: 'alerts still arrive, just delayed by Android');
      expect(health.blockers, [NotificationBlocker.exactAlarmsBlocked]);
    });

    test('battery restriction is reported on its own', () {
      final health = build(battery: false);
      expect(health.isHealthy, isFalse);
      expect(health.blockers, [NotificationBlocker.batteryRestricted]);
    });

    test('every blocker is reported, not just the first', () {
      final health =
          build(notifications: false, exact: false, battery: false);
      expect(health.blockers, hasLength(3));
    });

    test('an unanswerable platform never nags the user', () {
      expect(NotificationHealth.unknown.isHealthy, isTrue);
    });
  });
}
