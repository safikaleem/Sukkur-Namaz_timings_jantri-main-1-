import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/dr_slogan_header.dart';

enum TasbeehThemeIndex { gray, slate, brown }

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int _count = 0;
  bool _vibrateOn = false;
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
      // Restore the counter so it survives an app restart (a physical tasbeeh
      // keeps its count). Within a session it is unchanged.
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

  Future<void> _toggleVibrate() async {
    setState(() {
      _vibrateOn = !_vibrateOn;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tasbeeh_vibrate', _vibrateOn);
    if (_vibrateOn) {
      HapticFeedback.vibrate();
    }
  }

  void _increment() {
    setState(() {
      if (_target != null && _count >= _target!) {
        _count = 1;
        if (_vibrateOn) {
          HapticFeedback.vibrate();
        }
      } else {
        if (_vibrateOn) {
          HapticFeedback.vibrate();
        }
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
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  void _decrement() {
    if (_vibrateOn) {
      HapticFeedback.vibrate();
    }
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
    if (_vibrateOn) {
      HapticFeedback.vibrate();
    }
    setState(() {
      _count = 0;
      _completedCycles = 0;
    });
    _saveCounterState();
  }

  // Define styling based on selected color scheme & dark mode
  _ThemeColors _getColors(bool isDark, TasbeehThemeIndex selectedTheme) {
    switch (selectedTheme) {
      case TasbeehThemeIndex.gray:
        return _ThemeColors(
          screenBg: isDark ? const Color(0xFF303030) : const Color(0xFFFFFFFF),
          deviceBody: isDark ? const Color(0xFF212121) : const Color(0xFF757575),
          deviceBorder: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
          lcdBg: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFECEFF1),
          digitColor: isDark ? const Color(0xFFECEFF1) : const Color(0xFF212121),
          smallBtn: isDark ? const Color(0xFF303030) : const Color(0xFF9E9E9E),
          largeBtn: isDark ? const Color(0xFF424242) : const Color(0xFFBDBDBD),
          deviceShadow: Colors.black.withValues(alpha: 0.15),
          headerTextColor: isDark ? Colors.white : const Color(0xFF212121),
          headerSubColor: isDark ? Colors.white60 : const Color(0xFF555555),
        );
      case TasbeehThemeIndex.slate:
        return _ThemeColors(
          screenBg: isDark ? const Color(0xFF182229) : const Color(0xFF3D4E56),
          deviceBody: isDark ? const Color(0xFF0E171E) : const Color(0xFF1C2B36),
          deviceBorder: isDark ? const Color(0xFF37474F) : const Color(0xFF78909C),
          lcdBg: isDark ? const Color(0xFF1E3624) : const Color(0xFF9BC1A3),
          digitColor: isDark ? const Color(0xFF81C784) : const Color(0xFF1D2C20),
          smallBtn: isDark ? const Color(0xFF212F3D) : const Color(0xFF455A64),
          largeBtn: isDark ? const Color(0xFF37474F) : const Color(0xFF607D8B),
          deviceShadow: Colors.black.withValues(alpha: 0.25),
          headerTextColor: Colors.white,
          headerSubColor: Colors.white.withValues(alpha: 0.7),
        );
      case TasbeehThemeIndex.brown:
        return _ThemeColors(
          screenBg: isDark ? const Color(0xFF3E2723) : const Color(0xFF75513D),
          deviceBody: isDark ? const Color(0xFF27150E) : const Color(0xFF3D251A),
          deviceBorder: isDark ? const Color(0xFF5D4037) : const Color(0xFFA68573),
          lcdBg: isDark ? const Color(0xFF1D1B1A) : const Color(0xFFDFDAD4),
          digitColor: isDark ? const Color(0xFFDFDAD4) : const Color(0xFF1D1B1A),
          smallBtn: isDark ? const Color(0xFF4E342E) : const Color(0xFF826658),
          largeBtn: isDark ? const Color(0xFF8D6E63) : const Color(0xFFD6C8BB),
          deviceShadow: Colors.black.withValues(alpha: 0.2),
          headerTextColor: Colors.white,
          headerSubColor: Colors.white.withValues(alpha: 0.7),
        );
    }
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
    
    // Read selected theme from global settings
    final selectedTheme =
        TasbeehThemeIndex.values[settings.tasbeehThemeIndex.clamp(0, 2)];
    final theme = _getColors(isDark, selectedTheme);
    final countStr = _count.toString().padLeft(5, '0');

    // Dynamic height scaling factor to fit all screens
    final screenH = MediaQuery.of(context).size.height;
    final scale = (screenH / 760.0).clamp(0.70, 1.15);

    return Scaffold(
      backgroundColor: theme.screenBg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Hamburger Menu Button ──────────────────────────────────
            Positioned(
              top: 12,
              left: isRtl ? null : 16 * scale,
              right: isRtl ? 16 * scale : null,
              child: GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: Container(
                  width: 36 * scale,
                  height: 36 * scale,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    size: 22 * scale,
                    color: theme.headerTextColor == Colors.white ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            // ── Top Title bar ──────────────────────────────────────────
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    child: SizedBox(
                      height: 55 * scale,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 60),
                          Text(
                            settings.translate('Tasbeeh', 'تسبیح', 'تسبیح', 'التسبيح'),
                            style: TextStyle(
                              fontSize: isRtl ? 30 * scale : 24 * scale,
                              fontWeight: FontWeight.bold,
                              height: isRtl ? 1.6 : null,
                              color: theme.headerTextColor,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                              shadows: theme.headerTextColor == Colors.white
                                  ? [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        offset: Offset(0, 2 * scale),
                                        blurRadius: 4 * scale,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: DrSloganHeader(
                      textColor: theme.headerTextColor,
                      subColor: theme.headerSubColor,
                    ),
                  ),
                ],
              ),
            ),

            // ── Center Counter Device ───────────────────────────────────
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100.0 * scale, bottom: 80.0 * scale),
                child: Container(
                  width: 250 * scale,
                  height: 310 * scale,
                  decoration: BoxDecoration(
                    color: theme.deviceBody,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(100 * scale),
                      topRight: Radius.circular(100 * scale),
                      bottomLeft: Radius.circular(130 * scale),
                      bottomRight: Radius.circular(130 * scale),
                    ),
                    border: Border.all(color: theme.deviceBorder, width: 4.5 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: theme.deviceShadow,
                        blurRadius: 15 * scale,
                        spreadRadius: 1 * scale,
                        offset: Offset(0, 8 * scale),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // LCD Screen Display
                      Container(
                        width: 170 * scale,
                        height: 58 * scale,
                        margin: EdgeInsets.only(top: 18 * scale, bottom: 4 * scale),
                        decoration: BoxDecoration(
                          color: theme.lcdBg,
                          borderRadius: BorderRadius.circular(8 * scale),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                            width: 1.5 * scale,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 3 * scale,
                              offset: Offset(0, 1.5 * scale),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: _target != null ? Alignment.centerRight : Alignment.center,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: _target != null ? 10 * scale : 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  textDirection: TextDirection.ltr,
                                  children: List.generate(5, (index) {
                                    final digit = countStr[index];
                                    // Check if this digit is a leading zero
                                    final activeDigitIndex = 5 - _count.toString().length;
                                    final isLeadingZero = index < activeDigitIndex;

                                    return Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 1.5 * scale),
                                      child: Text(
                                        digit,
                                        style: TextStyle(
                                          fontSize: 34 * scale,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                          color: isLeadingZero
                                              ? theme.digitColor.withValues(alpha: 0.12)
                                              : theme.digitColor,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            if (_target != null)
                              Positioned(
                                left: 10 * scale,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        settings.translate('Round', 'تسبیح', 'تسبیح', 'دورة'),
                                        style: TextStyle(
                                          fontSize: 8.5 * scale,
                                          fontWeight: FontWeight.bold,
                                          color: theme.digitColor.withValues(alpha: 0.5),
                                          fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                        ),
                                      ),
                                      SizedBox(height: 1 * scale),
                                      Text(
                                        _completedCycles.toString(),
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.bold,
                                          color: theme.digitColor,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Action Row: Decrement (left) and Reset (right)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 36 * scale),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          textDirection: TextDirection.ltr,
                          children: [
                            // Minus Button
                            _buildDeviceButton(
                              icon: Icons.undo_rounded,
                              color: theme.smallBtn,
                              iconColor: isDark ? Colors.white70 : Colors.black87,
                              onTap: _decrement,
                              tooltip: settings.translate('Minus', 'منہا کریں', 'گهٽايو', 'طرح'),
                              scale: scale,
                            ),
                            // Reset Button
                            _buildDeviceButton(
                              icon: Icons.refresh_rounded,
                              color: theme.smallBtn,
                              iconColor: isDark ? Colors.white70 : Colors.black87,
                              onTap: _reset,
                              tooltip: settings.translate('Reset', 'ری سیٹ', 'ريسيٽ', 'إعادة تعيين'),
                              scale: scale,
                            ),
                          ],
                        ),
                      ),

                      // Target Selection Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTargetBtn(null, settings.translate('None', 'لا محدود', 'لامحدود', 'بلا'), scale, theme),
                          SizedBox(width: 12 * scale),
                          _buildTargetBtn(33, '33', scale, theme),
                          SizedBox(width: 12 * scale),
                          _buildTargetBtn(100, '100', scale, theme),
                        ],
                      ),

                      // Center Increment Button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _increment,
                        child: Container(
                          width: 88 * scale,
                          height: 88 * scale,
                          margin: EdgeInsets.only(bottom: 12 * scale),
                          decoration: BoxDecoration(
                            color: theme.largeBtn,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.deviceBorder.withValues(alpha: 0.6),
                              width: 3.5 * scale,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6 * scale,
                                offset: Offset(0, 3.5 * scale),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Dynamic Color Selector ──────────────────────────────────
            if (_showColorSelector)
              Positioned(
                bottom: 80 * scale,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 10 * scale),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      borderRadius: BorderRadius.circular(30 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8 * scale,
                          offset: Offset(0, 3 * scale),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Left Option: Brown (Index 2)
                        _buildColorOptionCircle(
                          color: const Color(0xFF3D251A),
                          border: const Color(0xFFA68573),
                          isActive: selectedTheme == TasbeehThemeIndex.brown,
                          onTap: () {
                            settings.setTasbeehThemeIndex(TasbeehThemeIndex.brown.index);
                          },
                          scale: scale,
                        ),
                        SizedBox(width: 14 * scale),
                        // Middle Option: Slate (Index 1) - Default screen setting
                        _buildColorOptionCircle(
                          color: const Color(0xFF1C2B36),
                          border: const Color(0xFF78909C),
                          isActive: selectedTheme == TasbeehThemeIndex.slate,
                          onTap: () {
                            settings.setTasbeehThemeIndex(TasbeehThemeIndex.slate.index);
                          },
                          scale: scale,
                        ),
                        SizedBox(width: 14 * scale),
                        // Right Option: Gray (Index 0)
                        _buildColorOptionCircle(
                          color: const Color(0xFF757575),
                          border: const Color(0xFFE0E0E0),
                          isActive: selectedTheme == TasbeehThemeIndex.gray,
                          onTap: () {
                            settings.setTasbeehThemeIndex(TasbeehThemeIndex.gray.index);
                          },
                          scale: scale,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Bottom Control Bar ─────────────────────────────────────
            Positioned(
              bottom: 16 * scale,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Vibration Button
                    _buildControlCircle(
                      icon: Icons.vibration_rounded,
                      isActive: _vibrateOn,
                      onTap: _toggleVibrate,
                      isVibrate: true,
                      isDark: isDark,
                      scale: scale,
                    ),
                    SizedBox(width: 24 * scale),
                    // Theme Color Picker Button
                    _buildControlCircle(
                      icon: Icons.palette_rounded,
                      isActive: _showColorSelector,
                      onTap: () {
                        setState(() {
                          _showColorSelector = !_showColorSelector;
                        });
                      },
                      isVibrate: false,
                      isDark: isDark,
                      scale: scale,
                    ),
                    SizedBox(width: 24 * scale),
                    // Dark Mode Toggle Button
                    _buildControlCircle(
                      icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      isActive: false,
                      onTap: () {
                        setState(() {
                          _localIsDark = !isDark;
                        });
                      },
                      isVibrate: false,
                      isDark: isDark,
                      scale: scale,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetBtn(int? targetVal, String label, double scale, _ThemeColors theme) {
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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.2)
              : theme.lcdBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: isSelected ? AppTheme.accent : theme.deviceBorder.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11 * scale,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.accent : theme.digitColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  // Helper widget to build device small buttons (reset / decrement)
  Widget _buildDeviceButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    required String tooltip,
    required double scale,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36 * scale,
          height: 36 * scale,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 3 * scale,
                offset: Offset(0, 1.5 * scale),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18 * scale,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  // Helper widget to build color option choice circles
  Widget _buildColorOptionCircle({
    required Color color,
    required Color border,
    required bool isActive,
    required VoidCallback onTap,
    required double scale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30 * scale,
        height: 30 * scale,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.yellow : border,
            width: isActive ? 3.0 * scale : 1.5 * scale,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.4),
                    blurRadius: 5 * scale,
                    spreadRadius: 1 * scale,
                  )
                ]
              : null,
        ),
      ),
    );
  }

  // Helper widget to build bottom row control circle buttons
  Widget _buildControlCircle({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isVibrate,
    required bool isDark,
    required double scale,
  }) {
    Color bg;
    Color iconColor;

    if (isActive) {
      if (isVibrate) {
        bg = const Color(0xFFFFEB3B); // Yellow highlight for vibrate
        iconColor = Colors.black87;
      } else {
        bg = AppTheme.accent;
        iconColor = Colors.white;
      }
    } else {
      bg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
      iconColor = isDark ? Colors.white70 : Colors.black87;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48 * scale,
        height: 48 * scale,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4 * scale,
              offset: Offset(0, 2 * scale),
            )
          ],
        ),
        child: Icon(
          icon,
          size: 22 * scale,
          color: iconColor,
        ),
      ),
    );
  }
}

// A private class helper for local color themes of Tasbeeh Counter
class _ThemeColors {
  final Color screenBg;
  final Color deviceBody;
  final Color deviceBorder;
  final Color lcdBg;
  final Color digitColor;
  final Color smallBtn;
  final Color largeBtn;
  final Color deviceShadow;
  final Color headerTextColor;
  final Color headerSubColor;

  const _ThemeColors({
    required this.screenBg,
    required this.deviceBody,
    required this.deviceBorder,
    required this.lcdBg,
    required this.digitColor,
    required this.smallBtn,
    required this.largeBtn,
    required this.deviceShadow,
    required this.headerTextColor,
    required this.headerSubColor,
  });
}
