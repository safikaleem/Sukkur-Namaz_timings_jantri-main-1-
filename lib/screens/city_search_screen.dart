import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/city_search.dart';
import '../utils/app_theme.dart';
import '../utils/world_location.dart';

/// Full-screen city picker: type a letter, get a list, tap to choose.
///
/// Pops with the chosen [CityResult], or null if the user backs out.
class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<CityResult> _results = const [];
  bool _loading = true;
  bool _isOnlineSearching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    await CitySearch.instance.load();
    if (!mounted) return;
    setState(() => _loading = false);
    // The keyboard is the whole point of this screen, so raise it immediately.
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Scanning 235,000 rows takes a few milliseconds, but doing it on every
  /// keystroke of a fast typist still stutters. One short debounce smooths it
  /// without feeling delayed.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _results = CitySearch.instance.search(value);
      });
    });
  }

  Future<void> _searchOnline(SettingsProvider settings) async {
    final queryText = _query.trim();
    if (queryText.isEmpty) return;

    setState(() => _isOnlineSearching = true);

    try {
      final locations = await locationFromAddress(queryText);
      if (!mounted) return;

      if (locations.isNotEmpty) {
        final loc = locations.first;
        String placeName = queryText;
        String countryCode = '';

        try {
          final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final resolvedName = cityNameFrom(p);
            if (resolvedName != null && resolvedName.isNotEmpty) {
              placeName = resolvedName;
            }
            countryCode = p.isoCountryCode ?? '';
          }
        } catch (_) {}

        final cityResult = CityResult(
          name: placeName,
          countryCode: countryCode,
          latitude: loc.latitude,
          longitude: loc.longitude,
        );

        if (mounted) {
          Navigator.of(context).pop(cityResult);
        }
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isOnlineSearching = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(settings.translate(
          'Could not find location online. Check spelling or internet connection.',
          'آن لائن مقام نہیں ملا۔ ہجے یا انٹرنیٹ کنکشن چیک کریں۔',
          'آن لائن جڳهه نه ملي. اسپيلنگ يا انٽرنيٽ ڪنيڪشن چيڪ ڪريو.',
          'تعذر العثور على الموقع عبر الإنترنت. تحقق من التهجئة أو الاتصال بالإنترنت.',
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final muted = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: settings.displayThemeBg(isDark),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: IconButton(
                icon: Icon(Icons.close, color: textColor, size: 26),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: settings.translate('Close', 'بند کریں', 'بند ڪريو', 'إغلاق'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autocorrect: false,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 24, color: textColor),
                decoration: InputDecoration(
                  hintText: settings.translate('Search city', 'شہر تلاش کریں',
                      'شهر ڳوليو', 'ابحث عن مدينة'),
                  hintStyle: TextStyle(fontSize: 24, color: muted),
                  border: const UnderlineInputBorder(),
                ),
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: _body(settings, textColor, muted)),
          ],
        ),
      ),
    );
  }

  Widget _jantriNote(SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: AppTheme.accent.withValues(alpha: isDark ? 0.20 : 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop(
              const CityResult(
                name: 'Sukkur',
                countryCode: 'PK',
                latitude: SukkurLocation.lat,
                longitude: SukkurLocation.lng,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.push_pin_rounded,
                    color: AppTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.translate(
                          'Sukkur',
                          'سکھر',
                          'سکر',
                          'سكر',
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.translate(
                          'Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu Jantri',
                          'بمطابق حضرت ڈاکٹر حفیظ اللہ صاحب قدس اللہ سرہ جنتری',
                          'حضرت ڊاڪٽر حفيظ الله صاحب قدس الله سره جي جنتري مطابق',
                          'بناءً على تقويم الشيخ الدكتور حفيظ الله قدس الله سره',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  settings.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: AppTheme.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(SettingsProvider settings, Color textColor, Color muted) {
    if (_loading || _isOnlineSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (_isOnlineSearching) ...[
              const SizedBox(height: 16),
              Text(
                settings.translate(
                  'Searching online...',
                  'آن لائن تلاش جاری ہے...',
                  'آن لائن ڳولا جاري آهي...',
                  'جاري البحث عبر الإنترنت...',
                ),
                style: TextStyle(color: muted, fontSize: 14),
              ),
            ],
          ],
        ),
      );
    }
    if (_query.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            settings.translate(
              'Start typing to see cities.',
              'شہر دیکھنے کے لیے لکھنا شروع کریں۔',
              'شهر ڏسڻ لاءِ لکڻ شروع ڪريو.',
              'ابدأ الكتابة لعرض المدن.',
            ),
            style: TextStyle(color: muted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final wantsSukkur = SukkurLocation.looksLikeSearchFor(_query);
    final hasResults = _results.isNotEmpty;
    final showOnlineSearchBtn = _query.trim().length >= 2 && !wantsSukkur;

    if (!hasResults && !wantsSukkur) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                settings.translate(
                  'No offline city match found.',
                  'کوئی آف لائن شہر نہیں ملا۔',
                  'ڪو به آف لائن شهر نه مليو.',
                  'لم يتم العثور على مدينة مطابقة آفلاين.',
                ),
                style: TextStyle(color: muted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _searchOnline(settings),
                icon: const Icon(Icons.travel_explore_rounded),
                label: Text(settings.translate(
                  'Search online for "${_query.trim()}"',
                  '"${_query.trim()}" کو آن لائن تلاش کریں',
                  '"${_query.trim()}" کي آن لائن ڳوليو',
                  'البحث عبر الإنترنت عن "${_query.trim()}"',
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalCount = _results.length + (wantsSukkur ? 1 : 0) + (showOnlineSearchBtn ? 1 : 0);

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (wantsSukkur && index == 0) {
          return _jantriNote(settings);
        }
        final listIndex = wantsSukkur ? index - 1 : index;

        if (showOnlineSearchBtn && listIndex == _results.length) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: OutlinedButton.icon(
              onPressed: () => _searchOnline(settings),
              icon: const Icon(Icons.travel_explore_rounded, size: 20),
              label: Text(settings.translate(
                'Search online for "${_query.trim()}"',
                '"${_query.trim()}" کو آن لائن تلاش کریں',
                '"${_query.trim()}" کي آن لائن ڳوليو',
                'البحث عبر الإنترنت عن "${_query.trim()}"',
              )),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }

        final city = _results[listIndex];
        return InkWell(
          onTap: () => Navigator.of(context).pop(city),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.label,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${settings.translate('Latitude', 'عرض البلد', 'ويڪرائي ڦاڪ', 'خط العرض')}: ${city.latitude}, '
                  '${settings.translate('Longitude', 'طول البلد', 'ڊگھائي ڦاڪ', 'خط الطول')}: ${city.longitude}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
