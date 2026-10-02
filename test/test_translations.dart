import '../lib/l10n/world_translations.dart';

void main() {
  final languages = [
    'english', 'urdu', 'sindhi', 'arabic', 'bengali',
    'indonesian', 'french', 'hindi', 'persian', 'turkish'
  ];

  final keysToTest = [
    'Islamic Hijri Calendar',
    'Nearby Mosque Finder',
    'Islamic Hijri Events',
    'Today in Hijri Calendar',
    'Tap any month below to view major blessed Islamic events & dates.',
    'All Events',
    'Current',
    'Gregorian',
    'Islamic New Year (1st Muharram)',
    'Beginning of the Hijri New Year 1448 AH.',
    'Yaum-e-Ashura (10th Muharram)',
    'Day of Ashura - Recommended Sunnah fasting on 9th & 10th Muharram.',
    '12 Rabi-ul-Awwal',
    'Blessed birth anniversary of Prophet Muhammad ﷺ.',
    'Shab-e-Meraj (27 Rajab)',
    'The miraculous Ascension journey of Prophet Muhammad ﷺ.',
    'Shab-e-Barat (15 Sha\'ban)',
    'Night of Forgiveness & Salvation - Recommended night prayers and fasting.',
    '1st Ramzan-ul-Mubarak',
    'Beginning of the Holy Month of Ramzan fasting.',
    'Laylat al-Qadr (Night of Power)',
    'Better than 1,000 months - Blessed odd night of Ramzan.',
    'Eid-ul-Fitr (1st Shawwal)',
    'Blessed festival of Fitr after completing Ramzan.',
    'Day of Arafah (9 Dhul Hijjah)',
    'The day of Hajj & recommended Sunnah fasting for non-pilgrims.',
    'Eid-ul-Adha (10 Dhul Hijjah)',
    'Festival of Sacrifice honoring Prophet Ibrahim (A.S).',
    'Eid Festival',
    'Blessed Night',
    'Sunnah Fasting',
    'Historical Event',
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
    'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah',
    'Find Mosques Near You',
    'Locate local Masjids for Congregational (Jama\'at) Prayers anywhere around the globe with live GPS directions.',
    'Open Nearby Mosques on Map',
    'Quick Search Categories',
    'Jamia / Main Mosques',
    'Search for larger Jamia Masjids nearby',
  ];

  int totalMissing = 0;

  for (final lang in languages) {
    int missingCount = 0;

    final langDict = worldTranslations[lang] ?? {};

    for (final key in keysToTest) {
      if (!langDict.containsKey(key)) {
        print('  ❌ ABSOLUTELY MISSING [$lang]: "$key"');
        missingCount++;
        totalMissing++;
      }
    }

    if (missingCount == 0) {
      print('  ✅ ALL ${keysToTest.length} KEYS ARE 100% INCLUDED IN "$lang" DICTIONARY!');
    } else {
      print('  ⚠️ $missingCount / ${keysToTest.length} KEYS MISSING IN "$lang" DICTIONARY!');
    }
  }

  print('========================================');
  print('TOTAL UNKEYED STRINGS ACROSS ALL 10 LANGUAGES: $totalMissing');
  print('========================================');
}
