import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../utils/alert_mode.dart';
import '../utils/app_theme.dart';
import '../utils/world_location.dart';
import '../data/timings_data.dart';

enum TimeFormat { system, h12, h24 }

enum DarkModeOption { on, off, auto }

enum ClockStyle {
  classic, minimal, sketch, dusk, linen, rose, sage, carbon, ocean,
  ivory, lavender, coral, mint, peach, champagne
}

enum DisplayTheme {
  defaultLight,
  skyGlow,
  linenStone,
  softOcean,
  emeraldMasjid,
}

enum UnifiedTheme {
  defaultLight,
  skyGlow,
  linenStone,
  softOcean,
  emeraldMasjid,
}

enum LocationMode { sukkur, world }

/// Sukkur has its own Jantri, which is more accurate than anything the world
/// calculation can produce, so Sukkur must never be stored as a world city -
/// not under its own name, and not by coordinates. This lives here rather than
/// on the world screen because every entry point has to honour it: the city
/// search, "Get Current Location", the onboarding GPS step, and prefs written
/// by older builds that had no such check.
class SukkurLocation {
  static const lat = 27.7052;
  static const lng = 68.8574;

  /// 20 km covers Sukkur, New Sukkur and Rohri across the river, while leaving
  /// genuinely separate cities like Khairpur (~22 km) free to be selected.
  static const radiusMetres = 20000.0;

  static const _names = [
    'sukkur', 'sukur', 'sukkar', 'sakkhar', 'سکھر', 'سکر', 'سكر',
  ];

  static bool matchesName(String? name) {
    if (name == null) return false;
    final n = name.toLowerCase();
    return _names.any(n.contains);
  }

  /// Shortest prefix that is unambiguous enough to be worth answering. Two
  /// letters would fire on half of Sindh; three is where "suk" stops being a
  /// coincidence.
  static const _minLookingForLength = 3;

