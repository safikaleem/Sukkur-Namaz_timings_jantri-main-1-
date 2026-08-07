import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_reader_screen.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../data/quran_data.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _surahSearchController = TextEditingController();
  final TextEditingController _parahSearchController = TextEditingController();
  String _surahQuery = '';
  String _parahQuery = '';

  /// Separates the parts of a surah's subtitle. In the Nastaleeq/Arabic fonts a
  /// bullet renders as a small round dot indistinguishable from the digit zero,
  /// so "۸ آیات" read as "۸۰" - eight ayahs looking like eighty. RTL languages
  /// get an Arabic comma instead, which cannot be mistaken for a digit.
  String get _metaSeparator =>
      context.read<SettingsProvider>().isRtl ? '، ' : ' • ';

  /// Search field + column headers collapse while the user scrolls further
  /// down the list, and come back as soon as they scroll the other way.
  bool _chromeVisible = true;

  bool _onListScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    // Direction is checked first: the gesture's UserScrollNotification arrives
    // while pixels is still 0, so an "always show at the top" rule placed ahead
    // of this would swallow every hide.
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          notification.metrics.maxScrollExtent > 0 &&
          _chromeVisible) {
        setState(() => _chromeVisible = false);
      } else if (notification.direction == ScrollDirection.forward &&
          !_chromeVisible) {
        setState(() => _chromeVisible = true);
      }
      return false;
    }

    // Settled back at the very top: the header belongs on screen again.
    if (!_chromeVisible && notification.metrics.pixels <= 0) {
      setState(() => _chromeVisible = true);
    }
    return false;
  }

  /// Wraps the search field and column headers so they collapse away smoothly.
  /// [keepVisible] pins them open - hiding the search box while a query is
  /// active would strand the user with a filtered list and no way to see why.
  Widget _collapsibleChrome({
    required List<Widget> children,
    required bool keepVisible,
  }) {
    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.bottomCenter,
        child: (_chromeVisible || keepVisible)
            ? Column(mainAxisSize: MainAxisSize.min, children: children)
            : const SizedBox(width: double.infinity),
      ),
    );
  }
  List<int> _favoriteSurahs = [];
  List<int> _favoriteParahs = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favSurahs = prefs.getStringList('favorite_surahs') ?? [];
    final favParahs = prefs.getStringList('favorite_parahs') ?? [];
    setState(() {
      _favoriteSurahs = favSurahs.map((e) => int.tryParse(e) ?? 0).toList();
      _favoriteParahs = favParahs.map((e) => int.tryParse(e) ?? 0).toList();
    });
  }

  List<dynamic> get _favoriteItems {
    final List<dynamic> favs = [];
    for (int pNum in _favoriteParahs) {
      favs.add(QuranData.parahs.firstWhere((p) => p.number == pNum, orElse: () => QuranData.parahs.first));
    }
    for (int sNum in _favoriteSurahs) {
      favs.add(QuranData.surahs.firstWhere((s) => s.number == sNum, orElse: () => QuranData.surahs.first));
    }
    return favs;
  }

  Future<void> _toggleSurahFavorite(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteSurahs.contains(surahNumber)) {
        _favoriteSurahs.remove(surahNumber);
      } else {
        _favoriteSurahs.add(surahNumber);
      }
    });
    await prefs.setStringList(
        'favorite_surahs', _favoriteSurahs.map((e) => e.toString()).toList());
  }

  Future<void> _toggleParahFavorite(int parahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteParahs.contains(parahNumber)) {
        _favoriteParahs.remove(parahNumber);
      } else {
        _favoriteParahs.add(parahNumber);
      }
    });
    await prefs.setStringList(
        'favorite_parahs', _favoriteParahs.map((e) => e.toString()).toList());
  }

  @override
  void dispose() {
    _surahSearchController.dispose();
    _parahSearchController.dispose();
    super.dispose();
  }

  // ── Filtered lists ────────────────────────────────────────────────────────────
  List<Surah> get _filteredSurahs {
    if (_surahQuery.isEmpty) return QuranData.surahs;
    final q = _surahQuery.toLowerCase();
    return QuranData.surahs.where((s) =>
      s.english.toLowerCase().contains(q) ||
      s.arabic.contains(q) ||
      s.urdu.contains(q) ||
      s.sindhi.contains(q) ||
      s.number.toString() == q
    ).toList();
  }

  List<Parah> get _filteredParahs {
    if (_parahQuery.isEmpty) return QuranData.parahs;
    final q = _parahQuery.toLowerCase();
    return QuranData.parahs.where((p) =>
      p.english.toLowerCase().contains(q) ||
      p.arabic.contains(q) ||
      p.urdu.contains(q) ||
      p.number.toString() == q
    ).toList();
  }

  // ── Navigation ────────────────────────────────────────────────────────────────
  void _openSurah(int number, String enName, String arabicName, String localName) {
    final settings = context.read<SettingsProvider>();
    int savedAyah = settings.surahProgress[number] ?? 1;
    if (savedAyah < 1) savedAyah = 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(
          surahNumber: number,
          surahNameEn: enName,
          surahNameArabic: arabicName,
          surahNameLocal: localName,
          initialPage: QuranData.surahStartPages[number] ?? 1,
          initialAyah: savedAyah,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openParah(Parah parah, [int? specificPage, int? specificSurahId, int? specificAyahId]) {
    final settings = context.read<SettingsProvider>();
    int savedPage = specificPage ?? (settings.parahProgress[parah.number] ?? parah.startPage);
    if (savedPage < parah.startPage) savedPage = parah.startPage;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(
          surahNumber: specificSurahId ?? parah.surahId,
          surahNameEn: 'Parah ${parah.number} – ${parah.english}',
          surahNameArabic: parah.arabic,
          surahNameLocal: 'پارہ ${parah.number}',
          initialPage: savedPage,
          initialAyah: specificAyahId ?? parah.ayahId,
          parahNumber: parah.number,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final parahTab    = settings.translate('Parah',    'پارہ',     'پارو',     'جزء');
    final surahTab    = settings.translate('Surah',    'سورۃ',     'سورت',     'سورة');
    final favoriteTab = settings.translate('Favorite', 'پسندیدہ', 'پسنديده', 'المفضلة');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        body: Column(
          children: [
            const SizedBox(height: 52), // Space for the floating hamburger menu
            _buildContinueReading(context, settings, isDark),
            TabBar(
              indicatorColor: AppTheme.accent,
              indicatorWeight: 3.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppTheme.accent,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(12),
              tabs: [
                Tab(text: parahTab),
                Tab(text: surahTab),
                Tab(text: favoriteTab),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildParahList(context, settings, isDark),
                  _buildSurahList(context, settings, isDark),
                  _buildFavoriteTab(context, settings, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueReading(BuildContext context, SettingsProvider settings, bool isDark) {
    if (settings.lastReadType == null || settings.lastReadId == null) {
      return const SizedBox.shrink();
    }

    final type = settings.lastReadType!;
    final id = settings.lastReadId!;

    String titleEn = '';
    String titleLocal = '';
    String subtitle = '';
    int progressPercent = 0;
    VoidCallback onTap = () {};

    if (type == 'surah') {
      final surah = QuranData.surahs.firstWhere((s) => s.number == id, orElse: () => QuranData.surahs.first);
      titleEn = surah.english;
      titleLocal = settings.isUrdu ? surah.urdu : (settings.isSindhi ? surah.sindhi : surah.arabic);
      int ayahsRead = settings.surahProgress[id] ?? 0;
      int totalAyahs = surah.totalAyahs;
      subtitle = '${settings.translate("Verse", "آیت", "آيت", "آية")} $ayahsRead ${settings.translate("of", "میں سے", "مان", "من")} $totalAyahs';
      progressPercent = totalAyahs > 0 ? ((ayahsRead / totalAyahs) * 100).toInt() : 0;
      onTap = () {
        _openSurah(surah.number, surah.english, surah.arabic, titleLocal);
      };
    } else {
      final parah = QuranData.parahs.firstWhere((p) => p.number == id, orElse: () => QuranData.parahs.first);
      titleEn = parah.english;
      titleLocal = parah.arabic;
      int pagesRead = settings.parahProgress[id] ?? parah.startPage;
      
      int totalPages = 0;
      if (parah.number == 30) {
        totalPages = 604 - parah.startPage + 1;
      } else {
        totalPages = QuranData.parahs[parah.number].startPage - parah.startPage; 
      }
      int pagesDone = pagesRead - parah.startPage + 1;
      if (pagesDone < 0) pagesDone = 0;
      if (pagesDone > totalPages) pagesDone = totalPages;
      
      subtitle = '${settings.translate("Page", "صفحہ", "صفحو", "صفحة")} $pagesRead';
      progressPercent = totalPages > 0 ? ((pagesDone / totalPages) * 100).toInt() : 0;
      onTap = () {
        _openParah(parah);
      };
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF00695C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00695C).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.translate('CONTINUE READING', 'پڑھنا جاری رکھیں', 'پڙهڻ جاري رکو', 'مواصلة القراءة').toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: settings.language == 'english' ? 10 : 12,
                                    fontFamily: settings.language == 'english' ? null : AppTheme.getFontForLanguage(context, settings.language),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: settings.language == 'english' ? 1.5 : 0.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  settings.language == 'english' ? titleEn : titleLocal,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: settings.language == 'english' ? 20 : 22,
                                    fontFamily: settings.language == 'english' ? null : AppTheme.urduFont,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: settings.language == 'english' ? 13 : 15,
                                    fontFamily: settings.language == 'english' ? null : AppTheme.getFontForLanguage(context, settings.language),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (settings.language == 'english')
                            Text(
                              titleLocal,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100.0,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Search bar widget ─────────────────────────────────────────────────────────
  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.accent),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: isDark ? Colors.white54 : Colors.black45, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF2B2C33) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Parah list ────────────────────────────────────────────────────────────────
  Widget _buildParahList(BuildContext context, SettingsProvider settings, bool isDark) {
    final filtered = _filteredParahs;
    final searchHint = settings.translate('Search Parah...', 'پارہ تلاش کریں...', 'پارو ڳولھيو...', 'ابحث عن الجزء...');

    return Column(
      children: [
        _collapsibleChrome(
          keepVisible: _parahQuery.isNotEmpty,
          children: [
            _buildSearchBar(
              controller: _parahSearchController,
              hint: searchHint,
              isDark: isDark,
              onChanged: (v) => setState(() => _parahQuery = v),
            ),
            _buildHeaderRow(settings),
          ],
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    settings.translate('No Parah found', 'کوئی پارہ نہیں ملا', 'ڪو پارو نه مليو', 'لم يتم العثور على جزء'),
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: _onListScroll,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final parah = filtered[index];
                      final isFav = _favoriteParahs.contains(parah.number);
                      return _buildParahTile(parah, isFav, isDark, settings);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(SettingsProvider settings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF00897B),
        borderRadius: BorderRadius.circular(24.0),
      ),
      // Every label is scaled down to fit rather than allowed to wrap: these
      // are one-word column headings, and at a large font setting the fixed
      // widths below are narrower than the words themselves - which is how
      // "Name" came to render as "Nam" over "e".
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: _HeaderLabel(
              settings.translate('No.', 'نمبر', 'نمبر', 'رقم'),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _HeaderLabel(
              settings.translate('Name', 'نام', 'نالو', 'الاسم'),
              fontSize: 15,
              alignment: AlignmentDirectional.centerStart,
            ),
          ),
          SizedBox(
            width: 40,
            child: _HeaderLabel(
              settings.translate('Read', 'پڑھیں', 'پڙهو', 'اقرأ'),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 75,
            child: _HeaderLabel(
              settings.translate('Page', 'صفحہ', 'صفحو', 'صفحة'),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  String _translateNumber(int number, SettingsProvider settings) {
    if (settings.language == 'english') return number.toString();
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String numStr = number.toString();
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], arabic[i]);
    }
    return numStr;
  }

  Widget _buildParahTile(Parah parah, bool isFav, bool isDark, SettingsProvider settings) {
    int totalPages = 0;
    if (parah.number == 30) {
      totalPages = 604 - parah.startPage + 1;
    } else {
      totalPages = QuranData.parahs[parah.number].startPage - parah.startPage; 
    }
    int pagesRead = (settings.parahProgress[parah.number] ?? 0) - parah.startPage + 1;
    if (pagesRead < 0) pagesRead = 0;
    if (pagesRead > totalPages) pagesRead = totalPages;
    final int parahPercent = totalPages > 0 ? ((pagesRead / totalPages) * 100).toInt() : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2C33) : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showQuarterSelectionSheet(context, parah, settings, isDark),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Directionality(
                    textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                    child: Row(
                      children: [
                        // Image Avatar
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: AppTheme.accent.withValues(alpha: 0.1),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/Q-logo.webp'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              left: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? const Color(0xFF2B2C33) : Colors.white, width: 2),
                                ),
                                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                alignment: Alignment.center,
                                child: Text(
                                  _translateNumber(parah.number, settings),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Arabic and English Name
                        Expanded(
                          flex: _kNameFlex,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  parah.arabic,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                parah.english,
                                // Wrap by word, never mid-word, and stop at two
                                // lines rather than growing the row.
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _TilePills(
                          percentLabel: '${_translateNumber(parahPercent, settings)}%',
                          pageLabel:
                              '${settings.translate("Page", "صفحہ", "صفحو", "صفحة")} ${_translateNumber(parah.startPage, settings)}',
                        ),
                        const SizedBox(width: 12),
                        // Favorite Icon
                        GestureDetector(
                          onTap: () => _toggleParahFavorite(parah.number),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? Colors.redAccent : (isDark ? Colors.white24 : Colors.black26),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Sleek Progress Bar at the bottom
                if (parahPercent > 0)
                  LinearProgressIndicator(
                    value: parahPercent / 100.0,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent.withValues(alpha: 0.8)),
                    minHeight: 3,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuarterSelectionSheet(BuildContext context, Parah parah, SettingsProvider settings, bool isDark) {
    int totalPages = 0;
    if (parah.number == 30) {
      totalPages = 604 - parah.startPage + 1;
    } else {
      totalPages = QuranData.parahs[parah.number].startPage - parah.startPage;
    }

    int startPage = parah.startPage;
    int arbaPage = parah.arba.page > 0 ? parah.arba.page : startPage + (totalPages * 0.25).toInt();
    int nisfPage = parah.nisf.page > 0 ? parah.nisf.page : startPage + (totalPages * 0.50).toInt();
    int slasaPage = parah.salasa.page > 0 ? parah.salasa.page : startPage + (totalPages * 0.75).toInt();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF00897B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: const Icon(Icons.view_quilt_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.translate('Select Quarter', 'کوارٹر منتخب کریں', 'ڪوارٽر چونڊيو', 'حدد الربع'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${settings.translate('Parah', 'پارہ', 'پاره', 'الجزء')} ${parah.number} — ${settings.translate(parah.english, parah.urdu, parah.sindhi, parah.arabic)}${settings.isRtl ? '' : ' (${parah.arabic})'}',
                            textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: settings.isRtl ? 15 : 13,
                              fontFamily: settings.isRtl 
                                  ? (settings.language == 'sindhi' ? AppTheme.getSindhiFont(context) : AppTheme.urduFont) 
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // List Options
              _buildQuarterOption(context, settings, isDark, 
                title: settings.translate('Start', 'شروع', 'شروع', 'البداية'),
                subtitle: settings.translate('Beginning of the Para', 'پارے کی شروعات', 'پاري جي شروعات', 'بداية الجزء'),
                page: startPage,
                icon: Icons.play_arrow_rounded,
                iconColor: const Color(0xFF00897B),
                onTap: () {
                  Navigator.pop(context);
                  _openParah(parah, startPage);
                },
              ),
              const Divider(height: 1, thickness: 1, indent: 72, endIndent: 20),
              
              _buildQuarterOption(context, settings, isDark, 
                title: settings.translate('Arba (1/4)', 'ربع (1/4)', 'ربع (1/4)', 'الربع (1/4)'),
                subtitle: settings.translate('First quarter', 'پہلا کوارٹر', 'پهريون ڪوارٽر', 'الربع الأول'),
                page: arbaPage,
                icon: Icons.looks_one_rounded,
                iconColor: const Color(0xFF00897B),
                onTap: () {
                  Navigator.pop(context);
                  _openParah(parah, arbaPage, parah.arba.surahId, parah.arba.ayahId);
                },
              ),
              const Divider(height: 1, thickness: 1, indent: 72, endIndent: 20),
              
              _buildQuarterOption(context, settings, isDark, 
                title: settings.translate('Nisf (1/2)', 'نصف (1/2)', 'نصف (1/2)', 'النصف (1/2)'),
                subtitle: settings.translate('Half', 'آدھا', 'اڌ', 'النصف'),
                page: nisfPage,
                icon: Icons.looks_two_rounded,
                iconColor: const Color(0xFF00897B),
                onTap: () {
                  Navigator.pop(context);
                  _openParah(parah, nisfPage, parah.nisf.surahId, parah.nisf.ayahId);
                },
              ),
              const Divider(height: 1, thickness: 1, indent: 72, endIndent: 20),
              
              _buildQuarterOption(context, settings, isDark, 
                title: settings.translate('Slasa (3/4)', 'ثلاثہ (3/4)', 'ثلاثہ (3/4)', 'الثلاثة (3/4)'),
                subtitle: settings.translate('Third quarter', 'تیسرا کوارٹر', 'ٽيون ڪوارٽر', 'الربع الثالث'),
                page: slasaPage,
                icon: Icons.looks_3_rounded,
                iconColor: const Color(0xFF00897B),
                onTap: () {
                  Navigator.pop(context);
                  _openParah(parah, slasaPage, parah.salasa.surahId, parah.salasa.ayahId);
                },
              ),
              
              // Cancel Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : const Color(0xFF00897B)),
                    label: Text(
                      settings.translate('Cancel', 'منسوخ کریں', 'منسوخ ڪريو', 'إلغاء'),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF00897B),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFE8F5E9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuarterOption(BuildContext context, SettingsProvider settings, bool isDark, {
    required String title,
    required String subtitle,
    required int page,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$page',
                style: const TextStyle(
                  color: Color(0xFF00897B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Surah list ────────────────────────────────────────────────────────────────
  Widget _buildSurahList(BuildContext context, SettingsProvider settings, bool isDark) {
    final filtered = _filteredSurahs;
    final searchHint = settings.translate('Search Surah...', 'سورۃ تلاش کریں...', 'سورت ڳولھيو...', 'ابحث عن السورة...');

    return Column(
      children: [
        _collapsibleChrome(
          keepVisible: _surahQuery.isNotEmpty,
          children: [
            _buildSearchBar(
              controller: _surahSearchController,
              hint: searchHint,
              isDark: isDark,
              onChanged: (v) => setState(() => _surahQuery = v),
            ),
            _buildHeaderRow(settings),
          ],
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    settings.translate('No Surahs found', 'کوئی سورۃ نہیں ملی', 'ڪا سورت نه ملي', 'لم يتم العثور على سورة'),
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: _onListScroll,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final surah = filtered[index];
                      final isFav = _favoriteSurahs.contains(surah.number);
                      return _buildSurahTile(surah, isFav, isDark, settings);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSurahTile(Surah surah, bool isFav, bool isDark, SettingsProvider settings) {
    int totalAyahs = surah.totalAyahs;
    int ayahsRead = settings.surahProgress[surah.number] ?? 0;
    if (ayahsRead < 0) ayahsRead = 0;
    if (ayahsRead > totalAyahs) ayahsRead = totalAyahs;
    final int surahPercent = totalAyahs > 0 ? ((ayahsRead / totalAyahs) * 100).toInt() : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2C33) : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final localName = settings.isUrdu
                  ? surah.urdu
                  : (settings.isSindhi
                      ? surah.sindhi
                      : (settings.isArabic ? surah.arabic : surah.english));
              _openSurah(surah.number, surah.english, surah.arabic, localName);
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Directionality(
                    textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                    child: Row(
                      children: [
                        // Image Avatar
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: AppTheme.accent.withValues(alpha: 0.1),
                                image: DecorationImage(
                                  image: AssetImage(surah.revelationType == 'Meccan' 
                                      ? 'assets/images/makkah.jpg' 
                                      : 'assets/images/madina.jpeg'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              left: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? const Color(0xFF2B2C33) : Colors.white, width: 2),
                                ),
                                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                alignment: Alignment.center,
                                child: Text(
                                  _translateNumber(surah.number, settings),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Arabic and English Name
                        Expanded(
                          flex: _kNameFlex,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  surah.arabic,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                                Text(
                                  '${surah.english}$_metaSeparator${surah.revelationType == 'Meccan' ? settings.translate('Makki', 'مکی', 'مڪي', 'مكية') : settings.translate('Madani', 'مدنی', 'مدني', 'مدنية')}$_metaSeparator${_translateNumber(surah.totalAyahs, settings)} ${settings.translate('Ayahs', 'آیات', 'آيتون', 'آيات')}',
                                  // Wrap by word, never mid-word, and stop at
                                  // two lines rather than growing the row.
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _TilePills(
                          percentLabel: '${_translateNumber(surahPercent, settings)}%',
                          pageLabel:
                              '${settings.translate("Page", "صفحہ", "صفحو", "صفحة")} ${_translateNumber(QuranData.surahStartPages[surah.number] ?? 1, settings)}',
                        ),
                        const SizedBox(width: 12),
                        // Favorite Icon
                        GestureDetector(
                          onTap: () => _toggleSurahFavorite(surah.number),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? Colors.redAccent : (isDark ? Colors.white24 : Colors.black26),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Sleek Progress Bar
                if (surahPercent > 0)
                  LinearProgressIndicator(
                    value: surahPercent / 100.0,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent.withValues(alpha: 0.8)),
                    minHeight: 3,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Favorite tab ──────────────────────────────────────────────────────────────
  Widget _buildFavoriteTab(BuildContext context, SettingsProvider settings, bool isDark) {
    final favSurahList = QuranData.surahs.where((s) => _favoriteSurahs.contains(s.number)).toList();
    final favParahList = QuranData.parahs.where((p) => _favoriteParahs.contains(p.number)).toList();

    if (favSurahList.isEmpty && favParahList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 56, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text(
              settings.translate(
                'No favorites yet.\nTap ♡ on any Surah or Parah.',
                'ابھی کوئی پسندیدہ نہیں۔\nکسی بھی سورۃ یا پارہ پر ♡ دبائیں۔',
                'اڃا ڪو پسنديده ناهي.\nڪنهن به سورت يا پاري تي ♡ کي ڇهيو.',
                'لا مفضلات بعد.\nاضغط ♡ على أي سورة أو جزء.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        // ── Favorite Parahs ──
        if (favParahList.isNotEmpty) ...[
          _buildSectionLabel(
            settings.translate('Parahs', 'پارے', 'پارا', 'أجزاء'),
            isDark,
          ),
          ...favParahList.map((p) => _buildParahTile(p, true, isDark, settings)),
        ],

        // ── Favorite Surahs ──
        if (favSurahList.isNotEmpty) ...[
          if (favParahList.isNotEmpty) const SizedBox(height: 8),
          _buildSectionLabel(
            settings.translate('Surahs', 'سورتیں', 'سورتون', 'سور'),
            isDark,
          ),
          ...favSurahList.map((s) => _buildSurahTile(s, true, isDark, settings)),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.accent,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// A single-word column heading that shrinks to fit instead of wrapping.
class _HeaderLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  final AlignmentGeometry alignment;

  const _HeaderLabel(
    this.text, {
    required this.fontSize,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      );
}

/// How the width of a list row is split between the name and the two pills.
///
/// Both sides used to take whatever they wanted, and since only the name was
/// Expanded it was the one that paid: raise the system font size and the pills
/// grew until the name had less room than a single word, so "Tilkal Rusul"
/// broke into "Til / ka / l / Ru / su / l". Fixed shares mean neither side can
/// starve the other at any font setting.
const int _kNameFlex = 5;
const int _kPillsFlex = 4;

/// The progress and page pills at the end of a Quran list row.
///
/// Scaled down to fit their share rather than demanding it, so a large font
/// setting shrinks the pills - which are glanceable either way - instead of
/// destroying the name beside them.
class _TilePills extends StatelessWidget {
  final String percentLabel;
  final String pageLabel;

  const _TilePills({required this.percentLabel, required this.pageLabel});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: _kPillsFlex,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD8F3EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                percentLabel,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF006D5B),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF00695C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    pageLabel,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _Parah {
  final int number;
  final String english;
  final String arabic;
  final String urdu;
  final String sindhi;
  final int startPage;
  final int startSurah;
  final int startAyah;

  const _Parah(this.number, this.english, this.arabic, this.urdu, this.sindhi, this.startPage, this.startSurah, this.startAyah);
}

class _Surah {
  final int index;
  final String english;
  final String arabic;
  final String urdu;
  final String sindhi;
  final String roman;
  final int ayahCount;
  final String revelationType;

  int get number => index;

  const _Surah(this.index, this.english, this.arabic, this.urdu, this.sindhi, this.roman, this.ayahCount, this.revelationType);
}
