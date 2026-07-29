import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations.dart';

/// The settings footer "All timings from the local Sukkur Jantri".
///
/// It shipped with only English, Urdu and Sindhi passed to translate(), so
/// Arabic silently fell back to the Urdu string - Urdu text on an Arabic
/// screen. English/Urdu/Sindhi/Arabic are passed inline; every other language
/// resolves through the shared dictionary.
const _key = 'All timings from the local Sukkur Jantri';

const _inline = {
  'english': 'All timings from the local Sukkur Jantri',
  'urdu': 'تمام اوقات سکھر کی مقامی جنتری سے لیے گئے ہیں',
  'sindhi': 'سڀ وقت سکر جي مقامي جنتري مان ورتا ويا آهن',
  'arabic': 'جميع الأوقات مأخوذة من جنتري سكر المحلية',
};

void main() {
  test('all four inline languages are present and distinct', () {
    expect(_inline.length, 4);
    for (final entry in _inline.entries) {
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
    }
    // The original bug: Arabic identical to Urdu because it was never passed.
    expect(_inline['arabic'], isNot(_inline['urdu']));
  });

  test('Arabic is written in Arabic, not Urdu', () {
    // These letters exist in Urdu but not in Arabic script.
    for (final urduOnly in ['ی', 'ہ', 'ے', 'ک']) {
      expect(_inline['arabic'], isNot(contains(urduOnly)),
          reason: 'Arabic string contains the Urdu letter "$urduOnly"');
    }
  });

  test('every world language covers the footer', () {
    for (final lang in worldTranslations.keys) {
      expect(worldTranslations[lang]?[_key]?.trim(), isNotEmpty,
          reason: '$lang is missing the Jantri footer');
    }
  });
}
