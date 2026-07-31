import '../l10n/world_translations.dart';

class DayTiming {
  final int day;

  // Detailed Jantri fields
  final String subahSadiq;    // صبح صادق (Fajr begin)
  final String tuluAftab;   // طلوع آفتاب (Sunrise)
  final String ishraq;       // اشراق
  final String zawalAftab;  // زوال آفتاب (Zuhr)
  final String mislEAwwal;  // مثل اول
  final String asrHanafi;   // عصر حنفی
  final String maghrib;      // مغرب
  final String isha;         // عشاء

  // Aliases for backwards compatibility
  String get fajr    => subahSadiq;
  String get sunrise => tuluAftab;
  String get zuhr    => zawalAftab;
  String get asr     => asrHanafi;

  /// Fajar = Subah Sadiq + 6 minutes
  String get fajar {
    final parts = subahSadiq.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final totalMins = h * 60 + m + 6;
    final fh = (totalMins ~/ 60).toString().padLeft(2, '0');
    final fm = (totalMins % 60).toString().padLeft(2, '0');
    return '$fh:$fm';
  }

  /// Zuhar = Zawal + 5 minutes
  String get zuhar {
    final parts = zawalAftab.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final totalMins = h * 60 + m + 5;
    final zh = (totalMins ~/ 60).toString().padLeft(2, '0');
    final zm = (totalMins % 60).toString().padLeft(2, '0');
    return '$zh:$zm';
  }

  /// True when these times were calculated for a world city rather than read
  /// from the Sukkur jantri. Calculated days expose only the six standard
  /// prayers - the jantri-specific entries (Intiha e Sehar, Ishraq, Zawal,
  /// Misl Awwal) have no equivalent in an astronomical calculation.
  final bool isCalculated;

  const DayTiming({
    required this.day,
    required this.subahSadiq,
    required this.tuluAftab,
    required this.ishraq,
    required this.zawalAftab,
    required this.mislEAwwal,
    required this.asrHanafi,
    required this.maghrib,
    required this.isha,
    this.isCalculated = false,
  });

  static String _field(Map<String, dynamic> json, String newKey, String oldKey) =>
      (json[newKey] as String?) ?? (json[oldKey] as String?) ?? '00:00';

  factory DayTiming.fromJson(Map<String, dynamic> json) {
    return DayTiming(
      day:         json['day'] as int,
      subahSadiq:   _field(json, 'subah_sadiq',  'fajr'),
      tuluAftab:   _field(json, 'tulu_aftab',   'sunrise'),
      ishraq:      _field(json, 'ishraq',       'ishraq'),
      zawalAftab:  _field(json, 'zawal_aftab',  'zuhr'),
      mislEAwwal:  _field(json, 'misl_e_awwal', 'asr'),
      asrHanafi:   _field(json, 'asr_hanafi',   'asr'),
      maghrib:     _field(json, 'maghrib',      'maghrib'),
      isha:        _field(json, 'isha',         'isha'),
    );
  }

  // Returns prayer time as a DateTime for today's date
  DateTime prayerDateTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(
      now.year, now.month, now.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );
  }

  /// The 5 obligatory prayers shown on the home/today screen
  List<PrayerTime> get prayers => [
    PrayerTime(name: 'Intiha e Sehar', urduName: 'انتہائے سحر', time: subahSadiq),
    PrayerTime(name: 'Zuhr',       urduName: 'ظہر',       time: zawalAftab),
    PrayerTime(name: 'Asr',        urduName: 'عصر حنفی',  time: asrHanafi),
    PrayerTime(name: 'Maghrib',    urduName: 'مغرب',      time: maghrib),
    PrayerTime(name: 'Isha',       urduName: 'عشاء',      time: isha),
  ];

  /// What the app shows: the full jantri for Sukkur, the six standard prayers
  /// for a calculated world city.
  List<PrayerTime> get allTimings =>
      isCalculated ? worldTimings : jantriTimings;

  /// The six prayers for a calculated location. Names deliberately match the
  /// jantri keys so notification/auto-silent preferences carry over unchanged.
  /// Fajar and Zuhar use the calculated values directly - the jantri's "+6" and
  /// "+5" offsets are Sukkur conventions and do not apply here.
  /// [is24Hour] rather than a fixed AM/PM per prayer: a calculated city can put
  /// Isha after midnight (routine in a northern summer) and Fajr before it, so
  /// the meridiem has to come from the time itself.
  List<PrayerTime> get worldTimings => [
    PrayerTime(name: 'Fajar',      urduName: 'فجر',        time: subahSadiq, is24Hour: true),
    PrayerTime(name: 'Tulu Aftab', urduName: 'طلوع آفتاب', time: tuluAftab,  is24Hour: true),
    PrayerTime(name: 'Zuhar',      urduName: 'ظہر',        time: zawalAftab, is24Hour: true),
    PrayerTime(name: 'Asr Hanafi', urduName: 'عصر',        time: asrHanafi,  is24Hour: true, displayName: 'Asr'),
    PrayerTime(name: 'Maghrib',    urduName: 'مغرب',       time: maghrib,    is24Hour: true),
    PrayerTime(name: 'Isha',       urduName: 'عشاء',       time: isha,       is24Hour: true),
  ];

  /// All 10 jantri timings (Fajar after Subah Sadiq, Zuhar after Zawal)
  List<PrayerTime> get jantriTimings => [
    PrayerTime(name: 'Intiha e Sehar',  urduName: 'انتہائے سحر',   time: subahSadiq,  isPm: false),
    PrayerTime(name: 'Fajar',        urduName: 'فجر',         time: fajar,       isPm: false),
    PrayerTime(name: 'Tulu Aftab',   urduName: 'طلوع آفتاب',  time: tuluAftab,   isPm: false),
    PrayerTime(name: 'Ishraq',       urduName: 'اشراق',       time: ishraq,      isPm: false),
    PrayerTime(name: 'Zawal',        urduName: 'زوال آفتاب',  time: zawalAftab,  isPm: true),  // 12:xx noon
    PrayerTime(name: 'Zuhar',        urduName: 'ظہر',         time: zuhar,       isPm: true),
    PrayerTime(name: 'Misl Awwal',   urduName: 'مثل اول',     time: mislEAwwal,  isPm: true),
    PrayerTime(name: 'Asr Hanafi',   urduName: 'عصر حنفی',   time: asrHanafi,   isPm: true),
    PrayerTime(name: 'Maghrib',      urduName: 'مغرب',        time: maghrib,     isPm: true),
    PrayerTime(name: 'Isha',         urduName: 'عشاء',        time: isha,        isPm: true),
  ];
}

