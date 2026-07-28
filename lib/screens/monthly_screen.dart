import 'package:flutter/material.dart';
import '../data/timings_data.dart';
import '../models/namaz_timing.dart';
import '../utils/app_theme.dart';
import '../widgets/dr_slogan_footer.dart';
import '../widgets/dr_slogan_header.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class MonthlyScreen extends StatefulWidget {
  const MonthlyScreen({super.key});

  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends State<MonthlyScreen> {
  int _selectedMonth = DateTime.now().month;
  MonthData? _monthData;

  static const _colHeaders = [
    'Date', 'Intiha\ne\nSehar', 'Fajar', 'Tulu\nAftab', 'Ishraq', 'Zawal',
    'Zuhar', 'Misl\nAwwal', 'Asr\nHanafi', 'Maghrib', 'Isha',
  ];
  static const _colHeadersUrdu = [
    'تاریخ', 'انتہائے\nسحر', 'فجر', 'طلوع\nآفتاب', 'اشراق', 'زوال',
    'ظہر', 'مثل\nاول', 'عصر\nحنفی', 'مغرب', 'عشاء',
  ];
  static const _colHeadersSindhi = [
    'تاريخ', 'انتهاءِ\nسحر', 'فجر', 'سج\nاڀرڻ', 'اشراق', 'زوال',
    'ظھر', 'مثل\nاول', 'عصر', 'مغرب', 'عشاء',
  ];
  static const _colHeadersArabic = [
    'تاريخ', 'نهاية\nالسحر', 'الفجر', 'الشروق', 'الإشراق', 'الزوال',
    'الظهر', 'المثل\nالأول', 'العصر', 'المغرب', 'العشاء',
  ];

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthNamesUrdu = [
    '', 'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
    'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر',
  ];
  static const _monthNamesSindhi = [
    '', 'جنوري', 'فيبروري', 'مارچ', 'اپريل', 'مئي', 'جون',
    'جولاءِ', 'آگسٽ', 'سيٽمبر', 'آڪٽوبر', 'نومبر', 'ڊسمبر',
  ];
  static const _monthNamesArabic = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  void _loadMonth() {
    setState(() => _monthData = TimingsData.instance.month(_selectedMonth));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    
    // Refresh timings in case location settings changed
    _monthData = TimingsData.instance.month(_selectedMonth);

    final isRtl = settings.isRtl;
    final isSindhi = settings.isSindhi;
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 360.0).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar (height=36 matches the main.dart hamburger overlay) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 42),
                    Text(
                      settings.translate('Monthly Schedule', 'ماہانہ شیڈیول', 'مهينووار شيڊيول', 'الجدول الشهري'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    _monthDropdown(context, settings, isDark),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            if (settings.locationMode == LocationMode.sukkur)
              const Center(
                child: DrSloganHeader(),
              ),

            // ── Month label strip ─────────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppTheme.accent.withValues(alpha: 0.18),
                          AppTheme.accent.withValues(alpha: 0.08),
                        ]
                      : [
                          AppTheme.accent.withValues(alpha: 0.10),
                          AppTheme.accent.withValues(alpha: 0.04),
                        ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppTheme.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${isSindhi ? _monthNamesSindhi[_selectedMonth] : (settings.isArabic ? _monthNamesArabic[_selectedMonth] : (isRtl ? _monthNamesUrdu[_selectedMonth] : _monthNames[_selectedMonth]))}  ${today.year}',
                    style: TextStyle(
                      fontSize: isRtl ? 18 : 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                ],
              ),
            ),

            // ── Table ─────────────────────────────────────────────────
            Expanded(
              child: _monthData == null
                  ? Center(
                      child: Text(
                        settings.translate('No data available', 'کوئی ڈیٹا دستیاب نہیں', 'ڪوبھ ڈيٽا دستياب ناھي', 'لا توجد بيانات'),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                        child: _buildTable(settings, isDark, today, scale),
                      ),
            ),

            const DrSloganFooter(),
            if (settings.locationMode != LocationMode.sukkur)
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(SettingsProvider settings, bool isDark, DateTime today, double scale) {
    final days = _monthData!.days;
    final isRtl = settings.isRtl;
    final isSindhi = settings.isSindhi;
    final headers = isSindhi ? _colHeadersSindhi
        : (settings.isArabic ? _colHeadersArabic
        : (settings.language == 'urdu' ? _colHeadersUrdu : _colHeaders));

    if (isRtl) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32 * scale,
                child: _buildHeaderCell(
                  columnIndex: 0,
                  title: headers[0],
                  isDate: true,
                  isDark: isDark,
                  isRtl: isRtl,
                  scale: scale,
                  fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                ),
              ),
              for (int i = 0; i < 10; i++)
                Expanded(
                  child: _buildHeaderCell(
                    columnIndex: i + 1,
                    title: headers[i + 1],
                    isDate: false,
                    isDark: isDark,
                    isRtl: isRtl,
                    scale: scale,
                    fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                  ),
                ),
            ],
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32 * scale,
                      child: _buildDataColumn(
                        columnIndex: 0,
                        isDate: true,
                        days: days,
                        isDark: isDark,
                        isRtl: isRtl,
                        today: today,
                        scale: scale,
                      ),
                    ),
                    for (int i = 0; i < 10; i++)
                      Expanded(
                        child: _buildDataColumn(
                          columnIndex: i + 1,
                          isDate: false,
                          days: days,
                          isDark: isDark,
                          isRtl: isRtl,
                          today: today,
                          scale: scale,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final dateWidth = 26.0 * scale;

      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: dateWidth,
                child: _buildHeaderCell(
                  columnIndex: 0,
                  title: headers[0],
                  isDate: true,
                  isDark: isDark,
                  isRtl: isRtl,
                  scale: scale,
                  fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                ),
              ),
              for (int i = 0; i < 10; i++)
                Expanded(
                  child: _buildHeaderCell(
                    columnIndex: i + 1,
                    title: headers[i + 1],
                    isDate: false,
                    isDark: isDark,
                    isRtl: isRtl,
                    scale: scale,
                    fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                  ),
                ),
            ],
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: dateWidth,
                      child: _buildDataColumn(
                        columnIndex: 0,
                        isDate: true,
                        days: days,
                        isDark: isDark,
                        isRtl: isRtl,
                        today: today,
                        scale: scale,
                      ),
                    ),
                    for (int i = 0; i < 10; i++)
                      Expanded(
                        child: _buildDataColumn(
                          columnIndex: i + 1,
                          isDate: false,
                          days: days,
                          isDark: isDark,
                          isRtl: isRtl,
                          today: today,
                          scale: scale,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildHeaderCell({
    required int columnIndex,
    required String title,
    required bool isDate,
    required bool isDark,
    required bool isRtl,
    required double scale,
    String? fontFamily,
  }) {
    final headerGradient = _getColumnGradient(columnIndex, isDark);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 4.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 5,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: isRtl ? 42 * scale : 48 * scale,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: headerGradient,
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 1 * scale, vertical: 2 * scale),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: isRtl
                  ? (isDate ? 11.5 : 10.0) * scale
                  : (isDate ? 11.0 : 9.5) * scale,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: isRtl ? 1.4 : 1.15,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildDataColumn({
    required int columnIndex,
    required bool isDate,
    required List<DayTiming> days,
    required bool isDark,
    required bool isRtl,
    required DateTime today,
    required double scale,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 4.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 5,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int rowIndex = 0; rowIndex < days.length; rowIndex++)
            _buildDataCell(
              day: days[rowIndex],
              rowIndex: rowIndex,
              isDate: isDate,
              columnIndex: columnIndex,
              isDark: isDark,
              isRtl: isRtl,
              today: today,
              scale: scale,
            ),
        ],
      ),
    );
  }

  Widget _buildDataCell({
    required DayTiming day,
    required int rowIndex,
    required bool isDate,
    required int columnIndex,
    required bool isDark,
    required bool isRtl,
    required DateTime today,
    required double scale,
  }) {
    final isToday = _selectedMonth == today.month && day.day == today.day;
    
    Color cellBg;
    if (isToday) {
      cellBg = AppTheme.accent.withValues(alpha: isDark ? 0.25 : 0.12);
    } else {
      cellBg = rowIndex.isEven
          ? (isDark ? const Color(0xFF1E1E2E) : Colors.white)
          : (isDark ? const Color(0xFF2A2A3C) : AppTheme.accent.withValues(alpha: 0.05));
    }

    Color textColor;
    if (isToday) {
      textColor = AppTheme.accent;
    } else {
      textColor = isDark ? Colors.white70 : const Color(0xFF2D2D3A);
    }

    final fontWeight = isToday ? FontWeight.bold : FontWeight.normal;

    String cellText;
    if (isDate) {
      cellText = day.day.toString().padLeft(2, '0');
    } else {
      final times = [
        day.subahSadiq,
        day.fajar,
        day.tuluAftab,
        day.ishraq,
        day.zawalAftab,
        day.zuhar,
        day.mislEAwwal,
        day.asrHanafi,
        day.maghrib,
        day.isha,
      ];
      cellText = times[columnIndex - 1];
    }

    return Container(
      height: isRtl ? 36 * scale : 34 * scale,
      width: double.infinity,
      color: cellBg,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 1 * scale),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          cellText,
          style: TextStyle(
            fontSize: isRtl
                ? (isDate ? 11.0 : 8.5) * scale
                : (isDate ? 11.0 : 9.0) * scale,
            color: textColor,
            fontWeight: fontWeight,
            fontFamily: 'sans-serif',
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Gradient _getColumnGradient(int index, bool isDark) {
    final baseColor = AppTheme.accent;
    return LinearGradient(
      colors: [baseColor, baseColor.withValues(alpha: 0.85)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  Widget _monthDropdown(BuildContext context, SettingsProvider settings, bool isDark) {
    return SizedBox(
      width: settings.isRtl ? 110 : 120,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMonth,
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: settings.isRtl ? 16 : 14,
            fontFamily: AppTheme.getFontForLanguage(context, settings.language),
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          items: List.generate(12, (i) => i + 1).map((m) {
            return DropdownMenuItem<int>(
              value: m,
              child: Text(
                settings.isSindhi ? _monthNamesSindhi[m] : (settings.isRtl ? _monthNamesUrdu[m] : _monthNames[m]),
                style: TextStyle(
                  fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              _selectedMonth = val;
              _loadMonth();
            }
          },
        ),
      ),
    );
  }
}
