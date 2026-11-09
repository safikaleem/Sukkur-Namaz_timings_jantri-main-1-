import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/pdf_mushaf_reader.dart';
import '../widgets/translation_reader.dart';
import '../data/quran_data.dart';
import '../data/quran_data_15_line.dart';

class QuranReaderScreen extends StatefulWidget {
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
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late String _titleEn;
  late String _titleArabic;
  late String _titleLocal;

  /// Mushaf page the reader opens at. The reader runs continuously from there
  /// across parah boundaries, so this is a starting point only.
  late final int _startPage;
  int _currentPage = 1;
  bool _isChromeVisible = true;
  Timer? _autoHideTimer;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _titleEn = widget.surahNameEn;
    _titleArabic = widget.surahNameArabic;
    _titleLocal = widget.surahNameLocal;
    final quranType = context.read<SettingsProvider>().quranType;
    final maxPages = quranType == '15_line' ? kQuran15LinePageCount : kQuranPageCount;
    _startPage = widget.initialPage.clamp(1, maxPages);
    _currentPage = _startPage;
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isChromeVisible) {
        setState(() => _isChromeVisible = false);
      }
    });
  }

  void _keepChromeVisible() {
    _autoHideTimer?.cancel();
    if (!_isChromeVisible) {
      setState(() => _isChromeVisible = true);
    }
  }

  void _toggleChrome() {
    setState(() {
      _isChromeVisible = !_isChromeVisible;
    });
    if (_isChromeVisible) {
      _startAutoHideTimer();
    } else {
      _autoHideTimer?.cancel();
    }
  }

  /// Retitles the screen when reading crosses into another parah - but only
  /// when it was opened as a parah in the first place.
  void _onParahChanged(int parah) {
    if (widget.parahNumber == null) return;
    if (parah >= 1 && parah <= QuranData.parahs.length) {
      final parahData = QuranData.parahs[parah - 1];
      final settings = context.read<SettingsProvider>();
      final parahWord = settings.translate('Parah', 'پارہ', 'پارو', 'جزء');
      final nameLocal = settings.translate(parahData.english, parahData.urdu, parahData.sindhi, parahData.arabic);
      setState(() {
        _titleEn = 'Parah ${parahData.number} – ${parahData.english}';
        _titleArabic = parahData.arabic;
        _titleLocal = '$parahWord ${parahData.number} – $nameLocal';
      });
    }
  }

  /// Retitles the screen when reading crosses into another surah in translation view.
  void _onSurahChanged(int surahNumber) {
    if (widget.parahNumber != null) return;
    if (surahNumber >= 1 && surahNumber <= QuranData.surahs.length) {
      final surahData = QuranData.surahs[surahNumber - 1];
      setState(() {
        _titleEn = surahData.english;
        _titleArabic = surahData.arabicOnly;
        _titleLocal = surahData.urdu;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final is15Line = settings.quranType == '15_line';
    final quranAccentColor = is15Line ? const Color(0xFF4C6A75) : AppTheme.accentGreen;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = 75.0 + 64.0 + topPadding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                settings.translate(
                  'Press back again to exit',
                  'بند کرنے کے لیے دوبارہ واپس جائیں',
                  'بند ڪرڻ لاءِ ٻيهر واپس وڃو',
                  'اضغط رجوع مرة أخرى للخروج',
                ),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: settings.displayThemeBg(isDark),
          body: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                height: _isChromeVisible ? headerHeight : 0.0,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.bottomCenter,
                    minHeight: 0,
                    maxHeight: headerHeight,
                    child: Container(
                      decoration: settings.getThemeDecoration(isDark),
                      child: SafeArea(
                        bottom: false,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTopToolbar(context, settings, isDark, quranAccentColor),
                              _buildTabBar(context, settings, isDark, quranAccentColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    PdfMushafReader(
                      settings: settings,
                      isDark: isDark,
                      initialPage: _startPage,
                      isChromeVisible: _isChromeVisible,
                      onToggleChrome: _toggleChrome,
                      onKeepChromeVisible: _keepChromeVisible,
                      onParahChanged: _onParahChanged,
                      onPageChanged: (page) {
                        if (_currentPage != page) {
                          setState(() {
                            _currentPage = page;
                          });
                        }
                        if (_isChromeVisible) {
                          _startAutoHideTimer();
                        }
                      },
                    ),
                    TranslationReader(
                      surahNumber: widget.surahNumber,
                      settings: settings,
                      isDark: isDark,
                      initialAyah: widget.initialAyah,
                      initialPage: _currentPage,
                      isChromeVisible: _isChromeVisible,
                      onToggleChrome: _toggleChrome,
                      onKeepChromeVisible: _keepChromeVisible,
                      onParahChanged: _onParahChanged,
                      onSurahChanged: _onSurahChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopToolbar(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    Color quranAccentColor,
  ) {
    return SizedBox(
      height: 75,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Material(
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_titleArabic.isNotEmpty)
                    Text(
                      _titleArabic,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: quranAccentColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: quranAccentColor.withValues(alpha: 0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    settings.language == 'english' ? _titleEn : _titleLocal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w500,
                      fontSize: _titleArabic.isNotEmpty ? 13 : 18,
                      fontFamily: settings.language == 'english' ? null : AppTheme.getFontForLanguage(context, settings.language),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    Color quranAccentColor,
  ) {
    return Container(
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
          color: quranAccentColor,
          boxShadow: [
            BoxShadow(
              color: quranAccentColor.withValues(alpha: 0.25),
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
              child: Text(
                settings.quranType == '15_line'
                    ? settings.translate('15 Line Quran', '15 سطر قرآن', '15 سٽر قرآن', 'القرآن 15 سطر')
                    : settings.translate('16 Line Quran', '16 سطر قرآن', '16 سٽر قرآن', 'القرآن 16 سطر'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Tab(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                settings.translate('Translation', 'ترجمہ', 'ترجمو', 'ترجمة'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
