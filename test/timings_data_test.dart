// Validates the bundled prayer-timings data so a typo or missing field in
// assets/data/timings.json is caught in CI rather than shipping a wrong azan
// time (e.g. a missing key silently becomes "00:00" at runtime).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // The eight time fields every day entry must contain.
  const timeFields = <String>[
    'subah_sadiq',
    'tulu_aftab',
    'ishraq',
    'zawal_aftab',
    'misl_e_awwal',
    'asr_hanafi',
    'maghrib',
    'isha',
  ];

  // Days per month for the (leap) year covered by the jantri.
  const daysInMonth = <int, int>{
    1: 31, 2: 29, 3: 31, 4: 30, 5: 31, 6: 30,
    7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31,
  };

  final timeFormat = RegExp(r'^\d{1,2}:\d{2}$');

  late Map<String, dynamic> data;

  setUpAll(() {
    final file = File('assets/data/timings.json');
    expect(file.existsSync(), isTrue,
        reason: 'assets/data/timings.json must exist');
    data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  test('top-level structure is present', () {
    expect(data['city'], isNotNull);
    expect(data['months'], isA<Map<String, dynamic>>());
  });

  test('all 12 months exist with the correct number of days', () {
    final months = data['months'] as Map<String, dynamic>;
    for (var m = 1; m <= 12; m++) {
      final month = months['$m'];
      expect(month, isNotNull, reason: 'month $m missing');
      final days = (month as Map<String, dynamic>)['days'] as List;
      expect(days.length, daysInMonth[m],
          reason: 'month $m should have ${daysInMonth[m]} days');
    }
  });

  test('every day has all time fields in valid HH:MM format', () {
    final months = data['months'] as Map<String, dynamic>;
    for (var m = 1; m <= 12; m++) {
      final days = (months['$m'] as Map<String, dynamic>)['days'] as List;
      for (final day in days.cast<Map<String, dynamic>>()) {
        final dayNum = day['day'];
        for (final field in timeFields) {
          final value = day[field];
          expect(value, isNotNull,
              reason: 'month $m day $dayNum is missing "$field"');
          expect(timeFormat.hasMatch(value as String), isTrue,
              reason: 'month $m day $dayNum "$field" = "$value" '
                  'is not valid HH:MM');
          final parts = value.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          expect(hour, inInclusiveRange(0, 23),
              reason: 'month $m day $dayNum "$field" hour out of range');
          expect(minute, inInclusiveRange(0, 59),
              reason: 'month $m day $dayNum "$field" minute out of range');
        }
      }
    }
  });
}