  /// True when someone typing [query] is plainly heading for Sukkur - either
  /// they have written one of its names, or what they have so far is the start
  /// of one.
  ///
  /// The search list withholds Sukkur outright, which left the user staring at
  /// a result that never came. This is what lets the picker say why instead.
  static bool looksLikeSearchFor(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < _minLookingForLength) return false;
    return _names.any((n) => q.contains(n) || n.startsWith(q));
  }

  static bool isNear(double latitude, double longitude) =>
      _distanceMetres(latitude, longitude, lat, lng) <= radiusMetres;

  /// True when this place should be served by the Jantri instead of the world
  /// calculation - either it is named Sukkur or it sits right beside it.
  static bool covers(double latitude, double longitude, String? city) =>
      matchesName(city) || isNear(latitude, longitude);

  /// Haversine. Kept local so the provider stays free of plugin imports; at a
  /// 20 km threshold the choice of earth model makes no practical difference.
  static double _distanceMetres(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    double toRad(double d) => d * math.pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

class SettingsProvider extends ChangeNotifier {
  DarkModeOption _darkModeOption = DarkModeOption.auto;
  String _language = 'english';
  bool _notificationsEnabled = true;
  bool _hasCompletedSetup = false;
  int _hijriAdjustment = 0;
  int _selectedAzanIndex = 0;
  TimeFormat _timeFormat = TimeFormat.system;
  ClockStyle _clockStyle = ClockStyle.classic;
  DisplayTheme _displayTheme = DisplayTheme.defaultLight;
  UnifiedTheme _unifiedTheme = UnifiedTheme.defaultLight;
  int _tasbeehThemeIndex = 0; // default is 0 (gray)
  String _circleWidgetStyle = 'digital';

  LocationMode _locationMode = LocationMode.sukkur;
  double? _latitude;
  double? _longitude;
  String? _cityName;
  /// IANA zone for the stored city, e.g. 'Europe/London'. Null only when the
  /// lookup could not place the coordinates.
  String? _cityTimezone;
  String _calculationMethod = 'Karachi';
  /// True once the user has picked a method themselves, which stops a newly
  /// selected city from applying its regional default over the top.
  bool _calculationMethodManual = false;
  bool _worldAlertsFollowDevice = false;
  String _asrMethod = 'Hanafi';

  bool _autoSilentEnabled = false;
  String _autoSilentMode = 'vibrate';

  final Map<String, int> _autoSilentOffsets = {
    'Fajar': 15,
    'Zuhar': 15,
    'Misl Awwal': 15,
    'Asr Hanafi': 15,
    'Maghrib': 5,
    'Isha': 15,
  };

  final Map<String, int> _autoSilentDurations = {
    'Fajar': 20,
    'Zuhar': 20,
    'Misl Awwal': 20,
    'Asr Hanafi': 20,
    'Maghrib': 15,
    'Isha': 20,
  };

  final Map<String, bool> _autoSilentPrayerToggles = {
    'Fajar': true,
    'Zuhar': true,
    'Misl Awwal': true,
    'Asr Hanafi': true,
    'Maghrib': true,
    'Isha': true,
  };

  final Map<String, bool> _prayerToggles = {
    'Intiha e Sehar': true,
    'Fajar': true,
    'Tulu Aftab': true,
    'Ishraq': true,
    'Zawal': true,
    'Zuhar': true,
    'Misl Awwal': true,
    'Asr Hanafi': true,
    'Maghrib': true,
    'Isha': true,
  };

  final Map<String, AlertMode> _alertModes = {
    'Intiha e Sehar': AlertMode.loud,
    'Fajar': AlertMode.loud,
    'Tulu Aftab': AlertMode.loud,
    'Ishraq': AlertMode.loud,
    'Zawal': AlertMode.loud,
    'Zuhar': AlertMode.loud,
    'Misl Awwal': AlertMode.loud,
    'Asr Hanafi': AlertMode.loud,
    'Maghrib': AlertMode.loud,
    'Isha': AlertMode.loud,
  };

  // Must match NotificationService._prefKeys exactly to avoid key mismatch.
  static const _notifyPrefKeys = {
    'Intiha e Sehar': 'notify_subah_sadiq',
    'Fajar': 'notify_fajar',
    'Tulu Aftab': 'notify_tulu_aftab',
    'Ishraq': 'notify_ishraq',
    'Zawal': 'notify_zawal',
    'Zuhar': 'notify_zuhar',
    'Misl Awwal': 'notify_misl_awwal',
    'Asr Hanafi': 'notify_asr_hanafi',
    'Maghrib': 'notify_maghrib',
    'Isha': 'notify_isha',
  };

  static const _alertModePrefKeys = {
    'Intiha e Sehar': 'alert_mode_subah_sadiq',
    'Fajar': 'alert_mode_fajar',
    'Tulu Aftab': 'alert_mode_tulu_aftab',
    'Ishraq': 'alert_mode_ishraq',
    'Zawal': 'alert_mode_zawal',
    'Zuhar': 'alert_mode_zuhar',
    'Misl Awwal': 'alert_mode_misl_awwal',
    'Asr Hanafi': 'alert_mode_asr_hanafi',
    'Maghrib': 'alert_mode_maghrib',
    'Isha': 'alert_mode_isha',
  };

  DarkModeOption get darkModeOption => _darkModeOption;
  bool get darkMode => _darkModeOption == DarkModeOption.on;
  String get language => _language;
  bool get isUrdu => _language == 'urdu';
  bool get isSindhi => _language == 'sindhi';
  bool get isArabic => _language == 'arabic';
  bool get isRtl => rtlLanguages.contains(_language);

  /// Every selectable language mapped to its own native name. The picker must
  /// read the selected language's name from here, never through [translate],
  /// which resolves against the *currently selected* language and so would
  /// fall back to 'English' for every world language.
  static const Map<String, String> languageNames = languageNamesMap;

  /// Native name of the language currently in use.
  String get languageName => languageNames[_language] ?? 'English';

  String translate(String en, String ur, String sd, [String? ar]) =>
      translateFor(_language, en, ur, sd, ar);

  bool get notificationsEnabled => _notificationsEnabled;
  bool get hasCompletedSetup => _hasCompletedSetup;
  int get hijriAdjustment => _hijriAdjustment;
  int get selectedAzanIndex => _selectedAzanIndex;
  TimeFormat get timeFormat => _timeFormat;
  ClockStyle get clockStyle => _clockStyle;
  DisplayTheme get displayTheme => _displayTheme;
  UnifiedTheme get unifiedTheme => _unifiedTheme;
  int get tasbeehThemeIndex => _tasbeehThemeIndex;
  String get circleWidgetStyle => _circleWidgetStyle;

  /// The mode the app is *actually* running in, which is not the same as the
  /// stored one. World mode with no city behind it resolves to Sukkur, because
  /// that is what the data layer already serves: TimingsData falls back to the
  /// Jantri when there are no coordinates. Sukkur mode with a city remembered
  /// behind it likewise resolves to Sukkur - the city is on file, not in use.
  ///
  /// Every screen that decides which prayer set to draw must use this, or it
  /// renders the six-prayer world layout over eleven-field Jantri data and the
  /// columns silently shift.
  LocationMode get locationMode =>
      usesCalculatedTimings ? LocationMode.world : LocationMode.sukkur;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get cityName => _cityName;
  String? get cityTimezone => _cityTimezone;

  /// True when a watched city's alerts should land on the phone's clock rather
  /// than the city's. Only observable when the two differ - i.e. when the user
  /// is not actually in the city they picked.
  bool get worldAlertsFollowDevice => _worldAlertsFollowDevice;

  Future<void> setWorldAlertsFollowDevice(bool value) async {
    if (_worldAlertsFollowDevice == value) return;
    _worldAlertsFollowDevice = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        TimingsData.alertTimezoneKey, value ? 'device' : 'city');
    // The whole schedule is pinned to one clock or the other, so it all has to
    // be rewritten - as does the widget, which reads the same preference.
    await TimingsData.instance.syncWorldTimingsToCache();
    WidgetService.updateWidget();
    if (_notificationsEnabled) {
      await NotificationService.instance.scheduleWeeklyNotifications();
    }
  }

  /// BCP-47 code for the current app language, for asking the platform
  /// geocoder to return place names in the user's own script.
  String get localeIdentifier => const {
        'urdu': 'ur',
        'sindhi': 'sd',
        'arabic': 'ar',
        'bengali': 'bn',
        'indonesian': 'id',
        'turkish': 'tr',
        'french': 'fr',
        'hindi': 'hi',
        'persian': 'fa',
      }[_language] ??
      'en';
  String get calculationMethod => _calculationMethod;
  String get asrMethod => _asrMethod;

  bool get autoSilentEnabled => _autoSilentEnabled;
  String get autoSilentMode => _autoSilentMode;

  int getAutoSilentOffset(String prayer) => _autoSilentOffsets[prayer] ?? 15;
  int getAutoSilentDuration(String prayer) => _autoSilentDurations[prayer] ?? 20;
  bool isAutoSilentPrayerEnabled(String prayer) => _autoSilentPrayerToggles[prayer] ?? true;

  Future<void> setLocationMode(LocationMode mode) async {
    if (_locationMode == mode) return;
    _locationMode = mode;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      // Something may have overridden the mode inside the delay - notably a
      // rejected Sukkur selection handing the timings back to the Jantri.
      // Writing the stale mode here would undo that.
      if (_locationMode != mode) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('location_mode', mode.name);
      if (mode == LocationMode.world) {
        await TimingsData.instance.syncWorldTimingsToCache();
      }
      WidgetService.updateWidget();
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  /// True once world mode actually has a city to calculate for. Both halves
  /// matter: coordinates with the mode set to Sukkur mean a city the user has
  /// parked behind the Jantri, and world mode without coordinates means a
  /// mode nothing backs. Either way the Jantri is what gets drawn.
  bool get usesCalculatedTimings =>
      _locationMode == LocationMode.world &&
      _latitude != null &&
      _longitude != null;

  /// A world city is on file, whether or not it is the one currently driving
  /// the timings. The World screen offers it back as "last selected".
  bool get hasStoredWorldCity =>
      _cityName != null && _latitude != null && _longitude != null;

  /// Switches to the Jantri while *keeping* the last world city on file, so
  /// the World screen can offer it back with one tap. The city stays inert:
  /// [usesCalculatedTimings] is false in Sukkur mode regardless of coordinates.
  ///
  /// Use [forgetWorldCity] instead when the stored city itself is the problem.
  Future<void> useSukkurJantri() async {
    _locationMode = LocationMode.sukkur;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location_mode', LocationMode.sukkur.name);
    // Otherwise the home-screen widget would keep serving the last calculated
    // month; with no cache it falls back to the bundled Jantri asset.
    await prefs.remove('world_timings_cache');
    WidgetService.updateWidget();
    if (_notificationsEnabled) {
      await NotificationService.instance.scheduleWeeklyNotifications();
    }
    notifyListeners();
  }

  /// Erases the stored world city outright and returns to the Jantri. For
  /// places that must never be offered again - Sukkur smuggled in by an older
  /// build - rather than the ordinary "show me the Jantri for now" switch.
  Future<void> forgetWorldCity() async {
    _latitude = null;
    _longitude = null;
    _cityName = null;
    _cityTimezone = null;
    _locationMode = LocationMode.sukkur;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location_mode', LocationMode.sukkur.name);
    await prefs.remove('latitude');
    await prefs.remove('longitude');
    await prefs.remove('city_name');
    await prefs.remove('city_timezone');
    await prefs.remove('world_timings_cache');
    WidgetService.updateWidget();
    if (_notificationsEnabled) {
      await NotificationService.instance.scheduleWeeklyNotifications();
    }
    notifyListeners();
  }

  /// Puts the remembered city back in charge. Returns false when there is
  /// nothing to restore, or when what is on file turns out to be Sukkur - in
  /// which case it is erased rather than resurrected, and the Jantri stands.
  Future<bool> useLastWorldCity() async {
    final lat = _latitude, lng = _longitude;
    if (lat == null || lng == null) return false;
    if (SukkurLocation.covers(lat, lng, _cityName)) {
      await forgetWorldCity();
      return false;
    }
    await setLocationMode(LocationMode.world);
    return true;
  }

  /// World mode is only meaningful with a real, non-Sukkur city behind it.
  /// Anything else falls back to the Jantri.
  Future<void> ensureWorldLocationValid() async {
    if (_locationMode != LocationMode.world) return;
    final lat = _latitude, lng = _longitude;
    if (lat == null || lng == null || SukkurLocation.covers(lat, lng, _cityName)) {
      await forgetWorldCity();
    }
  }

  /// Returns false when the place is Sukkur (or right beside it). Nothing is
  /// stored and nothing else changes - the caller just tells the user to pick
  /// the Jantri from the side bar. With no Sukkur coordinates on file, every
  /// screen keeps falling back to the Jantri's own timings.
  Future<bool> setLocation(double lat, double lng, String city) async {
    if (SukkurLocation.covers(lat, lng, city)) return false;
    _latitude = lat;
    _longitude = lng;
    _cityName = city;
    // Both are pure lookups on the coordinates, so they can be resolved now and
    // are on file before anything asks for a timing.
    _cityTimezone = WorldLocation.timezoneNameFor(lat, lng);
    // A city the user has never overridden the method for gets its own region's
    // convention - London on Karachi angles was simply wrong. Touching the
    // dropdown once pins the choice and this stops reaching for it.
    if (!_calculationMethodManual) {
      _calculationMethod =
          WorldLocation.defaultCalculationMethod(_cityTimezone, lat, lng);
    }
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      // Superseded within the delay - don't resurrect a cleared location.
      if (_latitude != lat || _longitude != lng) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latitude', lat);
      await prefs.setDouble('longitude', lng);
      await prefs.setString('city_name', city);
      await prefs.setString('calculation_method', _calculationMethod);
      // Written before the sync below, which reads it back to place the city
      // on its own clock rather than the phone's.
      final zone = _cityTimezone;
      if (zone != null) {
        await prefs.setString('city_timezone', zone);
      } else {
        await prefs.remove('city_timezone');
      }
      await TimingsData.instance.syncWorldTimingsToCache();
      WidgetService.updateWidget();
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
      notifyListeners();
    });
    return true;
  }

  Future<void> setCalculationMethod(String method) async {
    if (_calculationMethod == method) return;
    _calculationMethod = method;
    // From here on this is the user's choice, not a regional default, so
    // picking another city must not quietly overwrite it.
    _calculationMethodManual = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('calculation_method', method);
      await prefs.setBool('calculation_method_manual', true);
      await TimingsData.instance.syncWorldTimingsToCache();
      WidgetService.updateWidget();
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
      notifyListeners();
    });
  }

  Future<void> setAsrMethod(String method) async {
    if (_asrMethod == method) return;
    _asrMethod = method;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('asr_method', method);
      await TimingsData.instance.syncWorldTimingsToCache();
      WidgetService.updateWidget();
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
      notifyListeners();
    });
  }

  Future<void> setAutoSilentPrayerEnabled(String prayer, bool value) async {
    if (_autoSilentPrayerToggles[prayer] == value) return;
    _autoSilentPrayerToggles[prayer] = value;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_silent_enabled_$prayer', value);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }


  Future<void> setAutoSilentEnabled(bool value) async {
    if (_autoSilentEnabled == value) return;
    _autoSilentEnabled = value;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_silent_enabled', value);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  Future<void> setAutoSilentMode(String mode) async {
    if (_autoSilentMode == mode) return;
    _autoSilentMode = mode;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auto_silent_mode', mode);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  Future<void> setAutoSilentOffset(String prayer, int offset) async {
    if (_autoSilentOffsets[prayer] == offset) return;
    _autoSilentOffsets[prayer] = offset;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auto_silent_offset_$prayer', offset);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  Future<void> setAutoSilentDuration(String prayer, int duration) async {
    if (_autoSilentDurations[prayer] == duration) return;
    _autoSilentDurations[prayer] = duration;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auto_silent_duration_$prayer', duration);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  Decoration getThemeDecoration(bool isDark) {
    switch (_displayTheme) {
      case DisplayTheme.defaultLight:
        return BoxDecoration(
          color: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F5F5),
        );
      case DisplayTheme.skyGlow:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFE0F2FE), const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)],
          ),
        );
      case DisplayTheme.linenStone:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1B18), const Color(0xFF12100E)]
                : [const Color(0xFFF4EFE6), const Color(0xFFE6DFD3)],
          ),
        );
      case DisplayTheme.softOcean:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF0B132B)]
                : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE), const Color(0xFFF0F9FF)],
          ),
        );
      case DisplayTheme.emeraldMasjid:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF091612), const Color(0xFF122C24)]
                : [const Color(0xFFF2F6F1), const Color(0xFFE4ECE2)],
          ),
        );
    }
  }

  Color displayThemeBg(bool isDark) {
    switch (_displayTheme) {
      case DisplayTheme.defaultLight:
        return isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F5F5);
      case DisplayTheme.skyGlow:
        return isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE);
      case DisplayTheme.linenStone:
        return isDark ? const Color(0xFF1E1B18) : const Color(0xFFF4EFE6);
      case DisplayTheme.softOcean:
        return isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF);
      case DisplayTheme.emeraldMasjid:
        return isDark ? const Color(0xFF091612) : const Color(0xFFF2F6F1);
    }
  }

  Color displayThemeAccent() {
    switch (_displayTheme) {
      case DisplayTheme.defaultLight:
        return const Color(0xFF1E88E5);
      case DisplayTheme.skyGlow:
        return const Color(0xFF0284C7);
      case DisplayTheme.linenStone:
        return const Color(0xFFD97706);
      case DisplayTheme.softOcean:
        return const Color(0xFF0EA5E9);
      case DisplayTheme.emeraldMasjid:
        return const Color(0xFF0F8A5F);
    }
  }

  Color displayThemeNavBar(bool isDark) {
    if (isDark) return const Color(0xFF12122A);
    switch (_displayTheme) {
      case DisplayTheme.defaultLight:
        return Colors.white;
      case DisplayTheme.skyGlow:
        return const Color(0xFFFFFBEB);
      case DisplayTheme.linenStone:
        return const Color(0xFFE6DFD3);
      case DisplayTheme.softOcean:
        return const Color(0xFFE0F2FE);
      case DisplayTheme.emeraldMasjid:
        return const Color(0xFFE3ECE1);
    }
  }

  /// Card / surface colour that sits on top of [displayThemeBg].
  Color displayThemeCard(bool isDark) {
    return isDark ? const Color(0xFF1E1E2E) : Colors.white;
  }

  Color displayThemeCardBorder(bool isDark) {
    return isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);
  }

  /// Keeps the global [AppTheme.accent] in sync with the selected theme so
  /// every screen that reads it re-themes on the next rebuild.
  void _syncAccent() {
    AppTheme.accent = displayThemeAccent();
  }

  bool isPrayerEnabled(String prayer) => _prayerToggles[prayer] ?? true;
  bool get isAnyPrayerEnabled => _prayerToggles.values.any((v) => v);
  AlertMode getAlertMode(String prayer) {
    final mode = _alertModes[prayer] ?? AlertMode.loud;
    if ((prayer == 'Intiha e Sehar' || prayer == 'Zawal') && mode == AlertMode.azan) {
      return AlertMode.loud;
    }
    return mode;
  }

  /// Formats a "HH:MM" string according to the selected time format.
  String formatTime(String timeStr, {bool systemUse24h = false}) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final use12h = _timeFormat == TimeFormat.h12 ||
        (_timeFormat == TimeFormat.system && !systemUse24h);
    if (use12h) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final h = hour % 12 == 0 ? 12 : hour % 12;
      return '$h:${minute.toString().padLeft(2, '0')} $period';
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final dmRaw = prefs.getString('dark_mode_option');
    _darkModeOption = DarkModeOption.values.firstWhere(
      (e) => e.name == dmRaw,
      orElse: () {
        // migrate old bool pref
        final oldBool = prefs.getBool('dark_mode');
        if (oldBool == true) return DarkModeOption.on;
        if (oldBool == false) return DarkModeOption.off;
        return DarkModeOption.auto;
      },
    );
    final langRaw = prefs.getString('language_code');
    if (langRaw != null) {
      _language = langRaw;
    } else {
      if (prefs.getBool('is_sindhi') == true) {
        _language = 'sindhi';
      } else if (prefs.getBool('is_urdu') == true) {
        _language = 'urdu';
      } else if (prefs.getBool('is_arabic') == true) {
        _language = 'arabic';
      } else {
        _language = 'english';
      }
    }
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _hasCompletedSetup = prefs.getBool('has_completed_setup') ?? false;
    _hijriAdjustment = prefs.getInt('hijri_adjustment') ?? 0;
    _selectedAzanIndex = prefs.getInt('selected_azan') ?? 0;
    _tasbeehThemeIndex = prefs.getInt('tasbeeh_theme') ?? 0;
    _circleWidgetStyle = prefs.getString('circle_widget_style') ?? 'digital';
    final tf = prefs.getInt('time_format') ?? 0;
    _timeFormat = TimeFormat.values[tf.clamp(0, 2)];
    _clockStyle = ClockStyle.values[(prefs.getInt('clock_style') ?? 0).clamp(0, ClockStyle.values.length - 1)];
    _displayTheme = DisplayTheme.values[(prefs.getInt('display_theme') ?? 0).clamp(0, DisplayTheme.values.length - 1)];
    _unifiedTheme = UnifiedTheme.values[(prefs.getInt('unified_theme') ?? 0).clamp(0, UnifiedTheme.values.length - 1)];
    _tasbeehThemeIndex = prefs.getInt('tasbeeh_theme_index') ?? 0;
    _autoSilentEnabled = prefs.getBool('auto_silent_enabled') ?? false;
    _autoSilentMode = prefs.getString('auto_silent_mode') ?? 'vibrate';

    final locRaw = prefs.getString('location_mode');
    if (locRaw != null) {
      _locationMode = LocationMode.values.firstWhere(
        (e) => e.name == locRaw,
        orElse: () => LocationMode.sukkur,
      );
    }
    _latitude = prefs.getDouble('latitude');
    _longitude = prefs.getDouble('longitude');
    _cityName = prefs.getString('city_name');

    // Older builds - and the onboarding GPS step for anyone actually standing
    // in Sukkur - could leave Sukkur itself on file as a world city. In world
    // mode that served calculated timings in place of the Jantri across Times,
    // Today and Monthly; now that a stored city outlives a switch back to the
    // Jantri, it would also resurface as "last selected". Erase it on launch,
    // whichever mode it was left in.
    final storedLat = _latitude, storedLng = _longitude;
    if (storedLat != null &&
        storedLng != null &&
        SukkurLocation.covers(storedLat, storedLng, _cityName)) {
      _locationMode = LocationMode.sukkur;
      _latitude = null;
      _longitude = null;
      _cityName = null;
      await prefs.setString('location_mode', LocationMode.sukkur.name);
      await prefs.remove('latitude');
      await prefs.remove('longitude');
      await prefs.remove('city_name');
      await prefs.remove('world_timings_cache');
    } else if (_locationMode == LocationMode.world &&
        (storedLat == null || storedLng == null)) {
      // World mode with nothing behind it. There is no city to erase - just
      // stop claiming a mode the data layer cannot honour.
      _locationMode = LocationMode.sukkur;
      await prefs.setString('location_mode', LocationMode.sukkur.name);
      await prefs.remove('world_timings_cache');
    }

    _calculationMethod = prefs.getString('calculation_method') ?? 'Karachi';
    _calculationMethodManual =
        prefs.getBool('calculation_method_manual') ?? false;
    _cityTimezone = prefs.getString('city_timezone');
    _worldAlertsFollowDevice =
        (prefs.getString(TimingsData.alertTimezoneKey) ?? 'city') == 'device';
    // A city stored by a build that predates timezone support has no zone on
    // file. Resolve it from the coordinates rather than leaving that city
    // calculating on the phone's clock until it is picked again. Reads the
    // fields, not the prefs, so a city the Sukkur check just erased above stays
    // erased.
    final lat = _latitude, lng = _longitude;
    if (_cityTimezone == null && lat != null && lng != null) {
      _cityTimezone = WorldLocation.timezoneNameFor(lat, lng);
      if (_cityTimezone != null) {
        await prefs.setString('city_timezone', _cityTimezone!);
      }
    }
    _asrMethod = prefs.getString('asr_method') ?? 'Hanafi';

    for (final key in _autoSilentOffsets.keys) {
      _autoSilentOffsets[key] = prefs.getInt('auto_silent_offset_$key') ?? _autoSilentOffsets[key]!;
      _autoSilentDurations[key] = prefs.getInt('auto_silent_duration_$key') ?? _autoSilentDurations[key]!;
    }
    for (final key in _autoSilentPrayerToggles.keys) {
      _autoSilentPrayerToggles[key] = prefs.getBool('auto_silent_enabled_$key') ?? true;
    }
    _syncAccent();

    for (final key in _prayerToggles.keys) {
      final prefKey = _notifyPrefKeys[key];
      if (prefKey != null) {
        _prayerToggles[key] = prefs.getBool(prefKey) ?? true;
      }
    }

    for (final entry in _alertModePrefKeys.entries) {
      final raw = prefs.getString(entry.value);
      if (raw != null) {
        _alertModes[entry.key] = AlertMode.values.firstWhere(
          (m) => m.name == raw,
          orElse: () => AlertMode.loud,
        );
      }
    }

    // Load Quran Progress
    _lastReadType = prefs.getString('last_read_type');
    _lastReadId = prefs.getInt('last_read_id');

    for (final key in prefs.getKeys()) {
      if (key.startsWith('surah_progress_')) {
        final id = int.tryParse(key.replaceFirst('surah_progress_', ''));
        if (id != null) _surahProgress[id] = prefs.getInt(key) ?? 0;
      } else if (key.startsWith('parah_progress_')) {
        final id = int.tryParse(key.replaceFirst('parah_progress_', ''));
        if (id != null) _parahProgress[id] = prefs.getInt(key) ?? 0;
      }
    }

    notifyListeners();
  }

  // --- Quran Progress Tracking ---
  final Map<int, int> _surahProgress = {};
  final Map<int, int> _parahProgress = {};
  String? _lastReadType; // 'surah' or 'parah'
  int? _lastReadId;

  Map<int, int> get surahProgress => _surahProgress;
  Map<int, int> get parahProgress => _parahProgress;
  String? get lastReadType => _lastReadType;
  int? get lastReadId => _lastReadId;

  Future<void> updateSurahProgress(int surahNumber, int ayahNumber) async {
    _lastReadType = 'surah';
    _lastReadId = surahNumber;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_type', 'surah');
    await prefs.setInt('last_read_id', surahNumber);

    final current = _surahProgress[surahNumber] ?? 0;
    if (ayahNumber > current) {
      _surahProgress[surahNumber] = ayahNumber;
      await prefs.setInt('surah_progress_$surahNumber', ayahNumber);
      // We do not call notifyListeners() here to avoid excessive rebuilds during scrolling.
      // Progress will be visible when user returns to Quran screen.
    }
  }

  Future<void> updateParahProgress(int parahNumber, int pageNumber) async {
    _lastReadType = 'parah';
    _lastReadId = parahNumber;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_type', 'parah');
    await prefs.setInt('last_read_id', parahNumber);

    final current = _parahProgress[parahNumber] ?? 0;
    if (pageNumber > current) {
      _parahProgress[parahNumber] = pageNumber;
      await prefs.setInt('parah_progress_$parahNumber', pageNumber);
    }
  }

  Future<void> setDarkModeOption(DarkModeOption option) async {
    if (_darkModeOption == option) return;
    _darkModeOption = option;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dark_mode_option', option.name);
    });
  }

  Future<void> setDarkMode(bool value) async {
    await setDarkModeOption(value ? DarkModeOption.on : DarkModeOption.off);
  }

  Future<void> setLanguage(String langCode) async {
    if (_language == langCode) return;
    _language = langCode;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', langCode);
      await prefs.setBool('is_urdu', langCode == 'urdu');
      await prefs.setBool('is_sindhi', langCode == 'sindhi');
      await prefs.setBool('is_arabic', langCode == 'arabic');
      // A world city was geocoded in the previous language, so re-resolve it
      // before refreshing the widgets - otherwise it stays in the old script.
      await _relocaliseCityName();
      WidgetService.updateWidget();
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  /// Re-geocodes the saved world coordinates so the stored city name follows
  /// the current app language. Runs whenever a city is on file, not only while
  /// it is in charge - a city remembered behind the Jantri is still shown on
  /// the World screen. Keeps the existing name if the device geocoder has no
  /// localised entry or fails.
  Future<void> _relocaliseCityName() async {
    final lat = _latitude, lng = _longitude;
    if (lat == null || lng == null) return;
    try {
      await setLocaleIdentifier(localeIdentifier);
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return;
      final city = cityNameFrom(placemarks.first);
      if (city == null || city == _cityName) return;
      _cityName = city;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('city_name', city);
      notifyListeners();
    } catch (_) {
      // Geocoder unavailable - leave the previous name in place.
    }
  }

  Future<void> setIsUrdu(bool value) async {
    await setLanguage(value ? 'urdu' : 'english');
  }

  Future<void> completeSetup() async {
    _hasCompletedSetup = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_setup', true);
  }

  Future<void> setTasbeehThemeIndex(int index) async {
    if (_tasbeehThemeIndex != index) {
      _tasbeehThemeIndex = index;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 150), () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('tasbeeh_theme_index', index);
      });
    }
  }

  void setCircleWidgetStyle(String style) {
    if (_circleWidgetStyle != style) {
      _circleWidgetStyle = style;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 150), () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('circle_widget_style', style);
        WidgetService.updateWidget();
      });
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      await NotificationService.instance.setGlobalEnabled(value);
    });
  }

  Future<void> setHijriAdjustment(int value) async {
    if (_hijriAdjustment == value.clamp(-2, 2)) return;
    _hijriAdjustment = value.clamp(-2, 2);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hijri_adjustment', _hijriAdjustment);
      WidgetService.updateWidget();
    });
  }

  Future<void> setSelectedAzanIndex(int value) async {
    if (_selectedAzanIndex == value) return;
    _selectedAzanIndex = value;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_azan_index', value);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  Future<void> setPrayerEnabled(String prayer, bool value) async {
    if (_prayerToggles[prayer] == value) return;
    _prayerToggles[prayer] = value;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      await NotificationService.instance.setPrayerEnabled(prayer, value);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  Future<void> setAllPrayersEnabled(bool value) async {
    for (final prayer in _prayerToggles.keys) {
      _prayerToggles[prayer] = value;
    }
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      for (final prayer in _prayerToggles.keys) {
        await NotificationService.instance.setPrayerEnabled(prayer, value);
      }
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  Future<void> setTimeFormat(TimeFormat format) async {
    if (_timeFormat == format) return;
    _timeFormat = format;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('time_format', format.index);
      await WidgetService.updateWidget();
    });
  }

  Future<void> setClockStyle(ClockStyle style) async {
    if (_clockStyle == style) return;
    _clockStyle = style;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('clock_style', style.index);
    });
  }

  Future<void> setDisplayTheme(DisplayTheme theme) async {
    if (_displayTheme == theme) return;
    _displayTheme = theme;
    _syncAccent();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('display_theme', theme.index);
    });
  }

  Future<void> setUnifiedTheme(UnifiedTheme theme) async {
    _unifiedTheme = theme;
    // Map unified theme to display theme
    switch (theme) {
      case UnifiedTheme.defaultLight:
        _displayTheme = DisplayTheme.defaultLight;
        break;
      case UnifiedTheme.skyGlow:
        _displayTheme = DisplayTheme.skyGlow;
        break;
      case UnifiedTheme.linenStone:
        _displayTheme = DisplayTheme.linenStone;
        break;
      case UnifiedTheme.softOcean:
        _displayTheme = DisplayTheme.softOcean;
        break;
      case UnifiedTheme.emeraldMasjid:
        _displayTheme = DisplayTheme.emeraldMasjid;
        break;
    }
    _syncAccent();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unified_theme', theme.index);
      await prefs.setInt('display_theme', _displayTheme.index);
      await prefs.setInt('clock_style', _clockStyle.index);
    });
  }



  void applyClockAndTheme(ClockStyle style, DisplayTheme theme) {
    _clockStyle = style;
    _displayTheme = theme;
    _syncAccent();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () {
      _persistClockAndTheme(style, theme);
    });
  }

  Future<void> _persistClockAndTheme(ClockStyle style, DisplayTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('clock_style', style.index);
    await prefs.setInt('display_theme', theme.index);
  }

  Future<void> setAlertMode(String prayer, AlertMode mode) async {
    if (_alertModes[prayer] == mode) return;
    _alertModes[prayer] = mode;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      final key = _alertModePrefKeys[prayer];
      if (key != null) await prefs.setString(key, mode.name);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  Future<void> resetToDefaults() async {
    _notificationsEnabled = true;
    _hasCompletedSetup = false;
    _language = 'english';
    _darkModeOption = DarkModeOption.auto;
    _clockStyle = ClockStyle.classic;
    _displayTheme = DisplayTheme.defaultLight;
    _unifiedTheme = UnifiedTheme.defaultLight;
    _tasbeehThemeIndex = 0;
    _locationMode = LocationMode.sukkur;
    _syncAccent();
    _hijriAdjustment = 0;
    _selectedAzanIndex = 3;
    _timeFormat = TimeFormat.system;
    
    for (final key in _prayerToggles.keys) {
      _prayerToggles[key] = true;
    }
    for (final key in _alertModes.keys) {
      _alertModes[key] = AlertMode.loud;
    }
    
    _autoSilentEnabled = false;
    _autoSilentMode = 'vibrate';

    final defaultOffsets = {'Fajar': 15, 'Zuhar': 15, 'Misl Awwal': 15, 'Asr Hanafi': 15, 'Maghrib': 5, 'Isha': 15};
    final defaultDurations = {'Fajar': 20, 'Zuhar': 20, 'Misl Awwal': 20, 'Asr Hanafi': 20, 'Maghrib': 15, 'Isha': 20};
    for (final key in defaultOffsets.keys) {
      _autoSilentOffsets[key] = defaultOffsets[key]!;
      _autoSilentDurations[key] = defaultDurations[key]!;
    }
    for (final key in _autoSilentPrayerToggles.keys) {
      _autoSilentPrayerToggles[key] = true;
    }

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', true);
      await prefs.setBool('has_completed_setup', false);
      await prefs.setString('language_code', 'english');
      await prefs.setBool('is_urdu', false);
      await prefs.setBool('is_sindhi', false);
      await prefs.setBool('is_arabic', false);
      await prefs.setString('dark_mode_option', DarkModeOption.auto.name);
      await prefs.setInt('clock_style', ClockStyle.classic.index);
      await prefs.setInt('display_theme', DisplayTheme.defaultLight.index);
      await prefs.setInt('unified_theme', UnifiedTheme.defaultLight.index);
      await prefs.setInt('tasbeeh_theme_index', 0);
      await prefs.setInt('hijri_adjustment', _hijriAdjustment);
      await prefs.setInt('selected_azan', _selectedAzanIndex);
      await prefs.setInt('tasbeeh_theme', _tasbeehThemeIndex);
      await prefs.setString('circle_widget_style', _circleWidgetStyle);
      await prefs.setInt('time_format', TimeFormat.system.index);
      await prefs.setString('location_mode', LocationMode.sukkur.name);
      await prefs.remove('latitude');
      await prefs.remove('longitude');
      await prefs.remove('city_name');
      await prefs.setString('calculation_method', 'Karachi');
      await prefs.setString('asr_method', 'Hanafi');

      for (final key in _prayerToggles.keys) {
        final prefKey = _notifyPrefKeys[key];
        if (prefKey != null) {
          await prefs.setBool(prefKey, true);
        }
        await NotificationService.instance.setPrayerEnabled(key, true);
      }

      for (final key in _alertModes.keys) {
        final prefKey = _alertModePrefKeys[key];
        if (prefKey != null) {
          await prefs.setString(prefKey, AlertMode.loud.name);
        }
      }

      await prefs.setBool('auto_silent_enabled', false);
      await prefs.setString('auto_silent_mode', 'vibrate');

      for (final key in defaultOffsets.keys) {
        await prefs.setInt('auto_silent_offset_$key', defaultOffsets[key]!);
        await prefs.setInt('auto_silent_duration_$key', defaultDurations[key]!);
      }
      for (final key in _autoSilentPrayerToggles.keys) {
        await prefs.setBool('auto_silent_enabled_$key', true);
      }

      WidgetService.updateWidget();
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }
}
