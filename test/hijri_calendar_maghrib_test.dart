import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/utils/hijri_converter.dart';

void main() {
  test('HijriConverter getTodayResult adds +1 day after Maghrib', () {
    final maghribTime = DateTime(2026, 10, 9, 18, 0, 0);
    final beforeMaghrib = DateTime(2026, 10, 9, 17, 59, 0);
    final afterMaghrib = DateTime(2026, 10, 9, 18, 0, 1);

    final resultBefore = HijriConverter.getTodayResult(
      currentTime: beforeMaghrib,
      maghribTime: maghribTime,
    );

    final resultAfter = HijriConverter.getTodayResult(
      currentTime: afterMaghrib,
      maghribTime: maghribTime,
    );

    expect(resultAfter.hDay, equals(resultBefore.hDay + 1));
  });
}
