import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../utils/hijri_converter.dart';
import '../utils/urdu_strings.dart';

/// Renders the 4-line date header on the Clock screen:
/// 1. Day of the week (Large & Bold, black/white, NOT theme color)
/// 2. Hijri date (Day, Month, Year - advances after Maghrib)
/// 3. Dull notice: (Hijri date updates after Maghrib) in all 10 languages
/// 4. Gregorian date (Day, Month, Year) in all 10 languages
class ClockDateDisplay extends StatelessWidget {
  final DateTime now;
  final DateTime? maghribTime;
  final SettingsProvider settings;
  final bool isDark;
  final bool isCompact;

  const ClockDateDisplay({
    super.key,
    required this.now,
    required this.maghribTime,
    required this.settings,
    required this.isDark,
    this.isCompact = false,
  });

  static String getWeekdayName(DateTime date, String language) {
    final weekdays = S.getWeekdays(language);
    final index = (date.weekday - 1) % 7;
    if (index >= 0 && index < weekdays.length) {
      return weekdays[index];
    }
    return S.weekdaysEnglish[index];
  }

  static String getMaghribNotice(String language) {
    switch (language) {
      case 'urdu':
        return '(ہجری تاریخ مغرب کے بعد تبدیل ہوگی)';
      case 'sindhi':
        return '(هجري تاريخ مغرب کان پوءِ بدلجندي)';
      case 'arabic':
        return '(يتغير التاریخ الهجري بعد المغرب)';
      case 'persian':
        return '(تاریخ هجری پس از مغرب به‌روزرسانی می‌شود)';
      case 'bengali':
        return '(মাগরিবের পর হিজরি তারিখ আপডেট হয়)';
      case 'hindi':
        return '(हिजरी तिथि मगरिब के बाद अपडेट होती है)';
      case 'indonesian':
        return '(Tanggal Hijriah diperbarui setelah Maghrib)';
      case 'turkish':
        return '(Hicri tarih Akşam namazından sonra güncellenir)';
      case 'french':
        return '(La date hégirienne est mise à jour après le Maghreb)';
      case 'english':
      default:
        return '(Hijri date updates after Maghrib)';
    }
  }

  static String formatGregorianDate(DateTime date, String language) {
    final months = S.getMonths(language);
    final monthName = (date.month >= 1 && date.month < months.length)
        ? months[date.month]
        : S.monthsEnglish[date.month];
    final d = date.day;
    final y = date.year;

    if (language == 'urdu' ||
        language == 'sindhi' ||
        language == 'arabic' ||
        language == 'persian') {
      return '${S.toArabicNumerals(d)} $monthName ${S.toArabicNumerals(y)}';
    }
    if (language == 'bengali') {
      return '${_toBengaliNum(d)} $monthName ${_toBengaliNum(y)}';
    }
    if (language == 'hindi') {
      return '${_toHindiNum(d)} $monthName ${_toHindiNum(y)}';
    }
    return '$d $monthName $y';
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

  @override
  Widget build(BuildContext context) {
    final lang = settings.language;
    final isRtl = settings.isRtl;
    final dayName = getWeekdayName(now, lang);
    final hijriDate = HijriConverter.todayHijri(
      adjustment: settings.hijriAdjustment,
      language: lang,
      maghribTime: maghribTime,
      currentTime: now,
    );
    final notice = getMaghribNotice(lang);
    final gregorianDate = formatGregorianDate(now, lang);

    final font = AppTheme.getFontForLanguage(context, lang);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final hijriColor = AppTheme.accent;
    final dullNoticeColor = isDark ? Colors.white38 : Colors.black38;
    final gregorianColor = isDark ? Colors.white70 : Colors.black54;

    if (isCompact) {
      // Top right header placement (Sukkur mode - clean 3-line layout)
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isRtl ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontFamily: font,
              fontSize: isRtl ? 14.5 : 13.0,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
              height: 1.2,
            ),
            textAlign: isRtl ? TextAlign.left : TextAlign.right,
          ),
          const SizedBox(height: 2),
          Text(
            hijriDate,
            style: TextStyle(
              fontFamily: font,
              fontSize: isRtl ? 10.5 : 9.5,
              fontWeight: FontWeight.w600,
              color: hijriColor,
              letterSpacing: isRtl ? null : -0.2,
              height: 1.2,
            ),
            textAlign: isRtl ? TextAlign.left : TextAlign.right,
          ),
          const SizedBox(height: 2),
          Text(
            gregorianDate,
            style: TextStyle(
              fontFamily: font,
              fontSize: isRtl ? 10.5 : 9.0,
              fontWeight: FontWeight.w500,
              color: gregorianColor,
              height: 1.2,
            ),
            textAlign: isRtl ? TextAlign.left : TextAlign.right,
          ),
        ],
      );
    }

    // Prominent centered placement above clock (Other cities mode)
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          dayName,
          style: TextStyle(
            fontFamily: font,
            fontSize: isRtl ? 26 : 24,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          hijriDate,
          style: TextStyle(
            fontFamily: font,
            fontSize: isRtl ? 15.0 : 13.5,
            fontWeight: FontWeight.w600,
            color: hijriColor,
            letterSpacing: 0.2,
            height: 1.25,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          notice,
          style: TextStyle(
            fontFamily: font,
            fontSize: isRtl ? 11.5 : 10.0,
            fontWeight: FontWeight.w400,
            color: dullNoticeColor,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          gregorianDate,
          style: TextStyle(
            fontFamily: font,
            fontSize: isRtl ? 14.0 : 12.5,
            fontWeight: FontWeight.w500,
            color: gregorianColor,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
