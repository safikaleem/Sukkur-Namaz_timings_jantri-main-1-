import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import '../models/namaz_timing.dart';
import '../utils/world_location.dart';

class TimingsData {
  static TimingsData? _instance;
  static TimingsData get instance => _instance ??= TimingsData._();
  TimingsData._();

  /// Drops the loaded asset and the cached preferences handle.
  ///
  /// Tests only. The app resolves one location per launch and [load] is
  /// deliberately a no-op after the first call, so nothing in production has a
  /// reason to reach for this.
  @visibleForTesting
  static void resetForTest() => _instance = null;

  final Map<int, MonthData> _months = {};
  bool _loaded = false;
  SharedPreferences? _prefs;

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    final raw = await rootBundle.loadString('assets/data/timings.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final monthsJson = json['months'] as Map<String, dynamic>;
    for (final entry in monthsJson.entries) {
      final num = int.parse(entry.key);
      _months[num] = MonthData.fromJson(num, entry.value as Map<String, dynamic>);
    }
    _loaded = true;
  }

  /// Preference deciding which clock a world city's alerts run on.
  ///
  /// 'city' - the times mean what they say in that city, so an alert lands at
  /// the real moment there. 'device' - the same numbers are read against the
  /// phone's own clock, so the alert matches the figure on screen. The two are
  /// identical whenever the phone is actually in the city; the choice only
  /// exists for someone watching a city they are not in.
  static const alertTimezoneKey = 'world_alert_timezone';

  /// True when world alerts should follow the phone's clock rather than the
  /// city's. Defaults to false - the city's own time is the correct reading.
  bool get followsDeviceClock =>
      (_prefs?.getString(alertTimezoneKey) ?? 'city') == 'device';

  /// "Now" in the same frame as the timings this instance is serving.
  ///
  /// The Jantri, and a world city read on the phone's clock, both use ordinary
  /// local time. A world city read on its own clock needs the current time *in
  /// that city*, or every countdown would be measured against the wrong noon.
  DateTime nowForTimings() {
    final mode = _prefs?.getString('location_mode') ?? 'sukkur';
    if (mode != 'world' || followsDeviceClock) return DateTime.now();
    return WorldLocation.nowIn(_prefs?.getString('city_timezone'));
  }

  /// Latitude stood in for when the real one has no sunrise or sunset.
  ///
  /// 48 degrees is the customary choice for Aqrab al-Bilad: far enough south to
  /// always yield a full, ordered day, and close enough to the polar cities
  /// using it that the result still resembles their own daylight.
  static const double _polarFallbackLatitude = 48.0;

  /// Whether these six times can be laid out across a single day.
  ///
  /// Both halves matter. Strictly ascending rules out the polar winter, where
  /// Asr and Maghrib collapse into the same minute. Ending on the day it began
  /// rules out the polar summer, where sunset slides past midnight and Maghrib
  /// would sort ahead of that morning's Fajr - which is what the countdown and
  /// the notification order both read.
  static bool _isUsableDay(PrayerTimes t) {
    final times = [t.fajr, t.sunrise, t.dhuhr, t.asr, t.maghrib, t.isha];
    for (var i = 1; i < times.length; i++) {
      if (!times[i].isAfter(times[i - 1])) return false;
    }
    return times.first.day == times.last.day;
  }

