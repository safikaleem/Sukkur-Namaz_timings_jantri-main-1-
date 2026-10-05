import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran/quran_text.dart' show quranText;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quran_data.dart';
import '../data/quran_data_15_line.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

/// Reads the whole surah out of the bundled offline text in a single pass.
List<String> arabicForSurah(int surahNumber) {
  final verses = <String>[];
  for (final entry in quranText) {
    if (entry['surah_number'] == surahNumber) {
      verses.add(entry['content'].toString());
    }
  }
  if (verses.isNotEmpty && surahNumber != 1 && surahNumber != 9) {
    verses[0] = '${quran.basmala} ${verses[0]}';
  }
  return verses;
}

class _Translations {
  final List<String> english;
  final List<String> urdu;
  _Translations({required this.english, required this.urdu});
}

/// Runs in a background isolate - decodes the on-disk translation cache.
_Translations _decodeCache(String raw) {
  final map = json.decode(raw) as Map<String, dynamic>;
  return _Translations(
    english: (map['e'] as List).cast<String>(),
    urdu: (map['u'] as List).cast<String>(),
  );
}

/// Runs in a background isolate - parses the two translation payloads.
_Translations _decodeRemote(List<String> bodies) {
  List<String> chapter(String body) => (json.decode(body)['chapter'] as List)
      .map((v) => v['text'] as String)
      .toList();
  return _Translations(english: chapter(bodies[0]), urdu: chapter(bodies[1]));
}

class _VerseItem {
  final int globalIndex;
  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final bool isFirstAyahOfSurah;

  _VerseItem({
    required this.globalIndex,
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    required this.isFirstAyahOfSurah,
  });
}

class TranslationReader extends StatefulWidget {
  final int surahNumber;
  final SettingsProvider settings;
  final bool isDark;
  final int initialAyah;
  final int initialPage;
  final ValueChanged<int>? onParahChanged;
  final ValueChanged<int>? onSurahChanged;

  const TranslationReader({
    super.key,
    required this.surahNumber,
    required this.settings,
    required this.isDark,
    this.initialAyah = 1,
    this.initialPage = 1,
    this.onParahChanged,
    this.onSurahChanged,
  });

  @override
  State<TranslationReader> createState() => _TranslationReaderState();
}

class _TranslationReaderState extends State<TranslationReader> {
  static const _timeout = Duration(seconds: 15);

  static final List<_VerseItem> _allVerses = _buildAllVerses();
  static final Map<int, int> _surahStartGlobalIndex = _buildSurahStartGlobalIndex();

  static List<_VerseItem> _buildAllVerses() {
    final list = <_VerseItem>[];
    int globalIndex = 0;
    for (final entry in quranText) {
      final surah = entry['surah_number'] as int;
      final ayah = entry['verse_number'] as int;
      String content = entry['content'].toString();
      final isFirst = (ayah == 1);
      if (isFirst && surah != 1 && surah != 9) {
        content = '${quran.basmala} $content';
      }
      list.add(_VerseItem(
        globalIndex: globalIndex,
        surahNumber: surah,
        ayahNumber: ayah,
        arabicText: content,
        isFirstAyahOfSurah: isFirst,
      ));
      globalIndex++;
    }
    return list;
  }

  static Map<int, int> _buildSurahStartGlobalIndex() {
    final map = <int, int>{};
    for (var i = 0; i < _allVerses.length; i++) {
      final item = _allVerses[i];
      if (item.isFirstAyahOfSurah) {
        map[item.surahNumber] = item.globalIndex;
      }
    }
    return map;
  }

  final Map<int, _Translations> _translationsCache = {};
  final Set<int> _loadingSurahs = {};
  final Map<int, String> _errors = {};

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();

  int _currentReportedSurah = 1;
  int _currentReportedAyah = 1;

  @override
  void initState() {
    super.initState();
    _currentReportedSurah = widget.surahNumber;
    _currentReportedAyah = widget.initialAyah;
    _itemPositionsListener.itemPositions.addListener(_onScroll);

    // Initial load for starting surah & adjacent surahs
    _loadSurahTranslation(widget.surahNumber);
    if (widget.surahNumber > 1) _loadSurahTranslation(widget.surahNumber - 1);
    if (widget.surahNumber < 114) _loadSurahTranslation(widget.surahNumber + 1);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    _searchController.dispose();
    super.dispose();
  }

