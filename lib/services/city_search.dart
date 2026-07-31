import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../data/country_names.dart';
import '../providers/settings_provider.dart' show SukkurLocation;

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

  /// Places whose name starts with [query], best match first.
  ///
  /// Sukkur and its neighbours are dropped here rather than refused after the
  /// tap: the Jantri is the only correct source for them, so they must not be
  /// offerable in the first place.
  List<CityResult> search(String query, {int limit = defaultLimit}) {
    final cities = _cities;
    if (cities == null) return const [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final results = <CityResult>[];
    for (final city in cities) {
      if (!city.name.toLowerCase().startsWith(q)) continue;
      if (SukkurLocation.covers(city.latitude, city.longitude, city.name)) {
        continue;
      }
      results.add(city);
      if (results.length >= limit) break;
    }
    return results;
  }

  @visibleForTesting
  void loadForTest(List<CityResult> cities) => _cities = cities;

  @visibleForTesting
  void resetForTest() => _cities = null;
}
