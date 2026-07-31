import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/city_search.dart';
import '../utils/app_theme.dart';

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
                // City names are Latin here, so the app's own RTL layout would
                // only put the caret on the wrong side.
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

  /// The same sentence the GPS path shows, worded identically so the two routes
  /// to Sukkur never explain themselves differently.
  Widget _jantriNote(SettingsProvider settings) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              settings.translate(
                'Select Sukkur Jantri (Based on Hazrat Dr Hafeezullah Sahib Qaddasallahu Sirrahu Jantri) from the side bar for accurate timings',
                'درست اوقات کے لیے سائیڈ بار سے سکھر جنتری (بمطابق حضرت ڈاکٹر حفیظ اللہ صاحب قَدَّسَ اللہ سِرَّہُ جنتری) منتخب کریں',
                'صحيح وقتن لاءِ سائيڊ بار مان سکر جنتري (حضرت ڊاڪٽر حفيظ الله صاحب قَدَّسَ اللهُ سِرَّهُ جي جنتري مطابق) چونڊيو',
                'للحصول على أوقات دقيقة، اختر جنتري سكر (بناءً على تقويم الشيخ الدكتور حفيظ الله قَدَّسَ اللهُ سِرَّهُ) من الشريط الجانبي',
              ),
              style: TextStyle(
                fontSize: 13,
                height: settings.isRtl ? 1.7 : 1.35,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(SettingsProvider settings, Color textColor, Color muted) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
    // Sukkur is withheld from the list on purpose, which left anyone searching
    // for it staring at a result that was never going to arrive. Say why, in
    // the same words the GPS path uses - but only ever as a note. There is
    // nothing here to tap, and nothing is stored.
    final wantsSukkur = SukkurLocation.looksLikeSearchFor(_query);

    if (_results.isEmpty && !wantsSukkur) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            settings.translate(
              'No city found. Check the spelling, or try a nearby larger city.',
              'کوئی شہر نہیں ملا۔ ہجے دیکھ لیں، یا قریب کا کوئی بڑا شہر آزمائیں۔',
              'ڪو به شهر نه مليو. اسپيلنگ ڏسو، يا ويجهو ڪو وڏو شهر آزمايو.',
              'لم يتم العثور على مدينة. تحقق من التهجئة أو جرّب مدينة أكبر قريبة.',
            ),
            style: TextStyle(color: muted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      // The note takes the first slot, so genuine matches like Sukabumi still
      // appear beneath it rather than being replaced by it.
      itemCount: _results.length + (wantsSukkur ? 1 : 0),
      itemBuilder: (context, index) {
        if (wantsSukkur && index == 0) {
          return _jantriNote(settings);
        }
        final i = wantsSukkur ? index - 1 : index;
        final city = _results[i];
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