  int _getParahForVerse(int surah, int ayah) {
    for (int i = QuranData.parahs.length - 1; i >= 0; i--) {
      final p = QuranData.parahs[i];
      if (surah > p.surahId || (surah == p.surahId && ayah >= p.ayahId)) {
        return p.number;
      }
    }
    return 1;
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final topIndex = positions
        .where((p) => p.itemTrailingEdge > 0)
        .fold<int>(_allVerses.length, (min, p) => p.index < min ? p.index : min);

    if (topIndex >= 0 && topIndex < _allVerses.length) {
      final item = _allVerses[topIndex];
      if (item.surahNumber != _currentReportedSurah || item.ayahNumber != _currentReportedAyah) {
        _currentReportedSurah = item.surahNumber;
        _currentReportedAyah = item.ayahNumber;
        widget.settings.updateSurahProgress(item.surahNumber, item.ayahNumber);

        final parah = _getParahForVerse(item.surahNumber, item.ayahNumber);
        widget.onParahChanged?.call(parah);
        widget.onSurahChanged?.call(item.surahNumber);

        _loadSurahTranslation(item.surahNumber);
        if (item.surahNumber > 1) _loadSurahTranslation(item.surahNumber - 1);
        if (item.surahNumber < 114) _loadSurahTranslation(item.surahNumber + 1);
      }
    }
  }

