import 'package:flutter/material.dart';

class AppTheme {
  static const String urduFont = 'JameelNooriNastaleeqKasheeda';

  /// Returns a clean Naskh font family for the platform to avoid fallback to Nastaliq (Urdu font) for Sindhi.
  static String getSindhiFont(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return 'Geeza Pro';
    } else if (platform == TargetPlatform.windows) {
      return 'Tahoma';
    } else {
      return 'sans-serif';
    }
  }

  /// Returns the appropriate font family based on the active language.
  static String? getFontForLanguage(BuildContext context, String language) {
    if (language == 'urdu') {
      return urduFont;
    } else if (language == 'sindhi') {
      return getSindhiFont(context);
    }
    return null;
  }

  // Accent colours (const — used inside const Icon / const Border widgets)
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentGold = Color(0xFFD4A574);
  static const Color accentGreen = Color(0xFF00897B);

  /// Live app accent — mirrors the user's selected DisplayTheme accent.
  /// Updated by [SettingsProvider] on load and whenever the theme changes,
  /// so every screen that reads [accent] re-themes on the next rebuild.
  static Color accent = accentGreen;

  // Primary palette
  static const Color primaryNavy = Color(0xFF0D1B3E);
  static const Color greyText   = Color(0xFF9E9E9E);

  // Dark surface colours
  static const Color drawerDark  = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color navBarDark  = Color(0xFF12122A);

  // Per-prayer accent colours
  static const Color fajrColor    = Color(0xFF7986CB);
  static const Color zuhrColor    = Color(0xFFFFA726);
  static const Color asrColor     = Color(0xFFFF7043);
  static const Color maghribColor = Color(0xFFEF5350);
  static const Color ishaColor    = Color(0xFF5C6BC0);
  static const Color sunriseColor = Color(0xFFFFCA28);

  static ThemeData light({String? fontFamily, Color? seed, Color? scaffoldBg}) {
    final accentSeed = seed ?? accent;
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentSeed,
        brightness: Brightness.light,
      ).copyWith(primary: accentSeed),
      scaffoldBackgroundColor: scaffoldBg ?? const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      fontFamily: fontFamily,
      useMaterial3: true,
    );
  }

  static ThemeData dark({String? fontFamily, Color? seed, Color? scaffoldBg}) {
    final accentSeed = seed ?? accent;
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentSeed,
        brightness: Brightness.dark,
      ).copyWith(primary: accentSeed),
      scaffoldBackgroundColor: scaffoldBg ?? const Color(0xFF0F0F1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: drawerDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      fontFamily: fontFamily,
      useMaterial3: true,
    );
  }
}
