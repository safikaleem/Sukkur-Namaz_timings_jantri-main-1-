import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/sukkur_header.dart';
import '../data/timings_data.dart';
import '../models/namaz_timing.dart';
import '../utils/app_theme.dart';
import '../utils/hijri_converter.dart';
import '../utils/prayer_state.dart';
import '../widgets/dr_slogan_footer.dart';
import '../widgets/dr_slogan_header.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/widget_service.dart';
import '../utils/urdu_strings.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _selectedDate = DateTime.now();
  DayTiming? _today;
  PrayerStateResult? _state;
  Timer? _ticker;
  DateTime _now = DateTime.now();
  int _widgetTick = 0;

  @override
  void initState() {
    super.initState();
    _loadTimings();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) {
        final newNow = DateTime.now();
        if (newNow.second != _now.second) {
          setState(() {
            _now = newNow;
            _computeNextPrayer();
          });
          _widgetTick++;
          if (_widgetTick >= 60) {
            _widgetTick = 0;
            WidgetService.updateWidget();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _loadTimings() {
    _today = TimingsData.instance.timingFor(_selectedDate);
    _computeNextPrayer();
  }

  void _computeNextPrayer() {
    // The timings' own clock - see TimingsData.nowForTimings.
    final now = TimingsData.instance.nowForTimings();
    // If user is viewing today but date crossed midnight, refresh
    if (DateUtils.isSameDay(_selectedDate, now)) {
      _today = TimingsData.instance.timingFor(now);
    }
    if (_today == null || !DateUtils.isSameDay(_selectedDate, now)) {
      _state = null;
      return;
    }
    _state = computePrayerState(now, _today!);
  }

  static Color _accentFor(String name) {
    switch (name) {
      case 'Intiha e Sehar': return AppTheme.fajrColor;
      case 'Fajar':       return const Color(0xFF7ECFFF); // light sky-blue
      case 'Tulu Aftab': return AppTheme.sunriseColor;
      case 'Ishraq':     return const Color(0xFFFDB813);
      case 'Zawal':      return const Color(0xFFE6A817);
      case 'Zuhar':      return AppTheme.zuhrColor;
      case 'Misl Awwal': return AppTheme.zuhrColor;
      case 'Zuhr':       return AppTheme.zuhrColor;
      case 'Asr Hanafi': return AppTheme.asrColor;
      case 'Maghrib':    return AppTheme.maghribColor;
      case 'Isha':       return AppTheme.ishaColor;
      default:           return AppTheme.accent;
    }
  }

  String _getDayName(DateTime d, String language) {
    if (language == 'english') {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[d.weekday - 1];
    }
    return S.getWeekdays(language)[d.weekday - 1];
  }

  String _formatDate(DateTime d, String language) {
    if (language == 'english') {
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${months[d.month]} ${d.year}';
    }
    final months = S.getMonths(language);
    final dayStr = S.toArabicNumerals(d.day);
    final yearStr = S.toArabicNumerals(d.year);
    return '$dayStr ${months[d.month]} $yearStr';
  }

  void _navigateDay(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _loadTimings();
    });
  }

  void _resetToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _loadTimings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    // Refresh timings in case location settings changed
    _today = TimingsData.instance.timingFor(_selectedDate);
    if (_today != null && DateUtils.isSameDay(_selectedDate, _now)) {
      _state = computePrayerState(_now, _today!);
    } else {
      _state = null;
    }

    final hijriAdj = settings.hijriAdjustment;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTodaySelected = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final isSmall = MediaQuery.of(context).size.height < 680;

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Header ───────────────────────────────────────────────
            const SizedBox(
              height: 36,
              child: Center(child: SukkurHeader()),
            ),

            const SizedBox(height: 8),
            if (settings.locationMode == LocationMode.sukkur) ...[
              const Center(child: DrSloganHeader()),
              const SizedBox(height: 8),
            ],

            // ── Date selector ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.first_page_rounded,
                      color: isTodaySelected
                          ? (isDark ? Colors.white24 : Colors.black26)
                          : AppTheme.accent,
                      size: 22,
                    ),
                    onPressed: isTodaySelected ? null : _resetToToday,
                    tooltip: settings.translate('Go to Today', 'آج پر جائیں', 'اڈ تي ونجو', 'الذهاب إلى اليوم'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDayName(_selectedDate, settings.language),
                          style: TextStyle(
                            fontSize: settings.isRtl ? 19 : 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          textDirection: settings.isRtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: DateUtils.isSameDay(_selectedDate, DateTime.now())
                                    ? HijriConverter.todayHijri(
                                        adjustment: hijriAdj,
                                        language: settings.language,
                                        maghribTime: _today?.allTimings
                                            .where((p) => p.name == 'Maghrib')
                                            .map((p) => p.toDateTime(date: _now))
                                            .firstOrNull,
                                      )
                                    : HijriConverter.hijriForDate(_selectedDate, adjustment: hijriAdj, language: settings.language),
                                style: TextStyle(
                                  fontSize: settings.isRtl ? 16 : 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.accent,
                                ),
                              ),
                              TextSpan(
                                text: settings.isSindhi
                                    ? ' (هجري تاريخ مغرب کان پوءِ بدلجندي)'
                                    : settings.language == 'urdu'
                                    ? ' (ہجری تاریخ مغرب کے بعد تبدیل ہوگی)'
                                    : settings.isArabic
                                        ? ' (يتغير التاریخ الهجري بعد المغرب)'
                                        : ' (Hijri date updates after Maghrib)',
                                style: TextStyle(
                                  fontSize: settings.isRtl ? 11 : 10,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _formatDate(_selectedDate, settings.language),
                          style: TextStyle(
                            fontSize: settings.isRtl ? 14 : 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 26),
                        color: isDark ? Colors.white70 : Colors.black54,
                        onPressed: () => _navigateDay(-1),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 26),
                        color: isDark ? Colors.white70 : Colors.black54,
                        onPressed: () => _navigateDay(1),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmall ? 4 : 8),

            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark ? Colors.white12 : Colors.black12,
              indent: 16,
              endIndent: 16,
            ),

            // ── Prayer list ──────────────────────────────────────────
            Expanded(child: _buildPrayerList(context, settings.language, isDark)),

            const DrSloganFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerList(BuildContext context, String language, bool isDark) {
    if (_today == null) {
      final settings = context.read<SettingsProvider>();
      return Center(
        child: Text(
          settings.translate('No data available', 'کوئی ڈیٹا دستیاب نہیں', 'ڪوبھو ڊيٽا دستياب ناھي', 'لا توجد بيانات'),
          style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
        ),
      );
    }

    final now = _now;
    final allEntries = _today!.allTimings;
    final isTodaySelected = DateUtils.isSameDay(_selectedDate, now);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Switch to compact card style when each card would be < 46px tall
        final isCompact = constraints.maxHeight / allEntries.length < 46;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: List.generate(allEntries.length, (index) {
                final entry = allEntries[index];
                final prayerDt = entry.toDateTime(date: _selectedDate);
                final isActive = isTodaySelected &&
                    _state != null &&
                    entry.name == _state!.prayer.name;
                final isPast = isTodaySelected && prayerDt.isBefore(now) && !isActive;
                // Active prayer highlights in the theme accent; others keep their per-prayer tint.
                final accent = isActive ? AppTheme.accent : _accentFor(entry.name);
                Duration? elapsed;
                Duration? countdown;
                if (isActive && _state != null) {
                  if (_state!.isElapsed) {
                    elapsed = _state!.duration;
                  } else {
                    final ms = _state!.duration.inMilliseconds;
                    final seconds = ms <= 0 ? 0 : (ms / 1000).ceil();
                    countdown = Duration(seconds: seconds);
                  }
                }
                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 2 : 1,
                    bottom: index == allEntries.length - 1 ? 2 : 1,
                  ),
                  child: _TodayPrayerCard(
                    prayer: entry,
                    isPast: isPast,
                    isCurrent: isActive && (_state?.isElapsed ?? false),
                    isNext: isActive && !(_state?.isElapsed ?? true),
                    elapsed: elapsed,
                    countdown: countdown,
                    accent: accent,
                    isDark: isDark,
                    isCompact: isCompact,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// ── Individual prayer card ──────────────────────────────────────────────
class _TodayPrayerCard extends StatelessWidget {
  final PrayerTime prayer;
  final bool isPast;
  final bool isCurrent;
  final bool isNext;
  final Duration? elapsed;
  final Duration? countdown;
  final Color accent;
  final bool isDark;
  final bool isCompact;

  const _TodayPrayerCard({
    required this.prayer,
    required this.isPast,
    required this.isCurrent,
    required this.isNext,
    required this.elapsed,
    required this.countdown,
    required this.accent,
    required this.isDark,
    this.isCompact = false,
  });

  static IconData _iconFor(String name) {
    switch (name) {
      case 'Intiha e Sehar': return Icons.wb_twilight_rounded;
      case 'Fajar':       return Icons.star_half_rounded;
      case 'Tulu Aftab': return Icons.wb_sunny_outlined;
      case 'Ishraq':     return Icons.brightness_high_rounded;
      case 'Zawal':      return Icons.vertical_align_bottom_rounded;
      case 'Zuhar':      return Icons.wb_sunny_rounded;
      case 'Misl Awwal': return Icons.wb_sunny_rounded;
      case 'Zuhr':       return Icons.wb_sunny_rounded;
      case 'Asr Hanafi': return Icons.light_mode_outlined;
      case 'Maghrib':    return Icons.nights_stay_outlined;
      case 'Isha':       return Icons.nightlight_round;
      default:           return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final textColor = isDark ? Colors.white : Colors.black87;
    final pastColor = isDark ? Colors.white30 : Colors.black38;
    final isActive = isCurrent || isNext;

    final countdownWidget = isCurrent && elapsed != null
        ? _CountdownText(duration: elapsed!, accent: accent, prefix: '+')
        : (isNext && countdown != null
            ? _CountdownText(duration: countdown!, accent: accent, prefix: '−')
            : null);

    final dotWidget = (isCurrent || isNext)
        ? Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          )
        : null;

    final timeWidget = Text(
      '${prayer.displayTime} ${prayer.displayIsPm ? 'PM' : 'AM'}',
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontSize: isCompact ? 12 : 13,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        color: isPast ? pastColor : (isActive ? accent : textColor),
        fontFamily: 'sans-serif',
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? accent.withValues(alpha: isDark ? 0.22 : 0.12)
            : settings.displayThemeCard(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: 0.6)
              : settings.displayThemeCardBorder(isDark),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1))
              ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: isCompact ? 5 : 7, horizontal: isCompact ? 8 : 12),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: isCompact ? 26 : 32,
              height: isCompact ? 26 : 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconFor(prayer.name),
                color: isPast ? pastColor : accent,
                size: isCompact ? 13 : 16,
              ),
            ),
            SizedBox(width: isCompact ? 7 : 10),

            // Prayer name
            Expanded(
              child: Text(
                prayer.localizedName(settings.language),
                style: TextStyle(
                  fontSize: settings.isRtl ? (isCompact ? 15 : 18) : (isCompact ? 13 : 14),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isPast ? pastColor : textColor,
                  height: settings.isRtl ? 1.35 : null,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // Time + optional countdown
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: settings.isRtl
                      ? [
                          timeWidget,
                          if (dotWidget != null) ...[
                            const SizedBox(width: 4),
                            dotWidget,
                          ],
                        ]
                      : [
                          if (dotWidget != null) ...[
                            dotWidget,
                            const SizedBox(width: 4),
                          ],
                          timeWidget,
                        ],
                ),
                if (countdownWidget != null) ...[
                  const SizedBox(height: 2),
                  countdownWidget,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownText extends StatelessWidget {
  final Duration duration;
  final Color accent;
  final String prefix;
  const _CountdownText(
      {required this.duration, required this.accent, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    final str = h > 0
        ? '$prefix${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s'
        : '$prefix${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    return Text(
      str,
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontSize: 11,
        color: accent,
        fontWeight: FontWeight.w600,
        fontFamily: 'sans-serif',
      ),
    );
  }
}
