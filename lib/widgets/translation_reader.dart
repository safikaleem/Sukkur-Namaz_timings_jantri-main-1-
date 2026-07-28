import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

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
  bool _isLoading = true;
  String _error = '';
  List<_Verse> _verses = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final num = widget.surahNumber;
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'surah_data_$num';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final decoded = json.decode(cachedData) as List;
        final verses = decoded.map((v) => _Verse(
          number: v['n'],
          arabic: v['a'],
          english: v['e'],
          urdu: v['u'],
        )).toList();
        
        if (mounted) {
          setState(() {
            _verses = verses;
            _isLoading = false;
          });
        }
        return;
      }
      
      // Fetch data concurrently to reduce load time
      final responses = await Future.wait([
        http.get(Uri.parse('https://api.alquran.cloud/v1/surah/$num')),
        http.get(Uri.parse('https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/eng-muftitaqiusmani/$num.json')),
        http.get(Uri.parse('https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/urd-muhammadtaqiusm/$num.json')),
      ]);

      final araRes = responses[0];
      final engRes = responses[1];
      final urdRes = responses[2];

      if (araRes.statusCode == 200 && engRes.statusCode == 200 && urdRes.statusCode == 200) {
        final araData = json.decode(araRes.body)['data']['ayahs'] as List;
        final engData = json.decode(engRes.body)['chapter'] as List;
        final urdData = json.decode(urdRes.body)['chapter'] as List;

        final verses = <_Verse>[];
        final cacheList = [];
        
        for (int i = 0; i < araData.length; i++) {
          final arabic = araData[i]['text'];
          final english = engData[i]['text'];
          final urdu = urdData[i]['text'];
          
          verses.add(_Verse(
            number: i + 1,
            arabic: arabic,
            english: english,
            urdu: urdu,
          ));
          
          cacheList.add({
            'n': i + 1,
            'a': arabic,
            'e': english,
            'u': urdu,
          });
        }
        
        await prefs.setString(cacheKey, json.encode(cacheList));

        if (mounted) {
          setState(() {
            _verses = verses;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load translations');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = widget.settings.translate(
            'Failed to load data. Please check your internet connection.',
            'ڈیٹا لوڈ کرنے میں ناکام۔ براہ کرم اپنا انٹرنیٹ کنکشن چیک کریں۔',
            'ڊيٽا لوڊ ڪرڻ ۾ ناڪام. مهرباني ڪري پنهنجو انٽرنيٽ ڪنيڪشن چيڪ ڪريو.',
            'فشل تحميل البيانات. يرجى التحقق من اتصال الإنترنت الخاص بك.'
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.accent),
            const SizedBox(height: 16),
            Text(
              widget.settings.translate('Loading Surah...', 'سورة لوڈ ہو رہی ہے...', 'سورة لوڊ ٿي رهي آهي...', 'جاري تحميل السورة...'),
              style: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black54),
            )
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: widget.isDark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 16),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = '';
                  });
                  _fetchData();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                child: Text(
                  widget.settings.translate('Retry', 'دوبارہ کوشش کریں', 'ٻيهر ڪوشش ڪريو', 'إعادة المحاولة'),
                  style: const TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      );
    }

    int initIndex = 0;
    if (widget.initialAyah > 1 && widget.initialAyah <= _verses.length) {
       initIndex = widget.initialAyah;
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
                if (verse != null && verse >= 1 && verse <= _verses.length) {
                  _itemScrollController.jumpTo(index: verse);
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
        
        Expanded(
          child: ScrollablePositionedList.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: _verses.length,
            itemScrollController: _itemScrollController,
            initialScrollIndex: initIndex,
            itemBuilder: (context, index) {
        final v = _verses[index];
        
        // Update reading progress silently
        widget.settings.updateSurahProgress(widget.surahNumber, v.number);

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
                      '${widget.settings.translate("Verse", "آیت", "آيت", "آية")} ${v.number}',
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
                    v.arabic,
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
                Text(
                  v.urdu,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 21, 
                    color: widget.isDark ? Colors.white70 : Colors.black87,
                    fontFamily: AppTheme.urduFont,
                  ),
                ),
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
                Text(
                  v.english,
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 17, 
                    color: widget.isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
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
}

class _Verse {
  final int number;
  final String arabic;
  final String english;
  final String urdu;

  _Verse({
    required this.number,
    required this.arabic,
    required this.english,
    required this.urdu,
  });
}
