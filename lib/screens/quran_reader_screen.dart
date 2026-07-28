import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/pdf_mushaf_reader.dart';
import '../widgets/translation_reader.dart';
import '../data/quran_data.dart';

class QuranReaderScreen extends StatelessWidget {
  final int surahNumber;
  final String surahNameEn;
  final String surahNameArabic;
  final String surahNameLocal;
  final int initialPage;
  final int initialAyah;
  final int? parahNumber;

  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    required this.surahNameEn,
    this.surahNameArabic = '',
    required this.surahNameLocal,
    this.initialPage = 1,
    this.initialAyah = 1,
    this.parahNumber,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.isRtl;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: settings.displayThemeBg(isDark),
        appBar: AppBar(
          toolbarHeight: 75,
          flexibleSpace: Container(
            decoration: settings.getThemeDecoration(isDark),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Icon(
                      Icons.arrow_back_ios, 
                      color: isDark ? Colors.white : Colors.black87, 
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (surahNameArabic.isNotEmpty)
                Text(
                  surahNameArabic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: AppTheme.accentGreen.withValues(alpha: 0.15),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                isRtl ? surahNameLocal : surahNameEn,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                  fontSize: surahNameArabic.isNotEmpty ? 13 : 18,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? Colors.black38 : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                ),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.accentGreen,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.3),
                tabs: [
                  Tab(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(settings.translate('16 Lines Tajweed Quran', '16 لائن تجوید قرآن', '16 لائين تجويد قرآن', '16 سطر تجويد القرآن')),
                    ),
                  ),
                  Tab(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(settings.translate('Translation', 'ترجمہ', 'ترجمو', 'ترجمة')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Builder(
          builder: (context) {
            final int pNum = parahNumber ?? QuranData.getParahForPage(initialPage);
            int pdfStartPage = (pNum == 1) ? 1 : QuranData.parahs[pNum - 1].startPage;
            int localPage = initialPage - pdfStartPage + 1;
            if (localPage < 1) localPage = 1;
            
            return TabBarView(
              children: [
                PdfMushafReader(
                  settings: settings, 
                  isDark: isDark, 
                  initialPage: localPage,
                  parahNumber: pNum,
                ),
                TranslationReader(surahNumber: surahNumber, settings: settings, isDark: isDark, initialAyah: initialAyah),
              ],
            );
          }
        ),
      ),
    );
  }
}
