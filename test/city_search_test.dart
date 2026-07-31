import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/data/country_names.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart'
    show SukkurLocation;
import 'package:sukkur_prayer_timings/services/city_search.dart';

/// A stand-in list in the same shape the asset has: already sorted by
/// population, tab separated, four columns.
const _sample = 'Karachi\tPK\t24.9056\t67.0822\n'
    'London\tGB\t51.5085\t-0.1257\n'
    'Lahore\tPK\t31.5497\t74.3436\n'
    'London\tCA\t42.9834\t-81.2330\n'
    'Londonderry\tGB\t54.9972\t-7.3092\n'
    'Sukkur\tPK\t27.7052\t68.8574\n'
    'Rohri\tPK\t27.6928\t68.8957\n'
    'Khairpur\tPK\t27.5295\t68.7592\n'
    'Sukabumi\tID\t-6.9200\t106.9270\n';

void main() {
  final search = CitySearch.instance;

  setUp(() => search.loadForTest(CitySearch.parseRows(_sample)));
  tearDown(search.resetForTest);

  group('parsing', () {
    test('reads every well formed row', () {
      expect(CitySearch.parseRows(_sample), hasLength(9));
    });

    test('skips short and malformed rows rather than throwing', () {
      final rows = CitySearch.parseRows(
          'Good\tPK\t24.0\t67.0\nbroken\n\nBad\tPK\tnotanumber\t67.0\n');
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Good');
    });
  });

  group('searching', () {
    test('matches from the very first letter', () {
      final names = search.search('l').map((c) => c.name).toSet();
      expect(names, containsAll(['London', 'Lahore', 'Londonderry']));
    });

    test('narrows as more letters are typed', () {
      expect(search.search('lo').map((c) => c.name),
          everyElement(startsWith('Lo')));
      expect(search.search('lond').map((c) => c.name).toSet(),
          {'London', 'Londonderry'});
      expect(search.search('karac').single.name, 'Karachi');
    });

    test('is case insensitive', () {
      expect(search.search('KARACHI').single.name, 'Karachi');
      expect(search.search('karachi').single.name, 'Karachi');
    });

    test('keeps same-named cities in different countries apart', () {
      final londons = search.search('london').where((c) => c.name == 'London');
      expect(londons, hasLength(2));
      expect(londons.map((c) => c.countryName).toSet(),
          {'United Kingdom', 'Canada'});
    });

    test('preserves the population order of the source list', () {
      // Karachi precedes Lahore in the sample, so it must precede it here too.
      final all = search.search('', limit: 100);
      expect(all, isEmpty, reason: 'an empty query lists nothing');
      final k = search.search('k').map((c) => c.name).toList();
      expect(k.indexOf('Karachi'), lessThan(k.indexOf('Khairpur')));
    });

    test('honours the result limit', () {
      expect(search.search('l', limit: 2), hasLength(2));
    });

    test('an unknown place returns nothing rather than a wrong guess', () {
      expect(search.search('zzzznowhere'), isEmpty);
    });

    test('returns nothing at all before the list is loaded', () {
      search.resetForTest();
      expect(search.search('london'), isEmpty);
    });
  });

  group('Sukkur is never offerable', () {
    test('typing its name yields no result', () {
      expect(search.search('sukkur'), isEmpty);
      expect(search.search('sukk'), isEmpty);
    });

    test('other cities sharing the prefix still appear', () {
      // "suk" must still be a useful search - only Sukkur itself is withheld.
      expect(search.search('suk').map((c) => c.name), ['Sukabumi']);
    });

    test('towns inside the Jantri radius are withheld too', () {
      // Rohri is across the river and served by the same Jantri.
      expect(search.search('rohri'), isEmpty);
    });

    test('a genuinely separate nearby city is still selectable', () {
      // Khairpur is ~22 km out, outside the radius, and must stay pickable.
      expect(search.search('khairpur').single.name, 'Khairpur');
    });
  });

  group('telling the user why Sukkur is missing', () {
    // The list withholds Sukkur, so the picker has to explain itself rather
    // than leave the user waiting for a row that never arrives.
    bool asks(String q) => SukkurLocation.looksLikeSearchFor(q);

    test('fires once the query is clearly heading for Sukkur', () {
      for (final q in ['suk', 'sukk', 'sukku', 'sukkur', 'SUKKUR', ' sukkur ']) {
        expect(asks(q), isTrue, reason: '"$q" should explain itself');
      }
    });

    test('covers the other spellings the app already blocks', () {
      for (final q in ['sukur', 'sukkar', 'sakkhar', 'سکھر', 'سکر', 'سكر']) {
        expect(asks(q), isTrue, reason: '"$q" is a Sukkur spelling');
      }
    });

    test('stays quiet for one or two letters', () {
      // "s" and "su" begin half of Sindh; answering there would be noise.
      expect(asks('s'), isFalse);
      expect(asks('su'), isFalse);
    });

    test('stays quiet for unrelated cities', () {
      for (final q in ['london', 'karachi', 'stockholm', 'sydney', 'sukabumi']) {
        expect(asks(q), isFalse, reason: '"$q" is not a Sukkur search');
      }
    });

    test('the note never turns Sukkur into a result', () {
      // Both things must hold at once: the message is shown, and the list is
      // still empty of Sukkur.
      expect(asks('sukkur'), isTrue);
      expect(search.search('sukkur'), isEmpty);
      expect(search.search('sukk').map((c) => c.name), isNot(contains('Sukkur')));
    });

    test('genuine cities sharing the prefix are still listed alongside it', () {
      expect(asks('suk'), isTrue);
      expect(search.search('suk').map((c) => c.name), ['Sukabumi']);
    });
  });

  group('display', () {
    test('reads as "City, Country"', () {
      expect(search.search('karachi').single.label, 'Karachi, Pakistan');
    });

    test('falls back to the raw code for an unmapped territory', () {
      const odd = CityResult(
          name: 'Nowhere', countryCode: 'ZZ', latitude: 0, longitude: 0);
      expect(odd.countryName, 'ZZ');
      expect(odd.label, 'Nowhere, ZZ');
    });

    test('the country table covers the codes the app ships', () {
      for (final code in ['PK', 'GB', 'US', 'CA', 'IN', 'SA', 'AE', 'ID']) {
        expect(countryNames.containsKey(code), isTrue, reason: code);
      }
    });
  });
}
