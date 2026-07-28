import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import '../models/namaz_timing.dart';

class TimingsData {
  static TimingsData? _instance;
  static TimingsData get instance => _instance ??= TimingsData._();
  TimingsData._();

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

  DayTiming? _calculateWorldTiming(DateTime date) {
    final lat = _prefs?.getDouble('latitude');
    final lng = _prefs?.getDouble('longitude');
    if (lat == null || lng == null) {
      return _months[date.month]?.dayTiming(date.day); // fallback
    }

    final coordinates = Coordinates(lat, lng);
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

    final asrMethod = _prefs?.getString('asr_method') ?? 'Hanafi';
    if (asrMethod == 'Shafi') {
      params.madhab = Madhab.shafi;
    } else {
      params.madhab = Madhab.hanafi;
    }

    final dateComponents = DateComponents(date.year, date.month, date.day);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    String formatTime(DateTime dt) {
      int h = dt.hour;
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final fajr = formatTime(prayerTimes.fajr);
    final sunrise = formatTime(prayerTimes.sunrise);
    final ishraqDt = prayerTimes.sunrise.add(const Duration(minutes: 15));
    final ishraq = formatTime(ishraqDt);
    final dhuhr = formatTime(prayerTimes.dhuhr);
    
    params.madhab = Madhab.shafi;
    final prayerTimesShafi = PrayerTimes(coordinates, dateComponents, params);
    final mislAwwal = formatTime(prayerTimesShafi.asr);
    
    params.madhab = Madhab.hanafi;
    final prayerTimesHanafi = PrayerTimes(coordinates, dateComponents, params);
    final asrHanafi = formatTime(prayerTimesHanafi.asr);

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
    
    final fullJson = { 'months': monthsMap };
    await _prefs!.setString('world_timings_cache', jsonEncode(fullJson));
  }
}
