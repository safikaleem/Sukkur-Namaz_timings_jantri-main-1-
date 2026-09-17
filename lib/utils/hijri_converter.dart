import 'package:hijri/hijri_calendar.dart';
import '../l10n/world_translations.dart';
import 'urdu_strings.dart';

class HijriDateResult {
  final int hDay;
  final int hMonth;
  final int hYear;
  final int lengthOfMonth;

  const HijriDateResult({
    required this.hDay,
    required this.hMonth,
    required this.hYear,
    required this.lengthOfMonth,
  });

  @override
  String toString() => '$hDay/$hMonth/$hYear ($lengthOfMonth days)';
}

class HijriConverter {
  static const _englishMonths = [
    '', 'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban",
    'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah',
  ];

  // Official/Standard Pakistan Ruet-e-Hilal month start dates (YYYY-MM-DD).
  // These support dynamic 29 and 30 day months so day 30 is never skipped.
  static final Map<String, DateTime> _defaultMonthStarts = {
    // 1447 AH
    '1447-01': DateTime(2025, 6, 27),
    '1447-02': DateTime(2025, 7, 27),
    '1447-03': DateTime(2025, 8, 26),
    '1447-04': DateTime(2025, 9, 25),
    '1447-05': DateTime(2025, 10, 24),
    '1447-06': DateTime(2025, 11, 23),
    '1447-07': DateTime(2025, 12, 22),
    '1447-08': DateTime(2026, 1, 21),
    '1447-09': DateTime(2026, 2, 19),
    '1447-10': DateTime(2026, 3, 21),
    '1447-11': DateTime(2026, 4, 19),
    '1447-12': DateTime(2026, 5, 19),

    // 1448 AH (Current Year)
    '1448-01': DateTime(2026, 6, 17), // 1 Muharram 1448 (Pakistan: 17 Jun 2026)
    '1448-02': DateTime(2026, 7, 16), // 1 Safar 1448 (29 days)
    '1448-03': DateTime(2026, 8, 15), // 1 Rabi al-Awwal 1448 (30 days in Pakistan)
    '1448-04': DateTime(2026, 9, 14), // 1 Rabi al-Thani 1448 (Starts 14 Sep -> 13 Sep is 30 Rabi al-Awwal)
    '1448-05': DateTime(2026, 10, 14), // 1 Jumada al-Awwal 1448
    '1448-06': DateTime(2026, 11, 13), // 1 Jumada al-Thani 1448
    '1448-07': DateTime(2026, 12, 12), // 1 Rajab 1448
    '1448-08': DateTime(2027, 1, 11),  // 1 Sha'ban 1448
    '1448-09': DateTime(2027, 2, 9),   // 1 Ramadan 1448
    '1448-10': DateTime(2027, 3, 11),  // 1 Shawwal 1448
    '1448-11': DateTime(2027, 4, 10),  // 1 Dhu al-Qi'dah 1448
    '1448-12': DateTime(2027, 5, 9),   // 1 Dhu al-Hijjah 1448

    // 1449 AH
    '1449-01': DateTime(2027, 6, 8),
    '1449-02': DateTime(2027, 7, 7),
    '1449-03': DateTime(2027, 8, 6),
    '1449-04': DateTime(2027, 9, 4),
    '1449-05': DateTime(2027, 10, 4),
    '1449-06': DateTime(2027, 11, 3),
    '1449-07': DateTime(2027, 12, 2),
    '1449-08': DateTime(2028, 1, 1),
    '1449-09': DateTime(2028, 1, 30),
    '1449-10': DateTime(2028, 2, 29),
    '1449-11': DateTime(2028, 3, 29),
    '1449-12': DateTime(2028, 4, 28),
    '1450-01': DateTime(2028, 5, 27),
  };

  // Active month starts map (defaults merged with any online synced updates).
  static final Map<String, DateTime> _activeMonthStarts =
      Map.from(_defaultMonthStarts);