  DayTiming? _calculateWorldTiming(DateTime date) {
    final lat = _prefs?.getDouble('latitude');
    final lng = _prefs?.getDouble('longitude');
    if (lat == null || lng == null) {
      return _months[date.month]?.dayTiming(date.day); // fallback
    }

    final calculationMethodStr = _prefs?.getString('calculation_method') ?? 'Karachi';
    CalculationParameters params;
    switch (calculationMethodStr) {
      case 'Muslim World League':
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'ISNA':
        params = CalculationMethod.north_america.getParameters();
        break;
      case 'Umm Al-Qura':
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'Egyptian':
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 'Tehran':
        params = CalculationMethod.tehran.getParameters();
        break;
      case 'Gulf':
        params = CalculationMethod.dubai.getParameters();
        break;
      case 'Kuwait':
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 'Qatar':
        params = CalculationMethod.qatar.getParameters();
        break;
      case 'Singapore':
        params = CalculationMethod.singapore.getParameters();
        break;
      case 'Karachi':
      default:
        params = CalculationMethod.karachi.getParameters();
        break;
    }

    // Astronomically there are only two Asr rules: Hanafi puts it at twice the
    // object's shadow, while Shafi'i, Maliki and Hanbali all use once the
    // shadow. So every non-Hanafi madhab maps to Madhab.shafi.
    final asrMethod = _prefs?.getString('asr_method') ?? 'Hanafi';
    final asrMadhab = asrMethod == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;
    params.madhab = asrMadhab;

    // Above roughly 48 degrees the sun stops reaching the twilight angle for
    // part of the summer, so Fajr and Isha have no true solution at all and
    // this rule is what decides them instead.
    //
    // One seventh of the night, rather than adhan's default (middle of the
    // night) or the angle-based portion. Checked against a published London
    // timetable for 1 August: the angle rule gives Fajr 02:49 and Isha 23:15,
    // the middle-of-night rule 02:32 and 23:22, while a seventh gives 04:10 and
    // 22:02 - far closer to what UK mosques actually print. No rule matches
    // every mosque; northern committees genuinely differ on this.
    if (lat.abs() >= 48) {
      params.highLatitudeRule = HighLatitudeRule.seventh_of_the_night;
    }

    // The whole point: adhan returns *device local* times unless given an
    // offset, so without this a phone in Pakistan reads London's timetable on a
    // Pakistani clock. The zone comes from the city's own coordinates and the
    // offset is looked up per date, so BST/GMT (and every other DST regime)
    // changes over on the correct day.
    final zoneName = _prefs?.getString('city_timezone') ??
        WorldLocation.timezoneNameFor(lat, lng);
    final utcOffset = WorldLocation.utcOffsetFor(zoneName, lng, date);

    final dateComponents = DateComponents(date.year, date.month, date.day);

    /// One attempt at a latitude, or null when the sun's geometry leaves adhan
    /// with nothing to return.
    PrayerTimes? attempt(double useLat, Madhab madhab) {
      params.madhab = madhab;
      try {
        return PrayerTimes(
            Coordinates(useLat, lng), dateComponents, params,
            utcOffset: utcOffset);
      } catch (_) {
        // adhan throws on the NaN it gets when the sun never crosses the
        // horizon - a real case inside the polar circles, not a bad input.
        return null;
      }
    }

    // Inside the polar circles the sun can fail to rise or set for weeks, so
    // there is no sunrise, no sunset, and no order to put the six prayers in.
    // Longyearbyen threw outright; Tromso in January produced an Asr and a
    // Maghrib in the same minute; Reykjavik in June put Maghrib after midnight,
    // ahead of its own Fajr.
    //
    // The accepted answer is Aqrab al-Bilad - read the nearest latitude where
    // the times do exist. The city keeps its own longitude and time zone, so
    // only the sun's angle is borrowed. Nothing below the Arctic fringe is
    // touched: the fallback is only reached when the real latitude cannot
    // produce a usable day.
    var effectiveLat = lat;
    final direct = attempt(lat, asrMadhab);
    if (direct == null || !_isUsableDay(direct)) {
      effectiveLat = lat.isNegative ? -_polarFallbackLatitude : _polarFallbackLatitude;
    }

    final prayerTimes = attempt(effectiveLat, asrMadhab);
    if (prayerTimes == null) {
      // Should be unreachable - 48 degrees always has a sunrise - but a missing
      // day is still better than a crash on the Times screen.
      return null;
    }

    // 24-hour, unlike the Jantri's 12-hour strings. A calculated day cannot use
    // the Jantri's fixed "Maghrib and Isha are PM" convention: in a northern
    // summer Isha genuinely falls after midnight, and a 12-hour string with no
    // meridiem would be read back 12 hours out. [DayTiming.isCalculated] is
    // what tells every reader which of the two formats it is holding.
    String formatTime(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final fajr = formatTime(prayerTimes.fajr);
    final sunrise = formatTime(prayerTimes.sunrise);
    final ishraqDt = prayerTimes.sunrise.add(const Duration(minutes: 15));
    final ishraq = formatTime(ishraqDt);
    final dhuhr = formatTime(prayerTimes.dhuhr);

    // Misl-e-Awwal is jantri-only and is always the one-shadow time.
    final prayerTimesShafi = attempt(effectiveLat, Madhab.shafi);
    final mislAwwal = formatTime((prayerTimesShafi ?? prayerTimes).asr);

    // Asr follows the madhab the user actually chose.
    final asrHanafi = formatTime(prayerTimes.asr);

    final maghrib = formatTime(prayerTimes.maghrib);
    final isha = formatTime(prayerTimes.isha);

    return DayTiming(
      day: date.day,
      subahSadiq: fajr,
      tuluAftab: sunrise,
      ishraq: ishraq,
      zawalAftab: dhuhr,
      mislEAwwal: mislAwwal,
      asrHanafi: asrHanafi,
      maghrib: maghrib,
      isha: isha,
      isCalculated: true,
    );
  }

  MonthData? month(int m) {
    final mode = _prefs?.getString('location_mode') ?? 'sukkur';
    if (mode == 'sukkur') {
      return _months[m];
    } else {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, m + 1, 0).day;
      final List<DayTiming> generatedDays = [];
      for (int i = 1; i <= daysInMonth; i++) {
        final dt = DateTime(now.year, m, i);
        final timing = _calculateWorldTiming(dt);
        if (timing != null) {
          generatedDays.add(timing);
        }
      }
      return MonthData(
        monthNumber: m,
        name: _months[m]?.name ?? '',
        urduName: _months[m]?.urduName ?? '',
        days: generatedDays,
      );
    }
  }

