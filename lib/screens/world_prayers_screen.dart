import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/settings_provider.dart';
import '../services/city_search.dart';
import '../utils/app_theme.dart';
import '../utils/world_location.dart';
import 'city_search_screen.dart';

class WorldPrayersScreen extends StatefulWidget {
  const WorldPrayersScreen({super.key});

  @override
  State<WorldPrayersScreen> createState() => _WorldPrayersScreenState();
}

class _WorldPrayersScreenState extends State<WorldPrayersScreen> {
  bool _isLoading = false;

  final List<String> _calculationMethods = [
    'Karachi',
    'Muslim World League',
    'ISNA',
    'Umm Al-Qura',
    'Egyptian',
    'Tehran',
    'Gulf',
    'Kuwait',
    'Qatar',
    'Singapore'
  ];

  // Hanafi puts Asr at twice the object's shadow; Shafi'i, Maliki and Hanbali
  // all use once the shadow, so those three resolve to the same time.
  final List<String> _asrMethods = ['Hanafi', 'Shafi', 'Maliki', 'Hanbali'];

  String _asrMethodLabel(SettingsProvider settings, String m) {
    switch (m) {
      case 'Hanafi':
        return settings.translate('Hanafi', 'حنفی', 'حنفي', 'حنفي');
      case 'Maliki':
        return settings.translate('Maliki', 'مالکی', 'مالڪي', 'مالكي');
      case 'Hanbali':
        return settings.translate('Hanbali', 'حنبلی', 'حنبلي', 'حنبلي');
      default:
        return settings.translate('Shafi', 'شافعی', 'شافعي', 'شافعي');
    }
  }

