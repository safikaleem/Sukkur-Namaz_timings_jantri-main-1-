import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class MosqueFinderScreen extends StatelessWidget {
  const MosqueFinderScreen({super.key});

  Future<void> _launchMapsSearch(BuildContext context, String query) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lat = settings.latitude;
    final lng = settings.longitude;

    final String urlString;
    if (lat != null && lng != null) {
      urlString = 'https://www.google.com/maps/search/?api=1&query=$query+near+$lat,$lng';
    } else {
      urlString = 'https://www.google.com/maps/search/?api=1&query=$query';
    }

    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                settings.translate(
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching maps: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = settings.language;
    final accent = const Color(0xFF2E7D32); // Emerald Green accent

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121619) : const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          settings.translate(
            'Nearby Mosque Finder',
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
                      ? [const Color(0xFF1B382B), const Color(0xFF11241C)]
                      : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
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
                    settings.translate(
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
                    settings.translate(
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
                    icon: const Icon(Icons.explore_rounded, color: Color(0xFF1B5E20)),
                    label: Text(
                      settings.translate(
                        'Open Nearby Mosques on Map',
                        'نقشے پر قریب ترین مساجد کھولیں',
                        'نقشي تي ويجهيون مسجدون کوليو',
                        'افتح الخريطة للمساجد القريبة',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1B5E20),
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
                settings.translate(
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
              title: settings.translate(
                'Jamia / Main Mosques',
                'جامع مساجد',
                'جامع مسجدون',
                'المساجد الجامعة',
              ),
              subtitle: settings.translate(
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
