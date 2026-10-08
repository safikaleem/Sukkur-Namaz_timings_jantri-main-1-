import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/services/jamaat_times_service.dart';

void main() {
  test('JamaatTimesService format12HourEnglish correctly sets PM for Maghrib and afternoon prayers', () {
    // Standard 12-hour strings without AM/PM
    expect(JamaatTimesService.format12HourEnglish('06:15', defaultPm: true), equals('06:15 PM'));
    expect(JamaatTimesService.format12HourEnglish('05:43', defaultPm: true), equals('05:43 PM'));
    expect(JamaatTimesService.format12HourEnglish('07:20', defaultPm: true), equals('07:20 PM'));

    // Morning prayers (fajr) should stay AM
    expect(JamaatTimesService.format12HourEnglish('05:15 AM'), equals('05:15 AM'));

    // Explicit PM should stay PM
    expect(JamaatTimesService.format12HourEnglish('06:15 PM'), equals('06:15 PM'));

    // 24-hour time 18:15 should convert to 06:15 PM
    expect(JamaatTimesService.format12HourEnglish('18:15'), equals('06:15 PM'));
  });

  test('JamaatTimesService getTimingFor returns PM for Maghrib', () {
    final masjid = JamaatTimesService.sukkurMasjids[0];
    final timing = JamaatTimesService.instance.getTimingFor(masjid);
    expect(timing.maghrib.contains('PM'), isTrue, reason: 'Maghrib timing should be PM, got: ${timing.maghrib}');
    expect(timing.maghrib.contains('AM'), isFalse);
  });
}
