import 'package:flutter_test/flutter_test.dart';

/// Mirrors the subtitle built in QuranScreen's surah tile.
///
/// The bullet used as a separator renders in Nastaleeq/Arabic fonts as a small
/// round dot that is indistinguishable from the Arabic-Indic zero. Sitting
/// directly beside the ayah count it turned "۸ آیات" into what readers saw as
/// "۸۰" - eight ayahs looking like eighty.
String separatorFor({required bool isRtl}) => isRtl ? '، ' : ' • ';

String subtitle({
  required String english,
  required String revelation,
  required String ayahs,
  required String ayahsWord,
  required bool isRtl,
}) {
  final sep = separatorFor(isRtl: isRtl);
  return '$english$sep$revelation$sep$ayahs $ayahsWord';
}

void main() {
  test('English keeps the bullet', () {
    expect(
      subtitle(
        english: 'Al-Bayyinah',
        revelation: 'Madani',
        ayahs: '8',
        ayahsWord: 'Ayahs',
        isRtl: false,
      ),
      'Al-Bayyinah • Madani • 8 Ayahs',
    );
  });

  group('RTL', () {
    final urdu = subtitle(
      english: 'Al-Bayyinah',
      revelation: 'مدنی',
      ayahs: '۸',
      ayahsWord: 'آیات',
      isRtl: true,
    );

    test('uses an Arabic comma, never a bullet', () {
      expect(urdu, contains('،'));
      expect(urdu, isNot(contains('•')));
    });

    test('nothing zero-like sits against the ayah count', () {
      // The exact failure: a separator glyph immediately before the number.
      expect(urdu, isNot(matches(RegExp(r'[•·∙●]\s*[٠-٩۰-۹]'))));
      expect(urdu, contains('۸ آیات'));
    });

    for (final lang in ['مدنی', 'مدني', 'مدنية']) {
      test('holds for $lang', () {
        final s = subtitle(
          english: 'Al-Qadr',
          revelation: lang,
          ayahs: '۵',
          ayahsWord: 'آیات',
          isRtl: true,
        );
        expect(s, isNot(contains('•')));
        expect(s, contains('۵ آیات'));
      });
    }
  });
}