  /// Shown instead of switching to calculated timings, in every language.
  /// Nothing else happens - deliberately: a rejected Sukkur attempt must not
  /// disturb whatever is already in charge. If a world city was active it
  /// stays active; if the Jantri was showing, it goes on showing.
  void _showUseJantriMessage(SettingsProvider settings) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(settings.translate(
          'Select Sukkur Jantri (Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu Jantri) from the side bar for accurate timings',
          'درست اوقات کے لیے سائیڈ بار سے سکھر جنتری (بمطابق حضرت ڈاکٹر حفیظ اللہ صاحب قَدَّسَ اللہ سِرَّہُ جنتری) منتخب کریں',
          'صحيح وقتن لاءِ سائيڊ بار مان سکر جنتري (حضرت ڊاڪٽر حفيظ الله صاحب قَدَّسَ اللهُ سِرَّهُ جي جنتري مطابق) چونڊيو',
          'للحصول على أوقات دقيقة، اختر جنتري سكر (بناءً على تقويم الشيخ الدكتور حفيظ الله قَدَّسَ اللهُ سِرَّهُ) من الشريط الجانبي',
        )),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// The whole point of picking a city is to see its timings, so hand the user
  /// straight back to the Times tab instead of making them press back. The
  /// `true` result is what tells the shell to switch tabs; the snackbar lives
  /// on the app-level ScaffoldMessenger, so it survives the pop.
  void _returnToTimings() {
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _getCurrentLocation(SettingsProvider settings) async {
    setState(() {
      _isLoading = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Ask the platform geocoder for the place name in the user's own
      // language/script instead of always returning English.
      await setLocaleIdentifier(settings.localeIdentifier);
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      String city = 'Unknown Location';
      if (placemarks.isNotEmpty) {
        city = cityNameFrom(placemarks.first) ?? 'Unknown Location';
      }

      // Standing in (or near) Sukkur: the provider refuses to store it and
      // hands the timings back to the Jantri, so don't switch modes either.
      final accepted =
          await settings.setLocation(position.latitude, position.longitude, city);
      if (!accepted) {
        if (mounted) setState(() => _isLoading = false);
        _showUseJantriMessage(settings);
        return;
      }
      await settings.setLocationMode(LocationMode.world);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          '${settings.translate('Location updated: ', 'مقام اپڈیٹ ہو گیا: ', 'جڳهه اپڊيٽ ٿي وئي: ', 'تم تحديث الموقع: ')}$city'
        )));
      }
      _returnToTimings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          '${settings.translate('Error: ', 'خرابی: ', 'غلطي: ', 'خطأ: ')}${e.toString()}'
        )));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Opens the live city picker and applies whatever comes back.
  ///
  /// The picker itself never offers Sukkur, so a rejection here would mean the
  /// bundled list disagreed with [SukkurLocation] - handled anyway rather than
  /// trusted.
  Future<void> _pickCity(SettingsProvider settings) async {
    final chosen = await Navigator.of(context).push<CityResult>(
      MaterialPageRoute(builder: (_) => const CitySearchScreen()),
    );
    if (chosen == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final accepted = await settings.setLocation(
          chosen.latitude, chosen.longitude, chosen.name);
      if (!accepted) {
        if (mounted) setState(() => _isLoading = false);
        _showUseJantriMessage(settings);
        return;
      }
      await settings.setLocationMode(LocationMode.world);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          '${settings.translate('Location updated: ', 'مقام اپڈیٹ ہو گیا: ', 'جڳهه اپڊيٽ ٿي وئي: ', 'تم تحديث الموقع: ')}${chosen.name}'
        )));
      }
      _returnToTimings();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Hands the timings back to the city already on file. The provider refuses
  /// and erases it if that city turns out to be Sukkur from an older build, in
  /// which case there is nothing to switch to and the Jantri stands.
  Future<void> _useLastCity(SettingsProvider settings) async {
    final city = settings.cityName;
    final restored = await settings.useLastWorldCity();
    if (!mounted) return;
    if (!restored) {
      _showUseJantriMessage(settings);
      setState(() {});
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
      '${settings.translate('Location updated: ', 'مقام اپڈیٹ ہو گیا: ', 'جڳهه اپڊيٽ ٿي وئي: ', 'تم تحديث الموقع: ')}$city'
    )));
    _returnToTimings();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      appBar: AppBar(
        title: Text(settings.translate('World Prayer Timings', 'دنیا بھر کی نمازیں', 'دنيا جي نمازون', 'أوقات الصلاة العالمية')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Location Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: settings.displayThemeCard(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: settings.displayThemeCardBorder(isDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationSummary(settings, isDark, textColor),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isLoading ? null : () => _getCurrentLocation(settings),
                      icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(Icons.my_location),
                      label: Text(settings.translate('Get Current Location', 'موجودہ مقام حاصل کریں', 'موجودہ جڳھ حاصل ڪريو', 'الحصول على الموقع الحالي')),
                    ),
                  ),
                    
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black26)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(settings.translate('OR', 'یا', 'يا', 'أو')),
                      ),
                      Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black26)),
                    ],
                  ),
                  const SizedBox(height: 16),
                    
                  // Looks like a search field but opens the full-screen picker:
                  // the results list needs the whole screen, and typing here
                  // then jumping would lose the first letters.
                  InkWell(
                    onTap: _isLoading ? null : () => _pickCity(settings),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: settings.displayThemeCardBorder(isDark)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppTheme.accent, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              settings.translate(
                                  'Search any city in the world',
                                  'دنیا کا کوئی بھی شہر تلاش کریں',
                                  'دنيا جو ڪو به شهر ڳوليو',
                                  'ابحث عن أي مدينة في العالم'),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Only worth asking once a city is on file, and only shown when the
            // phone is somewhere else - in the city itself both answers give
            // the identical result, so the question would be noise.
            if (settings.hasStoredWorldCity && _clockOffsetMinutes(settings) != 0) ...[
              const SizedBox(height: 16),
              _buildAlertTimezoneCard(settings, isDark, textColor),
            ],

            const SizedBox(height: 16),

            // Calculation Methods
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: settings.displayThemeCard(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: settings.displayThemeCardBorder(isDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.translate('Calculation Parameters', 'حساب کے پیرامیٹرز', 'حساب جا پيرا ميٽرز', 'معلمات الحساب'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                    
                  Text(
                    settings.translate('Calculation Method', 'حساب کا طریقہ', 'حساب جو طريقو', 'طريقة الحساب'),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: settings.calculationMethod,
                    dropdownColor: settings.displayThemeCard(isDark),
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _calculationMethods.map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(settings.translate(m, m, m, m)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) settings.setCalculationMethod(val);
                    },
                  ),

                  const SizedBox(height: 16),
                    
                  Text(
                    settings.translate('Asr Juristic Method', 'عصر کا فقہی طریقہ', 'عصر جو فقهي طريقو', 'طريقة العصر الفقهية'),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: settings.asrMethod,
                    dropdownColor: settings.displayThemeCard(isDark),
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _asrMethods.map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(_asrMethodLabel(settings, m)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) settings.setAsrMethod(val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// How far the stored city's clock sits from the phone's, right now. Zero
  /// means the two agree and the alert-timezone question does not arise.
  int _clockOffsetMinutes(SettingsProvider settings) {
    final zone = settings.cityTimezone;
    final lng = settings.longitude;
    if (zone == null || lng == null) return 0;
    final cityOffset = WorldLocation.utcOffsetFor(zone, lng, DateTime.now());
    return (cityOffset - DateTime.now().timeZoneOffset).inMinutes;
  }

  String _offsetLabel(SettingsProvider settings) {
    final minutes = _clockOffsetMinutes(settings);
    final ahead = minutes > 0;
    final abs = minutes.abs();
    final hours = abs ~/ 60;
    final mins = abs % 60;
    final span = mins == 0 ? '$hours' : '$hours:${mins.toString().padLeft(2, '0')}';
    final city = settings.cityName ?? '';
    // Two separate translate() calls rather than one with a conditional key:
    // the coverage test only sees a literal first argument, and a key it cannot
    // see is a key that silently falls back to English for every world language.
    final template = ahead
        ? settings.translate(
            '{city} is {n} hours ahead of your phone.',
            '{city} آپ کے فون سے {n} گھنٹے آگے ہے۔',
            '{city} توهان جي فون کان {n} ڪلاڪ اڳتي آهي.',
            '{city} يسبق هاتفك بـ {n} ساعات.',
          )
        : settings.translate(
            '{city} is {n} hours behind your phone.',
            '{city} آپ کے فون سے {n} گھنٹے پیچھے ہے۔',
            '{city} توهان جي فون کان {n} ڪلاڪ پوئتي آهي.',
            '{city} يتأخر عن هاتفك بـ {n} ساعات.',
          );
    return template.replaceAll('{city}', city).replaceAll('{n}', span);
  }

  /// Which clock a watched city's alerts should ring on.
  ///
  /// The times on screen are the city's either way - this decides only the
  /// moment the phone buzzes, and what the countdown counts towards.
  Widget _buildAlertTimezoneCard(
      SettingsProvider settings, bool isDark, Color textColor) {
    final muted = isDark ? Colors.white54 : Colors.black54;
    final followsDevice = settings.worldAlertsFollowDevice;

    Widget option({
      required bool selected,
      required String title,
      required String detail,
      required VoidCallback onTap,
    }) =>
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppTheme.accent : muted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                      const SizedBox(height: 2),
                      Text(detail,
                          style: TextStyle(fontSize: 12, color: muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.displayThemeCard(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: settings.displayThemeCardBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.translate('Notification Time Zone', 'اطلاع کا ٹائم زون',
                'اطلاع جو ٽائم زون', 'المنطقة الزمنية للإشعار'),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent),
          ),
          const SizedBox(height: 6),
          Text(_offsetLabel(settings),
              style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 4),
          Text(
            settings.translate(
              'The times shown stay the same either way. This only decides when the notification rings.',
              'دکھائے گئے اوقات دونوں صورتوں میں ایک جیسے رہیں گے۔ اس سے صرف یہ طے ہوتا ہے کہ اطلاع کب بجے گی۔',
              'ڏيکاريل وقت ٻنهي صورتن ۾ ساڳيا رهندا. هن سان رڳو اهو طئي ٿيندو ته اطلاع ڪڏهن وڄندي.',
              'الأوقات المعروضة تبقى كما هي في الحالتين. هذا يحدد فقط وقت رنين الإشعار.',
            ),
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 12),
          option(
            selected: !followsDevice,
            title: settings.translate("City's time", 'شہر کا وقت', 'شهر جو وقت',
                'توقيت المدينة'),
            detail: settings.translate(
              'Rings at the real prayer moment in that city. Recommended.',
              'اس شہر میں نماز کے اصل وقت پر بجے گی۔ تجویز کردہ۔',
              'ان شهر ۾ نماز جي اصل وقت تي وڄندي. تجويز ڪيل.',
              'يرن في وقت الصلاة الحقيقي في تلك المدينة. موصى به.',
            ),
            onTap: () => settings.setWorldAlertsFollowDevice(false),
          ),
          option(
            selected: followsDevice,
            title: settings.translate("My phone's time", 'میرے فون کا وقت',
                'منهنجي فون جو وقت', 'توقيت هاتفي'),
            detail: settings.translate(
              'Rings at the time shown on screen, on your own clock.',
              'اسکرین پر دکھائے گئے وقت پر، آپ کی اپنی گھڑی کے مطابق بجے گی۔',
              'اسڪرين تي ڏيکاريل وقت تي، توهان جي پنهنجي گھڙي مطابق وڄندي.',
              'يرن في الوقت المعروض على الشاشة، حسب ساعتك.',
            ),
            onTap: () => settings.setWorldAlertsFollowDevice(true),
          ),
        ],
      ),
    );
  }

  /// Three states, one card header. The city on file outlives a switch back to
  /// the Jantri, so "stored" and "in charge" are separate questions:
  ///  - in charge            -> "Selected Location", plain.
  ///  - stored, not in charge -> "Last selected", plus a button to restore it.
  ///  - nothing stored       -> a line saying the Jantri is what's showing.
  ///
  /// Sukkur is never any of these: it cannot be stored, so it cannot appear.
  Widget _buildLocationSummary(
      SettingsProvider settings, bool isDark, Color textColor) {
    final city = settings.cityName;
    final active = settings.usesCalculatedTimings;
    final muted = isDark ? Colors.white54 : Colors.black54;

    if (!settings.hasStoredWorldCity || city == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.translate('Selected Location', 'منتخب مقام', 'چونڊيل جڳھ', 'الموقع المحدد'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accent),
          ),
          const SizedBox(height: 12),
          Text(
            settings.translate(
              'No city selected. Showing the Sukkur Jantri.',
              'کوئی شہر منتخب نہیں۔ سکھر جنتری دکھائی جا رہی ہے۔',
              'ڪو به شهر چونڊيل ناهي. سکر جنتري ڏيکاري پئي وڃي.',
              'لم يتم اختيار مدينة. يتم عرض جنتري سكر.',
            ),
            style: TextStyle(fontSize: 14, color: muted),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          active
              ? settings.translate('Selected Location', 'منتخب مقام', 'چونڊيل جڳھ', 'الموقع المحدد')
              : settings.translate('Last selected', 'آخری منتخب مقام', 'آخري چونڊيل جڳھ', 'آخر موقع محدد'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accent),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.location_on, color: active ? Colors.red : muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                city,
                style: TextStyle(
                  fontSize: 16,
                  color: active ? textColor : muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32, top: 4),
          child: Text(
            '${settings.latitude!.toStringAsFixed(4)}, ${settings.longitude!.toStringAsFixed(4)}',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ),
        if (!active) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              settings.translate(
                'Currently showing the Sukkur Jantri.',
                'اس وقت سکھر جنتری دکھائی جا رہی ہے۔',
                'هن وقت سکر جنتري ڏيکاري پئي وڃي.',
                'يتم عرض جنتري سكر حاليًا.',
              ),
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isLoading ? null : () => _useLastCity(settings),
              icon: const Icon(Icons.restore),
              // A placeholder rather than concatenation: languages differ on
              // where the city goes relative to the verb.
              label: Text(
                settings.translate(
                  'Use {city}',
                  '{city} استعمال کریں',
                  '{city} استعمال ڪريو',
                  'استخدم {city}',
                ).replaceAll('{city}', city),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