/// "Asr Hanafi" is a jantri term. A calculated world city just has "Asr", so
/// labels resolve through this while the stored preference key stays the same.
String displayKeyFor(String prayerKey, {required bool isCalculated}) =>
    (isCalculated && prayerKey == 'Asr Hanafi') ? 'Asr' : prayerKey;

class PrayerTime {
  final String name;
  final String urduName;
  final String time;
  final bool isPm;

  /// True when [time] is already a 24-hour "HH:mm" and [isPm] means nothing.
  ///
  /// The Jantri stores 12-hour strings and recovers the meridiem from a fixed
  /// per-prayer flag, which works only because Sukkur's Isha never crosses
  /// midnight. A calculated city's does, so those timings carry the full hour
  /// and let the value speak for itself.
  final bool is24Hour;

  /// Label to show instead of [name], when they differ. [name] stays the
  /// preference key so notification and auto-silent settings carry over.
  final String? displayName;

  const PrayerTime({
    required this.name,
    required this.urduName,
    required this.time,
    this.isPm = false,
    this.is24Hour = false,
    this.displayName,
  });

  int get _hour24 {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    if (is24Hour) return hour;
    return (isPm && hour < 12) ? hour + 12 : hour;
  }

  /// Whether this time falls in the afternoon, however it is stored.
  bool get displayIsPm => is24Hour ? _hour24 >= 12 : isPm;

  /// The 12-hour "hh:mm" the UI prints next to [displayIsPm]. Jantri times are
  /// already in that form and pass through untouched.
  String get displayTime {
    if (!is24Hour) return time;
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = _hour24 % 12 == 0 ? 12 : _hour24 % 12;
    return '${hour.toString().padLeft(2, '0')}:${parts[1]}';
  }

  String localizedName(String language) {
    final name = displayName ?? this.name;
    if (language == 'sindhi') {
      switch (name) {
        case 'Intiha e Sehar': return 'انتهاءِ سحر';
        case 'Fajar': return 'فجر';
        case 'Tulu Aftab': return 'سج اڀرڻ';
        case 'Ishraq': return 'اشراق';
        case 'Zawal': return 'زوالِ آفتاب';
        case 'Zuhar': return 'ظھر';
        case 'Zuhr': return 'ظھر';
        case 'Misl Awwal': return 'مثل اول';
        case 'Asr Hanafi': return 'عصر';
        case 'Asr': return 'عصر';
        case 'Maghrib': return 'مغرب';
        case 'Isha': return 'عشاء';
      }
    }
    if (language == 'arabic') {
      switch (name) {
        case 'Intiha e Sehar': return 'نهاية السحر';
        case 'Fajar': return 'الفجر';
        case 'Tulu Aftab': return 'الشروق';
        case 'Ishraq': return 'الإشراق';
        case 'Zawal': return 'الزوال';
        case 'Zuhar': return 'الظهر';
        case 'Zuhr': return 'الظهر';
        case 'Misl Awwal': return 'المثل الأول';
        case 'Asr Hanafi': return 'العصر';
        case 'Asr': return 'العصر';
        case 'Maghrib': return 'المغرب';
        case 'Isha': return 'العشاء';
      }
    }
    if (language == 'urdu') return urduName;
    // World languages resolve through the shared dictionary; anything it does
    // not cover falls back to the English name.
    return worldTranslations[language]?[name] ?? name;
  }

  DateTime toDateTime({DateTime? date, bool isPm = false}) {
    final base = date ?? DateTime.now();
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    // A 24-hour time already says which half of the day it is in; coercing it
    // would push an after-midnight Isha to lunchtime.
    if (!is24Hour) {
      // Use the instance's isPm field OR the override parameter
      final usePm = this.isPm || isPm;
      if (usePm && hour < 12) hour += 12;
    }
    return DateTime(base.year, base.month, base.day, hour, minute);
  }
}

class MonthData {
  final int monthNumber;
  final String name;
  final String urduName;
  final List<DayTiming> days;

  const MonthData({
    required this.monthNumber,
    required this.name,
    required this.urduName,
    required this.days,
  });

  factory MonthData.fromJson(int monthNum, Map<String, dynamic> json) {
    final daysList = (json['days'] as List)
        .map((d) => DayTiming.fromJson(d as Map<String, dynamic>))
        .toList();
    return MonthData(
      monthNumber: monthNum,
      name: json['name'] as String,
      urduName: json['urdu_name'] as String,
      days: daysList,
    );
  }

  DayTiming? dayTiming(int day) {
    try {
      return days.firstWhere((d) => d.day == day);
    } catch (_) {
      return null;
    }
  }
}
