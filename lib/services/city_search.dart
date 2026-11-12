import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../data/country_names.dart';
import '../providers/settings_provider.dart' show SukkurLocation;
import 'multilingual_city_aliases.dart';

/// One place the user can pick.
class CityResult {
  final String name;
  final String countryCode;
  final double latitude;
  final double longitude;

  const CityResult({
    required this.name,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  /// Falls back to the raw code so an unrecognised territory still reads as
  /// something rather than as a blank half of the line.
  String get countryName => countryNames[countryCode] ?? countryCode;

  /// "Karachi, Pakistan"
  String get label => '$name, $countryName';
}

/// Offline city lookup for the World Prayer Timings picker.
///
/// The bundled list is roughly 235,000 populated places, already sorted by
/// population, so a prefix scan can stop at the first [defaultLimit] hits and
/// those are already the ones a user most likely meant - no sorting at
/// keystroke time, and "lon" reaches London before it reaches Lonquimay.
class CitySearch {
  CitySearch._();
  static final CitySearch instance = CitySearch._();

  static const _assetPath = 'assets/data/cities.txt';

  /// Enough to fill several screens; typing one more letter narrows it faster
  /// than anyone scrolls. Drawing all 235,000 would simply hang.
  static const defaultLimit = 50;

  List<CityResult>? _cities;

  bool get isLoaded => _cities != null;

  /// Parses the asset once. Around 235k rows, so it is deliberately a plain
  /// split rather than anything that allocates per field.
  Future<void> load() async {
    if (_cities != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    _cities = parseRows(raw);
  }

  @visibleForTesting
  static List<CityResult> parseRows(String raw) {
    final out = <CityResult>[];
    for (final line in raw.split('\n')) {
      if (line.isEmpty) continue;
      final f = line.split('\t');
      if (f.length < 4) continue;
      final lat = double.tryParse(f[2]);
      final lng = double.tryParse(f[3]);
      if (lat == null || lng == null) continue;
      out.add(CityResult(
        name: f[0],
        countryCode: f[1],
        latitude: lat,
        longitude: lng,
      ));
    }
    return out;
  }

  /// Places whose name or country starts with or contains [query], best matches first.
  /// Supports all 10 app languages: English, Urdu, Sindhi, Arabic, Hindi, Bengali,
  /// Persian, Turkish, French, and Indonesian.
  ///
  /// Sukkur and its neighbours are dropped here rather than refused after the
  /// tap: the Jantri is the only correct source for them, so they must not be
  /// offerable in the first place.
  List<CityResult> search(String query, {int limit = defaultLimit}) {
    final cities = _cities;
    if (cities == null) return const [];
    final rawTrimmed = query.trim();
    if (rawTrimmed.isEmpty) return const [];

    final q = rawTrimmed.toLowerCase();
    final qNorm = MultilingualCityAliases.normalize(rawTrimmed);

    final aliasCities = MultilingualCityAliases.getMatchingEnglishCities(rawTrimmed);
    final aliasTargetSet = aliasCities.map((e) => e.toLowerCase()).toSet();

    final aliasCountries = MultilingualCityAliases.getMatchingCountries(rawTrimmed);
    final countryTargetSet = aliasCountries.map((e) => e.toLowerCase()).toSet();

    final aliasMatches = <CityResult>[];
    final prefixMatches = <CityResult>[];
    final substringMatches = <CityResult>[];
    final countryMatches = <CityResult>[];
    final seen = <String>{};

    for (final city in cities) {
      if (SukkurLocation.covers(city.latitude, city.longitude, city.name)) {
        continue;
      }
      final nameLower = city.name.toLowerCase();
      final countryLower = city.countryName.toLowerCase();
      final key = '${city.name}_${city.countryCode}_${city.latitude}_${city.longitude}';

      if (seen.contains(key)) continue;

      if (aliasTargetSet.contains(nameLower)) {
        seen.add(key);
        aliasMatches.add(city);
        if (aliasMatches.length >= limit) break;
      } else if (nameLower.startsWith(q) || (qNorm.isNotEmpty && nameLower.startsWith(qNorm))) {
        seen.add(key);
        prefixMatches.add(city);
      } else if (nameLower.contains(q) ||
          (qNorm.isNotEmpty && nameLower.contains(qNorm)) ||
          countryLower.startsWith(q) ||
          (qNorm.isNotEmpty && countryLower.startsWith(qNorm))) {
        seen.add(key);
        substringMatches.add(city);
      } else if (countryTargetSet.contains(countryLower)) {
        seen.add(key);
        countryMatches.add(city);
      }
    }

    final combined = <CityResult>[];
    combined.addAll(aliasMatches);
    if (combined.length < limit) {
      for (final city in prefixMatches) {
        combined.add(city);
        if (combined.length >= limit) break;
      }
    }
    if (combined.length < limit) {
      for (final city in substringMatches) {
        combined.add(city);
        if (combined.length >= limit) break;
      }
    }
    if (combined.length < limit) {
      for (final city in countryMatches) {
        combined.add(city);
        if (combined.length >= limit) break;
      }
    }

    return combined;
  }

  @visibleForTesting
  void loadForTest(List<CityResult> cities) => _cities = cities;

  @visibleForTesting
  void resetForTest() => _cities = null;
}
