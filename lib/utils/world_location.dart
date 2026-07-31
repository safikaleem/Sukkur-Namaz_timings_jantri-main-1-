import 'package:geocoding/geocoding.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tz_map;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The best name a geocoder result offers, or null if it offers none.
///
/// Every field is checked for being *blank*, not merely null: the platform
/// geocoder returns `locality: ''` for a great many places - London among them,
/// where the name lives in `subAdministrativeArea` instead - and `??` alone
/// happily accepts the empty string, which is how a city ended up displaying as
/// nothing at all.
String? cityNameFrom(Placemark p) {
  for (final candidate in [
    p.locality,
    p.subAdministrativeArea,
    p.administrativeArea,
    p.name,
    p.country,
  ]) {
    final trimmed = candidate?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// What a set of coordinates implies: which clock the place runs on, and which
/// calculation convention its mosques publish against.
///
/// Prayer times are an astronomical fact about a place, but the numbers people
/// read off a timetable are wall-clock times *in that place*. adhan returns its
/// results in the device's timezone unless told otherwise, so without this a
/// phone in Pakistan showed Glasgow's sunset as 01:26 instead of 21:26.
class WorldLocation {
  const WorldLocation._();

  static bool _databaseChecked = false;

  /// Loads the tz database unless something already has.
  ///
  /// Deliberately not an unconditional [tz_data.initializeTimeZones] call:
  /// that resets `tz.local` back to UTC, and NotificationService sets the local
  /// zone exactly once at startup - every scheduled prayer is pinned to it. A
  /// second init here would silently move every pending notification.
  static void _ensureDatabase() {
    if (_databaseChecked) return;
    _databaseChecked = true;
    try {
      tz.getLocation('UTC');
      return; // Already initialised - leave tz.local alone.
    } catch (_) {
      // Database still empty; loading it below is safe.
    }
    try {
      tz_data.initializeTimeZones();
    } catch (_) {
      // Leave it unloaded - [utcOffsetFor] falls back to the longitude.
    }
  }

  /// The IANA zone governing these coordinates, e.g. `Europe/London`.
  ///
  /// A pure lookup: no network, no data files, so it works on a plane and on
  /// first launch alike.
  static String? timezoneNameFor(double lat, double lng) {
    try {
      final name = tz_map.latLngToTimezoneString(lat, lng);
      return name.trim().isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  /// [zoneName]'s offset from UTC on [date], daylight saving included - London
  /// is +1 in July and 0 in January, and it switches on the right day because
  /// the tz database, not a guess, decides.
  ///
  /// Falls back to the offset implied by [lng] when the zone is unknown. That
  /// is rough, but it is at least anchored to the city rather than to wherever
  /// the phone happens to be.
  static Duration utcOffsetFor(String? zoneName, double lng, DateTime date) {
    if (zoneName != null) {
      _ensureDatabase();
      try {
        final location = tz.getLocation(zoneName);
        // Noon, not midnight: a DST changeover lands in the small hours, and
        // midday is unambiguous on either side of it.
        final noon = DateTime.utc(date.year, date.month, date.day, 12);
        return tz.TZDateTime.from(noon, location).timeZoneOffset;
      } catch (_) {
        // Unrecognised zone name - fall through.
      }
    }
    return Duration(hours: (lng / 15).round().clamp(-12, 14));
  }

  /// The moment now, written as [zoneName]'s wall clock.
  ///
  /// Returned as a plain [DateTime] so it can be compared directly against the
  /// wall-clock times a timetable holds. Both sides are then in the same frame,
  /// which is what makes "how long until Maghrib" come out right for a city the
  /// phone is not standing in.
  static DateTime nowIn(String? zoneName) {
    if (zoneName == null || zoneName.isEmpty) return DateTime.now();
    _ensureDatabase();
    try {
      final here = tz.TZDateTime.now(tz.getLocation(zoneName));
      return DateTime(here.year, here.month, here.day, here.hour, here.minute,
          here.second, here.millisecond);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Which twilight-angle convention a place's own mosques normally publish.
  ///
  /// Keyed off the timezone rather than a latitude/longitude box: `Europe/
  /// London` identifies the UK far more exactly than any rectangle, and the
  /// zone is already on file. Anything unrecognised gets Muslim World League,
  /// the usual international default.
  ///
  /// This only ever supplies the *initial* method for a newly picked city. The
  /// moment the user touches the dropdown their choice takes over for good.
  static String defaultCalculationMethod(String? zoneName, double lat, double lng) {
    switch (zoneName) {
      case 'Asia/Riyadh':
      case 'Asia/Mecca':
      case 'Asia/Jeddah':
        return 'Umm Al-Qura';
      case 'Asia/Tehran':
        return 'Tehran';
      case 'Asia/Kuwait':
        return 'Kuwait';
      case 'Asia/Qatar':
        return 'Qatar';
      case 'Asia/Dubai':
      case 'Asia/Muscat':
        return 'Gulf';
      case 'Africa/Cairo':
        return 'Egyptian';
      case 'Asia/Karachi':
      case 'Asia/Kolkata':
      case 'Asia/Calcutta':
      case 'Asia/Dhaka':
      case 'Asia/Kabul':
      case 'Asia/Colombo':
      case 'Asia/Kathmandu':
        return 'Karachi';
      case 'Asia/Singapore':
      case 'Asia/Kuala_Lumpur':
      case 'Asia/Jakarta':
      case 'Asia/Brunei':
        return 'Singapore';
    }

    // The US and Canada span dozens of zone names, so match the continent
    // instead of listing them. Kept north of the Tropic of Cancer so Central
    // and South America fall through to the international default.
    final inNorthAmerica = lat > 24 && lat < 72 && lng > -170 && lng < -52;
    if (inNorthAmerica) return 'ISNA';

    return 'Muslim World League';
  }
}
