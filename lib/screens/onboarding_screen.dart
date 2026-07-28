import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

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
          await settings.setLocation(position.latitude, position.longitude, city);
        } catch (_) {}
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          settings.translate('App Setup', 'ایپ سیٹ اپ', 'ايپ سيٽ اپ', 'إعداد التطبيق'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          settings.translate(
                            'To get the most out of Sukkur Salah, we need a few permissions.',
                            'سکھر صلاۃ سے مکمل فائدہ اٹھانے کے لیے، ہمیں کچھ اجازتیں درکار ہیں۔',
                            'سکر صلاۃ مان مڪمل فائدو وٺڻ لاءِ، اسان کي ڪجهه اجازتن جي ضرورت آهي.',
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          settings.translate('Select Prayer Timings', 'نماز کے اوقات کا انتخاب کریں', 'نماز جي وقتن جو انتخاب ڪريو', 'اختر أوقات الصلاة'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildModeOption(
                          title: settings.translate('Sukkur (Jantri)', 'سکھر (جنتری)', 'سکر (جنتري)', 'سكر (جنتري)'),
                          subtitle: settings.translate('Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu sirrahu Jantri', 'بمطابق حضرت ڈاکٹر حفیظ اللہ صاحب قدس اللہ سرہ جنتری', 'حضرت ڊاڪٽر حفيظ الله صاحب قدس الله سره جي جنتري مطابق', 'بناءً على تقويم الشيخ الدكتور حفيظ الله قدس الله سره'),
                          mode: LocationMode.sukkur,
                          icon: Icons.push_pin_rounded,
                          accent: accent,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildModeOption(
                          title: settings.translate('Other Cities', 'دیگر شہر', 'ٻيا شهر', 'مدن أخرى'),
                          subtitle: settings.translate('Auto-calculate timings based on GPS location', 'GPS لوکیشن کے مطابق اوقات کا خودکار حساب', 'GPS لوڪيشن جي مطابق وقتن جو خودڪار حساب', 'حساب الأوقات تلقائيًا بناءً على الموقع'),
                          mode: LocationMode.world,
                          icon: Icons.public_rounded,
                          accent: accent,
                          isDark: isDark,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          settings.translate('Required Permissions', 'مطلوبہ اجازتیں', 'گهربل اجازتون', 'الأذونات المطلوبة'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        
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
                        ),
                        const SizedBox(height: 16),
                        
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
                        ),
                        const SizedBox(height: 16),

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
                        ),
                        
                        const Spacer(),
                        const SizedBox(height: 24),
                        
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _requestPermissions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                            disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  settings.translate('Allow Permissions', 'اجازت دیں', 'اجازت ڏيو', 'السماح بالأذونات'),
                                  style: const TextStyle(
                                    fontSize: 18,
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
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
    required bool isDark,
    required bool isTicked,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isTicked ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isTicked ? Colors.green : (isDark ? Colors.white24 : Colors.black26),
              size: 28,
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
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? accent : (isDark ? Colors.white12 : Colors.black12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle_rounded,
                color: accent,
                size: 28,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
