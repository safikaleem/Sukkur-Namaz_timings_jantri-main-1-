import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../utils/alert_mode.dart';
import '../utils/app_theme.dart';
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
  String _calculationMethod = 'Karachi';
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

  LocationMode get locationMode => _locationMode;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get cityName => _cityName;

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

  Future<void> setLocation(double lat, double lng, String city) async {
    _latitude = lat;
    _longitude = lng;
    _cityName = city;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latitude', lat);
      await prefs.setDouble('longitude', lng);
      await prefs.setString('city_name', city);
      await TimingsData.instance.syncWorldTimingsToCache();
      WidgetService.updateWidget();
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    });
  }

  Future<void> setCalculationMethod(String method) async {
    if (_calculationMethod == method) return;
    _calculationMethod = method;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 150), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('calculation_method', method);
      await TimingsData.instance.syncWorldTimingsToCache();
      WidgetService.updateWidget();
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
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
    _calculationMethod = prefs.getString('calculation_method') ?? 'Karachi';
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
  /// the current app language. No-op outside world mode; keeps the existing
  /// name if the device geocoder has no localised entry or fails.
  Future<void> _relocaliseCityName() async {
    if (_locationMode != LocationMode.world) return;
    final lat = _latitude, lng = _longitude;
    if (lat == null || lng == null) return;
    try {
      await setLocaleIdentifier(localeIdentifier);
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return;
      final p = placemarks.first;
      final city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
      if (city == null || city.isEmpty || city == _cityName) return;
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
