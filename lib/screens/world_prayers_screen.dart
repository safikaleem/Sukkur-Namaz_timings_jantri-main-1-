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

  final List<String> _asrMethods = ['Hanafi', 'Shafi'];

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
      
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String city = 'Unknown Location';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? p.country ?? 'Unknown Location';
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

    final q = query.toLowerCase();
    if (q.contains('sukkur') || q.contains('sukur') || q.contains('sukkar') || 
        q.contains('سکھر') || q.contains('سکر') || q.contains('سكر')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(settings.translate(
              'Please select Sukkur from the side bar!',
              'براہ کرم سائیڈ بار سے سکھر منتخب کریں!',
              'مھرباني ڪري سائيڊ بار مان سکر چونڊيو!',
              'يرجى تحديد سكر من القائمة الجانبية!'
            )),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
        String city = query;
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = p.locality ?? p.subAdministrativeArea ?? query;
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
                        child: Text(m == 'Hanafi' 
                            ? settings.translate('Hanafi', 'حنفی', 'حنفي', 'حنفي') 
                            : settings.translate('Shafi / Standard', 'شافعی / معیاری', 'شافعي / معياري', 'شافعي / قياسي')),
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
