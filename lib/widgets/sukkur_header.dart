import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../screens/city_search_screen.dart';
import '../services/city_localizer.dart';
import '../services/city_search.dart';
import '../utils/app_theme.dart';

/// The city shown in the header and in the monthly month strip: just the city
/// name, or the chosen city when the app is in world-location mode.
String locationLabel(SettingsProvider settings) {
  if (settings.usesCalculatedTimings &&
      settings.cityName != null &&
      settings.locationMode != LocationMode.sukkur) {
    return CityLocalizer.localize(settings.cityName!, settings.language);
  }
  return settings.translate('Sukkur', 'سکھر', 'سکر', 'سكر');
}

class SukkurHeader extends StatelessWidget {
  const SukkurHeader({super.key});

  static String _tChooseLocation(String lang) {
    switch (lang) {
      case 'urdu': return 'مقام منتخب کریں';
      case 'sindhi': return 'مقام چونڊيو';
      case 'arabic': return 'اختر الموقع';
      case 'persian': return 'انتخاب مکان';
      case 'hindi': return 'स्थान चुनें';
      case 'bengali': return 'অবস্থান নির্বাচন করুন';
      case 'turkish': return 'Konum Seçin';
      case 'french': return 'Choisir l\'emplacement';
      case 'indonesian': return 'Pilih Lokasi';
      case 'english':
      default: return 'Choose location';
    }
  }

  Future<void> _openCitySearch(BuildContext context, SettingsProvider settings) async {
    final chosen = await Navigator.of(context).push<CityResult>(
      MaterialPageRoute(builder: (_) => const CitySearchScreen()),
    );
    if (chosen == null || !context.mounted) return;

    if (SukkurLocation.covers(chosen.latitude, chosen.longitude, chosen.name) ||
        chosen.name.toLowerCase() == 'sukkur' ||
        chosen.name == 'سکھر') {
      await settings.useSukkurJantri();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          settings.translate(
            'Sukkur selected – Sukkur Jantri of Hazrat Dr. Hafeezullah Sahib activated',
            'سکھر کا انتخاب ہو گیا – حضرت ڈاکٹر حفیظ اللہ صاحب کی سکھر جنتری فعال کر دی گئی',
            'سکر جو چونڊ ٿيو – حضرت ڊاڪٽر حفيظ الله صاحب جي سکر جنتري فعال ڪئي وئي',
            'تم اختيار سكر - تم تفعيل تقويم سكر للشيخ الدكتور حفيظ الله',
          ),
        )));
      }
      return;
    }

    final accepted = await settings.setLocation(chosen.latitude, chosen.longitude, chosen.name);
    if (!accepted) return;
    await settings.setLocationMode(LocationMode.world);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        '${settings.translate('Location updated: ', 'مقام اپڈیٹ ہو گیا: ', 'جڳهه اپڊيٽ ٿي وئي: ', 'تم تحديث الموقع: ')}${chosen.name}',
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = locationLabel(settings);
    final isLong = label.length > 20;

    return InkWell(
      onTap: () => _openCitySearch(context, settings),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(
                    Icons.location_on,
                    size: isLong ? 18 : 20,
                    color: isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                      fontSize: isLong
                          ? (isRtl ? 20 : 17)
                          : (isRtl ? 28 : 24),
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              _tChooseLocation(settings.language),
              style: TextStyle(
                fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
                decoration: TextDecoration.underline,
                decorationColor: isDark ? Colors.white38 : Colors.black38,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
