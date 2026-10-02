import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/world_translations.dart';
import '../utils/app_theme.dart';
import '../services/city_search.dart';
import '../services/notification_service.dart';
import '../utils/world_location.dart';
import 'city_search_screen.dart';

/// Measured height of the setup checklist at scale 1.0. Shorter screens scale
/// everything down proportionally so it still fits in one view. Verified by
/// test/onboarding_fits_test.dart - if the content changes, that test fails and
/// this number needs re-measuring.
const double _kDesignHeight = 960.0;

/// Same, for the taller layout: choosing Other Cities opens a city panel under
/// the option, which measures 129px at scale 1.0. Kept separate so the shorter
/// Sukkur layout is not shrunk to make room for a panel it never shows.
const double _kDesignHeightWithCityPanel = _kDesignHeight + 129.0;

/// And for the permissions step, which carries three cards instead of the
/// timings choice. Re-measured after the split - see the test named below.
const double _kPermissionsDesignHeight = 760.0;

const Map<String, String> _dualLanguageDisplayNames = {
  'english': 'English',
  'urdu': 'Urdu (اردو)',
  'sindhi': 'Sindhi (سنڌي)',
  'arabic': 'Arabic (عربي)',
  'bengali': 'Bengali (বাংলা)',
  'indonesian': 'Indonesian (Indonesia)',
  'turkish': 'Turkish (Türkçe)',
  'french': 'French (Français)',
  'hindi': 'Hindi (हिन्दी)',
  'persian': 'Persian (فارسی)',
};

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
  
  /// Null until the user picks. Pre-selecting Sukkur meant anyone who skipped
  /// past this section had "chosen" it without knowing, so the choice is now
  /// genuinely theirs to make.
  LocationMode? _selectedLocationMode;

  /// Which step is showing: 0 picks the timings, 1 asks for permissions.
  int _step = 0;

  /// Set when Next is pressed with something still missing, so the screen says
  /// what is wanted rather than just refusing.
  bool _showSelectionError = false;

  /// The city chosen for Other Cities, by search or by GPS. Held here rather
  /// than written straight to settings so nothing is committed until the user
  /// presses the button at the bottom.
  String? _cityName;
  double? _cityLat;
  double? _cityLng;

  /// Set once the user has actually been refused location, so the screen can
  /// point them at the search button instead of leaving them stuck.
  bool _locationDenied = false;
  bool _findingLocation = false;

  bool get _hasCity => _cityLat != null && _cityLng != null;

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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  /// Sukkur is never a world city: the Jantri is more accurate than any
  /// calculation for it. Same refusal the World screen makes, worded for this
  /// screen - here the Jantri is the option directly above, not the side bar.
  void _refuseSukkur(SettingsProvider settings) {
    _snack(settings.translate(
      'Select Sukkur from the option above for accurate timings',
      'درست اوقات کے لیے اوپر دیے گئے آپشن سے سکھر منتخب کریں',
      'صحيح وقتن لاءِ مٿي ڏنل آپشن مان سکر چونڊيو',
      'للحصول على أوقات دقيقة، اختر سكر من الخيار أعلاه',
    ));
  }

  /// The offline picker: 235,000 cities inside the app, so this is the path
  /// that still works with no permission and no internet.
  Future<void> _searchCity(SettingsProvider settings) async {
    final chosen = await Navigator.of(context).push<CityResult>(
      MaterialPageRoute(builder: (_) => const CitySearchScreen()),
    );
    if (chosen == null || !mounted) return;

    // The picker itself never lists Sukkur; SukkurLocation is the authority,
    // so check rather than trust.
    if (SukkurLocation.covers(chosen.latitude, chosen.longitude, chosen.name)) {
      _refuseSukkur(settings);
      return;
    }
    setState(() {
      _cityName = chosen.name;
      _cityLat = chosen.latitude;
      _cityLng = chosen.longitude;
      _locationDenied = false;
    });
  }

  Future<void> _useMyLocation(SettingsProvider settings) async {
    setState(() => _findingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _locationDenied = true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationDenied = true);
        return;
      }
      if (mounted) setState(() => _locTicked = true);

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);

      // Ask the platform geocoder for the name in the user's own script.
      String city = settings.translate('Current Location', 'موجودہ مقام', 'موجوده جڳھ', 'الموقع الحالي');
      try {
        await setLocaleIdentifier(settings.localeIdentifier);
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final geocodedCity = cityNameFrom(placemarks.first);
          if (geocodedCity != null && geocodedCity.isNotEmpty) {
            city = geocodedCity;
          }
        }
      } catch (_) {
        // Platform geocoder may fail if device is offline or Google Play Services/Geocoder is unavailable.
      }

      if (SukkurLocation.covers(position.latitude, position.longitude, city)) {
        _refuseSukkur(settings);
        return;
      }
      if (!mounted) return;
      setState(() {
        _cityName = city;
        _cityLat = position.latitude;
        _cityLng = position.longitude;
        _locationDenied = false;
      });
    } catch (_) {
      _snack(settings.translate(
        'Could Not Get Location',
        'مقام حاصل نہیں ہو سکا',
        'مقام حاصل نه ٿي سگهيو',
        'تعذر الحصول على الموقع',
      ));
    } finally {
      if (mounted) setState(() => _findingLocation = false);
    }
  }

  /// What still has to be answered before the timings step can be left, or null
  /// when it is complete.
  String? _selectionProblem(SettingsProvider settings) {
    if (_selectedLocationMode == null) {
      return settings.translate(
        'Please select Sukkur or Other Cities',
        'براہ کرم سکھر یا دیگر شہر منتخب کریں',
        'مهرباني ڪري سکر يا ٻيا شهر چونڊيو',
        'يرجى اختيار سكر أو مدن أخرى',
      );
    }
    if (_selectedLocationMode == LocationMode.world && !_hasCity) {
      return settings.translate(
        'Choose a city to continue',
        'جاری رکھنے کے لیے ایک شہر منتخب کریں',
        'اڳتي وڌڻ لاءِ هڪ شهر چونڊيو',
        'اختر مدينة للمتابعة',
      );
    }
    return null;
  }

  void _goToPermissions(SettingsProvider settings) {
    if (_selectionProblem(settings) != null) {
      setState(() => _showSelectionError = true);
      return;
    }
    setState(() {
      _showSelectionError = false;
      _step = 2;
    });
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

      // Step 1 will not let anyone past without a mode, and without a city if
      // that mode is World, so both are settled by the time we get here.
      final mode = _selectedLocationMode ?? LocationMode.sukkur;
      await settings.setLocationMode(mode);
      if (mode == LocationMode.world && _hasCity) {
        // Already checked against SukkurLocation when it was picked, so a
        // refusal here would mean the two disagree - handled, not trusted.
        await settings.setLocation(_cityLat!, _cityLng!, _cityName!);
        // A city that somehow still fails that check would leave World mode
        // pointing at nowhere; this hands it back to the Jantri instead.
        await settings.ensureWorldLocationValid();

        if (!settings.usesCalculatedTimings) {
          _snack(settings.translate(
            'No city selected - using Sukkur Jantri. You can choose your city later from World Prayer Timings.',
            'کوئی شہر منتخب نہیں - سکھر جنتری استعمال ہو رہی ہے۔ آپ بعد میں ورلڈ پریئر ٹائمنگز سے اپنا شہر منتخب کر سکتے ہیں۔',
            'ڪو به شهر چونڊيل ناهي - سکر جنتري استعمال ٿي رهي آهي. توهان بعد ۾ ورلڊ پريئر ٽائيمنگز مان پنهنجو شهر چونڊي سگهو ٿا.',
            'لم يتم اختيار مدينة - يتم استخدام جنتري سكر. يمكنك اختيار مدينتك لاحقًا من مواقيت الصلاة العالمية.',
          ));
        }
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

  (String, String) _splitLanguageName(String langKey, String defaultNative) {
    final dual = _dualLanguageDisplayNames[langKey] ?? defaultNative;
    final match = RegExp(r'^(.+?)\s*\((.+)\)$').firstMatch(dual);
    if (match != null) {
      return (match.group(1)!, match.group(2)!);
    }
    return (dual, '');
  }

  Widget _buildStepperHeader({
    required SettingsProvider settings,
    required Color accent,
    required bool isDark,
    required double Function(double) s,
  }) {
    final steps = [
      settings.translate('Language', 'زبان', 'ٻولي', 'اللغة'),
      settings.translate('Timings', 'اوقات', 'وقت', 'الأوقات'),
      settings.translate('Permissions', 'اجازتیں', 'اجازتون', 'الأذونات'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final isActive = index == _step;
        final isCompleted = index < _step;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(
                horizontal: s(isActive ? 12 : 8),
                vertical: s(4),
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withValues(alpha: 0.15)
                    : isCompleted
                        ? accent.withValues(alpha: 0.08)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? accent
                      : isCompleted
                          ? accent.withValues(alpha: 0.4)
                          : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: s(18),
                    height: s(18),
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? accent
                          : (isDark ? Colors.white24 : Colors.black26),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(Icons.check_rounded, size: s(12), color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: s(10),
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black54),
                              ),
                            ),
                    ),
                  ),
                  if (isActive) ...[
                    SizedBox(width: s(6)),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: s(11.5),
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (index < steps.length - 1) ...[
              SizedBox(width: s(4)),
              Container(
                width: s(12),
                height: s(2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? accent.withValues(alpha: 0.5)
                      : (isDark ? Colors.white12 : Colors.black12),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              SizedBox(width: s(4)),
            ],
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = settings.displayThemeAccent();

    return Scaffold(
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(100) / 100;
              final designHeight = _step == 0
                  ? 760.0
                  : (_step == 1
                      ? (_selectedLocationMode == LocationMode.world
                          ? _kDesignHeightWithCityPanel
                          : _kDesignHeight)
                      : _kPermissionsDesignHeight);
            // 0.62 is a readability floor: below it the body text stops being
            // legible, so very short screens (or a very large font setting)
            // scroll the last bit instead of shrinking further.
            final scale =
                (constraints.maxHeight / (designHeight * textScale))
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
                        SizedBox(height: s(4)),
                        _buildStepperHeader(settings: settings, accent: accent, isDark: isDark, s: s),
                        SizedBox(height: s(12)),
                        Text(
                          settings.translate('App Setup', 'ایپ سیٹ اپ', 'ايپ سيٽ اپ', 'إعداد التطبيق'),
                          style: TextStyle(
                            fontSize: s(26),
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: s(6)),
                        Text(
                          settings.translate(
                            'To get the most out of Sukkur Salah, we need a few permissions.',
                            'سکھر صلاۃ سے مکمل فائدہ اٹھانے کے لیے، ہمیں کچھ اجازتیں درکار ہیں۔',
                            'سکر صلاۃ مان مڪمل فائدو وٺڻ لاءِ، اسان کي ڪجهه اجازتن جي ضرورت آهي.',
                            'للحصول على أقصى استفادة من سكر صلاة، نحتاج إلى بعض الأذونات.',
                          ),
                          style: TextStyle(
                            fontSize: s(15),
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: s(18)),

                        // ── Step 0: Language Selection ─────────────────────────────
                        if (_step == 0) ...[
                        Text(
                          settings.translate('Select Language', 'زبان کا انتخاب کریں', 'ٻولي چونڊيو', 'اختر اللغة'),
                          style: TextStyle(
                            fontSize: s(17),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: s(4)),
                        Text(
                          settings.translate(
                            'Choose your preferred language for the app',
                            'ایپ کے لیے اپنی پسندیدہ زبان کا انتخاب کریں',
                            'ايپ لاءِ پنهنجي پسنديده ٻولي چونڊيو',
                            'اختر لغتك المفضلة للتطبيق',
                          ),
                          style: TextStyle(
                            fontSize: s(12.5),
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: s(12)),

                        Column(
                          children: [
                            for (int i = 0; i < languageNamesMap.length; i += 2) ...[
                              if (i > 0) SizedBox(height: s(8)),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLanguageOption(
                                      langKey: languageNamesMap.keys.elementAt(i),
                                      nativeName: languageNamesMap.values.elementAt(i),
                                      settings: settings,
                                      accent: accent,
                                      isDark: isDark,
                                      s: s,
                                    ),
                                  ),
                                  SizedBox(width: s(8)),
                                  if (i + 1 < languageNamesMap.length)
                                    Expanded(
                                      child: _buildLanguageOption(
                                        langKey: languageNamesMap.keys.elementAt(i + 1),
                                        nativeName: languageNamesMap.values.elementAt(i + 1),
                                        settings: settings,
                                        accent: accent,
                                        isDark: isDark,
                                        s: s,
                                      ),
                                    )
                                  else
                                    const Expanded(child: SizedBox.shrink()),
                                ],
                              ),
                            ],
                          ],
                        ),
                        ],

                        // ── Step 1: which timings ───────────────────────────
                        if (_step == 1) ...[
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
                          title: settings.translate('Sukkur', 'سکھر', 'سکر', 'سكر'),
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

                        if (_selectedLocationMode == LocationMode.world) ...[
                          SizedBox(height: s(10)),
                          _buildCityPanel(
                            settings: settings,
                            accent: accent,
                            isDark: isDark,
                            s: s,
                          ),
                        ],

                        // Says what is still wanted, rather than leaving a dead
                        // button with no explanation.
                        if (_showSelectionError &&
                            _selectionProblem(settings) != null) ...[
                          SizedBox(height: s(12)),
                          Text(
                            _selectionProblem(settings)!,
                            style: TextStyle(
                              fontSize: s(13),
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        ],

                        // ── Step 2: permissions ─────────────────────────────
                        if (_step == 2) ...[
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
                            'مطلوب لحساب اوقات الصلاة بدقة وتحديد اتجاه القبلة.',
                          ),
                          accent: accent,
                          iconBgColor: const Color(0xFF3F7A63),
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
                            'مطلوب لإرسال تنبيهات الأذان وأوقات الصلاة في الوقت المحدد.',
                          ),
                          accent: accent,
                          iconBgColor: const Color(0xFF1E88E5),
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
                            'مطلوب لتجاوز موفر البطارية لتعمل التنبيهات في الوقت المحدد.',
                          ),
                          accent: accent,
                          iconBgColor: const Color(0xFFFFA726),
                          isDark: isDark,
                          isTicked: _batteryTicked,
                          s: s,
                        ),
                        ],

                        const Spacer(),
                        SizedBox(height: s(16)),

                        if (_step == 1 && !_isProcessing) ...[
                          TextButton.icon(
                            onPressed: () => setState(() => _step = 0),
                            icon: Icon(Icons.arrow_back_rounded, size: s(18)),
                            style: TextButton.styleFrom(foregroundColor: accent),
                            label: Text(
                              settings.translate('Select Language', 'زبان کا انتخاب کریں', 'ٻولي چونڊيو', 'اختر اللغة'),
                              style: TextStyle(fontSize: s(13)),
                            ),
                          ),
                          SizedBox(height: s(4)),
                        ],

                        if (_step == 2 && !_isProcessing) ...[
                          TextButton.icon(
                            onPressed: () => setState(() => _step = 1),
                            icon: Icon(Icons.arrow_back_rounded, size: s(18)),
                            style: TextButton.styleFrom(foregroundColor: accent),
                            label: Text(
                              settings.translate('Select Prayer Timings', 'نماز کے اوقات کا انتخاب کریں', 'نماز جي وقتن جو انتخاب ڪريو', 'اختر أوقات الصلاة'),
                              style: TextStyle(fontSize: s(13)),
                            ),
                          ),
                          SizedBox(height: s(4)),
                        ],

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: _isProcessing
                                ? null
                                : LinearGradient(
                                    colors: [accent, accent.withValues(alpha: 0.85)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: _isProcessing
                                ? null
                                : [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : (_step == 0
                                    ? () => setState(() => _step = 1)
                                    : (_step == 1
                                        ? () => _goToPermissions(settings)
                                        : _requestPermissions)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                              disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
                              padding: EdgeInsets.symmetric(vertical: s(14)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isProcessing)
                                  SizedBox(
                                    height: s(20),
                                    width: s(20),
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                else ...[
                                  Text(
                                    _step == 2
                                        ? settings.translate('Allow Permissions', 'اجازت دیں', 'اجازت ڏيو', 'السماح بالأذونات')
                                        : settings.translate('Next', 'آگے', 'اڳتي', 'التالي'),
                                    style: TextStyle(
                                      fontSize: s(16.5),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: s(8)),
                                  Icon(
                                    _step == 2 ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                                    size: s(19),
                                  ),
                                ],
                              ],
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

  Widget _buildLanguageOption({
    required String langKey,
    required String nativeName,
    required SettingsProvider settings,
    required Color accent,
    required bool isDark,
    required double Function(double) s,
  }) {
    final isSelected = settings.language == langKey;
    final (enName, nativeScript) = _splitLanguageName(langKey, nativeName);

    return InkWell(
      onTap: () {
        settings.setLanguage(langKey);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(8)),
        decoration: BoxDecoration(
          color: isSelected 
              ? accent.withValues(alpha: 0.14) 
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? accent 
                : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: s(30),
              height: s(30),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  langKey.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    fontSize: s(11),
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ),
            SizedBox(width: s(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    enName,
                    style: TextStyle(
                      fontSize: s(13),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (nativeScript.isNotEmpty) ...[
                    SizedBox(height: s(1)),
                    Text(
                      '($nativeScript)',
                      style: TextStyle(
                        fontSize: s(11),
                        fontWeight: FontWeight.normal,
                        fontFamily: AppTheme.getFontForLanguage(context, langKey),
                        color: isSelected
                            ? accent
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: s(4)),
              Icon(
                Icons.check_circle_rounded,
                color: accent,
                size: s(18),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
    required Color iconBgColor,
    required bool isDark,
    required bool isTicked,
    required double Function(double) s,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(s(12)),
        decoration: BoxDecoration(
          color: isTicked
              ? iconBgColor.withValues(alpha: 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTicked 
                ? iconBgColor.withValues(alpha: 0.7) 
                : (isDark ? Colors.white12 : Colors.black12),
            width: isTicked ? 2 : 1,
          ),
          boxShadow: isTicked
              ? [
                  BoxShadow(
                    color: iconBgColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(s(8)),
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconBgColor,
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
              color: isTicked ? iconBgColor : (isDark ? Colors.white24 : Colors.black26),
              size: s(24),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown under Other Cities: which city is set, and the two ways to set one.
  /// Search comes first deliberately - it needs neither permission nor
  /// internet, so it is the path that always works.
  Widget _buildCityPanel({
    required SettingsProvider settings,
    required Color accent,
    required bool isDark,
    required double Function(double) s,
  }) {
    return Container(
      padding: EdgeInsets.all(s(12)),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasCity
              ? Colors.green.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.black12),
          width: _hasCity ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _hasCity
                    ? Icons.check_circle_rounded
                    : Icons.location_city_rounded,
                color: _hasCity
                    ? Colors.green
                    : (isDark ? Colors.white38 : Colors.black38),
                size: s(20),
              ),
              SizedBox(width: s(8)),
              Expanded(
                child: Text(
                  _cityName ??
                      settings.translate(
                        'No city selected',
                        'کوئی شہر منتخب نہیں',
                        'ڪو به شهر چونڊيل ناهي',
                        'لم يتم اختيار مدينة',
                      ),
                  style: TextStyle(
                    fontSize: s(14),
                    fontWeight: _hasCity ? FontWeight.bold : FontWeight.normal,
                    color: _hasCity
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s(10)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _findingLocation ? null : () => _searchCity(settings),
                  icon: Icon(Icons.search_rounded, size: s(18)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withValues(alpha: 0.6)),
                    padding: EdgeInsets.symmetric(vertical: s(10)),
                  ),
                  label: Text(
                    settings.translate('Search city...', 'شہر تلاش کریں...',
                        'شهر ڳوليو...', 'ابحث عن مدينة...'),
                    style: TextStyle(fontSize: s(13)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: s(8)),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _findingLocation ? null : () => _useMyLocation(settings),
                  icon: _findingLocation
                      ? SizedBox(
                          height: s(16),
                          width: s(16),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: accent),
                        )
                      : Icon(Icons.my_location_rounded, size: s(18)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withValues(alpha: 0.6)),
                    padding: EdgeInsets.symmetric(vertical: s(10)),
                  ),
                  label: Text(
                    settings.translate(
                        'Get Current Location',
                        'موجودہ مقام حاصل کریں',
                        'موجوده مقام حاصل ڪريو',
                        'الحصول على الموقع الحالي'),
                    style: TextStyle(fontSize: s(13)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          // Being refused location is not a dead end - the search above needs
          // no permission at all, so point at it rather than leave them stuck.
          if (_locationDenied && !_hasCity) ...[
            SizedBox(height: s(8)),
            Text(
              settings.translate(
                'Location denied - search your city instead',
                'مقام کی اجازت نہیں دی گئی - اس کے بجائے اپنا شہر تلاش کریں',
                'مقام جي اجازت نه ملي - ان جي بدران پنهنجو شهر ڳوليو',
                'تم رفض إذن الموقع - ابحث عن مدينتك بدلاً من ذلك',
              ),
              style: TextStyle(
                fontSize: s(12),
                color: Colors.orange.shade700,
                height: 1.25,
              ),
            ),
          ],
        ],
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
