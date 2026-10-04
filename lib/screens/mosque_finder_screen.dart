import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/world_translations.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class MosqueFinderScreen extends StatelessWidget {
  const MosqueFinderScreen({super.key});

  String _t(
    SettingsProvider settings,
    String key, [
    String? ur,
    String? sd,
    String? ar,
  ]) {
    final lang = settings.language;
    final map = worldTranslations[lang];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return settings.translate(key, ur ?? key, sd ?? ur ?? key, ar);
  }

  Future<void> _launchMapsSearch(BuildContext context, String query) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lat = settings.latitude;
    final lng = settings.longitude;

    final String queryText = (lat != null && lng != null)
        ? '$query near $lat,$lng'
        : query;

    final Uri httpsUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': queryText,
    });

    final Uri geoUri = Uri.parse(
      lat != null && lng != null
          ? 'geo:$lat,$lng?q=${Uri.encodeComponent(query)}'
          : 'geo:0,0?q=${Uri.encodeComponent(queryText)}',
    );

    bool launched = false;

    // 1. Try Google Maps HTTPS URL with external application mode
    try {
      launched = await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    // 2. Fallback to platform default launch mode
    if (!launched) {
      try {
        launched = await launchUrl(httpsUri, mode: LaunchMode.platformDefault);
      } catch (_) {
        launched = false;
      }
    }

    // 3. Fallback to geo: URI scheme
    if (!launched) {
      try {
        launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
    }

    // 4. Show SnackBar if map app or browser could not be launched
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              settings,
              'Could not open Maps app.',
              'نقشہ ایپ نہیں کھل سکی۔',
              'نقشو ايپ نه کلي سگهي.',
              'تعذر فتح تطبيق الخرائط.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = settings.language;
    const accent = Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121619) : const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          _t(
            settings,
            'Nearby Masjid Finder',
            'قریب ترین مساجد کی تلاش',
            'ويجهيون مسجدون ڳوليو',
            'مساجد قريبة',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Main Card Header ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E282A), const Color(0xFF151C1E)]
                      : [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : accent).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t(
                      settings,
                      'Find Mosques Near You',
                      'اپنے قریب ترین مساجد تلاش کریں',
                      'پنهنجي ويجهيون مسجدون ڳوليو',
                      'ابحث عن المساجد القريبة منك',
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      settings,
                      'Locate local Masjids for Congregational (Jama\'at) Prayers anywhere around the globe with live GPS directions.',
                      'دنیا بھر میں باجماعت نمازوں کے لیے اپنے قریبی مساجد کا راستہ دیکھیں۔',
                      'سڄي دنيا ۾ باجماعت نمازن لاءِ پنهنجي ويجهين مسجدن جو رستو ڏسو.',
                      'حدد موقع المساجد المحلية لصلاة الجماعة في أي مكان حول العالم مع الاتجاهات المباشرة.',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _launchMapsSearch(context, 'mosque'),
                    icon: const Icon(Icons.explore_rounded, color: Color(0xFF1B4332)),
                    label: Text(
                      _t(
                        settings,
                        'Open Nearby Mosques on Map',
                        'نقشے پر قریب ترین مساجد کھولیں',
                        'نقشي تي ويجهيون مسجدون کوليو',
                        'افتح الخريطة للمساجد القريبة',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1B4332),
                        fontFamily: AppTheme.getFontForLanguage(context, lang),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Quick Categories Grid ─────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _t(
                  settings,
                  'Quick Search Categories',
                  'فوری تلاش کے زمرے',
                  'فوري ڳولا جا زمره',
                  'فئات البحث السريع',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.getFontForLanguage(context, lang),
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildCategoryTile(
              context: context,
              icon: Icons.store_mall_directory_rounded,
              iconColor: const Color(0xFF1565C0),
              title: _t(
                settings,
                'Jamia / Main Mosques',
                'جامع مساجد',
                'جامع مسجدون',
                'المساجد الجامعة',
              ),
              subtitle: _t(
                settings,
                'Search for larger Jamia Masjids nearby',
                'قریبی بڑی جامع مساجد کی تلاش',
                'ويجهين وڏين جامع مسجدن جي ڳولا',
                'البحث عن المساجد الجامعة القريبة',
              ),
              onTap: () => _launchMapsSearch(context, 'Jamia+Mosque'),
              isDark: isDark,
              lang: lang,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required String lang,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2628) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppTheme.getFontForLanguage(context, lang),
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
