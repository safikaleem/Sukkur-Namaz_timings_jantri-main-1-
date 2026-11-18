import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';
import 'package:sukkur_prayer_timings/widgets/clock_date_display.dart';
import 'package:sukkur_prayer_timings/utils/app_theme.dart';
import 'package:sukkur_prayer_timings/utils/hijri_converter.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDate = DateTime(2026, 11, 15); // Sunday, 15 Nov 2026

  group('ClockDateDisplay multi-language tests', () {
    test('Hijri date advances after Maghrib time', () {
      final beforeMaghrib = DateTime(2026, 11, 15, 17, 0); // 5:00 PM
      final afterMaghrib = DateTime(2026, 11, 15, 18, 0);  // 6:00 PM
      final maghribTime = DateTime(2026, 11, 15, 17, 30);  // 5:30 PM

      final hijriBefore = HijriConverter.todayHijri(
        language: 'english',
        maghribTime: maghribTime,
        currentTime: beforeMaghrib,
      );

      final hijriAfter = HijriConverter.todayHijri(
        language: 'english',
        maghribTime: maghribTime,
        currentTime: afterMaghrib,
      );

      expect(hijriBefore, isNot(equals(hijriAfter)));
    });

    test('Weekdays for all 10 languages', () {
      final expectedSunday = {
        'english': 'Sunday',
        'urdu': 'اتوار',
        'sindhi': 'آچر',
        'arabic': 'الأحد',
        'hindi': 'रविवार',
        'bengali': 'রবিবার',
        'turkish': 'Pazar',
        'indonesian': 'Minggu',
        'french': 'Dimanche',
        'persian': 'یکشنبه',
      };

      for (final entry in expectedSunday.entries) {
        final day = ClockDateDisplay.getWeekdayName(testDate, entry.key);
        expect(day, entry.value, reason: 'Failed for ${entry.key}');
      }
    });

    test('Maghrib notice for all 10 languages', () {
      for (final lang in languageNamesMap.keys) {
        final notice = ClockDateDisplay.getMaghribNotice(lang);
        expect(notice.isNotEmpty, isTrue, reason: 'Empty notice for $lang');
        expect(notice.startsWith('('), isTrue, reason: 'Missing ( for $lang');
        expect(notice.endsWith(')'), isTrue, reason: 'Missing ) for $lang');
      }
    });

    test('Gregorian date format for all 10 languages', () {
      for (final lang in languageNamesMap.keys) {
        final formatted = ClockDateDisplay.formatGregorianDate(testDate, lang);
        expect(formatted.isNotEmpty, isTrue, reason: 'Empty for $lang');
        if (lang == 'english') {
          expect(formatted, '15 November 2026');
        } else if (lang == 'french') {
          expect(formatted, '15 Novembre 2026');
        } else if (lang == 'turkish') {
          expect(formatted, '15 Kasım 2026');
        } else if (lang == 'indonesian') {
          expect(formatted, '15 November 2026');
        }
      }
    });
  });

  group('ClockDateDisplay Widget rendering', () {
    testWidgets('Renders centered layout with large bold day and proper colors', (tester) async {
      final settings = SettingsProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClockDateDisplay(
              now: testDate,
              maghribTime: DateTime(2026, 11, 15, 17, 30),
              settings: settings,
              isDark: false,
              isCompact: false,
            ),
          ),
        ),
      );

      expect(find.text('Sunday'), findsOneWidget);
      expect(find.text('(Hijri date updates after Maghrib)'), findsOneWidget);
      expect(find.text('15 November 2026'), findsOneWidget);

      final dayWidget = tester.widget<Text>(find.text('Sunday'));
      expect(dayWidget.style?.fontSize, 24);
      expect(dayWidget.style?.fontWeight, FontWeight.bold);
      // Ensure NOT theme color
      expect(dayWidget.style?.color, const Color(0xFF1A1A1A));
    });

    testWidgets('Renders compact header layout for Sukkur mode (3 lines without notice)', (tester) async {
      final settings = SettingsProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClockDateDisplay(
              now: testDate,
              maghribTime: DateTime(2026, 11, 15, 17, 30),
              settings: settings,
              isDark: false,
              isCompact: true,
            ),
          ),
        ),
      );

      expect(find.text('Sunday'), findsOneWidget);
      expect(find.text('(Hijri date updates after Maghrib)'), findsNothing);
      expect(find.text('15 November 2026'), findsOneWidget);

      final dayWidget = tester.widget<Text>(find.text('Sunday'));
      expect(dayWidget.style?.fontSize, 13);
      expect(dayWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('Applies Urdu Nastaliq font to ALL lines when language is Urdu', (tester) async {
      final settings = SettingsProvider();
      await settings.setLanguage('urdu');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClockDateDisplay(
              now: testDate,
              maghribTime: DateTime(2026, 11, 15, 17, 30),
              settings: settings,
              isDark: false,
              isCompact: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(textWidgets.length, 4);

      for (final tw in textWidgets) {
        expect(
          tw.style?.fontFamily,
          equals(AppTheme.urduFont),
          reason: 'Text "${tw.data}" must use AppTheme.urduFont',
        );
      }
    });
  });
}
