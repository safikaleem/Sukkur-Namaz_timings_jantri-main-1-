import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sukkur_prayer_timings/widgets/translation_reader.dart';

void main() {
  group('offline Arabic source', () {
    test('every surah yields the expected number of verses', () {
      for (var s = 1; s <= 114; s++) {
        expect(arabicForSurah(s).length, quran.getVerseCount(s),
            reason: 'surah $s verse count mismatch');
      }
    });

    test('verses are in order and non-empty', () {
      final baqarah = arabicForSurah(2);
      expect(baqarah.length, 286);
      expect(baqarah.every((v) => v.trim().isNotEmpty), isTrue);
      // Ordering: index i must hold ayah i+1, and ayah 1 must not leak into it.
      expect(baqarah[1], quran.getVerse(2, 2));
      expect(baqarah[285], quran.getVerse(2, 286));
    });

    test('Basmala is folded into ayah 1 except Al-Fatiha and At-Tawbah', () {
      expect(arabicForSurah(2).first.startsWith(quran.basmala), isTrue);
      expect(arabicForSurah(9).first.startsWith(quran.basmala), isFalse);
      // Al-Fatiha already has the Basmala as its own first verse.
      expect(arabicForSurah(1).first, quran.getVerse(1, 1));
      expect(arabicForSurah(1).length, 7);
    });

    test('matches quran.getVerse for sampled verses', () {
      for (final s in [1, 2, 18, 36, 55, 114]) {
        final verses = arabicForSurah(s);
        for (var v = 2; v <= verses.length; v += 37) {
          expect(verses[v - 1], quran.getVerse(s, v),
              reason: 'surah $s ayah $v');
        }
      }
    });
  });
}
