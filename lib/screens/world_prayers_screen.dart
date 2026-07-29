import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/sukkur_header.dart';

class WorldPrayersScreen extends StatefulWidget {
  const WorldPrayersScreen({super.key});

  @override
  State<WorldPrayersScreen> createState() => _WorldPrayersScreenState();
}

class _WorldPrayersScreenState extends State<WorldPrayersScreen> {
  final TextEditingController _cityController = TextEditingController();
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

  // Sukkur has its own Jantri, so the calculated world timings must never
  // silently replace it - not by name, and not by standing in the city.
  static const _sukkurLat = 27.7052;
  static const _sukkurLng = 68.8574;
  // 20 km covers Sukkur, New Sukkur and Rohri across the river, while leaving
  // genuinely separate cities like Khairpur (~22 km) free to be selected.
  static const _sukkurRadiusMetres = 20000.0;

  static const _sukkurNames = [
    'sukkur', 'sukur', 'sukkar', 'sakkhar', 'سکھر', 'سکر', 'سكر',
  ];

  bool _looksLikeSukkur(String? name) {
    if (name == null) return false;
    final n = name.toLowerCase();
    return _sukkurNames.any(n.contains);
  }

  bool _isNearSukkur(double lat, double lng) =>
      Geolocator.distanceBetween(lat, lng, _sukkurLat, _sukkurLng) <=
      _sukkurRadiusMetres;

  /// Shown instead of switching to calculated timings, in every language.
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
        final p = placemarks.first;
        city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? p.country ?? 'Unknown Location';
      }

      // Standing in (or near) Sukkur: keep the Jantri, don't switch modes.
      if (_looksLikeSukkur(city) ||
          _isNearSukkur(position.latitude, position.longitude)) {
        setState(() => _isLoading = false);
        _showUseJantriMessage(settings);
        return;
      }

      await settings.setLocation(position.latitude, position.longitude, city);
      await settings.setLocationMode(LocationMode.world);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          '${settings.translate('Location updated: ', 'مقام اپڈیٹ ہو گیا: ', 'جڳهه اپڊيٽ ٿي وئي: ', 'تم تحديث الموقع: ')}$city'
        )));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          '${settings.translate('Error: ', 'خرابی: ', 'غلطي: ', 'خطأ: ')}${e.toString()}'
        )));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCity(SettingsProvider settings) async {
    final query = _cityController.text.trim();
    if (query.isEmpty) return;

    if (_looksLikeSukkur(query)) {
      _showUseJantriMessage(settings);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await setLocaleIdentifier(settings.localeIdentifier);
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        List<Placemark> placemarks = await placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        );
        String city = query;
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = p.locality ?? p.subAdministrativeArea ?? query;
        }

        // The typed word passed the name check, but the place it resolved to
        // may still be Sukkur or a town right beside it.
        if (_looksLikeSukkur(city) ||
            _isNearSukkur(loc.latitude, loc.longitude)) {
          setState(() => _isLoading = false);
          _showUseJantriMessage(settings);
          return;
        }

        await settings.setLocation(loc.latitude, loc.longitude, city);
        await settings.setLocationMode(LocationMode.world);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            '${settings.translate('Location updated: ', 'مقام اپڈیٹ ہو گیا: ', 'جڳهه اپڊيٽ ٿي وئي: ', 'تم تحديث الموقع: ')}$city'
          )));
          _cityController.clear();
        }
      } else {
        throw Exception('Location not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          '${settings.translate('Could not find location: ', 'مقام نہیں مل سکا: ', 'جڳهه نه ملي سگهي: ', 'تعذر العثور على الموقع: ')}$query'
        )));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
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
            // Mode Selection
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
                    settings.translate('Location Mode', 'مقام کا انتخاب', 'جڳھ جي چونڊ', 'وضع الموقع'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<LocationMode>(
                    title: Text(settings.translate('Sukkur (Jantri)', 'سکھر (جنتری)', 'سکر (جنتري)', 'سكر (جنتري)')),
                    subtitle: Text(settings.translate('(Based on Hazrat Dr Hafeezullah Qaddasallahu sirrahu Jantri)', '(بمطابق حضرت ڈاکٹر حفیظ اللہ صاحب قدس اللہ سرہ جنتری)', '(حضرت ڊاڪٽر حفيظ الله صاحب قدس الله سره جي جنتري مطابق)', '(بناءً على تقويم الشيخ الدكتور حفيظ الله قدس الله سره)')),
                    value: LocationMode.sukkur,
                    groupValue: settings.locationMode,
                    activeColor: AppTheme.accent,
                    onChanged: (mode) {
                      if (mode != null) settings.setLocationMode(mode);
                    },
                  ),
                  RadioListTile<LocationMode>(
                    title: Text(settings.translate('World (Calculated)', 'دنیا (خودکار حساب)', 'دنيا (خودڪار حساب)', 'عالمي (محسوب)')),
                    subtitle: Text(settings.translate('Calculate timings for any city worldwide', 'دنیا کے کسی بھی شہر کے لیے اوقات کا حساب لگائیں', 'دنيا جي ڪنهن به شهر لاءِ وقتن جو حساب لڳايو', 'حساب الأوقات لأي مدينة في العالم')),
                    value: LocationMode.world,
                    groupValue: settings.locationMode,
                    activeColor: AppTheme.accent,
                    onChanged: (mode) {
                      if (mode != null) settings.setLocationMode(mode);
                    },
                  ),
                ],
              ),
            ),

            if (settings.locationMode == LocationMode.world) ...[
              const SizedBox(height: 16),
              
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
                    Text(
                      settings.translate('Selected Location', 'منتخب مقام', 'چونڊيل جڳھ', 'الموقع المحدد'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            settings.cityName ?? 'None',
                            style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (settings.latitude != null && settings.longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4),
                        child: Text(
                          '${settings.latitude!.toStringAsFixed(4)}, ${settings.longitude!.toStringAsFixed(4)}',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                        ),
                      ),
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
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: settings.translate('Enter city name (e.g., London)', 'شہر کا نام درج کریں', 'شهر جو نالو لکو', 'أدخل اسم المدينة'),
                              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: settings.displayThemeCardBorder(isDark)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: settings.displayThemeCardBorder(isDark)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _isLoading ? null : () => _searchCity(settings),
                          icon: const Icon(Icons.search),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
          ],
        ),
      ),
    );
  }
}
