import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
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
      await setLocaleIdentifier(settings.localeIdentifier);
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      final city = placemarks.isEmpty
          ? 'Unknown Location'
          : (cityNameFrom(placemarks.first) ?? 'Unknown Location');

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
      _step = 1;
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
            final designHeight = _step == 0
                ? (_selectedLocationMode == LocationMode.world
                    ? _kDesignHeightWithCityPanel
                    : _kDesignHeight)
                : _kPermissionsDesignHeight;
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

                        // ── Step 1: which timings ───────────────────────────
                        if (_step == 0) ...[
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
                        if (_step == 1) ...[
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
                        ],

                        const Spacer(),
                        SizedBox(height: s(16)),

                        // Going back to change the timings must stay possible -
                        // the permissions step is where people realise they
                        // picked the wrong one.
                        if (_step == 1 && !_isProcessing) ...[
                          TextButton.icon(
                            onPressed: () => setState(() => _step = 0),
                            icon: Icon(Icons.arrow_back_rounded, size: s(18)),
                            style: TextButton.styleFrom(foregroundColor: accent),
                            label: Text(
                              settings.translate('Select Prayer Timings', 'نماز کے اوقات کا انتخاب کریں', 'نماز جي وقتن جو انتخاب ڪريو', 'اختر أوقات الصلاة'),
                              style: TextStyle(fontSize: s(13)),
                            ),
                          ),
                          SizedBox(height: s(4)),
                        ],

                        ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : (_step == 0
                                  ? () => _goToPermissions(settings)
                                  : _requestPermissions),
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
                                  _step == 0
                                      ? settings.translate('Next', 'آگے', 'اڳتي', 'التالي')
                                      : settings.translate('Allow Permissions', 'اجازت دیں', 'اجازت ڏيو', 'السماح بالأذونات'),
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
