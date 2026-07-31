import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/sukkur_header.dart';
import '../data/timings_data.dart';
import '../models/namaz_timing.dart';
import '../utils/app_theme.dart';
import '../utils/prayer_state.dart';
import '../widgets/analog_clock.dart';
import '../widgets/dr_slogan_footer.dart';
import '../widgets/dr_slogan_header.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/widget_service.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  DayTiming? _today;
  PrayerStateResult? _state;
  Timer? _ticker;
  DateTime _now = DateTime.now();
  int _widgetTick = 0;

  @override
  void initState() {
    super.initState();
    _loadTimings();
    // Poll at 200ms to catch the second boundary promptly, but only rebuild
    // when the displayed second actually changes — repaints the clock face
    // once per second instead of 5x, with no visible difference.
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final newNow = DateTime.now();
      if (newNow.second == _now.second) return;
      setState(() {
        _now = newNow;
        _computeNextPrayer();
      });
      _widgetTick++;
      if (_widgetTick >= 60) {
        _widgetTick = 0;
        WidgetService.updateWidget();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _loadTimings() {
    _today = TimingsData.instance.timingFor(TimingsData.instance.nowForTimings());
    _computeNextPrayer();
  }

  void _computeNextPrayer() {
    // The timings' own clock, not the device's: for a world city read on its
    // own time zone this is the city's current time, so the countdown lands on
    // the same moment the notification does.
    final now = TimingsData.instance.nowForTimings();
    _today = TimingsData.instance.timingFor(now);
    if (_today == null) {
      _state = null;
      return;
    }
    _state = computePrayerState(now, _today!);
  }

  String _formatCountdown(Duration d) {
    final ms = d.inMilliseconds;
    final seconds = ms <= 0 ? 0 : (ms / 1000).ceil();
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '- ${h.toString().padLeft(2, '0')} : ${m.toString().padLeft(2, '0')} : ${s.toString().padLeft(2, '0')}';
    }
    return '- ${m.toString().padLeft(2, '0')} : ${s.toString().padLeft(2, '0')}';
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '+ ${h.toString().padLeft(2, '0')} : ${m.toString().padLeft(2, '0')} : ${s.toString().padLeft(2, '0')}';
    }
    return '+ ${m.toString().padLeft(2, '0')} : ${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Clock accent follows the selected display theme (matches the style picker preview).
    final accent = AppTheme.accent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: settings.getThemeDecoration(isDark),
        child: SafeArea(
          child: Column(
          children: [
            const SizedBox(height: 12),
            const SizedBox(
              height: 36,
              child: Center(child: SukkurHeader()),
            ),
            const SizedBox(height: 8),
            if (settings.locationMode == LocationMode.sukkur) const DrSloganHeader(),

            // ── Flexible middle — clock + prayer info ──────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Clock fills ~52% of available height, capped at 260px
                  final clockSize = math
                      .min(constraints.maxWidth - 40, constraints.maxHeight * 0.52)
                      .clamp(150.0, 260.0);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ── Analog clock ─────────────────────────────────
                      AnalogClockWidget(
                        now: _now,
                        isDark: isDark,
                        accentColor: accent,
                        size: clockSize,
                        style: settings.clockStyle,
                      ),

                      // ── Prayer info ───────────────────────────────────
                      if (_state != null)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _state!.prayer.localizedName(settings.language),
                              style: TextStyle(
                                fontSize: settings.isRtl ? 28 : 24,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_state!.prayer.displayTime} ${_state!.prayer.displayIsPm ? 'PM' : 'AM'}',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _state!.isElapsed
                                  ? settings.translate('Time elapsed', 'گزرا وقت', 'گذريل وقت', 'الوقت المنقضي')
                                  : settings.translate('Time remaining', 'باقی وقت', 'باقي وقت', 'الوقت المتبقي'),
                              style: TextStyle(
                                fontSize: settings.isRtl ? 14 : 11,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _state!.isElapsed
                                  ? _formatElapsed(_state!.duration)
                                  : _formatCountdown(_state!.duration),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                                letterSpacing: 3,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      else
                        Text(
                          settings.translate(
                            'All prayers done for today',
                            'آج کی نمازیں مکمل ہو گئیں',
                            'اڄ جون نمازون مڪمل ٿي ويون',
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  );
                },
              ),
            ),

            // ── Fixed footer ───────────────────────────────────────────
            const DrSloganFooter(),
          ],
        ),
      ),
     ),
    );
  }
}
