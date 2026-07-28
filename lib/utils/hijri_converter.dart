import 'package:hijri/hijri_calendar.dart';
import '../l10n/world_translations.dart';
import 'urdu_strings.dart';

class HijriConverter {
  static const _englishMonths = [
    '', 'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban",
    'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah',
  ];

  /// Returns today's Hijri date string.
  /// If [maghribTime] is provided and current time >= Maghrib,
  /// we add 1 extra day because in Islam the new day starts at Maghrib.
  static String todayHijri({
    int adjustment = 0,
    String language = 'english',
    DateTime? maghribTime,
  }) {
    final now = DateTime.now();
    // After Maghrib the Islamic day has already moved to the next day
    final extraDay = (maghribTime != null && !now.isBefore(maghribTime)) ? 1 : 0;
    final adjusted = now.add(Duration(days: adjustment + extraDay));
    return _format(HijriCalendar.fromDate(adjusted), language);
  }

  static String hijriForDate(DateTime date, {int adjustment = 0, String language = 'english'}) {
    final adjusted = date.add(Duration(days: adjustment));
    return _format(HijriCalendar.fromDate(adjusted), language);
  }

  static String _format(HijriCalendar h, String language) {
    final isCoreRtl = language == 'urdu' || language == 'sindhi' || language == 'arabic';
    if (isCoreRtl) {
      final months = S.getHijriMonths(language);
      return '${S.toArabicNumerals(h.hDay)} ${months[h.hMonth]} ${S.toArabicNumerals(h.hYear)}';
    }
    
    // For other languages
    String englishMonth = _englishMonths[h.hMonth];
    String translatedMonth = englishMonth;
    if (worldTranslations.containsKey(language)) {
      translatedMonth = worldTranslations[language]?[englishMonth] ?? englishMonth;
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
    const w = ['0','1','2','3','4','5','6','7','8','9'];
    const b = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    var s = n.toString();
    for (int i = 0; i < 10; i++) s = s.replaceAll(w[i], b[i]);
    return s;
  }

  static String _toHindiNum(int n) {
    const w = ['0','1','2','3','4','5','6','7','8','9'];
    const h = ['०','१','२','३','४','५','६','७','८','९'];
    var s = n.toString();
    for (int i = 0; i < 10; i++) s = s.replaceAll(w[i], h[i]);
    return s;
  }
}
