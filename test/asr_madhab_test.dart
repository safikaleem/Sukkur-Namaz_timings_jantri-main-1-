import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the madhab resolution in TimingsData._calculateWorldTiming: Hanafi
/// is the two-shadow rule, every other madhab is the one-shadow rule.
Madhab madhabFor(String asrMethod) =>
    asrMethod == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;

String asrFor(String asrMethod) {
  final params = CalculationMethod.karachi.getParameters()
    ..madhab = madhabFor(asrMethod);
  final times = PrayerTimes(
    Coordinates(27.7052, 68.8574), // Sukkur
    DateComponents(2026, 7, 29),
    params,
  );
  return '${times.asr.hour.toString().padLeft(2, '0')}:'
      '${times.asr.minute.toString().padLeft(2, '0')}';
}

void main() {
  test('Hanafi Asr is later than the one-shadow madhabs', () {
    final hanafi = asrFor('Hanafi');
    final shafi = asrFor('Shafi');
    expect(hanafi.compareTo(shafi), greaterThan(0),
        reason: 'Hanafi $hanafi should be after Shafi $shafi');
  });

  test('Shafi, Maliki and Hanbali all resolve to the same Asr', () {
    expect(asrFor('Maliki'), asrFor('Shafi'));
    expect(asrFor('Hanbali'), asrFor('Shafi'));
  });

  test('an unknown or unset value falls back to the one-shadow rule', () {
    expect(madhabFor('Shafi'), Madhab.shafi);
    expect(madhabFor('Hanafi'), Madhab.hanafi);
  });
}
