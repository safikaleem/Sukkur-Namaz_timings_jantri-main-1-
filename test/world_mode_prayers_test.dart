import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/models/namaz_timing.dart';
import 'package:sukkur_prayer_timings/utils/prayer_state.dart';

DayTiming build({required bool calculated}) => DayTiming(
      day: 15,
      subahSadiq: '04:10',
      tuluAftab: '05:40',
      ishraq: '05:55',
      zawalAftab: '12:25',
      mislEAwwal: '04:00',
      asrHanafi: '05:15',
      maghrib: '07:20',
      isha: '08:45',
      isCalculated: calculated,
    );

void main() {
  group('Sukkur (jantri)', () {
    test('shows all 10 timings', () {
      expect(build(calculated: false).allTimings.length, 10);
    });

    test('keeps the jantri Fajar +6 and Zuhar +5 offsets', () {
      final t = build(calculated: false);
      final byName = {for (final p in t.allTimings) p.name: p.time};
      expect(byName['Intiha e Sehar'], '04:10');
      expect(byName['Fajar'], '04:16'); // subah + 6
      expect(byName['Zuhar'], '12:30'); // zawal + 5
    });
  });

  group('World city (calculated)', () {
    final t = build(calculated: true);

    test('shows exactly the six standard prayers, in order', () {
      expect(t.allTimings.map((p) => p.name).toList(),
          ['Fajar', 'Tulu Aftab', 'Zuhar', 'Asr Hanafi', 'Maghrib', 'Isha']);
    });

    test('drops the jantri-only entries', () {
      final names = t.allTimings.map((p) => p.name);
      for (final gone in ['Intiha e Sehar', 'Ishraq', 'Zawal', 'Misl Awwal']) {
        expect(names, isNot(contains(gone)), reason: gone);
      }
    });

    test('uses calculated values directly, without the jantri offsets', () {
      final byName = {for (final p in t.allTimings) p.name: p.time};
      expect(byName['Fajar'], '04:10'); // not 04:16
      expect(byName['Zuhar'], '12:25'); // not 12:30
    });

    test('prayer state resolves across the whole day', () {
      // The old jantri rules returned null here: no Intiha e Sehar to anchor
      // on, and nothing covering the midday stretch.
      for (var hour = 0; hour < 24; hour++) {
        for (final minute in [0, 30]) {
          final now = DateTime(2026, 7, 15, hour, minute);
          final state = computePrayerState(now, t);
          expect(state, isNotNull, reason: 'null at $hour:$minute');
          expect(state!.duration.isNegative, isFalse,
              reason: 'negative duration at $hour:$minute');
        }
      }
    });

    test('labels Asr without "Hanafi", in every language', () {
      final asr = t.allTimings.firstWhere((p) => p.name == 'Asr Hanafi');
      expect(asr.localizedName('english'), 'Asr');
      expect(asr.localizedName('urdu'), 'عصر');
      expect(asr.localizedName('sindhi'), 'عصر');
      expect(asr.localizedName('arabic'), 'العصر');
      expect(asr.localizedName('turkish'), 'İkindi'); // not "İkindi (Hanefi)"
      expect(asr.localizedName('hindi'), 'असर');
    });

    test('keeps "Asr Hanafi" as the preference key so settings carry over', () {
      final asr = t.allTimings.firstWhere((p) => p.displayName == 'Asr');
      expect(asr.name, 'Asr Hanafi');
    });

    test('Sukkur still says Asr Hanafi', () {
      final asr =
          build(calculated: false).allTimings.firstWhere((p) => p.name == 'Asr Hanafi');
      expect(asr.localizedName('english'), 'Asr Hanafi');
      expect(asr.localizedName('urdu'), 'عصر حنفی');
      expect(asr.localizedName('turkish'), 'İkindi (Hanefi)');
    });

    test('counts down before a prayer and up after it', () {
      final t2 = build(calculated: true);
      // 12:00 is 25 min before Zuhar (12:25) - inside the 40 min lead.
      final before = computePrayerState(DateTime(2026, 7, 15, 12, 0), t2)!;
      expect(before.prayer.name, 'Zuhar');
      expect(before.isElapsed, isFalse);

      // 12:40 is just past Zuhar and well clear of Asr's lead window.
      final after = computePrayerState(DateTime(2026, 7, 15, 12, 40), t2)!;
      expect(after.prayer.name, 'Zuhar');
      expect(after.isElapsed, isTrue);
    });
  });
}
