import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

/// Measured height of the setup checklist at scale 1.0. Shorter screens scale
/// everything down proportionally so it still fits in one view. Verified by
/// test/onboarding_fits_test.dart - if the content changes, that test fails and
/// this number needs re-measuring.
const double _kDesignHeight = 960.0;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  bool _isProcessing = false;
  Completer<void>? _resumeCompleter;
  AppLifecycleState _appState = AppLifecycleState.resumed;

  bool _locTicked = false;
  bool _notifTicked = false;
  bool _batteryTicked = false;
  
  LocationMode _selectedLocationMode = LocationMode.sukkur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = state;
    if (state == AppLifecycleState.resumed) {
      if (_resumeCompleter != null && !_resumeCompleter!.isCompleted) {
        _resumeCompleter!.complete();
      }
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final loc = await Geolocator.checkPermission();
    final notif = await NotificationService.instance.areNotificationsEnabled();
    const channel = MethodChannel('pk.sukkur.salah/native_helper');
    bool battery = true;
    try {
      battery = await channel.invokeMethod('isBatteryOptimizationIgnored') ?? false;
    } catch (_) {}

    if (mounted) {
      setState(() {
        if (loc == LocationPermission.always || loc == LocationPermission.whileInUse) _locTicked = true;
        if (notif) _notifTicked = true;
        if (battery) _batteryTicked = true;
      });
    }
  }

  Future<void> _waitForResume() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_appState != AppLifecycleState.resumed) {
      _resumeCompleter = Completer<void>();
      await _resumeCompleter!.future;
      _resumeCompleter = null;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isProcessing = true);
    final settings = context.read<SettingsProvider>();

    try {
      // 1. Location
      LocationPermission loc = await Geolocator.checkPermission();
      if (loc == LocationPermission.denied) {
        loc = await Geolocator.requestPermission();
      }
      if (mounted) setState(() => _locTicked = true);

      await settings.setLocationMode(_selectedLocationMode);
      if (_selectedLocationMode == LocationMode.world && (loc == LocationPermission.always || loc == LocationPermission.whileInUse)) {
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          String city = 'Unknown Location';
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? p.country ?? 'Unknown Location';
          }
          // A user setting up while in Sukkur is refused here and handed the
          // Jantri instead - it is more accurate than the calculation.
          await settings.setLocation(position.latitude, position.longitude, city);
        } catch (_) {}
        // No fix, or geocoding failed: world mode with no city would show
        // calculated timings for nowhere, so fall back to the Jantri.
        await settings.ensureWorldLocationValid();
      }

      // 2. Notification
      await NotificationService.instance.requestPermissions();
      if (mounted) setState(() => _notifTicked = true);

      // 3. Battery / AutoStart
      const channel = MethodChannel('pk.sukkur.salah/native_helper');
      try {
        final bool isIgnoring = await channel.invokeMethod('isBatteryOptimizationIgnored') ?? false;
        if (!isIgnoring && mounted) {
          await channel.invokeMethod('requestIgnoreBatteryOptimization');
          await _waitForResume();
          
          final bool hasAutoStart = await channel.invokeMethod('hasAutoStart') ?? false;
          if (hasAutoStart && mounted) {
             await channel.invokeMethod('requestAutoStart');
             await _waitForResume();
          }
        }
      } catch (_) {}
      
      if (mounted) setState(() => _batteryTicked = true);

      // Wait a tiny bit so the user can see all 3 green checkmarks before navigating away
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        await settings.completeSetup();
      }

    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = settings.displayThemeAccent();

    return Scaffold(
      // Onboarding is a fixed checklist that has to be read at a glance, so the
      // system font scale is capped here - otherwise a large accessibility
      // setting alone pushes the Allow button off-screen.
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Everything scales off the height actually available, so the whole
            // checklist fits without scrolling on small and large phones alike.
            // The user's font scale is folded in too: bigger text means taller
            // content, so the layout has to shrink further to compensate.
            final textScale = MediaQuery.textScalerOf(context).scale(100) / 100;
            // 0.62 is a readability floor: below it the body text stops being
            // legible, so very short screens (or a very large font setting)
            // scroll the last bit instead of shrinking further.
            final scale =
                (constraints.maxHeight / (_kDesignHeight * textScale))
                    .clamp(0.62, 1.0);
            double s(double value) => value * scale;

            return SingleChildScrollView(
              // Scrolling stays available as a safety net (landscape, split
              // screen), but portrait never needs it.
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: s(24.0), vertical: s(16.0)),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: s(12)),
                        Text(
                          settings.translate('App Setup', 'ایپ سیٹ اپ', 'ايپ سيٽ اپ', 'إعداد التطبيق'),
                          style: TextStyle(
                            fontSize: s(28),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: s(6)),
                        Text(
                          settings.translate(
                            'To get the most out of Sukkur Salah, we need a few permissions.',
                            'سکھر صلاۃ سے مکمل فائدہ اٹھانے کے لیے، ہمیں کچھ اجازتیں درکار ہیں۔',
                            'سکر صلاۃ مان مڪمل فائدو وٺڻ لاءِ، اسان کي ڪجهه اجازتن جي ضرورت آهي.',
                          ),
                          style: TextStyle(
                            fontSize: s(15),
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: s(18)),

                        Text(
                          settings.translate('Select Prayer Timings', 'نماز کے اوقات کا انتخاب کریں', 'نماز جي وقتن جو انتخاب ڪريو', 'اختر أوقات الصلاة'),
                          style: TextStyle(
                            fontSize: s(17),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: s(10)),

                        _buildModeOption(
                          title: settings.translate('Sukkur (Jantri)', 'سکھر (جنتری)', 'سکر (جنتري)', 'سكر (جنتري)'),
                          subtitle: settings.translate('Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu Jantri', 'بمطابق حضرت ڈاکٹر حفیظ اللہ صاحب قدس اللہ سرہ جنتری', 'حضرت ڊاڪٽر حفيظ الله صاحب قدس الله سره جي جنتري مطابق', 'بناءً على تقويم الشيخ الدكتور حفيظ الله قدس الله سره'),
                          mode: LocationMode.sukkur,
                          icon: Icons.push_pin_rounded,
                          accent: accent,
                          isDark: isDark,
                          s: s,
                        ),
                        SizedBox(height: s(10)),
                        _buildModeOption(
                          title: settings.translate('Other Cities', 'دیگر شہر', 'ٻيا شهر', 'مدن أخرى'),
                          subtitle: settings.translate('Auto-calculate timings based on GPS location', 'GPS لوکیشن کے مطابق اوقات کا خودکار حساب', 'GPS لوڪيشن جي مطابق وقتن جو خودڪار حساب', 'حساب الأوقات تلقائيًا بناءً على الموقع'),
                          mode: LocationMode.world,
                          icon: Icons.public_rounded,
                          accent: accent,
                          isDark: isDark,
                          s: s,
                        ),

                        SizedBox(height: s(20)),

                        Text(
                          settings.translate('Required Permissions', 'مطلوبہ اجازتیں', 'گهربل اجازتون', 'الأذونات المطلوبة'),
                          style: TextStyle(
                            fontSize: s(17),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: s(10)),

                        _buildPermissionCard(
                          icon: Icons.location_on_rounded,
                          title: settings.translate('Location Access', 'مقام کی رسائی', 'مقام تائين رسائي', 'الوصول إلى الموقع'),
                          description: settings.translate(
                            'Needed to accurately calculate prayer times and find the Qibla direction.',
                            'نماز کے اوقات کا درست حساب لگانے اور قبلہ کی سمت معلوم کرنے کے لیے درکار ہے۔',
                            'نماز جي وقتن جو درست حساب لڳائڻ ۽ قبلي جي سمت معلوم ڪرڻ لاءِ گهربل آهي.',
                          ),
                          accent: accent,
                          isDark: isDark,
                          isTicked: _locTicked,
                          s: s,
                        ),
                        SizedBox(height: s(10)),

                        _buildPermissionCard(
                          icon: Icons.notifications_active_rounded,
                          title: settings.translate('Notifications', 'اطلاعات', 'اطلاعون', 'الإشعارات'),
                          description: settings.translate(
                            'Needed to send you Adhan and prayer time alerts on time.',
                            'اذان اور نماز کے اوقات کی اطلاعات وقت پر بھیجنے کے لیے درکار ہے۔',
                            'اذان ۽ نماز جي وقتن جون اطلاعون وقت تي موڪلڻ لاءِ گهربل آهي.',
                          ),
                          accent: accent,
                          isDark: isDark,
                          isTicked: _notifTicked,
                          s: s,
                        ),
                        SizedBox(height: s(10)),

                        _buildPermissionCard(
                          icon: Icons.battery_charging_full_rounded,
                          title: settings.translate('Background Execution', 'پس منظر کا عمل', 'پس منظر جو عمل', 'التنفيذ في الخلفية'),
                          description: settings.translate(
                            'Needed to bypass battery savers so alerts ring exactly on time.',
                            'بیٹری سیورز کو نظر انداز کرنے کے لیے درکار ہے تاکہ الارم بالکل وقت پر بجے۔',
                            'بيٽري سيورز کي نظر انداز ڪرڻ لاءِ گهربل آهي ته جيئن الارم بلڪل وقت تي وڄي.',
                          ),
                          accent: accent,
                          isDark: isDark,
                          isTicked: _batteryTicked,
                          s: s,
                        ),

                        const Spacer(),
                        SizedBox(height: s(16)),

                        ElevatedButton(
                          onPressed: _isProcessing ? null : _requestPermissions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                            disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
                            padding: EdgeInsets.symmetric(vertical: s(14)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? SizedBox(
                                  height: s(22),
                                  width: s(22),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  settings.translate('Allow Permissions', 'اجازت دیں', 'اجازت ڏيو', 'السماح بالأذونات'),
                                  style: TextStyle(
                                    fontSize: s(17),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
    required bool isDark,
    required bool isTicked,
    required double Function(double) s,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(s(12)),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTicked 
                ? Colors.green.withValues(alpha: 0.5) 
                : (isDark ? Colors.white12 : Colors.black12),
            width: isTicked ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(s(8)),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accent,
                size: s(20),
              ),
            ),
            SizedBox(width: s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: s(15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: s(2)),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: s(12.5),
                      height: 1.25,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: s(8)),
            Icon(
              isTicked ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isTicked ? Colors.green : (isDark ? Colors.white24 : Colors.black26),
              size: s(24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required String subtitle,
    required LocationMode mode,
    required IconData icon,
    required Color accent,
    required bool isDark,
    required double Function(double) s,
  }) {
    final isSelected = _selectedLocationMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLocationMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(s(12)),
        decoration: BoxDecoration(
          color: isSelected 
              ? accent.withValues(alpha: 0.15) 
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? accent 
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(s(8)),
              decoration: BoxDecoration(
                color: isSelected ? accent : (isDark ? Colors.white12 : Colors.black12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                size: s(20),
              ),
            ),
            SizedBox(width: s(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: s(15),
                      fontWeight: FontWeight.bold,
                      color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  SizedBox(height: s(2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: s(12),
                      height: 1.25,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: s(8)),
              Icon(
                Icons.check_circle_rounded,
                color: accent,
                size: s(24),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
