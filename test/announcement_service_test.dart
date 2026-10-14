import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/services/announcement_service.dart';

void main() {
  group('AnnouncementService City Filtering Tests', () {
    test('Default announcement without cities targets all users', () {
      final json = {
        'enabled': true,
        'id': 'hadith-global',
        'title': 'Hadith for everyone',
      };

      expect(AnnouncementService.selectAnnouncementForUser(json, 'Sukkur')?['id'], 'hadith-global');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Karachi')?['id'], 'hadith-global');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'London')?['id'], 'hadith-global');
    });

    test('Announcement with "all" targets everyone', () {
      final json = {
        'enabled': true,
        'id': 'all-msg',
        'cities': ['all'],
        'title': 'All cities message',
      };

      expect(AnnouncementService.selectAnnouncementForUser(json, 'Sukkur')?['id'], 'all-msg');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Karachi')?['id'], 'all-msg');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'New York')?['id'], 'all-msg');
    });

    test('Single announcement targeting only Sukkur', () {
      final json = {
        'enabled': true,
        'id': 'sukkur-only',
        'cities': ['sukkur'],
        'title': 'Sukkur only message',
      };

      expect(AnnouncementService.selectAnnouncementForUser(json, 'Sukkur')?['id'], 'sukkur-only');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'سکھر')?['id'], 'sukkur-only');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Karachi'), isNull);
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Lahore'), isNull);
    });

    test('Single announcement targeting only Karachi', () {
      final json = {
        'enabled': true,
        'id': 'karachi-only',
        'cities': ['karachi'],
        'title': 'Karachi only message',
      };

      expect(AnnouncementService.selectAnnouncementForUser(json, 'Karachi')?['id'], 'karachi-only');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Karachi, Pakistan')?['id'], 'karachi-only');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'کراچی')?['id'], 'karachi-only');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Sukkur'), isNull);
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Islamabad'), isNull);
    });

    test('Supports "city" string and comma-separated lists', () {
      final json = {
        'enabled': true,
        'id': 'sindh-event',
        'city': 'sukkur, karachi, hyderabad',
      };

      expect(AnnouncementService.selectAnnouncementForUser(json, 'Sukkur')?['id'], 'sindh-event');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Karachi')?['id'], 'sindh-event');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Hyderabad')?['id'], 'sindh-event');
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Lahore'), isNull);
    });

    test('Multi-announcement list prioritizes city-specific over global fallback', () {
      final json = {
        'announcements': [
          {
            'enabled': true,
            'id': 'sukkur-msg',
            'cities': ['sukkur'],
            'title': 'Sukkur Message',
          },
          {
            'enabled': true,
            'id': 'karachi-msg',
            'cities': ['karachi'],
            'title': 'Karachi Message',
          },
          {
            'enabled': true,
            'id': 'global-fallback',
            'cities': ['all'],
            'title': 'General Message',
          },
        ],
      };

      // Sukkur user gets Sukkur-specific message
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Sukkur')?['id'], 'sukkur-msg');

      // Karachi user gets Karachi-specific message
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Karachi')?['id'], 'karachi-msg');

      // London user gets global fallback
      expect(AnnouncementService.selectAnnouncementForUser(json, 'London')?['id'], 'global-fallback');

      // Lahore user gets global fallback
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Lahore')?['id'], 'global-fallback');
    });

    test('Disabled announcements are ignored', () {
      final json = {
        'announcements': [
          {
            'enabled': false,
            'id': 'sukkur-disabled',
            'cities': ['sukkur'],
          },
          {
            'enabled': true,
            'id': 'global-msg',
            'cities': ['all'],
          },
        ],
      };

      // Since Sukkur message is disabled, Sukkur user gets global
      expect(AnnouncementService.selectAnnouncementForUser(json, 'Sukkur')?['id'], 'global-msg');
    });
  });
}
