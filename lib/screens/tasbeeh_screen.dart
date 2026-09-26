import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/dr_slogan_header.dart';

enum TasbeehThemeMode { defaultTheme, teal }

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int _count = 0;
  bool _vibrateOn = false;
  bool _soundOn = false;
  bool _showColorSelector = false;
  int? _target;
  int _completedCycles = 0;
  bool? _localIsDark;
  DarkModeOption? _lastDarkModeOption;

  @override
  void initState() {
    super.initState();
    _loadVibrateSetting();
  }

  Future<void> _loadVibrateSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _vibrateOn = prefs.getBool('tasbeeh_vibrate') ?? false;
      _soundOn = prefs.getBool('tasbeeh_sound') ?? false;
      _count = prefs.getInt('tasbeeh_count') ?? 0;
      _completedCycles = prefs.getInt('tasbeeh_cycles') ?? 0;
      final savedTarget = prefs.getInt('tasbeeh_target') ?? -1;
      _target = savedTarget > 0 ? savedTarget : null;
    });
  }

  Future<void> _saveCounterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeeh_count', _count);
    await prefs.setInt('tasbeeh_cycles', _completedCycles);
    await prefs.setInt('tasbeeh_target', _target ?? -1);
  }

  Future<void> _triggerVibrate() async {
    if (!_vibrateOn) return;
    try {
      await HapticFeedback.selectionClick();
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  void _playSound() {
    if (!_soundOn) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  Future<void> _toggleVibrate() async {
    setState(() {
      _vibrateOn = !_vibrateOn;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tasbeeh_vibrate', _vibrateOn);
    _triggerVibrate();
  }

  Future<void> _toggleSound() async {
    setState(() {
      _soundOn = !_soundOn;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tasbeeh_sound', _soundOn);
    _playSound();
  }

  void _increment() {
    _triggerVibrate();
    _playSound();
    setState(() {
      if (_target != null && _count >= _target!) {
        _count = 1;
      } else {
        if (_count < 99999) {
          _count++;
          if (_target != null && _count == _target) {
            _completedCycles++;
            _vibrateTargetReached();
          }
        } else {
          _count = 0;
        }
      }
    });
    _saveCounterState();
  }

  Future<void> _vibrateTargetReached() async {
    for (int i = 0; i < 3; i++) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  void _decrement() {
    _triggerVibrate();
    _playSound();
    setState(() {
      if (_count > 0) {
        if (_target != null && _count == _target) {
          if (_completedCycles > 0) {
            _completedCycles--;
          }
        }
        _count--;
      }
    });
    _saveCounterState();
  }

  void _reset() {
    _triggerVibrate();
    _playSound();
    setState(() {
      _count = 0;
      _completedCycles = 0;
    });
    _saveCounterState();
  }

  _TasbeehStyle _getStyle(bool isDark, TasbeehThemeMode mode) {
    if (mode == TasbeehThemeMode.teal) {
      return const _TasbeehStyle(
        screenBg: Color(0xFF09292B),
        dialBg: Color(0xFF061E20),
        ringTrack: Color(0xFF0F3B3E),
        ringFill: Color(0xFFF5AD27),
        digitActive: Color(0xFFF5AD27),
        digitInactive: Color(0x1AF5AD27),
        badgeBg: Color(0xFFF5AD27),
        badgeText: Color(0xFF061E20),
        textColor: Colors.white,
        subTextColor: Colors.white70,
        pillBg: Color(0xFF061E20),
        pillBorder: Color(0xFF0F3B3E),
      );
    }

    // Default Theme (Adapts to app light / dark mode)
    return _TasbeehStyle(
      screenBg: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF4F6F8),
      dialBg: isDark ? const Color(0xFF252632) : Colors.white,
      ringTrack: isDark ? const Color(0xFF323444) : const Color(0xFFE2E8F0),
      ringFill: AppTheme.accent,
      digitActive: isDark ? Colors.white : const Color(0xFF1A202C),
      digitInactive: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
      badgeBg: AppTheme.accent,
      badgeText: Colors.white,
      textColor: isDark ? Colors.white : const Color(0xFF1A202C),
      subTextColor: isDark ? Colors.white60 : const Color(0xFF718096),
      pillBg: isDark ? const Color(0xFF252632) : Colors.white,
      pillBorder: isDark ? const Color(0xFF323444) : const Color(0xFFE2E8F0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;
    final globalBrightness = Theme.of(context).brightness;
    final currentOption = settings.darkModeOption;

    if (_lastDarkModeOption != null && _lastDarkModeOption != currentOption) {
      _localIsDark = null;
    }
    _lastDarkModeOption = currentOption;
    final isDark = _localIsDark ?? (globalBrightness == Brightness.dark);

    final themeIdx = settings.tasbeehThemeIndex.clamp(0, 1);
    final themeMode = TasbeehThemeMode.values[themeIdx];
    final style = _getStyle(isDark, themeMode);

    final screenH = MediaQuery.of(context).size.height;
    final scale = (screenH / 760.0).clamp(0.70, 1.15);

    double progress = 0.0;
    if (_target != null && _target! > 0) {
      progress = (_count / _target!).clamp(0.0, 1.0);
    } else {
      progress = (_count % 100) / 100.0;
    }

    final digitsStr = _count.toString();

    return Scaffold(
      backgroundColor: style.screenBg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Hamburger Menu Button ──────────────────────────────────
            Positioned(
              top: 12 * scale,
              left: isRtl ? null : 16 * scale,
              right: isRtl ? 16 * scale : null,
              child: GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  width: 36 * scale,
                  height: 36 * scale,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    size: 22 * scale,
                    color: style.textColor,
                  ),
                ),
              ),
            ),

            // ── Top Header Title ──────────────────────────────────────
            Positioned(
              top: 12 * scale,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 40 * scale,
                    child: Center(
                      child: Text(
                        settings.translate('Tasbeeh', 'تسبیح', 'تسبیح', 'التسبيح'),
                        style: TextStyle(
                          fontSize: isRtl ? 26 * scale : 22 * scale,
                          fontWeight: FontWeight.bold,
                          color: style.textColor,
                          fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  DrSloganHeader(
                    textColor: style.textColor,
                    subColor: style.subTextColor,
                  ),
                ],
              ),
            ),

            // ── Center Dial Counter & Controls Layout ─────────────────
            Positioned.fill(
              top: 110 * scale,
              bottom: 84 * scale,
              child: Column(
                children: [
                  const Spacer(),

                  // Circular Progress Dial (Tappable strictly inside the circle)
                  ClipOval(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _increment,
                      child: SizedBox(
                        width: 260 * scale,
                        height: 260 * scale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Dial Background & Ring Painter
                            CustomPaint(
                              size: Size(260 * scale, 260 * scale),
                              painter: _DialProgressPainter(
                                progress: progress,
                                dialBg: style.dialBg,
                                ringTrack: style.ringTrack,
                                ringFill: style.ringFill,
                                badgeBg: style.badgeBg,
                                badgeText: style.badgeText,
                                hasTarget: _target != null,
                              ),
                            ),

                            // Center 7-Segment Digital Number Display
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: digitsStr.split('').map((char) {
                                final digitVal = int.tryParse(char) ?? 0;
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2.5 * scale),
                                  child: SevenSegmentDigit(
                                    digit: digitVal,
                                    activeColor: style.digitActive,
                                    inactiveColor: style.digitInactive,
                                    size: 68 * scale,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Target Selector Row (None | 33 | 100 | 500 | 1000)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTargetPillOption(null, settings.translate('None', 'لا محدود', 'لامحدود', 'بلا'), scale, style),
                        SizedBox(width: 8 * scale),
                        _buildTargetPillOption(33, '33', scale, style),
                        SizedBox(width: 8 * scale),
                        _buildTargetPillOption(100, '100', scale, style),
                        SizedBox(width: 8 * scale),
                        _buildTargetPillOption(500, '500', scale, style),
                        SizedBox(width: 8 * scale),
                        _buildTargetPillOption(1000, '1000', scale, style),
                      ],
                    ),
                  ),

                  SizedBox(height: 14 * scale),

                  // Stats Row: Rounds (Left) & Count (Right) below target row
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32 * scale),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rounds Stat
                        Text(
                          '${settings.translate("Rounds", "تسبیح", "تسبيح", "الدورات")}: ${_translateNum(_completedCycles, settings)}',
                          style: TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w600,
                            color: style.textColor,
                            fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                          ),
                        ),

                        // Count Stat
                        Text(
                          _target != null
                              ? '${settings.translate("Count", "شمار", "شمار", "العدد")}: ${_translateNum(_count, settings)} / ${_translateNum(_target!, settings)}'
                              : '${settings.translate("Count", "شمار", "شمار", "العدد")}: ${_translateNum(_count, settings)}',
                          style: TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.bold,
                            color: style.ringFill,
                            fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 6 * scale),
                ],
              ),
            ),

            // ── Color Theme Switcher Overlay ─────────────────────────
            if (_showColorSelector)
              Positioned(
                bottom: 85 * scale,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10 * scale),
                    decoration: BoxDecoration(
                      color: style.pillBg,
                      borderRadius: BorderRadius.circular(25 * scale),
                      border: Border.all(color: style.pillBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10 * scale,
                          offset: Offset(0, 4 * scale),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Option 0: Default App Theme
                        _buildColorCircleOption(
                          label: settings.translate('Default', 'ڈیفالٹ', 'ڊيفالٽ', 'افتراضي'),
                          color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF4F6F8),
                          borderColor: AppTheme.accent,
                          isActive: themeMode == TasbeehThemeMode.defaultTheme,
                          onTap: () {
                            settings.setTasbeehThemeIndex(0);
                            setState(() => _showColorSelector = false);
                          },
                          scale: scale,
                          style: style,
                        ),
                        SizedBox(width: 16 * scale),
                        // Option 1: Dark Teal Theme
                        _buildColorCircleOption(
                          label: settings.translate('Teal', 'ٹیل', 'ٽيل', 'أزرق داكن'),
                          color: const Color(0xFF09292B),
                          borderColor: const Color(0xFFF5AD27),
                          isActive: themeMode == TasbeehThemeMode.teal,
                          onTap: () {
                            settings.setTasbeehThemeIndex(1);
                            setState(() => _showColorSelector = false);
                          },
                          scale: scale,
                          style: style,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Bottom Control Pill Bar ───────────────────────────────
            Positioned(
              bottom: 20 * scale,
              left: 28 * scale,
              right: 28 * scale,
              child: Center(
                child: Container(
                  height: 54 * scale,
                  padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                  decoration: BoxDecoration(
                    color: style.pillBg,
                    borderRadius: BorderRadius.circular(30 * scale),
                    border: Border.all(color: style.pillBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12 * scale,
                        offset: Offset(0, 4 * scale),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reset Button
                      _buildPillActionIcon(
                        icon: Icons.refresh_rounded,
                        onTap: _reset,
                        style: style,
                        scale: scale,
                        tooltip: settings.translate('Reset', 'ری سیٹ', 'ريسيٽ', 'إعادة تعيين'),
                      ),

                      // Decrement Button
                      _buildPillActionIcon(
                        icon: Icons.remove_rounded,
                        onTap: _decrement,
                        style: style,
                        scale: scale,
                        tooltip: settings.translate('Minus', 'منہا', 'گهٽايو', 'طرح'),
                      ),

                      // Vibration Button (Highlights when selected/active!)
                      _buildPillActionIcon(
                        icon: _vibrateOn ? Icons.vibration_rounded : Icons.vibration_outlined,
                        onTap: _toggleVibrate,
                        style: style,
                        scale: scale,
                        isActive: _vibrateOn,
                        tooltip: settings.translate('Vibrate', 'وائبریشن', 'وائبريشن', 'اهتزاز'),
                      ),

                      // Sound Button (Highlights when selected/active!)
                      _buildPillActionIcon(
                        icon: _soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        onTap: _toggleSound,
                        style: style,
                        scale: scale,
                        isActive: _soundOn,
                        tooltip: settings.translate('Sound', 'صدا', 'صدا', 'الصوت'),
                      ),

                      // Theme Palette Button (Highlights when active!)
                      _buildPillActionIcon(
                        icon: Icons.palette_outlined,
                        onTap: () {
                          setState(() {
                            _showColorSelector = !_showColorSelector;
                          });
                        },
                        style: style,
                        scale: scale,
                        isActive: _showColorSelector,
                        tooltip: settings.translate('Theme', 'تھیم', 'ٿيم', 'المظهر'),
                      ),

                      // Dark/Light Mode Toggle Button (Beside Theme Palette!)
                      _buildPillActionIcon(
                        icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        onTap: () {
                          setState(() {
                            _localIsDark = !isDark;
                          });
                        },
                        style: style,
                        scale: scale,
                        isActive: _localIsDark != null,
                        tooltip: settings.translate('Dark/Light Mode', 'ڈارک/لائٹ موڈ', 'ڊارڪ/لائيٽ موڊ', 'الوضع الداكن/الفاتح'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillActionIcon({
    required IconData icon,
    required VoidCallback onTap,
    required _TasbeehStyle style,
    required double scale,
    required String tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40 * scale,
          height: 40 * scale,
          decoration: BoxDecoration(
            color: isActive ? style.ringFill : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: style.ringFill.withValues(alpha: 0.4),
                      blurRadius: 8 * scale,
                      spreadRadius: 1 * scale,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 22 * scale,
            color: isActive ? style.badgeText : style.textColor.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetPillOption(int? targetVal, String label, double scale, _TasbeehStyle style) {
    final isSelected = _target == targetVal;
    return GestureDetector(
      onTap: () {
        setState(() {
          _target = targetVal;
          _count = 0;
          _completedCycles = 0;
        });
        _saveCounterState();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 7 * scale),
        decoration: BoxDecoration(
          color: isSelected ? style.ringFill : style.ringTrack.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(
            color: isSelected ? style.ringFill : style.ringTrack,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5 * scale,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? style.badgeText : style.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildColorCircleOption({
    required String label,
    required Color color,
    required Color borderColor,
    required bool isActive,
    required VoidCallback onTap,
    required double scale,
    required _TasbeehStyle style,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32 * scale,
            height: 32 * scale,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? borderColor : Colors.grey,
                width: isActive ? 2.5 * scale : 1.0,
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            label,
            style: TextStyle(
              fontSize: 10 * scale,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: style.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _translateNum(int num, SettingsProvider settings) {
    final str = num.toString();
    if (!settings.isRtl) return str;
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const urduDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = str;
    for (int i = 0; i < englishDigits.length; i++) {
      result = result.replaceAll(englishDigits[i], urduDigits[i]);
    }
    return result;
  }
}

/// Style data holder for Tasbeeh theme
class _TasbeehStyle {
  final Color screenBg;
  final Color dialBg;
  final Color ringTrack;
  final Color ringFill;
  final Color digitActive;
  final Color digitInactive;
  final Color badgeBg;
  final Color badgeText;
  final Color textColor;
  final Color subTextColor;
  final Color pillBg;
  final Color pillBorder;

  const _TasbeehStyle({
    required this.screenBg,
    required this.dialBg,
    required this.ringTrack,
    required this.ringFill,
    required this.digitActive,
    required this.digitInactive,
    required this.badgeBg,
    required this.badgeText,
    required this.textColor,
    required this.subTextColor,
    required this.pillBg,
    required this.pillBorder,
  });
}

/// Custom painter to draw circular dial background, progress ring, and percentage pill badge
class _DialProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color dialBg;
  final Color ringTrack;
  final Color ringFill;
  final Color badgeBg;
  final Color badgeText;
  final bool hasTarget;

  _DialProgressPainter({
    required this.progress,
    required this.dialBg,
    required this.ringTrack,
    required this.ringFill,
    required this.badgeBg,
    required this.badgeText,
    required this.hasTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20.0;

    // Fill Dial Background
    final bgPaint = Paint()
      ..color = dialBg
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Track Ring
    final trackPaint = Paint()
      ..color = ringTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, trackPaint);

    // Fill Progress Arc
    const startAngle = -math.pi / 2;
    final sweepAngle = progress * 2 * math.pi;

    if (sweepAngle > 0) {
      final fillPaint = Paint()
        ..color = ringFill
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.5;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        fillPaint,
      );
    }

    // Percentage Pill Badge running along the progress tip
    final tipAngle = startAngle + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final badgeCenter = Offset(tipX, tipY);
    final badgePaint = Paint()
      ..color = badgeBg
      ..style = PaintingStyle.fill;

    canvas.drawCircle(badgeCenter, 13.5, badgePaint);

    // Text inside Badge (0%, 6%, 51%, 100%)
    final pctText = '${(progress * 100).toInt()}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: pctText,
        style: TextStyle(
          color: badgeText,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.dialBg != dialBg ||
        oldDelegate.ringFill != ringFill ||
        oldDelegate.hasTarget != hasTarget;
  }
}

/// 7-Segment Digital LCD Display Digit Widget
class SevenSegmentDigit extends StatelessWidget {
  final int digit;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const SevenSegmentDigit({
    super.key,
    required this.digit,
    required this.activeColor,
    required this.inactiveColor,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.52, size),
      painter: _SevenSegmentPainter(
        digit: digit,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      ),
    );
  }
}

class _SevenSegmentPainter extends CustomPainter {
  final int digit;
  final Color activeColor;
  final Color inactiveColor;

  _SevenSegmentPainter({
    required this.digit,
    required this.activeColor,
    required this.inactiveColor,
  });

  // 7 Segments boolean map for digits 0..9
  static const Map<int, List<bool>> _segments = {
    0: [true, true, true, true, true, true, false],
    1: [false, true, true, false, false, false, false],
    2: [true, true, false, true, true, false, true],
    3: [true, true, true, true, false, false, true],
    4: [false, true, true, false, false, true, true],
    5: [true, false, true, true, false, true, true],
    6: [true, false, true, true, true, true, true],
    7: [true, true, true, false, false, false, false],
    8: [true, true, true, true, true, true, true],
    9: [true, true, true, true, false, true, true],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final active = _segments[digit] ?? _segments[0]!;
    final w = size.width;
    final h = size.height;
    final stroke = math.max(3.5, w * 0.16);
    final pad = stroke * 0.6;

    Paint segPaint(bool isOn) => Paint()
      ..color = isOn ? activeColor : inactiveColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Segment a (top horizontal)
    _drawHorizontalSegment(canvas, Offset(pad, pad), w - 2 * pad, stroke, segPaint(active[0]));
    // Segment b (top-right vertical)
    _drawVerticalSegment(canvas, Offset(w - pad, pad), h / 2 - pad, stroke, segPaint(active[1]));
    // Segment c (bottom-right vertical)
    _drawVerticalSegment(canvas, Offset(w - pad, h / 2), h / 2 - pad, stroke, segPaint(active[2]));
    // Segment d (bottom horizontal)
    _drawHorizontalSegment(canvas, Offset(pad, h - pad), w - 2 * pad, stroke, segPaint(active[3]));
    // Segment e (bottom-left vertical)
    _drawVerticalSegment(canvas, Offset(pad, h / 2), h / 2 - pad, stroke, segPaint(active[4]));
    // Segment f (top-left vertical)
    _drawVerticalSegment(canvas, Offset(pad, pad), h / 2 - pad, stroke, segPaint(active[5]));
    // Segment g (middle horizontal)
    _drawHorizontalSegment(canvas, Offset(pad, h / 2), w - 2 * pad, stroke, segPaint(active[6]));
  }

  void _drawHorizontalSegment(Canvas canvas, Offset start, double length, double thickness, Paint paint) {
    final path = Path()
      ..moveTo(start.dx + thickness / 2, start.dy)
      ..lineTo(start.dx + length - thickness / 2, start.dy)
      ..lineTo(start.dx + length, start.dy + thickness / 2)
      ..lineTo(start.dx + length - thickness / 2, start.dy + thickness)
      ..lineTo(start.dx + thickness / 2, start.dy + thickness)
      ..lineTo(start.dx, start.dy + thickness / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawVerticalSegment(Canvas canvas, Offset start, double length, double thickness, Paint paint) {
    final path = Path()
      ..moveTo(start.dx, start.dy + thickness / 2)
      ..lineTo(start.dx + thickness / 2, start.dy)
      ..lineTo(start.dx + thickness, start.dy + thickness / 2)
      ..lineTo(start.dx + thickness, start.dy + length - thickness / 2)
      ..lineTo(start.dx + thickness / 2, start.dy + length)
      ..lineTo(start.dx, start.dy + length - thickness / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SevenSegmentPainter oldDelegate) {
    return oldDelegate.digit != digit ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
