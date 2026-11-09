import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';
import 'package:sukkur_prayer_timings/widgets/translation_reader.dart';

void silencePluginChannels() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in const [
    'home_widget',
    'dexterous.com/flutter/local_notifications',
    'flutter.baseflow.com/geocoding',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(name), (call) async => null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(silencePluginChannels);

  group('SettingsProvider translation mode tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults according to app language when no preference set', () async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      // Default language in mock is 'english'
      expect(settings.quranTranslationMode, QuranTranslationMode.english);

      // Change language to urdu
      await settings.setLanguage('urdu');
      expect(settings.quranTranslationMode, QuranTranslationMode.urdu);

      // Change back to english
      await settings.setLanguage('english');
      expect(settings.quranTranslationMode, QuranTranslationMode.english);
    });

    test('persists user-chosen translation mode', () async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      await settings.setQuranTranslationMode(QuranTranslationMode.both);
      expect(settings.quranTranslationMode, QuranTranslationMode.both);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quran_translation_mode'), 'both');

      // Even if app language changes, user's explicit preference stays
      await settings.setLanguage('urdu');
      expect(settings.quranTranslationMode, QuranTranslationMode.both);

      // Now switch explicitly to english
      await settings.setQuranTranslationMode(QuranTranslationMode.english);
      expect(settings.quranTranslationMode, QuranTranslationMode.english);
      expect(prefs.getString('quran_translation_mode'), 'english');
    });

    test('loads saved preference from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'quran_translation_mode': 'urdu',
        'language_code': 'english',
      });

      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      expect(settings.quranTranslationMode, QuranTranslationMode.urdu);
    });

    test('resetToDefaults clears quran translation mode', () async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();
      await settings.setQuranTranslationMode(QuranTranslationMode.both);
      expect(settings.quranTranslationMode, QuranTranslationMode.both);

      await settings.resetToDefaults();
      expect(settings.quranTranslationMode, QuranTranslationMode.english);
    });
  });

  group('TranslationReader 3-way selector widget tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<void> pumpReader(
      WidgetTester tester, {
      required SettingsProvider settings,
    }) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranslationReader(
              surahNumber: 1,
              settings: settings,
              isDark: false,
              isChromeVisible: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders 3-way translation selector in English', (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();
      await settings.setLanguage('english');

      await pumpReader(tester, settings: settings);

      expect(find.text('Urdu'), findsWidgets);
      expect(find.text('English'), findsWidgets);
      expect(find.text('Both'), findsWidgets);
    });

    testWidgets('renders 3-way translation selector in Urdu', (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();
      await settings.setLanguage('urdu');

      await pumpReader(tester, settings: settings);

      expect(find.text('اردو'), findsWidgets);
      expect(find.text('انگریزی'), findsWidgets);
      expect(find.text('دونوں'), findsWidgets);
    });

    testWidgets('renders 3-way translation selector in Sindhi and Arabic', (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      // Sindhi
      await settings.setLanguage('sindhi');
      await pumpReader(tester, settings: settings);
      expect(find.text('اردو'), findsWidgets);
      expect(find.text('انگريزي'), findsWidgets);
      expect(find.text('ٻئي'), findsWidgets);

      // Arabic
      await settings.setLanguage('arabic');
      await pumpReader(tester, settings: settings);
      expect(find.text('الأردية'), findsWidgets);
      expect(find.text('الإنجليزية'), findsWidgets);
      expect(find.text('كلاهما'), findsWidgets);
    });

    testWidgets('renders 3-way translation selector in all other 6 languages', (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      // Hindi
      await settings.setLanguage('hindi');
      await pumpReader(tester, settings: settings);
      expect(find.text('उर्दू'), findsWidgets);
      expect(find.text('अंग्रेज़ी'), findsWidgets);
      expect(find.text('दोनों'), findsWidgets);

      // Bengali
      await settings.setLanguage('bengali');
      await pumpReader(tester, settings: settings);
      expect(find.text('উর্দু'), findsWidgets);
      expect(find.text('ইংরেজি'), findsWidgets);
      expect(find.text('উভয়'), findsWidgets);

      // Turkish
      await settings.setLanguage('turkish');
      await pumpReader(tester, settings: settings);
      expect(find.text('Urduca'), findsWidgets);
      expect(find.text('İngilizce'), findsWidgets);
      expect(find.text('Her İkisi'), findsWidgets);

      // Indonesian
      await settings.setLanguage('indonesian');
      await pumpReader(tester, settings: settings);
      expect(find.text('Urdu'), findsWidgets);
      expect(find.text('Inggris'), findsWidgets);
      expect(find.text('Keduanya'), findsWidgets);

      // French
      await settings.setLanguage('french');
      await pumpReader(tester, settings: settings);
      expect(find.text('Ourdou'), findsWidgets);
      expect(find.text('Anglais'), findsWidgets);
      expect(find.text('Les deux'), findsWidgets);

      // Persian
      await settings.setLanguage('persian');
      await pumpReader(tester, settings: settings);
      expect(find.text('اردو'), findsWidgets);
      expect(find.text('انگلیسی'), findsWidgets);
      expect(find.text('هر دو'), findsWidgets);
    });

    testWidgets('toggling between Urdu, English, and Both updates mode', (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();
      await settings.setLanguage('english');

      await pumpReader(tester, settings: settings);

      // Tap Urdu option
      await tester.tap(find.text('Urdu').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(settings.quranTranslationMode, QuranTranslationMode.urdu);

      // Tap Both option
      await tester.tap(find.text('Both').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(settings.quranTranslationMode, QuranTranslationMode.both);

      // Tap English option
      await tester.tap(find.text('English').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(settings.quranTranslationMode, QuranTranslationMode.english);
    });

    testWidgets('handles extreme text scaling on narrow 320px screen without overflow', (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();
      await settings.setLanguage('urdu');

      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranslationReader(
              surahNumber: 1,
              settings: settings,
              isDark: false,
              isChromeVisible: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('reacts to external SettingsProvider updates', (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();
      await settings.setLanguage('english');

      await pumpReader(tester, settings: settings);

      // Mode changed externally
      await settings.setQuranTranslationMode(QuranTranslationMode.both);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Language changed externally to urdu
      await settings.setLanguage('urdu');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('دونوں'), findsWidgets);
    });
  });
}