  /// Applies updated month starts (e.g. from online Ruet-e-Hilal sync).
  static void applyMonthStarts(Map<String, String> newStarts) {
    newStarts.forEach((key, val) {
      try {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) {
          _activeMonthStarts[key] = DateTime(parsed.year, parsed.month, parsed.day);
        }
      } catch (_) {}
    });
  }

  /// Converts a Gregorian date into a Hijri date with exact month lengths.
  static HijriDateResult convertDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final sorted = _activeMonthStarts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Check if target is within our table range
    if (sorted.isNotEmpty &&
        !target.isBefore(sorted.first.value) &&
        target.isBefore(sorted.last.value.add(const Duration(days: 35)))) {
      int idx = -1;
      for (int i = 0; i < sorted.length; i++) {
        if (!target.isBefore(sorted[i].value)) {
          idx = i;
        } else {
          break;
        }
      }

      if (idx != -1) {
        final cur = sorted[idx];
        final parts = cur.key.split('-');
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final start = cur.value;

        int len = 30;
        if (idx + 1 < sorted.length) {
          len = sorted[idx + 1].value.difference(start).inDays;
        }

        final d = target.difference(start).inDays + 1;
        return HijriDateResult(
          hDay: d,
          hMonth: m,
          hYear: y,
          lengthOfMonth: len,
        );
      }
    }

    // Fallback to standard HijriCalendar if outside defined table range
    final h = HijriCalendar.fromDate(target);
    return HijriDateResult(
      hDay: h.hDay,
      hMonth: h.hMonth,
      hYear: h.hYear,
      lengthOfMonth: h.lengthOfMonth,
    );
  }

  /// Returns today's Hijri date result.
  /// If [maghribTime] is provided and current time >= Maghrib,
  /// we add 1 extra day because the Islamic day starts at Maghrib.
  static HijriDateResult getTodayResult({
    int adjustment = 0,
    DateTime? maghribTime,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final extraDay =
        (maghribTime != null && !now.isBefore(maghribTime)) ? 1 : 0;
    final adjusted = now.add(Duration(days: adjustment + extraDay));
    return convertDate(adjusted);
  }

  /// Returns today's Hijri date formatted as a localized string.
  static String todayHijri({
    int adjustment = 0,
    String language = 'english',
    DateTime? maghribTime,
    DateTime? currentTime,
  }) {
    final result = getTodayResult(
      adjustment: adjustment,
      maghribTime: maghribTime,
      currentTime: currentTime,
    );
    return _format(result, language);
  }

  /// Returns the Hijri date formatted as a localized string for any date.
  static String hijriForDate(
    DateTime date, {
    int adjustment = 0,
    String language = 'english',
  }) {
    final adjusted = date.add(Duration(days: adjustment));
    return _format(convertDate(adjusted), language);
  }

  static String _format(HijriDateResult h, String language) {
    final isCoreRtl =
        language == 'urdu' || language == 'sindhi' || language == 'arabic';
    if (isCoreRtl) {
      final months = S.getHijriMonths(language);
      final monthName = (h.hMonth >= 1 && h.hMonth < months.length)
          ? months[h.hMonth]
          : _englishMonths[h.hMonth];
      return '${S.toArabicNumerals(h.hDay)} $monthName ${S.toArabicNumerals(h.hYear)}';
    }

    // For other languages
    String englishMonth = (h.hMonth >= 1 && h.hMonth < _englishMonths.length)
        ? _englishMonths[h.hMonth]
        : 'Month ${h.hMonth}';
    String translatedMonth = englishMonth;
    if (worldTranslations.containsKey(language)) {
      translatedMonth =
          worldTranslations[language]?[englishMonth] ?? englishMonth;
    }

    if (language == 'persian') {
      return '${S.toArabicNumerals(h.hDay)} $translatedMonth ${S.toArabicNumerals(h.hYear)}';
    }
    if (language == 'bengali') {
      return '${_toBengaliNum(h.hDay)} $translatedMonth ${_toBengaliNum(h.hYear)}';
    }
    if (language == 'hindi') {
      return '${_toHindiNum(h.hDay)} $translatedMonth ${_toHindiNum(h.hYear)}';
    }

    return '${h.hDay} $translatedMonth ${h.hYear}';
  }

  static String _toBengaliNum(int n) {
    const w = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const b = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var s = n.toString();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(w[i], b[i]);
    }
    return s;
  }

  static String _toHindiNum(int n) {
    const w = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const h = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    var s = n.toString();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(w[i], h[i]);
    }
    return s;
  }
}
