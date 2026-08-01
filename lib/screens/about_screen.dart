import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';
import '../widgets/dr_slogan_header.dart';
import '../l10n/about_translations.dart';
import '../utils/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _selectedTabIndex = 0;

  Future<void> _shareCurrentImage(BuildContext context) async {
    const assetPath = 'assets/images/about.jpeg';
    const fileName = 'about.jpeg';
    try {
      final bytes = await rootBundle.load(assetPath);
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/$fileName');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share image')),
        );
      }
    }
  }

  Widget _buildRichText(BuildContext context, String text, bool isDark, bool isRtl, SettingsProvider settings) {
    final fontFamily = AppTheme.getFontForLanguage(context, settings.language);
    final useLargerFont = settings.isUrdu;
    
    final defaultStyle = TextStyle(
      fontSize: useLargerFont ? 18 : 16,
      height: useLargerFont ? 2.0 : 1.6,
      color: isDark ? Colors.white70 : Colors.black87,
      fontFamily: fontFamily,
    );
    final boldStyle = defaultStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
    );

    List<TextSpan> spans = [];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: i % 2 == 1 ? boldStyle : defaultStyle,
      ));
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: RichText(
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        text: TextSpan(children: spans),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.isRtl;

    final isSukkur = settings.locationMode == LocationMode.sukkur;
    final aboutText = aboutTranslations[settings.language] ?? aboutTranslations['english']!;

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 0),
              child: SizedBox(
                height: 36,
                child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 20,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      settings.translate('About', 'ہمارے بارے میں', 'اسان بابت', 'عن التطبيق'),
                      style: TextStyle(
                        fontSize: isRtl ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    tooltip: settings.translate('Share', 'شیئر کریں', 'شيئر ڪريو', 'مشاركة'),
                    onPressed: () => _shareCurrentImage(context),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: DrSloganHeader(),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Toggle Bar ───────────────────────────────────────────────────
                    if (isSukkur)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black38 : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTabIndex = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: _selectedTabIndex == 0 ? AppTheme.accentGreen : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _selectedTabIndex == 0 ? [
                                        BoxShadow(
                                          color: AppTheme.accentGreen.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ] : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      settings.translate(
                                        'About Sukkur Salah app features',
                                        'سکھر صلاة ایپ کی خصوصیات کے بارے میں',
                                        'سکر صلاة ايپ جي خصوصيتن بابت',
                                        'حول ميزات تطبيق صلاة سكر'
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                        color: _selectedTabIndex == 0 ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                                        fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w600,
                                        fontSize: settings.isRtl ? 14 : 12.5,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTabIndex = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: _selectedTabIndex == 1 ? AppTheme.accentGreen : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _selectedTabIndex == 1 ? [
                                        BoxShadow(
                                          color: AppTheme.accentGreen.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ] : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      settings.translate(
                                        'About Sukkur Jantri',
                                        'سکھر جنتری کے بارے میں',
                                        'سکر جنتري بابت',
                                        'حول تقويم سكر'
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                        color: _selectedTabIndex == 1 ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                                        fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w600,
                                        fontSize: settings.isRtl ? 14 : 12.5,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── About Text ───────────────────────────────────────────────────
                    if (!isSukkur || _selectedTabIndex == 0)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.fromLTRB(20, 8, 20, isSukkur ? 8 : 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: settings.displayThemeCard(isDark),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: settings.displayThemeCardBorder(isDark),
                            width: 1,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: _buildRichText(context, aboutText, isDark, isRtl, settings),
                      ),

                    // ── Image Card Container ───────────────────────────────────────────────────
                    if (isSukkur && _selectedTabIndex == 1) ...[
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        decoration: BoxDecoration(
                          color: settings.displayThemeCard(isDark),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: settings.displayThemeCardBorder(isDark),
                            width: 1,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 4.0,
                            child: Image.asset(
                              'assets/images/about.jpeg',
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return frame != null
                                    ? child
                                    : const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(32.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                              },
                            ),
                          ),
                        ),
                      ),
                      // ── Pinch to Zoom Hint ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.zoom_in_rounded,
                              size: 16,
                              color: isDark ? Colors.white30 : Colors.black38,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              settings.translate(
                                'Pinch to zoom',
                                'زوم کرنے کے لیے پنچ کریں',
                                'زوم ڪرڻ لاءِ پنچ ڪريو',
                                'قرّب إصبعيك للتكبير',
                              ),
                              style: TextStyle(
                                fontSize: settings.isRtl ? 13 : 11,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
