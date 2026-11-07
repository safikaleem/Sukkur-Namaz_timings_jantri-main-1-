import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/data/timings_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('World Timings Cache generates all 12 months for Karachi', () async {
    SharedPreferences.setMockInitialValues({
      'location_mode': 'world',
      'city_name': 'Karachi',
      'latitude': 24.8607,
      'longitude': 67.0011,
      'calculation_method': 'Karachi',
      'asr_method': 'Hanafi',
    });

    final timings = TimingsData.instance;
    await timings.load();

    await timings.syncWorldTimingsToCache();

    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString('world_timings_cache');

    expect(cacheJson, isNotNull);
    final map = jsonDecode(cacheJson!) as Map<String, dynamic>;
    expect(map['is_24h'], isTrue);
    expect(map['months'], isNotNull);

    final months = map['months'] as Map<String, dynamic>;
    // All 12 months must be present in the cache
    for (int m = 1; m <= 12; m++) {
      expect(months.containsKey(m.toString()), isTrue, reason: 'Month $m should be present');
      final monthData = months[m.toString()] as Map<String, dynamic>;
      final days = monthData['days'] as List;
      expect(days.isNotEmpty, isTrue, reason: 'Month $m should contain days');
      
      // Check day 1
      final day1 = days[0] as Map<String, dynamic>;
      expect(day1['day'], equals(1));
      expect(day1['subah_sadiq'], isNotEmpty);
      expect(day1['maghrib'], isNotEmpty);
      expect(day1['isha'], isNotEmpty);
    }
  });
}
