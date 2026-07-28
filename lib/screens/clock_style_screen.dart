import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/timings_data.dart';

import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class ClockStyleScreen extends StatefulWidget {
  const ClockStyleScreen({super.key});

  @override
  State<ClockStyleScreen> createState() => _ClockStyleScreenState();
}

class _ClockStyleScreenState extends State<ClockStyleScreen>
    with SingleTickerProviderStateMixin {
  DateTime _now = DateTime.now();
  Timer? _ticker;

  late UnifiedTheme _stagedTheme;
  late ClockStyle _stagedClockStyle;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _stagedTheme = settings.unifiedTheme;
    _stagedClockStyle = settings.clockStyle;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final provider = context.read<SettingsProvider>();
    provider.setUnifiedTheme(_stagedTheme);
    provider.setClockStyle(_stagedClockStyle);
    Navigator.pop(context);
  }

  static final _themes = [
    _ThemeDef(
      UnifiedTheme.defaultLight,
      'Default',
      'پہلے سے طے شدہ',
      'ڊفالٽ',
      const Color(0xFF1E88E5),
      (isDark) => BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F5F5),
      ),
      ClockStyle.classic,
    ),
    _ThemeDef(
      UnifiedTheme.skyGlow,
      'Sky Glow',
      'آسمانی چمک',
      'آسماني چمڪ',
      const Color(0xFF0284C7),
      (isDark) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFE0F2FE), const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)],
        ),
      ),
      ClockStyle.classic,
    ),
    _ThemeDef(
      UnifiedTheme.linenStone,
      'Linen Stone',
      'لنن پتھر',
      'لينن پٿر',
      const Color(0xFFD97706),
      (isDark) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1B18), const Color(0xFF12100E)]
              : [const Color(0xFFF4EFE6), const Color(0xFFE6DFD3)],
        ),
      ),
      ClockStyle.linen,
    ),
    _ThemeDef(
      UnifiedTheme.softOcean,
      'Soft Ocean',
      'نرم سمندر',
      'نرم سمنڊ',
      const Color(0xFF0EA5E9),
      (isDark) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF0B132B)]
              : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE), const Color(0xFFF0F9FF)],
        ),
      ),
      ClockStyle.ocean,
    ),
    _ThemeDef(
      UnifiedTheme.emeraldMasjid,
      'Emerald Masjid',
      'زمرد مسجد',
      'زمرد مسجد',
      const Color(0xFF0F8A5F),
      (isDark) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF091612), const Color(0xFF122C24)]
              : [const Color(0xFFF2F6F1), const Color(0xFFE4ECE2)],
        ),
      ),
      ClockStyle.sage,
    ),
  ];

  // Clock styles available for user selection
  static const _clockDefs = [
    _ClockDef(ClockStyle.classic,   'Classic',    'کلاسک',      'ڪلاسڪ'),
    _ClockDef(ClockStyle.minimal,   'Minimal',    'مختصر',      'مختصر'),
    _ClockDef(ClockStyle.sketch,    'Sketch',     'خاکہ',       'خاڪو'),
    _ClockDef(ClockStyle.dusk,      'Dusk',       'شفق',        'شفق'),
    _ClockDef(ClockStyle.linen,     'Linen',      'لنن',        'لينن'),
    _ClockDef(ClockStyle.rose,      'Rose',       'گلاب',       'گلاب'),
    _ClockDef(ClockStyle.sage,      'Sage',       'سیج',        'سيج'),
    _ClockDef(ClockStyle.carbon,    'Carbon',     'کاربن',      'ڪاربن'),
    _ClockDef(ClockStyle.ocean,     'Ocean',      'سمندر',      'سمنڊ'),
    _ClockDef(ClockStyle.ivory,     'Ivory',      'ہاتھی دانت', 'هاٿي ڏند'),
    _ClockDef(ClockStyle.mint,      'Mint',       'پودینہ',     'پوڌينو'),
  ];

  _ThemeDef _currentThemeDef() =>
      _themes.firstWhere((t) => t.theme == _stagedTheme, orElse: () => _themes[0]);

  Decoration _previewDecoration(bool isDark) {
    return _currentThemeDef().decoration(isDark);
  }

  Color _clockAccent(ClockStyle style) {
    // Return accent color matching the clock style for preview ring
    switch (style) {
      case ClockStyle.rose: return const Color(0xFFF472B6);
      case ClockStyle.sage: return const Color(0xFF059669);
      case ClockStyle.ocean: return const Color(0xFF0EA5E9);
      case ClockStyle.linen: return const Color(0xFFD97706);
      case ClockStyle.ivory: return const Color(0xFFB7860C);
      case ClockStyle.lavender: return const Color(0xFF7C3AED);
      case ClockStyle.coral: return const Color(0xFFE05A3A);
      case ClockStyle.mint: return const Color(0xFF10B981);
      case ClockStyle.peach: return const Color(0xFFF97316);
      case ClockStyle.champagne: return const Color(0xFFC49A22);
      case ClockStyle.carbon: return const Color(0xFFC49A22);
      case ClockStyle.dusk: return const Color(0xFF8B5CF6);
      default: return _themeAccent(_stagedTheme);
    }
  }

  Color _themeAccent(UnifiedTheme theme) =>
      _themes.firstWhere((t) => t.theme == theme, orElse: () => _themes[0]).accent;

  bool _isPreviewDark(bool systemDark) => systemDark;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUrdu = settings.isUrdu;
    final isSindhi = settings.isSindhi;
    final isArabic = settings.isArabic;
    final previewDec = _previewDecoration(isDark);
    final accent = _themeAccent(_stagedTheme);
    final previewIsDark = _isPreviewDark(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.drawerDark : const Color(0xFFF0F2F7),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 20, 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded,
                          size: 20, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        settings.translate('Display Customization', 'ڈسپلے کی تخصیص', 'ڊسپلي جي تخصيص', 'تخصيص العرض'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    // Top-right Apply
                    TextButton(
                      onPressed: _apply,
                      child: Text(
                        settings.translate('Apply', 'لاگو کریں', 'لاڳو ڪريو', 'تطبيق'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Live preview (phone-frame style) ───────────────
                      _LivePreviewCard(
                        previewDecoration: previewDec,
                        previewIsDark: previewIsDark,
                        stagedStyle: _stagedClockStyle,
                        stagedTheme: _stagedTheme,
                        accent: accent,
                        now: _now,
                        isDark: isDark,
                        isUrdu: isUrdu,
                        isSindhi: isSindhi,
                        isArabic: isArabic,
                      ),

                      const SizedBox(height: 28),

                      // ── Display Theme section ────────────────────────
                      _SectionHeader(
                        isSindhi ? 'ڊسپلي ٿيم' : (isUrdu ? 'ڈسپلے تھیم' : 'Display Theme'),
                        isDark,
                        accent,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _themes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final t = _themes[index];
                            final isSelected = t.theme == _stagedTheme;
                            return _ThemeCard(
                              def: t,
                              isDark: isDark,
                              isSelected: isSelected,
                              isUrdu: isUrdu,
                              isSindhi: isSindhi,
                              onTap: () {
                                setState(() => _stagedTheme = t.theme);
                                _fadeCtrl
                                  ..reset()
                                  ..forward();
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Clock Style section ─────────────────────────
                      _SectionHeader(
                        isSindhi ? 'گهڙيءَ جو انداز' : (isUrdu ? 'گھڑی کا انداز' : 'Clock Style'),
                        isDark,
                        accent,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _clockDefs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final c = _clockDefs[index];
                            final isSelected = c.style == _stagedClockStyle;
                            final clockAccent = _clockAccent(c.style);
                            return _ClockCard(
                              def: c,
                              isDark: isDark,
                              isSelected: isSelected,
                              isUrdu: isUrdu,
                              isSindhi: isSindhi,
                              accent: clockAccent,
                              now: _now,
                              onTap: () {
                                setState(() => _stagedClockStyle = c.style);
                                _fadeCtrl
                                  ..reset()
                                  ..forward();
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                    ],
                  ),
                ),
              ),

              // ── Apply button ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: accent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      settings.translate('Apply', 'لاگو کریں', 'لاڳو ڪريو', 'تطبيق'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────────────
class _ThemeDef {
  final UnifiedTheme theme;
  final String label;
  final String urduLabel;
  final String sindhiLabel;
  final Color accent;
  final Decoration Function(bool isDark) decoration;
  final ClockStyle clockStyle;

  const _ThemeDef(this.theme, this.label, this.urduLabel, this.sindhiLabel,
      this.accent, this.decoration, this.clockStyle);
}

class _ClockDef {
  final ClockStyle style;
  final String label;
  final String urduLabel;
  final String sindhiLabel;
  const _ClockDef(this.style, this.label, this.urduLabel, this.sindhiLabel);
}

// ── Clock card (mini clock preview) ─────────────────────────────────────
class _ClockCard extends StatelessWidget {
  final _ClockDef def;
  final bool isDark;
  final bool isSelected;
  final bool isUrdu;
  final bool isSindhi;
  final Color accent;
  final DateTime now;
  final VoidCallback onTap;

  const _ClockCard({
    required this.def,
    required this.isDark,
    required this.isSelected,
    required this.isUrdu,
    required this.isSindhi,
    required this.accent,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 104,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accent
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withOpacity(0.35)
                  : Colors.black.withOpacity(0.07),
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            // Miniature live clock preview
            SizedBox(
              width: 58,
              height: 58,
              child: CustomPaint(
                painter: _ClockPreviewPainter(
                  now: now,
                  style: def.style,
                  isDark: isDark,
                  accentColor: accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSindhi ? def.sindhiLabel : (isUrdu ? def.urduLabel : def.label),
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? accent
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}


class _LivePreviewCard extends StatelessWidget {
  final Decoration previewDecoration;
  final bool previewIsDark;
  final ClockStyle stagedStyle;
  final UnifiedTheme stagedTheme;
  final Color accent;
  final DateTime now;
  final bool isDark;
  final bool isUrdu;
  final bool isSindhi;
  final bool isArabic;

  const _LivePreviewCard({
    required this.previewDecoration,
    required this.previewIsDark,
    required this.stagedStyle,
    required this.stagedTheme,
    required this.accent,
    required this.now,
    required this.isDark,
    required this.isUrdu,
    required this.isSindhi,
    required this.isArabic,
  });

  /// Compute real next prayer from today's timings.
  ({String name, String localizedName, String time, Duration remaining})? _nextPrayer() {
    final today = TimingsData.instance.timingFor(now);
    if (today == null) return null;
    final lang = isSindhi ? 'sindhi' : (isUrdu ? 'urdu' : (isArabic ? 'arabic' : 'english'));
    for (final p in today.allTimings) {
      final dt = p.toDateTime();
      if (dt.isAfter(now)) {
        final rem = dt.difference(now);
        return (name: p.name, localizedName: p.localizedName(lang), time: p.time, remaining: rem);
      }
    }
    return null;
  }

  String _timeStr() {
    final h = now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $period';
  }

  String _countdownStr(Duration rem) {
    final ms = rem.inMilliseconds;
    final seconds = ms <= 0 ? 0 : (ms / 1000).ceil();
    final h = seconds ~/ 3600;
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '-$h:$m:$s' : '-$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final prayer = _nextPrayer();
    final navBg = isDark ? const Color(0xFF12122A) : Colors.white;
    final navTextColor = previewIsDark ? Colors.white38 : Colors.black38;

    // Real nav items matching the app
    final navItems = [
      (Icons.access_time_rounded,          isSindhi ? 'وقت' : (isUrdu ? 'اوقات' : 'Times'),      true),
      (Icons.today_rounded,                isSindhi ? 'اڄ' : (isUrdu ? 'آج' : 'Today'),          false),
      (Icons.view_list_rounded,            isSindhi ? 'مهاني' : (isUrdu ? 'ماہانہ' : 'Monthly'), false),
      (Icons.notifications_active_rounded, isSindhi ? 'ياددهاني' : (isUrdu ? 'اطلاعات' : 'Reminders'), false),
      (Icons.explore_rounded,              isSindhi ? 'قبلو' : (isUrdu ? 'قبلہ' : 'Qibla'),      false),
      (Icons.menu_book_rounded,            isSindhi ? 'هدايت' : (isUrdu ? 'ہدایت' : 'Instructions'),  false),
      (Icons.fingerprint_rounded,          isSindhi ? 'تسبیح' : (isUrdu ? 'تسبیح' : 'Tasbeeh'),  false),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: previewDecoration,
          child: Column(
            children: [
              // ── Mini top bar (hamburger) ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.menu_rounded, size: 20,
                        color: previewIsDark ? Colors.white54 : Colors.black38),
                    const Spacer(),
                  ],
                ),
              ),

              // ── City label (no subtitle) ─────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.push_pin_rounded, size: 14, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      isSindhi ? 'سکر' : (isUrdu ? 'سکھر' : (isArabic ? 'سكر' : 'Sukkur')),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: previewIsDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Large clock preview ──────────────────────────────────
              SizedBox(
                width: 170,
                height: 170,
                child: CustomPaint(
                  painter: _ClockPreviewPainter(
                    now: now,
                    style: stagedStyle,
                    isDark: previewIsDark,
                    accentColor: accent,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Real next prayer info ────────────────────────────────
              if (prayer != null) ...[
                Text(
                  prayer.localizedName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                Text(
                  prayer.time,
                  style: TextStyle(
                    fontSize: 13,
                    color: previewIsDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  _countdownStr(prayer.remaining),
                  style: TextStyle(
                    fontSize: 12,
                    color: previewIsDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ] else
                Text(
                  isSindhi ? 'نمازون مڪمل' : (isUrdu ? 'نمازیں مکمل' : 'Prayers done'),
                  style: TextStyle(
                    fontSize: 13,
                    color: previewIsDark ? Colors.white38 : Colors.black38,
                  ),
                ),

              const SizedBox(height: 10),

              // ── Digital time ─────────────────────────────────────────
              Text(
                _timeStr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: previewIsDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              // ── Real nav bar (matching app exactly) ──────────────────
              Container(
                decoration: BoxDecoration(
                  color: navBg,
                  border: Border(
                    top: BorderSide(
                      color: previewIsDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black12,
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: navItems.map((item) {
                    final isSelected = item.$3;
                    return Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.$1,
                            size: 20,
                            color: isSelected
                                ? accent
                                : navTextColor,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: isSelected
                                  ? accent
                                  : navTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Theme card ──────────────────────────────────────────────────────────
class _ThemeCard extends StatelessWidget {
  final _ThemeDef def;
  final bool isDark;
  final bool isSelected;
  final bool isUrdu;
  final bool isSindhi;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.def,
    required this.isDark,
    required this.isSelected,
    required this.isUrdu,
    required this.isSindhi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 104,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? def.accent
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? def.accent.withOpacity(0.35)
                  : Colors.black.withOpacity(0.07),
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // Miniature preview with gradient
            Container(
              width: 80,
              height: 52,
              decoration: (def.decoration(isDark) as BoxDecoration).copyWith(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSindhi ? def.sindhiLabel : (isUrdu ? def.urduLabel : def.label),
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? def.accent
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color accent;
  const _SectionHeader(this.text, this.isDark, this.accent);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
}

// ── Clock preview painter ──────────────────────────────────────────────
class _ClockPreviewPainter extends CustomPainter {
  final DateTime now;
  final ClockStyle style;
  final bool isDark;
  final Color accentColor;

  _ClockPreviewPainter({
    required this.now,
    required this.style,
    required this.isDark,
    required this.accentColor,
  });

  double get _sf => (now.second + now.millisecond / 1000) / 60;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    switch (style) {
      case ClockStyle.classic:   _paintClassic(canvas, center, radius);
      case ClockStyle.minimal:   _paintMinimal(canvas, center, radius);
      case ClockStyle.sketch:    _paintSketch(canvas, center, radius);
      case ClockStyle.dusk:      _paintDusk(canvas, center, radius);
      case ClockStyle.linen:     _paintLinen(canvas, center, radius);
      case ClockStyle.rose:      _paintRose(canvas, center, radius);
      case ClockStyle.sage:      _paintSage(canvas, center, radius);
      case ClockStyle.carbon:    _paintCarbon(canvas, center, radius);
      case ClockStyle.ocean:     _paintOcean(canvas, center, radius);
      case ClockStyle.ivory:     _paintIvory(canvas, center, radius);
      case ClockStyle.lavender:  _paintLavender(canvas, center, radius);
      case ClockStyle.coral:     _paintCoral(canvas, center, radius);
      case ClockStyle.mint:      _paintMint(canvas, center, radius);
      case ClockStyle.peach:     _paintPeach(canvas, center, radius);
      case ClockStyle.champagne: _paintChampagne(canvas, center, radius);
    }
  }

  void _ring(Canvas canvas, Offset c, double r, Color track, Color arc, double w) {
    canvas.drawCircle(c, r,
        Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = w);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2, _sf * 2 * math.pi, false,
      Paint()..color = arc..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round,
    );
  }

  void _numbers(Canvas canvas, Offset center, double radius, Color color, double fontSize) {
    const labels = {0: '12', 1: '1', 2: '2', 3: '3', 4: '4', 5: '5', 6: '6', 7: '7', 8: '8', 9: '9', 10: '10', 11: '11'};
    labels.forEach((i, label) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final labelR = radius - 18;
      final pos = Offset(center.dx + labelR * math.cos(angle), center.dy + labelR * math.sin(angle));
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w400)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  void _ticks60(Canvas canvas, Offset center, double ringInset, Color major, Color minor) {
    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final isMajor = i % 5 == 0;
      final outer = ringInset - 3;
      final inner = isMajor ? ringInset - 11 : ringInset - 7;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()
          ..color = isMajor ? major : minor
          ..strokeWidth = isMajor ? 1.5 : 0.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintClassic(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    canvas.drawCircle(center, radius, Paint()..color = isDark ? const Color(0xFF1C1C2E) : Colors.white);
    _ring(canvas, center, ri, accentColor.withValues(alpha: 0.15), accentColor, 2.5);
    _ticks60(canvas, center, ri,
        isDark ? Colors.white60 : Colors.black45,
        isDark ? Colors.white24 : Colors.black12);
    _numbers(canvas, center, ri, isDark ? Colors.white70 : Colors.black87, radius * 0.13);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.48, width: 4.0, color: isDark ? Colors.white : Colors.black87);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.68, width: 2.5, color: isDark ? Colors.white70 : Colors.black54);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.72, width: 1.2, color: accentColor);
    canvas.drawCircle(center, 4, Paint()..color = accentColor);
    canvas.drawCircle(center, 2, Paint()..color = isDark ? Colors.black : Colors.white);
  }

  void _paintMinimal(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = isDark ? const Color(0xFF12121A) : Colors.white);
    _ring(canvas, center, radius - 2, accentColor.withValues(alpha: 0.12), accentColor, 2.0);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final dotC = Offset(center.dx + (radius - 8) * math.cos(angle),
          center.dy + (radius - 8) * math.sin(angle));
      canvas.drawCircle(
          dotC,
          i % 3 == 0 ? 3.5 : 2.0,
          Paint()..color = isDark
              ? (i % 3 == 0 ? Colors.white54 : Colors.white24)
              : (i % 3 == 0 ? Colors.black45 : Colors.black.withValues(alpha: 0.20)));
    }
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.42, width: 3.5, color: isDark ? Colors.white : Colors.black87);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 1.8, color: accentColor);
    canvas.drawCircle(center, 3, Paint()..color = accentColor);
    canvas.drawCircle(center, 1.5, Paint()..color = isDark ? Colors.black : Colors.white);
  }

  void _paintSketch(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    canvas.drawCircle(center, radius, Paint()..color = isDark ? const Color(0xFF1A1A22) : Colors.white);
    _ring(canvas, center, ri, accentColor.withValues(alpha: 0.12), accentColor, 1.5);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final outer = ri - 5;
      final inner = isCardinal ? ri - 17 : ri - 10;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: isCardinal ? 0.70 : 0.30)
              : Colors.black.withValues(alpha: isCardinal ? 0.60 : 0.20)
          ..strokeWidth = isCardinal ? 1.8 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.44, width: 3.5, color: isDark ? Colors.white : Colors.black87);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.0, color: isDark ? Colors.white70 : Colors.black54);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.1, color: accentColor);
    canvas.drawCircle(center, 3, Paint()..color = accentColor);
    canvas.drawCircle(center, 1.5, Paint()..color = isDark ? Colors.black : Colors.white);
  }

  void _paintDusk(Canvas canvas, Offset center, double radius) {
    const bg = Color(0xFF0C1638);
    canvas.drawCircle(center, radius, Paint()..color = bg);
    _ring(canvas, center, radius - 2, Colors.white.withValues(alpha: 0.08), accentColor, 2.5);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final dotC = Offset(center.dx + (radius - 10) * math.cos(angle),
          center.dy + (radius - 10) * math.sin(angle));
      canvas.drawCircle(dotC, isCardinal ? 3.0 : 1.8,
          Paint()..color = Colors.white.withValues(alpha: isCardinal ? 0.80 : 0.40));
    }
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: Colors.white);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: Colors.white70);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: accentColor);
    canvas.drawCircle(center, 4.0, Paint()..color = accentColor);
    canvas.drawCircle(center, 2.0, Paint()..color = bg);
  }

  void _paintLinen(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF1E180C) : const Color(0xFFFFF9F0);
    const amber = Color(0xFFD97706);
    final handColor = isDark ? const Color(0xFFD4C090) : const Color(0xFF3D1F0D);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, amber.withValues(alpha: 0.15), amber, 2.5);
    _ticks60(canvas, center, ri,
        isDark ? Colors.white.withValues(alpha: 0.50) : const Color(0xFF8B6914).withValues(alpha: 0.60),
        isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFF8B6914).withValues(alpha: 0.22));
    _numbers(canvas, center, ri, handColor.withValues(alpha: 0.72), radius * 0.13);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: amber);
    canvas.drawCircle(center, 4, Paint()..color = amber);
    canvas.drawCircle(center, 2, Paint()..color = bgColor);
  }

  void _paintRose(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF1F1018) : Colors.white;
    const rose = Color(0xFFF472B6);
    final handColor = isDark ? Colors.white : Colors.black87;
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, rose.withValues(alpha: 0.15), rose, 3.0);
    _ticks60(canvas, center, ri,
        isDark ? Colors.white.withValues(alpha: 0.50) : Colors.black.withValues(alpha: 0.35),
        isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.12));
    _numbers(canvas, center, ri, isDark ? Colors.white60 : Colors.black54, radius * 0.13);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: rose);
    canvas.drawCircle(center, 4, Paint()..color = rose);
    canvas.drawCircle(center, 2, Paint()..color = bgColor);
  }

  void _paintSage(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF0A1A10) : const Color(0xFFF0FDF4);
    const sage = Color(0xFF059669);
    final handColor = isDark ? Colors.white : const Color(0xFF065F46);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, sage.withValues(alpha: 0.15), sage, 3.0);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final outer = ri - 5;
      final inner = isCardinal ? ri - 16 : ri - 10;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: isCardinal ? 0.60 : 0.28)
              : sage.withValues(alpha: isCardinal ? 0.70 : 0.35)
          ..strokeWidth = isCardinal ? 2.0 : 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
    _numbers(canvas, center, ri, isDark ? Colors.white60 : sage.withValues(alpha: 0.78), radius * 0.12);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: sage);
    canvas.drawCircle(center, 4, Paint()..color = sage);
    canvas.drawCircle(center, 2, Paint()..color = bgColor);
  }

  void _paintCarbon(Canvas canvas, Offset center, double radius) {
    const bg = Color(0xFF18181B);
    canvas.drawCircle(center, radius, Paint()..color = bg);
    _ring(canvas, center, radius - 2, Colors.white.withValues(alpha: 0.07), accentColor, 2.5);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      _drawRectMarker(canvas, center, radius - 5, angle: angle,
          markerWidth: isCardinal ? 3.0 : 2.0,
          markerLength: isCardinal ? 10.0 : 5.5,
          color: Colors.white.withValues(alpha: isCardinal ? 0.75 : 0.38));
    }
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: Colors.white);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: Colors.white70);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: accentColor);
    canvas.drawCircle(center, 4.0, Paint()..color = accentColor);
    canvas.drawCircle(center, 2.0, Paint()..color = bg);
  }

  void _paintOcean(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF071828) : const Color(0xFFF0F9FF);
    const ocean = Color(0xFF0EA5E9);
    final handColor = isDark ? Colors.white : const Color(0xFF0C4A6E);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, ocean.withValues(alpha: 0.15), ocean, 3.0);
    _ticks60(canvas, center, ri,
        isDark ? Colors.white.withValues(alpha: 0.50) : ocean.withValues(alpha: 0.60),
        isDark ? Colors.white.withValues(alpha: 0.18) : ocean.withValues(alpha: 0.20));
    _numbers(canvas, center, ri, isDark ? Colors.white60 : ocean.withValues(alpha: 0.80), radius * 0.13);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: ocean);
    canvas.drawCircle(center, 4, Paint()..color = ocean);
    canvas.drawCircle(center, 2, Paint()..color = bgColor);
  }

  void _paintIvory(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF1C1A08) : const Color(0xFFFFFEF0);
    const gold = Color(0xFFB7860C);
    final handColor = isDark ? const Color(0xFFE8D5A0) : const Color(0xFF3D2B00);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, gold.withValues(alpha: 0.18), gold, 2.5);
    _ticks60(canvas, center, ri,
        isDark ? Colors.white.withValues(alpha: 0.50) : gold.withValues(alpha: 0.55),
        isDark ? Colors.white.withValues(alpha: 0.18) : gold.withValues(alpha: 0.22));
    _numbers(canvas, center, ri, handColor.withValues(alpha: 0.78), radius * 0.13);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.72, width: 1.0, color: gold);
    canvas.drawCircle(center, 4.0, Paint()..color = gold);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  void _paintLavender(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF1A0A2E) : const Color(0xFFFAF7FF);
    const violet = Color(0xFF7C3AED);
    final handColor = isDark ? const Color(0xFFC4B5FD) : const Color(0xFF2D1B69);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, violet.withValues(alpha: 0.18), violet, 3.0);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      final outer = ri - 5;
      final inner = isCardinal ? ri - 16 : ri - 9;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(angle), center.dy + inner * math.sin(angle)),
        Offset(center.dx + outer * math.cos(angle), center.dy + outer * math.sin(angle)),
        Paint()
          ..color = isDark
              ? violet.withValues(alpha: isCardinal ? 0.80 : 0.38)
              : violet.withValues(alpha: isCardinal ? 0.55 : 0.25)
          ..strokeWidth = isCardinal ? 2.0 : 1.1
          ..strokeCap = StrokeCap.round,
      );
    }
    _numbers(canvas, center, ri,
        isDark ? const Color(0xFFC4B5FD) : violet.withValues(alpha: 0.70),
        radius * 0.13);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: violet);
    canvas.drawCircle(center, 4.0, Paint()..color = violet);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  void _paintCoral(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF1A0A08) : const Color(0xFFFFF5F2);
    const coral = Color(0xFFE05A3A);
    final handColor = isDark ? Colors.white : const Color(0xFF7C2416);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, coral.withValues(alpha: 0.18), coral, 3.0);
    _ticks60(canvas, center, ri,
        isDark ? Colors.white.withValues(alpha: 0.48) : coral.withValues(alpha: 0.45),
        isDark ? Colors.white.withValues(alpha: 0.16) : coral.withValues(alpha: 0.18));
    _numbers(canvas, center, ri, isDark ? Colors.white60 : coral.withValues(alpha: 0.65), radius * 0.13);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: coral);
    canvas.drawCircle(center, 4.0, Paint()..color = coral);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  void _paintMint(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF061A12) : const Color(0xFFF0FDF8);
    const mint = Color(0xFF10B981);
    final handColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF064E3B);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, mint.withValues(alpha: 0.18), mint, 3.0);
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * math.pi - math.pi / 2;
      final dotC = Offset(center.dx + (ri - 8) * math.cos(angle),
          center.dy + (ri - 8) * math.sin(angle));
      canvas.drawCircle(dotC, 3.5,
          Paint()..color = isDark ? mint.withValues(alpha: 0.60) : mint.withValues(alpha: 0.45));
    }
    for (int i = 0; i < 12; i++) {
      if (i % 3 == 0) continue;
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final dotC = Offset(center.dx + (ri - 8) * math.cos(angle),
          center.dy + (ri - 8) * math.sin(angle));
      canvas.drawCircle(dotC, 1.8,
          Paint()..color = isDark ? mint.withValues(alpha: 0.35) : mint.withValues(alpha: 0.28));
    }
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.44, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.65, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: mint);
    canvas.drawCircle(center, 4.0, Paint()..color = mint);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  void _paintPeach(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF1A1208) : const Color(0xFFFFF8F2);
    const peach = Color(0xFFF97316);
    final handColor = isDark ? const Color(0xFFFED7AA) : const Color(0xFF7C3010);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, peach.withValues(alpha: 0.18), peach, 3.0);
    _ticks60(canvas, center, ri,
        isDark ? Colors.white.withValues(alpha: 0.48) : peach.withValues(alpha: 0.42),
        isDark ? Colors.white.withValues(alpha: 0.16) : peach.withValues(alpha: 0.18));
    _numbers(canvas, center, ri, isDark ? Colors.white60 : peach.withValues(alpha: 0.68), radius * 0.13);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.70, width: 1.2, color: peach);
    canvas.drawCircle(center, 4.0, Paint()..color = peach);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  void _paintChampagne(Canvas canvas, Offset center, double radius) {
    final ri = radius - 2.0;
    final bgColor = isDark ? const Color(0xFF1A1608) : const Color(0xFFFEFBF0);
    const gold = Color(0xFFC49A22);
    final handColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF4A3000);
    canvas.drawCircle(center, radius, Paint()..color = bgColor);
    _ring(canvas, center, ri, gold.withValues(alpha: 0.20), gold, 2.5);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final isCardinal = i % 3 == 0;
      _drawRectMarker(canvas, center, ri - 2, angle: angle,
          markerWidth: isCardinal ? 2.8 : 1.6,
          markerLength: isCardinal ? 10.0 : 5.5,
          color: isDark
              ? Colors.white.withValues(alpha: isCardinal ? 0.65 : 0.30)
              : gold.withValues(alpha: isCardinal ? 0.72 : 0.38));
    }
    _numbers(canvas, center, ri,
        isDark ? const Color(0xFFFDE68A) : gold.withValues(alpha: 0.75),
        radius * 0.13);
    _drawHand(canvas, center,
        angle: ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2,
        length: radius * 0.46, width: 4.0, color: handColor);
    _drawHand(canvas, center,
        angle: ((now.minute + now.second / 60) / 60) * 2 * math.pi - math.pi / 2,
        length: radius * 0.66, width: 2.5, color: handColor);
    _drawHand(canvas, center,
        angle: _sf * 2 * math.pi - math.pi / 2,
        length: radius * 0.72, width: 1.0, color: gold);
    canvas.drawCircle(center, 4.0, Paint()..color = gold);
    canvas.drawCircle(center, 2.0, Paint()..color = bgColor);
  }

  void _drawHand(Canvas canvas, Offset center,
      {required double angle, required double length, required double width, required Color color}) {
    canvas.drawLine(
      center,
      Offset(center.dx + length * math.cos(angle), center.dy + length * math.sin(angle)),
      Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round,
    );
  }

  void _drawRectMarker(Canvas canvas, Offset center, double radius,
      {required double angle, required double markerWidth, required double markerLength, required Color color}) {
    final markerCenter = Offset(
      center.dx + (radius - 4 - markerLength / 2) * math.cos(angle),
      center.dy + (radius - 4 - markerLength / 2) * math.sin(angle),
    );
    canvas.save();
    canvas.translate(markerCenter.dx, markerCenter.dy);
    canvas.rotate(angle + math.pi / 2);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: markerWidth, height: markerLength),
      Paint()..color = color..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClockPreviewPainter old) =>
      old.now != now || old.style != style || old.isDark != isDark || old.accentColor != accentColor;
}