  DayTiming? todayTiming() {
    final now = DateTime.now();
    return timingFor(now);
  }

  DayTiming? tomorrowTiming() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return timingFor(tomorrow);
  }

  DayTiming? timingFor(DateTime date) {
    final mode = _prefs?.getString('location_mode') ?? 'sukkur';
    if (mode == 'sukkur') {
      return _months[date.month]?.dayTiming(date.day);
    } else {
      return _calculateWorldTiming(date);
    }
  }

  List<MonthData> get allMonths {
    return List.generate(12, (i) => month(i + 1)).whereType<MonthData>().toList();
  }

  Future<void> syncWorldTimingsToCache() async {
    if (_prefs == null) return;
    final now = DateTime.now();
    final monthsMap = <String, dynamic>{};
    
    for (int i = 0; i < 2; i++) {
      int m = now.month + i;
      int y = now.year;
      if (m > 12) {
        m -= 12;
        y += 1;
      }
      
      final daysInMonth = DateTime(y, m + 1, 0).day;
      final List<Map<String, dynamic>> daysList = [];
      
      for (int d = 1; d <= daysInMonth; d++) {
        final dt = DateTime(y, m, d);
        final timing = _calculateWorldTiming(dt);
        if (timing != null) {
          daysList.add({
            'day': timing.day,
            'subah_sadiq': timing.subahSadiq,
            'tulu_aftab': timing.tuluAftab,
            'ishraq': timing.ishraq,
            'zawal_aftab': timing.zawalAftab,
            'misl_e_awwal': timing.mislEAwwal,
            'asr_hanafi': timing.asrHanafi,
            'maghrib': timing.maghrib,
            'isha': timing.isha,
          });
        }
      }
      monthsMap[m.toString()] = { 'days': daysList };
    }

    // The bundled Jantri asset this cache stands in for holds 12-hour strings
    // that the reader turns into real times with a fixed AM/PM per prayer.
    // Calculated days are 24-hour instead, so say so: the Android widget reads
    // this file directly and would otherwise apply the Jantri's convention and
    // land 12 hours out on an after-midnight Isha.
    final fullJson = { 'is_24h': true, 'months': monthsMap };
    await _prefs!.setString('world_timings_cache', jsonEncode(fullJson));
  }
}
