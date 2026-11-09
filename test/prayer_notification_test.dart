import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations.dart';
import 'package:sukkur_prayer_timings/models/namaz_timing.dart';
import 'package:sukkur_prayer_timings/services/notification_service.dart';

PrayerTime prayer(String name, String urduName) =>
    PrayerTime(name: name, urduName: urduName, time: '05:12');

(String, String) alertFor(String language, {required bool sukkur, String name = 'Fajar'}) =>
    NotificationService.instance.prayerAlert(
      prayer: prayer(name, 'فجر'),
      language: language,
      isSukkurMode: sukkur,
      rawTime: '5:12AM',
    );

/// Strips the leading bidi control character so assertions read cleanly.
String body((String, String) alert) => alert.$2.substring(1);
String title((String, String) alert) => alert.$1.substring(1);

void main() {
  group('Sukkur mode prayer alerts across all languages', () {
    test('English has proper English phrasing with Fajr advisory in Sukkur mode', () {
      expect(body(alertFor('english', sukkur: true)),
          '<b>Fajr</b> time has started\n(Fajr Azan should not be called before this time)');
    });

    test('World mode is fully English without Sukkur advisory', () {
      final b = body(alertFor('english', sukkur: false));
      expect(b, '<b>Fajar</b> time has started');
      expect(b, isNot(contains('کا وقت')));
    });

    test('the special prayers in English', () {
      expect(body(alertFor('english', sukkur: true, name: 'Tulu Aftab')),
          '<b>Sunrise</b> has occurred\n(Forbidden time for prayer)');

      final world = body(alertFor('english', sukkur: false, name: 'Tulu Aftab'));
      expect(world, '<b>Sunrise</b> time has started\n'
          '(Forbidden time for prayer)');

      expect(body(alertFor('english', sukkur: false, name: 'Ishraq')),
          '<b>Ishraq</b> time has started\n(You can pray now)');
    });
  });

  group('Sukkur mode notifications include advisories', () {
    test('Urdu', () {
      expect(body(alertFor('urdu', sukkur: true)),
          '<b>فجر</b> کا وقت شروع ہو گیا ہے\n(فجر کی اذان اس وقت سے پہلے نہ دی جائے)');
      expect(body(alertFor('urdu', sukkur: false)),
          '<b>فجر</b> کا وقت شروع ہو گیا ہے');
    });

    test('Sindhi', () {
      expect(body(alertFor('sindhi', sukkur: true)),
          '<b>فجر</b> جو وقت شروع ٿي ويو آهي\n(فجر جي اذان هن وقت کان اڳ نه ڏني وڃي)');
      expect(body(alertFor('sindhi', sukkur: true, name: 'Maghrib')),
          '<b>مغرب</b> جو وقت شروع ٿي ويو آهي');
      expect(body(alertFor('sindhi', sukkur: true, name: 'Isha')),
          '<b>عشاء</b> جو وقت شروع ٿي ويو آهي');
      expect(body(alertFor('sindhi', sukkur: true, name: 'Misl Awwal')),
          '<b>مثل اول</b> جو وقت شروع ٿي ويو آهي');
    });

    test('Arabic keeps its verb-first word order and adds advisory', () {
      expect(body(alertFor('arabic', sukkur: true)),
          'بدأ وقت <b>الفجر</b>\n(لا ينبغي رفع أذان الفجر قبل هذا الوقت)');
    });
  });

  group('world languages get their own language in both modes', () {
    const worldLanguages = [
      'bengali', 'indonesian', 'turkish', 'french', 'hindi', 'persian',
    ];

    test('body is translated, never English or Urdu leftovers', () {
      for (final lang in worldLanguages) {
        for (final sukkur in [true, false]) {
          final b = body(alertFor(lang, sukkur: sukkur));
          final where = '$lang (sukkur=$sukkur)';

          expect(b, isNot(contains('کا وقت شروع ہو گیا ہے')),
              reason: '$where still carries the Urdu suffix');
          expect(b, isNot(contains('time has started')),
              reason: '$where fell back to English');
          expect(b, contains(worldTranslations[lang]!['Fajar']!),
              reason: '$where is missing the translated prayer name');
        }
      }
    });

    test('title is translated', () {
      for (final lang in worldLanguages) {
        expect(title(alertFor(lang, sukkur: false)),
            '${worldTranslations[lang]!['Sukkur Salah']!} (5:12AM)',
            reason: lang);
      }
    });

    test('the Ishraq and sunrise notes are translated too', () {
      for (final lang in worldLanguages) {
        expect(body(alertFor(lang, sukkur: false, name: 'Ishraq')),
            contains(worldTranslations[lang]!['(You can pray now)']!),
            reason: lang);
        expect(body(alertFor(lang, sukkur: false, name: 'Tulu Aftab')),
            contains(worldTranslations[lang]!['(Forbidden time for prayer)']!),
            reason: lang);
      }
    });
  });

  test('right-to-left languages get the RTL mark, others the LTR mark', () {
    for (final lang in languageNamesMap.keys) {
      final expected = rtlLanguages.contains(lang) ? '‏' : '‪';
      final alert = alertFor(lang, sukkur: false);
      expect(alert.$1[0], expected, reason: '$lang title mark');
      expect(alert.$2[0], expected, reason: '$lang body mark');
    }
  });
}
