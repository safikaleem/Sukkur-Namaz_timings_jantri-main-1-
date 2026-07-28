import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/widgets/translation_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every surah ships an English and Urdu translation matching the Arabic',
      () async {
    for (var surah = 1; surah <= 114; surah++) {
      final raw =
          await rootBundle.loadString('assets/quran_translations/surah_$surah.json');
      final map = json.decode(raw) as Map<String, dynamic>;
      final english = (map['e'] as List).cast<String>();
      final urdu = (map['u'] as List).cast<String>();
      final arabic = arabicForSurah(surah);

      expect(english.length, arabic.length, reason: 'English, surah $surah');
      expect(urdu.length, arabic.length, reason: 'Urdu, surah $surah');
      expect(english.every((v) => v.trim().isNotEmpty), isTrue,
          reason: 'empty English verse in surah $surah');
      expect(urdu.every((v) => v.trim().isNotEmpty), isTrue,
          reason: 'empty Urdu verse in surah $surah');
    }
  });
}
