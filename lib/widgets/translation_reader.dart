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
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

/// Reads the whole surah out of the bundled offline text in a single pass.
/// (quran.getVerse() scans all 6236 verses per call, so calling it in a loop
/// is quadratic - this walks the list once instead.)
List<String> arabicForSurah(int surahNumber) {
  final verses = <String>[];
  for (final entry in quranText) {
    if (entry['surah_number'] == surahNumber) {
      verses.add(entry['content'].toString());
    }
  }
  // The remote edition this screen used to fetch carries the Basmala inside
  // ayah 1 of every surah except Al-Fatiha (where it is ayah 1) and At-Tawbah.
  if (verses.isNotEmpty && surahNumber != 1 && surahNumber != 9) {
    verses[0] = '${quran.basmala} ${verses[0]}';
  }
  return verses;
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

class TranslationReader extends StatefulWidget {
  final int surahNumber;
  final SettingsProvider settings;
  final bool isDark;
  final int initialAyah;

  const TranslationReader({
    super.key,
    required this.surahNumber,
    required this.settings,
    required this.isDark,
    this.initialAyah = 1,
  });

  @override
  State<TranslationReader> createState() => _TranslationReaderState();
}

class _TranslationReaderState extends State<TranslationReader> {
  static const _timeout = Duration(seconds: 15);

  late final List<String> _arabic;
  _Translations? _translations;
  bool _translationsLoading = true;
  String _error = '';

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();
  int _reportedAyah = 0;

  @override
  void initState() {
    super.initState();
    // Arabic is bundled with the app, so the surah is on screen immediately.
    _arabic = arabicForSurah(widget.surahNumber);
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    _loadTranslations();
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    _searchController.dispose();
    super.dispose();
  }

  /// Records reading progress from the top visible verse instead of from
  /// itemBuilder, which fired a SharedPreferences write on every frame.
  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final topIndex = positions
        .where((p) => p.itemTrailingEdge > 0)
        .fold<int>(_arabic.length, (min, p) => p.index < min ? p.index : min);
    final ayah = topIndex + 1;
    if (ayah > _reportedAyah && ayah <= _arabic.length) {
      _reportedAyah = ayah;
      widget.settings.updateSurahProgress(widget.surahNumber, ayah);
    }
  }

  String get _cacheKey => 'quran_translation_${widget.surahNumber}';

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/quran_translations');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/surah_${widget.surahNumber}.json');
  }

  /// The Mufti Taqi Usmani English and Urdu editions bundled under
  /// assets/quran_translations/, in the same {"e":[...],"u":[...]} shape as the
  /// on-disk cache. Never throws.
  Future<String?> _readBundled() async {
    try {
      return await rootBundle
          .loadString('assets/quran_translations/surah_${widget.surahNumber}.json');
    } catch (_) {
      return null;
    }
  }

  /// Best-effort cache read. Never throws: path_provider has no web
  /// implementation, and a corrupt cache must fall through to the network
  /// rather than leaving the surah permanently untranslated.
  Future<String?> _readCache() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_cacheKey);
      }
      final file = await _cacheFile();
      if (await file.exists()) return await file.readAsString();
    } catch (_) {}
    return null;
  }

  /// Best-effort cache write. Never throws.
  Future<void> _writeCache(String raw) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, raw);
        return;
      }
      final file = await _cacheFile();
      await file.writeAsString(raw);
    } catch (_) {}
  }

  Future<void> _loadTranslations() async {
    // Both editions ship with the app, so the translation is available offline
    // on every platform. The cache and the network are only fallbacks.
    for (final source in [_readBundled, _readCache]) {
      final raw = await source();
      if (raw == null) continue;
      try {
        final decoded = await compute(_decodeCache, raw);
        if (!mounted) return;
        setState(() {
          _translations = decoded;
          _translationsLoading = false;
        });
        return;
      } catch (_) {
        // Unreadable payload - fall through to the next source.
      }
    }

    try {
      final num = widget.surahNumber;
      final responses = await Future.wait([
        http.get(Uri.parse(
            'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/eng-muftitaqiusmani/$num.json')),
        http.get(Uri.parse(
            'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/urd-muhammadtaqiusm/$num.json')),
      ]).timeout(_timeout);

      if (responses.any((r) => r.statusCode != 200)) {
        throw Exception(
            'Translation server returned ${responses.map((r) => r.statusCode).join(', ')}');
      }

      final parsed =
          await compute(_decodeRemote, responses.map((r) => r.body).toList());
      if (!mounted) return;
      setState(() {
        _translations = parsed;
        _translationsLoading = false;
      });

      await _writeCache(json.encode({'e': parsed.english, 'u': parsed.urdu}));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _translationsLoading = false;
        _error = _describeError(e);
      });
    }
  }

  /// Only blame the connection when the connection is actually at fault -
  /// anything else gets reported as itself so it can be diagnosed.
  String _describeError(Object e) {
    final offline = e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException;
    if (offline) {
      return widget.settings.translate(
          'Could not load the translation. Please check your internet connection.',
          'ترجمہ لوڈ نہیں ہو سکا۔ براہ کرم اپنا انٹرنیٹ کنکشن چیک کریں۔',
          'ترجمو لوڊ نه ٿي سگهيو. مهرباني ڪري پنهنجو انٽرنيٽ ڪنيڪشن چيڪ ڪريو.',
          'تعذر تحميل الترجمة. يرجى التحقق من اتصال الإنترنت الخاص بك.');
    }
    final prefix = widget.settings.translate(
        'Could not load the translation.',
        'ترجمہ لوڈ نہیں ہو سکا۔',
        'ترجمو لوڊ نه ٿي سگهيو.',
        'تعذر تحميل الترجمة.');
    return '$prefix $e';
  }

  void _retryTranslations() {
    setState(() {
      _error = '';
      _translationsLoading = true;
    });
    _loadTranslations();
  }

  @override
  Widget build(BuildContext context) {
    int initIndex = 0;
    if (widget.initialAyah > 1 && widget.initialAyah <= _arabic.length) {
      initIndex = widget.initialAyah - 1;
    }

    return Column(
      children: [
        // Search Box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                isDense: true,
              hintText: widget.settings.translate('Search Verse No...', 'آیت نمبر تلاش کریں...', 'آيت نمبر ڳوليو...', 'ابحث برقم الآية...'),
              hintStyle: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black54),
              prefixIcon: Icon(Icons.search, color: AppTheme.accent),
              filled: true,
              fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
              onSubmitted: (value) {
                final verse = int.tryParse(value);
                if (verse != null && verse >= 1 && verse <= _arabic.length) {
                  _itemScrollController.jumpTo(index: verse - 1);
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),
        ),

        // Fixed Translation Label
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
                'الترجمة: الشيخ مفتي تقي عثماني حفظه الله'
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

        // Inline banner: translations are still coming in, or failed to load.
        if (_translationsLoading || _error.isNotEmpty)
          _buildTranslationStatus(),

        Expanded(
          child: ScrollablePositionedList.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: _arabic.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            initialScrollIndex: initIndex,
            itemBuilder: (context, index) {
        final urdu = _translations?.urdu;
        final english = _translations?.english;

        return Container(
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
                      '${widget.settings.translate("Verse", "آیت", "آيت", "آية")} ${index + 1}',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Arabic Text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    _arabic[index],
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 0,
                      fontFamily: 'SurahNames', // Use the provided Arabic font
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Elegant Divider
                Row(
                  children: [
                    Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppTheme.accent.withValues(alpha: 0.3)])))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(Icons.star_half_rounded, size: 14, color: AppTheme.accent.withValues(alpha: 0.6)),
                    ),
                    Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.accent.withValues(alpha: 0.3), Colors.transparent])))),
                  ],
                ),
                const SizedBox(height: 20),

                // Urdu Translation Label
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'اردو ترجمہ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white54 : AppTheme.accent.withValues(alpha: 0.8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Urdu Translation (Taqi Usmani)
                if (urdu != null && index < urdu.length)
                  Text(
                    urdu[index],
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 21,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                      fontFamily: AppTheme.urduFont,
                    ),
                  )
                else
                  _buildPlaceholderLines(2),
                const SizedBox(height: 24),

                // English Translation Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ENGLISH',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: widget.isDark ? Colors.white54 : AppTheme.accent.withValues(alpha: 0.8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // English Translation (Taqi Usmani)
                if (english != null && index < english.length)
                  Text(
                    english[index],
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 17,
                      color: widget.isDark ? Colors.white54 : Colors.black54,
                    ),
                  )
                else
                  _buildPlaceholderLines(2),
              ],
            ),
          ),
        );
      },
    ),
    ),
    ],
    );
  }

  Widget _buildTranslationStatus() {
    final loading = _error.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent),
              )
            else
              Icon(Icons.wifi_off_rounded,
                  size: 16,
                  color: widget.isDark ? Colors.white38 : Colors.black38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loading
                    ? widget.settings.translate(
                        'Loading translation...',
                        'ترجمہ لوڈ ہو رہا ہے...',
                        'ترجمو لوڊ ٿي رهيو آهي...',
                        'جاري تحميل الترجمة...')
                    : _error,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            if (!loading)
              TextButton(
                onPressed: _retryTranslations,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  widget.settings.translate('Retry', 'دوبارہ کوشش کریں',
                      'ٻيهر ڪوشش ڪريو', 'إعادة المحاولة'),
                  style: TextStyle(color: AppTheme.accent, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Grey bars standing in for a translation that has not arrived yet.
  Widget _buildPlaceholderLines(int count) {
    final color = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        count,
        (i) => Container(
          height: 12,
          margin: EdgeInsets.only(bottom: i == count - 1 ? 0 : 8),
          width: i == count - 1 ? 120 : double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _Translations {
  final List<String> english;
  final List<String> urdu;

  _Translations({required this.english, required this.urdu});
}

/// One-time cleanup of the old cache, which stored every surah's full text as
/// a ~450KB string in SharedPreferences. Android reads the entire preferences
/// file into memory on first access and rewrites it on every put, so those
/// blobs slowed down app startup and every unrelated setting write.
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