  @override
  void didUpdateWidget(TranslationReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage || oldWidget.surahNumber != widget.surahNumber) {
      final newIndex = _calculateInitialGlobalIndex();
      if (_itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: newIndex);
      }
    }
  }

  int _calculateInitialGlobalIndex() {
    if (widget.initialAyah > 1) {
      final start = _surahStartGlobalIndex[widget.surahNumber] ?? 0;
      return (start + widget.initialAyah - 1).clamp(0, _allVerses.length - 1);
    }

    final page = widget.initialPage;
    final is15Line = widget.settings.quranType == '15_line';

    if (page > 0) {
      if (is15Line) {
        final (targetSurah, targetAyah) = Quran15LineData.getFirstVerseForPage(page);
        final start = _surahStartGlobalIndex[targetSurah] ?? 0;
        return (start + targetAyah - 1).clamp(0, _allVerses.length - 1);
      } else {
        try {
          final pageData = quran.getPageData(page.clamp(1, 604));
          if (pageData.isNotEmpty) {
            final firstRange = pageData.first;
            final s = firstRange['surah'] as int;
            final a = firstRange['start'] as int;
            final start = _surahStartGlobalIndex[s] ?? 0;
            return (start + a - 1).clamp(0, _allVerses.length - 1);
          }
        } catch (_) {}
      }
    }

    return _surahStartGlobalIndex[widget.surahNumber] ?? 0;
  }

  Future<void> _loadSurahTranslation(int surahNum) async {
    if (_translationsCache.containsKey(surahNum) || _loadingSurahs.contains(surahNum)) return;
    _loadingSurahs.add(surahNum);

    // 1. Try bundled asset
    try {
      final raw = await rootBundle.loadString('assets/quran_translations/surah_$surahNum.json');
      final decoded = await compute(_decodeCache, raw);
      if (mounted) {
        setState(() {
          _translationsCache[surahNum] = decoded;
          _loadingSurahs.remove(surahNum);
        });
      }
      return;
    } catch (_) {}

    // 2. Try disk cache / Web prefs
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('quran_translation_$surahNum');
        if (raw != null) {
          final decoded = await compute(_decodeCache, raw);
          if (mounted) {
            setState(() {
              _translationsCache[surahNum] = decoded;
              _loadingSurahs.remove(surahNum);
            });
          }
          return;
        }
      } else {
        final dir = await getApplicationSupportDirectory();
        final file = File('${dir.path}/quran_translations/surah_$surahNum.json');
        if (await file.exists()) {
          final raw = await file.readAsString();
          final decoded = await compute(_decodeCache, raw);
          if (mounted) {
            setState(() {
              _translationsCache[surahNum] = decoded;
              _loadingSurahs.remove(surahNum);
            });
          }
          return;
        }
      }
    } catch (_) {}

    // 3. Fallback to API if missing
    try {
      final responses = await Future.wait([
        http.get(Uri.parse(
            'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/eng-muftitaqiusmani/$surahNum.json')),
        http.get(Uri.parse(
            'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/urd-muhammadtaqiusm/$surahNum.json')),
      ]).timeout(_timeout);

      if (responses.every((r) => r.statusCode == 200)) {
        final parsed = await compute(_decodeRemote, responses.map((r) => r.body).toList());
        if (mounted) {
          setState(() {
            _translationsCache[surahNum] = parsed;
            _loadingSurahs.remove(surahNum);
          });
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errors[surahNum] = e.toString();
          _loadingSurahs.remove(surahNum);
        });
      }
    }
  }

  void _jumpToVerse(String input) {
    FocusScope.of(context).unfocus();
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      final s = int.tryParse(parts[0]);
      final a = int.tryParse(parts[1]);
      if (s != null && s >= 1 && s <= 114 && a != null && a >= 1) {
        final start = _surahStartGlobalIndex[s];
        if (start != null) {
          final maxAyah = quran.getVerseCount(s);
          final clampedAyah = a.clamp(1, maxAyah);
          _itemScrollController.jumpTo(index: start + clampedAyah - 1);
          return;
        }
      }
    }

    final verse = int.tryParse(trimmed);
    if (verse != null) {
      final currentSurah = _currentReportedSurah;
      final start = _surahStartGlobalIndex[currentSurah] ?? 0;
      final maxAyah = quran.getVerseCount(currentSurah);
      final clampedAyah = verse.clamp(1, maxAyah);
      _itemScrollController.jumpTo(index: start + clampedAyah - 1);
    }
  }

  Widget _buildSurahHeader(int surahNum) {
    final surah = QuranData.surahs[surahNum - 1];
    final isRtl = widget.settings.isRtl;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDark
              ? [const Color(0xFF1E2D32), const Color(0xFF142024)]
              : [const Color(0xFFEAF4F4), const Color(0xFFD5E8E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGreen.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            surah.arabicOnly,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isRtl ? surah.urdu : '${surah.number}. ${surah.english}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${surah.revelationType} • ${surah.totalAyahs} ${widget.settings.translate("Verses", "آیات", "آيتون", "آيات")}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          if (surahNum != 1 && surahNum != 9) ...[
            const SizedBox(height: 16),
            Text(
              quran.basmala,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 22,
                fontFamily: 'Amiri',
                color: AppTheme.accentGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initIndex = _calculateInitialGlobalIndex();

    return Column(
      children: [
        // Search Box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.settings.translate(
                    'Search Verse No. (e.g. 25 or 2:255)...',
                    'آیت نمبر تلاش کریں (مثلاً 25 یا 2:255)...',
                    'آيت نمبر ڳوليو (مثال 25 يا 2:255)...',
                    'ابحث برقم الآية (مثلاً 25 أو 2:255)...'),
                hintStyle: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black54, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: AppTheme.accent, size: 20),
                filled: true,
                fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _jumpToVerse,
            ),
          ),
        ),

        // Fixed Translation Header Label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              widget.settings.translate(
                'Translation: Hazrat Mufti Taqi Usmani Hafizahullah',
                'ترجمہ: حضرت مفتی تقی عثمانی حفظہ اللہ',
                'ترجمو: حضرت مفتي تقي عثماني حفظه الله',
                'الترجمة: الشيخ مفتي تقي عثماني حفظه الله',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.accent,
              ),
            ),
          ),
        ),

        Expanded(
          child: ScrollablePositionedList.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: _allVerses.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            initialScrollIndex: initIndex,
            itemBuilder: (context, index) {
              final item = _allVerses[index];
              final surahNum = item.surahNumber;
              final translations = _translationsCache[surahNum];
              final isRtl = widget.settings.isRtl;

              if (translations == null && !_loadingSurahs.contains(surahNum)) {
                _loadSurahTranslation(surahNum);
              }

              final urdu = translations?.urdu;
              final english = translations?.english;

              String? translationText;
              if (urdu != null && english != null) {
                final idx = item.ayahNumber - 1;
                if (idx >= 0 && idx < urdu.length && idx < english.length) {
                  translationText = isRtl ? urdu[idx] : english[idx];
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (item.isFirstAyahOfSurah) _buildSurahHeader(surahNum),
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isDark
                            ? [const Color(0xFF2B2C33), const Color(0xFF23242A)]
                            : [Colors.white, const Color(0xFFFAFBFC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (!widget.isDark)
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                      ],
                      border: Border.all(
                        color: widget.isDark ? Colors.white10 : AppTheme.accent.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Decorative Verse Badge
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.accent.withValues(alpha: 0.15),
                                    AppTheme.accent.withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 1),
                              ),
                              child: Text(
                                '${QuranData.surahs[surahNum - 1].arabicOnly} • ${widget.settings.translate("Verse", "آیت", "آيت", "آية")} ${item.ayahNumber}',
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Arabic Text
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              item.arabicText,
                              textAlign: TextAlign.justify,
                              textDirection: TextDirection.rtl,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 24,
                                height: 2.0,
                                letterSpacing: 0,
                                color: widget.isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Translation Text
                          if (translationText != null) ...[
                            Divider(color: widget.isDark ? Colors.white10 : Colors.black12),
                            const SizedBox(height: 12),
                            Text(
                              translationText,
                              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: widget.isDark ? Colors.white70 : Colors.black87,
                                fontFamily: isRtl ? 'Jameel Noori Nastaleeq' : null,
                              ),
                            ),
                          ] else if (_errors.containsKey(surahNum)) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errors[surahNum]!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One-time cleanup of the old cache
Future<void> purgeLegacySurahCache() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('legacy_surah_cache_purged') ?? false) return;
  for (final key in prefs.getKeys().toList()) {
    if (key.startsWith('surah_data_')) {
      await prefs.remove(key);
    }
  }
  await prefs.setBool('legacy_surah_cache_purged', true);
}
