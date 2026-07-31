import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/data/timings_data.dart';
import 'package:sukkur_prayer_timings/models/namaz_timing.dart';
import 'package:sukkur_prayer_timings/utils/world_location.dart';

/// Minutes since midnight for an "HH:mm" string.
int _mins(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

Future<DayTiming> _timingFor({
  required double lat,
  required double lng,
  required DateTime date,
  String method = 'Muslim World League',
}) async {
  SharedPreferences.setMockInitialValues({
    'location_mode': 'world',
    'latitude': lat,
    'longitude': lng,
    'city_timezone': WorldLocation.timezoneNameFor(lat, lng) ?? '',
    'calculation_method': method,
    'asr_method': 'Hanafi',
  });
  // load() caches its SharedPreferences handle and is a no-op afterwards, so
  // without this every case after the first would silently re-run the first
  // city's coordinates.
  TimingsData.resetForTest();
  await TimingsData.instance.load();
  final timing = TimingsData.instance.timingFor(date);
  expect(timing, isNotNull, reason: 'no timing produced for $lat,$lng');
  return timing!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const londonLat = 51.5074, londonLng = -0.1278;
  const glasgowLat = 55.8642, glasgowLng = -4.2518;

  group('timezone lookup', () {
    test('places UK coordinates in Europe/London', () {
      expect(WorldLocation.timezoneNameFor(londonLat, londonLng),
          'Europe/London');
      expect(WorldLocation.timezoneNameFor(glasgowLat, glasgowLng),
          'Europe/London');
    });

    test('follows British Summer Time across the year', () {
      final summer = WorldLocation.utcOffsetFor(
          'Europe/London', londonLng, DateTime(2026, 7, 31));
      final winter = WorldLocation.utcOffsetFor(
          'Europe/London', londonLng, DateTime(2026, 1, 15));
      expect(summer, const Duration(hours: 1), reason: 'July is BST');
      expect(winter, Duration.zero, reason: 'January is GMT');
    });

    test('falls back to the longitude when the zone is unknown', () {
      // Anchored to the city rather than to the device, which is the point.
      expect(WorldLocation.utcOffsetFor(null, 67.0, DateTime(2026, 7, 31)),
          const Duration(hours: 4));
    });
  });

  group('calculated day', () {
    test('puts London on London time, not the device timezone', () async {
      final day = await _timingFor(
          lat: londonLat, lng: londonLng, date: DateTime(2026, 7, 31));

      // Late July in London: sunrise is early morning and sunset is late
      // evening, in local wall-clock terms. Before the fix these came back on
      // the device's clock, which on a Pakistani phone put Maghrib near 01:26.
      expect(_mins(day.tuluAftab), inInclusiveRange(_mins('04:00'), _mins('06:30')),
          reason: 'sunrise ${day.tuluAftab} is not a London morning');
      expect(_mins(day.maghrib), inInclusiveRange(_mins('20:00'), _mins('21:30')),
          reason: 'sunset ${day.maghrib} is not a London evening');
      expect(_mins(day.zawalAftab), inInclusiveRange(_mins('12:30'), _mins('13:30')),
          reason: 'solar noon ${day.zawalAftab} is not around midday');
    });

    test('is unaffected by how far the device clock is from the city',
        () async {
      // The device timezone is whatever the test host uses; the result must be
      // the same either way, which is exactly what utcOffset buys us.
      final day = await _timingFor(
          lat: glasgowLat, lng: glasgowLng, date: DateTime(2026, 7, 31));
      expect(_mins(day.maghrib), inInclusiveRange(_mins('21:00'), _mins('22:15')),
          reason: 'Glasgow sunset ${day.maghrib} is wrong');
    });

    test('marks the day calculated and stores 24-hour times', () async {
      final day = await _timingFor(
          lat: londonLat, lng: londonLng, date: DateTime(2026, 7, 31));
      expect(day.isCalculated, isTrue);
      for (final p in day.worldTimings) {
        expect(p.is24Hour, isTrue);
        expect(p.time, matches(RegExp(r'^\d{2}:\d{2}$')));
      }
    });

    test('round-trips every prayer through toDateTime unchanged', () async {
      final day = await _timingFor(
          lat: londonLat, lng: londonLng, date: DateTime(2026, 7, 31));
      final date = DateTime(2026, 7, 31);
      for (final p in day.allTimings) {
        final dt = p.toDateTime(date: date);
        expect(dt.hour * 60 + dt.minute, _mins(p.time),
            reason: '${p.name} was shifted by the AM/PM rule');
      }
    });

    test('uses the seventh-of-the-night rule in the far north', () async {
      // London in early August has no true Fajr or Isha - the sky never gets
      // dark enough - so the high-latitude rule decides both. A seventh of the
      // night is what UK timetables print; the angle rule this replaced gave
      // Fajr 02:49 and Isha 23:15, which no London mosque publishes.
      final day = await _timingFor(
          lat: londonLat, lng: londonLng, date: DateTime(2026, 8, 1));

      expect(_mins(day.subahSadiq),
          inInclusiveRange(_mins('03:45'), _mins('04:30')),
          reason: 'Fajr ${day.subahSadiq} is not a seventh-of-night Fajr');
      expect(_mins(day.isha), inInclusiveRange(_mins('21:40'), _mins('22:30')),
          reason: 'Isha ${day.isha} is not a seventh-of-night Isha');

      // The night is split evenly, so Fajr sits as far before sunrise as Isha
      // sits after sunset.
      final beforeSunrise = _mins(day.tuluAftab) - _mins(day.subahSadiq);
      final afterSunset = _mins(day.isha) - _mins(day.maghrib);
      expect((beforeSunrise - afterSunset).abs(), lessThan(5),
          reason: 'the two portions should match: '
              '$beforeSunrise vs $afterSunset minutes');
    });

    test('leaves equatorial cities to the ordinary calculation', () async {
      // Karachi is at 24 degrees, far below the threshold, so the high-latitude
      // rule must not touch it - this is the guard that keeps the change away
      // from everywhere the Jantri's own region cares about.
      final day = await _timingFor(
          lat: 24.8607, lng: 67.0011, date: DateTime(2026, 8, 1),
          method: 'Karachi');
      expect(_mins(day.subahSadiq),
          inInclusiveRange(_mins('04:00'), _mins('05:00')));
      expect(_mins(day.isha), inInclusiveRange(_mins('20:00'), _mins('21:15')));
    });

    test('never breaks inside the polar circles', () async {
      // The sun can stay up, or stay down, for weeks at these latitudes.
      // adhan has no answer and throws on the NaN, which used to take the Times
      // screen down with it; the polar winter also collapsed Asr and Maghrib
      // into one minute, and the polar summer pushed Maghrib past midnight so
      // it sorted ahead of that morning's Fajr.
      const polar = <String, List<double>>{
        'Longyearbyen': [78.2232, 15.6469],
        'Tromso': [69.6492, 18.9553],
        'Reykjavik': [64.1466, -21.9426],
        'Ushuaia': [-54.8019, -68.3030],
      };
      final dates = [
        DateTime(2026, 6, 21), // midnight sun in the north
        DateTime(2026, 12, 21), // polar night in the north
        DateTime(2026, 1, 15),
        DateTime(2026, 8, 1),
      ];

      for (final city in polar.entries) {
        for (final date in dates) {
          final day = await _timingFor(
              lat: city.value[0], lng: city.value[1], date: date);
          final times = day.worldTimings.map((p) => _mins(p.time)).toList();
          for (var i = 1; i < times.length; i++) {
            expect(times[i], greaterThan(times[i - 1]),
                reason: '${city.key} on ${date.month}/${date.day} is out of '
                    'order at index $i: $times');
          }
        }
      }
    });

    test('keeps prayers in ascending order', () async {
      final day = await _timingFor(
          lat: londonLat, lng: londonLng, date: DateTime(2026, 7, 31));
      final times = day.worldTimings.map((p) => _mins(p.time)).toList();
      for (var i = 1; i < times.length; i++) {
        expect(times[i], greaterThan(times[i - 1]),
            reason: 'prayer order breaks at index $i: $times');
      }
    });
  });

  group('alert time zone choice', () {
    Future<DayTiming> londonWith(String mode) async {
      SharedPreferences.setMockInitialValues({
        'location_mode': 'world',
        'latitude': londonLat,
        'longitude': londonLng,
        'city_timezone': 'Europe/London',
        'calculation_method': 'Muslim World League',
        'asr_method': 'Hanafi',
        TimingsData.alertTimezoneKey: mode,
      });
      TimingsData.resetForTest();
      await TimingsData.instance.load();
      return TimingsData.instance.timingFor(DateTime(2026, 7, 31))!;
    }

    test('the displayed times are identical under both choices', () async {
      final city = await londonWith('city');
      final device = await londonWith('device');
      // The promise made to the user: the setting moves the alert, never the
      // timetable. Maghrib reads 20:50 either way.
      expect(device.subahSadiq, city.subahSadiq);
      expect(device.tuluAftab, city.tuluAftab);
      expect(device.zawalAftab, city.zawalAftab);
      expect(device.asrHanafi, city.asrHanafi);
      expect(device.maghrib, city.maghrib);
      expect(device.isha, city.isha);
    });

    test('city mode measures now on the city clock', () async {
      await londonWith('city');
      expect(TimingsData.instance.followsDeviceClock, isFalse);
      final now = TimingsData.instance.nowForTimings();
      final expected = WorldLocation.nowIn('Europe/London');
      // Same minute; the two calls are microseconds apart.
      expect(now.difference(expected).inMinutes.abs(), lessThanOrEqualTo(1));
    });

    test('device mode measures now on the phone clock', () async {
      await londonWith('device');
      expect(TimingsData.instance.followsDeviceClock, isTrue);
      final now = TimingsData.instance.nowForTimings();
      expect(now.difference(DateTime.now()).inMinutes.abs(),
          lessThanOrEqualTo(1));
    });

    test('city mode is the default when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({
        'location_mode': 'world',
        'latitude': londonLat,
        'longitude': londonLng,
        'city_timezone': 'Europe/London',
      });
      TimingsData.resetForTest();
      await TimingsData.instance.load();
      expect(TimingsData.instance.followsDeviceClock, isFalse);
    });

    test('the Jantri always uses the phone clock', () async {
      // Sukkur has no time zone question; the setting must not reach it even if
      // a stale value is left on file.
      SharedPreferences.setMockInitialValues({
        'location_mode': 'sukkur',
        'city_timezone': 'Europe/London',
        TimingsData.alertTimezoneKey: 'city',
      });
      TimingsData.resetForTest();
      await TimingsData.instance.load();
      expect(
          TimingsData.instance
              .nowForTimings()
              .difference(DateTime.now())
              .inMinutes
              .abs(),
          lessThanOrEqualTo(1));
    });
  });

  group('PrayerTime display', () {
    test('derives the meridiem from a 24-hour value', () {
      const evening = PrayerTime(
          name: 'Maghrib', urduName: '', time: '21:26', is24Hour: true);
      expect(evening.displayTime, '09:26');
      expect(evening.displayIsPm, isTrue);

      const afterMidnight =
          PrayerTime(name: 'Isha', urduName: '', time: '00:35', is24Hour: true);
      expect(afterMidnight.displayTime, '12:35');
      expect(afterMidnight.displayIsPm, isFalse,
          reason: 'an after-midnight Isha is AM, not PM');
      final dt = afterMidnight.toDateTime(date: DateTime(2026, 7, 31));
      expect(dt.hour, 0, reason: 'the fixed PM flag must not apply here');
    });

    test('leaves Jantri times exactly as they were', () {
      // The Jantri path is 12-hour plus a fixed flag; none of it may change.
      const maghrib =
          PrayerTime(name: 'Maghrib', urduName: '', time: '06:52', isPm: true);
      expect(maghrib.displayTime, '06:52');
      expect(maghrib.displayIsPm, isTrue);
      expect(maghrib.toDateTime(date: DateTime(2026, 7, 31)).hour, 18);

      const fajar =
          PrayerTime(name: 'Fajar', urduName: '', time: '04:20', isPm: false);
      expect(fajar.displayTime, '04:20');
      expect(fajar.displayIsPm, isFalse);
      expect(fajar.toDateTime(date: DateTime(2026, 7, 31)).hour, 4);
    });
  });

  group('regional calculation method', () {
    test('matches the region a city is actually in', () {
      expect(WorldLocation.defaultCalculationMethod('Europe/London', 51.5, -0.1),
          'Muslim World League');
      expect(WorldLocation.defaultCalculationMethod('Asia/Karachi', 24.9, 67.0),
          'Karachi');
      expect(WorldLocation.defaultCalculationMethod('Asia/Riyadh', 24.7, 46.7),
          'Umm Al-Qura');
      expect(
          WorldLocation.defaultCalculationMethod('America/New_York', 40.7, -74.0),
          'ISNA');
      expect(WorldLocation.defaultCalculationMethod('Africa/Cairo', 30.0, 31.2),
          'Egyptian');
      // South America is not North America.
      expect(
          WorldLocation.defaultCalculationMethod('America/Sao_Paulo', -23.5, -46.6),
          'Muslim World League');
    });
  });
}
