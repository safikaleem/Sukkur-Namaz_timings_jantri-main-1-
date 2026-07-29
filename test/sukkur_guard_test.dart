import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

/// Mirrors the guard in WorldPrayersScreen: Sukkur has its own Jantri, so
/// neither typing its name nor standing in the city may switch the app to
/// calculated world timings.
const _sukkurLat = 27.7052;
const _sukkurLng = 68.8574;
const _sukkurRadiusMetres = 20000.0;

const _sukkurNames = [
  'sukkur', 'sukur', 'sukkar', 'sakkhar', 'سکھر', 'سکر', 'سكر',
];

bool looksLikeSukkur(String? name) {
  if (name == null) return false;
  final n = name.toLowerCase();
  return _sukkurNames.any(n.contains);
}

bool isNearSukkur(double lat, double lng) =>
    Geolocator.distanceBetween(lat, lng, _sukkurLat, _sukkurLng) <=
    _sukkurRadiusMetres;

void main() {
  group('by name', () {
    for (final typed in [
      'sukkur',
      'Sukkur',
      'SUKKUR',
      'sukkur, sindh',
      'sukur',
      'sukkar',
      'سکھر',
      'سکر',
      'سكر',
    ]) {
      test('"$typed" is blocked', () => expect(looksLikeSukkur(typed), isTrue));
    }

    for (final typed in ['Karachi', 'Lahore', 'Istanbul', 'Makkah', 'Hyderabad']) {
      test('"$typed" is allowed through',
          () => expect(looksLikeSukkur(typed), isFalse));
    }

    test('null place name is not treated as Sukkur',
        () => expect(looksLikeSukkur(null), isFalse));
  });

  group('by distance', () {
    test('the city centre is inside the radius', () {
      expect(isNearSukkur(_sukkurLat, _sukkurLng), isTrue);
    });

    test('Rohri, right across the river, is inside', () {
      expect(isNearSukkur(27.6926, 68.8964), isTrue);
    });

    test('New Sukkur is inside', () {
      expect(isNearSukkur(27.7200, 68.8300), isTrue);
    });

    test('Khairpur, a separate city ~22 km away, stays selectable', () {
      final km =
          Geolocator.distanceBetween(27.5295, 68.7592, _sukkurLat, _sukkurLng) /
              1000;
      expect(km, greaterThan(20), reason: 'Khairpur measured at ${km}km');
      expect(isNearSukkur(27.5295, 68.7592), isFalse);
    });

    test('Karachi is far outside', () {
      expect(isNearSukkur(24.8607, 67.0011), isFalse);
    });
  });

  test('a nearby town with an unrelated name is still caught by distance', () {
    // The exact case name-matching alone would miss.
    expect(looksLikeSukkur('Rohri'), isFalse);
    expect(isNearSukkur(27.6926, 68.8964), isTrue);
  });
}
