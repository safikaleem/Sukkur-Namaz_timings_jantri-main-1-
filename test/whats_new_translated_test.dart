import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations.dart';

/// The What's New dialog and the setup screen pass English text to translate(),
/// which uses that text as the dictionary key. Change the English wording
/// without changing the key in every language file and the string silently
/// renders in English for the six world languages - no crash, no failing test,
/// just an untranslated dialog nobody notices.
///
/// These are the strings added in 1.1.6. If one of them starts failing here,
/// the English was edited in one place and not the other.
const _v116 = [
  'Read Straight Through the Quran',
  'Reading no longer stops at the end of a Para. Pull past the last page and the next Para opens by itself, so a Surah spread over two Paras is read without a break.',
  'Choose Your City When You Set Up',
  'The first screen now lets you search for your city or use your location, instead of depending on GPS alone. Choosing Sukkur still gives you the Jantri.',
  'Fajar Named Correctly in World Timings',
  'The note under world prayer timings said Subah Sadiq where the app itself shows Fajar. It now says Fajar, in every language.',
];

/// The setup screen's own strings, added at the same time.
const _setupScreen = [
  'No city selected',
  'Location denied - search your city instead',
  'No city selected - using Sukkur Jantri. You can choose your city later from World Prayer Timings.',
  'Select Sukkur from the option above for accurate timings',
  'Next',
  'Please select Sukkur or Other Cities',
  'Choose a city to continue',
];

/// The world footer, reworded from Subah Sadiq to Fajar in 1.1.6.
const _footer = [
  'These timings are according to the calculation method, therefore a 3-minute precaution should be added to prayer timings (prayers and Iftar should be observed 3 minutes after the given times, while fasting should end 3 minutes before Fajar time).',
];

/// The four built-in languages are supplied inline at each call site, so only
/// the six that go through the dictionary can fall back.
final _dictionaryLanguages = languageNamesMap.keys.where(
    (l) => !['english', 'urdu', 'sindhi', 'arabic'].contains(l));

void main() {
  for (final group in {
    "What's New 1.1.6": _v116,
    'setup screen': _setupScreen,
    'world footer': _footer,
  }.entries) {
    test('${group.key} is translated in every language', () {
      final missing = <String>[];
      for (final lang in _dictionaryLanguages) {
        for (final english in group.value) {
          if (translateFor(lang, english, '', '', null) == english) {
            missing.add('$lang: $english');
          }
        }
      }
      expect(missing, isEmpty,
          reason: 'these fell back to English:\n${missing.join('\n')}');
    });
  }
}
