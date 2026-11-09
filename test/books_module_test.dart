import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/data/ahmiyat_ramzan_data.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations_extra.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';
import 'package:sukkur_prayer_timings/screens/munajat_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Books Module Translations Test across 10 Languages', () {
    final expectedBooks = {
      'english': 'Books',
      'arabic': 'الكتب',
      'urdu': 'کتب',
      'sindhi': 'ڪتاب',
      'indonesian': 'Buku',
      'french': 'Livres',
      'hindi': 'किताबें',
      'persian': 'کتاب‌ها',
      'turkish': 'Kitaplar',
      'bengali': 'বইসমূহ',
    };

    final expectedAhmiyatRamzan = {
      'english': 'Ahmiyat-e-Ramzan',
      'arabic': 'أهمية رمضان',
      'urdu': 'اہمیتِ رمضان',
      'sindhi': 'اهميتِ رمضان',
      'indonesian': 'Ahmiyat-e-Ramzan',
      'french': 'Ahmiyat-e-Ramzan',
      'hindi': 'अहमियत-ए-रमज़ान',
      'persian': 'اهمیت رمضان',
      'turkish': 'Ahmiyet-i Ramazan',
      'bengali': 'আহমিয়াতে রমযান',
    };

    final expected13Chapters = {
      'english': '13 Chapters',
      'arabic': '١٣ باباً',
      'urdu': '۱۳ ابواب',
      'sindhi': '13 باب',
      'indonesian': '13 Bab',
      'french': '13 Chapitres',
      'hindi': '13 अध्याय',
      'persian': '۱۳ فصل',
      'turkish': '13 Bölüm',
      'bengali': '১৩টি অধ্যায়',
    };

    test('All 10 languages have valid Books translation via translateFor', () {
      for (final entry in expectedBooks.entries) {
        final translated = translateFor(
          entry.key,
          'Books',
          'کتب',
          'ڪتاب',
          'الكتب',
        );
        expect(translated, equals(entry.value),
            reason: 'Failed for language ${entry.key}');
      }
    });

    test('All 10 languages have additionalTranslations entries for keys', () {
      for (final lang in expectedBooks.keys) {
        expect(additionalTranslations[lang], isNotNull,
            reason: 'Language $lang missing in additionalTranslations');
        expect(additionalTranslations[lang]!['Books'], equals(expectedBooks[lang]),
            reason: 'Books missing or wrong in $lang');
        expect(additionalTranslations[lang]!['Ahmiyat-e-Ramzan'],
            equals(expectedAhmiyatRamzan[lang]),
            reason: 'Ahmiyat-e-Ramzan missing or wrong in $lang');
        expect(additionalTranslations[lang]!['13 Chapters'],
            equals(expected13Chapters[lang]),
            reason: '13 Chapters missing or wrong in $lang');
        expect(additionalTranslations[lang]!['Search Chapters or Authors...'],
            isNotNull,
            reason: 'Search Chapters or Authors... missing in $lang');
        expect(additionalTranslations[lang]!['Title & Author'],
            isNotNull,
            reason: 'Title & Author missing in $lang');
        expect(additionalTranslations[lang]!['Downloading Ahmiyat-e-Ramzan'],
            isNotNull,
            reason: 'Downloading Ahmiyat-e-Ramzan missing in $lang');
        expect(additionalTranslations[lang]!['No topics found'],
            isNotNull,
            reason: 'No topics found missing in $lang');
      }
    });
  });

  group('Ahmiyat-e-Ramzan Dataset Integrity Tests', () {
    final supportedLanguages = [
      'english',
      'urdu',
      'sindhi',
      'arabic',
      'bengali',
      'indonesian',
      'turkish',
      'french',
      'hindi',
      'persian',
    ];

    test('Contains exactly 13 topics', () {
      expect(AhmiyatRamzanData.topics.length, equals(13));
    });

    test('Every topic has complete titles and authors in all 10 languages', () {
      for (final topic in AhmiyatRamzanData.topics) {
        for (final lang in supportedLanguages) {
          final title = topic.getTitle(lang);
          final author = topic.getAuthor(lang);
          expect(title.isNotEmpty, isTrue,
              reason: 'Topic ${topic.num} missing title for $lang');
          expect(author.isNotEmpty, isTrue,
              reason: 'Topic ${topic.num} missing author for $lang');
        }
      }
    });

    test('All 13 topics have exact opening pages and authors specified by task', () {
      final expectedPages = [5, 8, 23, 45, 54, 61, 84, 85, 90, 94, 100, 106, 125];
      for (int i = 0; i < 13; i++) {
        expect(AhmiyatRamzanData.topics[i].num, equals(i + 1));
        expect(AhmiyatRamzanData.topics[i].page, equals(expectedPages[i]));
      }

      // Topic 1: Ta'aaruf / Hazrat Dr Naeemullah sahib Damat Barakatuhum
      expect(AhmiyatRamzanData.topics[0].titles['urdu'], equals('تعارف'));
      expect(AhmiyatRamzanData.topics[0].authors['urdu'], contains('ڈاکٹر نعیم اللہ'));
      expect(AhmiyatRamzanData.topics[0].authors['urdu'], contains('دامت برکاتہم'));
      expect(AhmiyatRamzanData.topics[0].page, equals(5));

      // Topic 2: Ramzan ul mubarak k anwaar o in'amaat / hazrat dr abdul Haye sahib Aarfi Qaddasallahu sirrahu
      expect(AhmiyatRamzanData.topics[1].titles['urdu'], contains('رمضان المبارک کے انوار وانعامات'));
      expect(AhmiyatRamzanData.topics[1].authors['urdu'], contains('ڈاکٹر عبد الحئی'));
      expect(AhmiyatRamzanData.topics[1].authors['urdu'], contains('قدس سرہ'));
      expect(AhmiyatRamzanData.topics[1].page, equals(8));

      // Topic 3: Ramzan ul Mubarak Hidayaat wa Tambihaat / Hazrat Dr Abdul Haye Sahib Aarfi
      expect(AhmiyatRamzanData.topics[2].titles['urdu'], contains('ہدایات وتنبیہات'));
      expect(AhmiyatRamzanData.topics[2].authors['urdu'], contains('ڈاکٹر عبد الحئی'));
      expect(AhmiyatRamzanData.topics[2].page, equals(23));

      // Topic 4: Dua ki Zarurat wa Ahmiyat / Hazrat Dr Abdul Haye Sahib Aarfi
      expect(AhmiyatRamzanData.topics[3].titles['urdu'], contains('دعا کی ضرورت واہمیت'));
      expect(AhmiyatRamzanData.topics[3].authors['urdu'], contains('ڈاکٹر عبد الحئی'));
      expect(AhmiyatRamzanData.topics[3].page, equals(45));

      // Topic 5: Ramzan ki Ahmiyat / Hazrat Molana mufti Rafi Usmani sahib Rahmatullah aalaih
      expect(AhmiyatRamzanData.topics[4].titles['urdu'], contains('رمضان کی اہمیت'));
      expect(AhmiyatRamzanData.topics[4].authors['urdu'], contains('مفتی محمد رفیع عثمانی'));
      expect(AhmiyatRamzanData.topics[4].authors['urdu'], contains('اللہ علیہ'));
      expect(AhmiyatRamzanData.topics[4].page, equals(54));

      // Topic 6: Ramzan ul Mubarak kis tarah guzarain / Hazrat Molana mufti Taqi Usmani sahib Damat Barakatuhum
      expect(AhmiyatRamzanData.topics[5].titles['urdu'], contains('رمضان المبارک کس طرح گزاریں'));
      expect(AhmiyatRamzanData.topics[5].authors['urdu'], contains('مفتی تقی عثمانی'));
      expect(AhmiyatRamzanData.topics[5].authors['urdu'], contains('دامت برکاتہم'));
      expect(AhmiyatRamzanData.topics[5].page, equals(61));

      // Topic 7: Khutabat e Ramzan / Hazrat Dr Hafeezullah sahib Qaddasallahu sirrahu
      expect(AhmiyatRamzanData.topics[6].titles['urdu'], contains('خطباتِ رمضان'));
      expect(AhmiyatRamzanData.topics[6].authors['urdu'], contains('ڈاکٹر حفیظ اللہ'));
      expect(AhmiyatRamzanData.topics[6].authors['urdu'], contains('قدس سرہ'));
      expect(AhmiyatRamzanData.topics[6].page, equals(84));

      // Topic 8: fazilat e Aitkaaf (1) / Hazrat Dr Hafeezullah
      expect(AhmiyatRamzanData.topics[7].titles['urdu'], contains('فضیلتِ اعتکاف (۱)'));
      expect(AhmiyatRamzanData.topics[7].authors['urdu'], contains('ڈاکٹر حفیظ اللہ'));
      expect(AhmiyatRamzanData.topics[7].page, equals(85));

      // Topic 9: fazilat e Aitkaaf (2) / Hazrat Dr Hafeezullah
      expect(AhmiyatRamzanData.topics[8].titles['urdu'], contains('فضیلتِ اعتکاف (۲)'));
      expect(AhmiyatRamzanData.topics[8].authors['urdu'], contains('ڈاکٹر حفیظ اللہ'));
      expect(AhmiyatRamzanData.topics[8].page, equals(90));

      // Topic 10: Shab e Qadr / Hazrat Dr Hafeezullah
      expect(AhmiyatRamzanData.topics[9].titles['urdu'], contains('شبِ قدر'));
      expect(AhmiyatRamzanData.topics[9].authors['urdu'], contains('ڈاکٹر حفیظ اللہ'));
      expect(AhmiyatRamzanData.topics[9].page, equals(94));

      // Topic 11: Targheeb wa inamaat / Hazrat Dr Hafeezullah
      expect(AhmiyatRamzanData.topics[10].titles['urdu'], contains('ترغیب وانعامات'));
      expect(AhmiyatRamzanData.topics[10].authors['urdu'], contains('ڈاکٹر حفیظ اللہ'));
      expect(AhmiyatRamzanData.topics[10].page, equals(100));

      // Topic 12: Ehtamaam Talab e Maghfirat / Hazrat Dr Hafeezullah
      expect(AhmiyatRamzanData.topics[11].titles['urdu'], contains('اہتمامِ طلبِ مغفرت'));
      expect(AhmiyatRamzanData.topics[11].authors['urdu'], contains('ڈاکٹر حفیظ اللہ'));
      expect(AhmiyatRamzanData.topics[11].page, equals(106));

      // Topic 13: Dua / Hazrat Dr Hafeezullah
      expect(AhmiyatRamzanData.topics[12].titles['urdu'], equals('دعا'));
      expect(AhmiyatRamzanData.topics[12].authors['urdu'], contains('ڈاکٹر حفیظ اللہ'));
      expect(AhmiyatRamzanData.topics[12].page, equals(125));
    });
  });

  group('MunajatScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestApp(SettingsProvider settings, {ThemeMode themeMode = ThemeMode.light}) {
      return ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const MunajatScreen(),
        ),
      );
    }

    testWidgets('MunajatScreen displays Books title, Munajaat Maqbool, and Ahmiyat-e-Ramzan with 13 Chapters badge',
        (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      await tester.pumpWidget(createTestApp(settings));
      await tester.pumpAndSettle();

      // Top title should be "Books"
      expect(find.text('Books'), findsWidgets);

      // Books cards
      expect(find.text('Munajaat Maqbool'), findsOneWidget);
      expect(find.text('Ahmiyat-e-Ramzan'), findsOneWidget);
      expect(find.text('Virtues, rulings & blessings of Ramadan'), findsOneWidget);

      // Badge must be "13 Chapters"
      expect(find.text('13 Chapters'), findsOneWidget);

      // Tapping Ahmiyat-e-Ramzan opens chapters view
      await tester.tap(find.text('Ahmiyat-e-Ramzan'));
      await tester.pumpAndSettle();

      // Inside Ahmiyat-e-Ramzan chapters view:
      // Topic 1 (Ta'aaruf) should be visible
      expect(find.text("Ta'aaruf (Introduction)"), findsOneWidget);
      expect(find.text('Hazrat Dr. Naeemullah Sahib (Damat Barakatuhum)'), findsOneWidget);
      expect(find.text('Page 5'), findsOneWidget);

      // Topic 2 should be visible
      expect(find.text('Blessings & Rewards of Ramadan'), findsOneWidget);
      expect(find.text('Hazrat Dr. Abdul Haye Sahib Aarfi (Qaddasallahu Sirrahu)'), findsWidgets);
      expect(find.text('Page 8'), findsOneWidget);

      // Test Search filtering
      final searchFinder = find.byType(TextField);
      expect(searchFinder, findsOneWidget);
      await tester.enterText(searchFinder, 'Taqi');
      await tester.pumpAndSettle();

      // Only topic 6 (Mufti Taqi Usmani) should match
      expect(find.text("Ta'aaruf (Introduction)"), findsNothing);
      expect(find.text('How to Spend Ramadan Mubarak'), findsOneWidget);
      expect(find.text('Hazrat Maulana Mufti Taqi Usmani (Damat Barakatuhum)'), findsOneWidget);

      // Clear search
      await tester.enterText(searchFinder, '');
      await tester.pumpAndSettle();
      expect(find.text("Ta'aaruf (Introduction)"), findsOneWidget);

      // Back navigation returns to Books view
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Back at Books list
      expect(find.text('Munajaat Maqbool'), findsOneWidget);
      expect(find.text('13 Chapters'), findsOneWidget);
    });

    testWidgets('MunajatScreen in Urdu displays کتب, اہمیتِ رمضان, and ۱۳ ابواب badge',
        (tester) async {
      SharedPreferences.setMockInitialValues({'language_code': 'urdu'});
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      await tester.pumpWidget(createTestApp(settings));
      await tester.pumpAndSettle();

      // Center title should be "کتب"
      expect(find.text('کتب'), findsOneWidget);

      // Both cards in Urdu
      expect(find.text('مناجاتِ مقبول'), findsOneWidget);
      expect(find.text('اہمیتِ رمضان'), findsOneWidget);
      expect(find.text('فضائل، مسائل و برکاتِ رمضان'), findsOneWidget);
      expect(find.text('۱۳ ابواب'), findsOneWidget);

      // Tapping opens chapters view in Urdu
      await tester.tap(find.text('اہمیتِ رمضان'));
      await tester.pumpAndSettle();

      // Verify Urdu chapter titles & authors
      expect(find.text('تعارف'), findsOneWidget);
      expect(find.text('حضرت ڈاکٹر نعیم اللہ صاحب دامت برکاتہم'), findsOneWidget);
      expect(find.text('رمضان المبارک کے انوار وانعامات'), findsOneWidget);
      expect(find.text('حضرت ڈاکٹر عبد الحئی صاحب عارفی قدس سرہ'), findsWidgets);
    });

    testWidgets('PopScope back gesture navigates from chapters view back to books list',
        (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      await tester.pumpWidget(createTestApp(settings));
      await tester.pumpAndSettle();

      // Open Ahmiyat-e-Ramzan chapters
      await tester.tap(find.text('Ahmiyat-e-Ramzan'));
      await tester.pumpAndSettle();
      expect(find.text("Ta'aaruf (Introduction)"), findsOneWidget);

      // Trigger system back gesture
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Should be back on Books screen
      expect(find.text('Munajaat Maqbool'), findsOneWidget);
      expect(find.text('13 Chapters'), findsOneWidget);
    });

    testWidgets('MunajatScreen badge pills have matching sage green styling in light and dark mode',
        (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      // 1. Verify in Light Mode
      await tester.pumpWidget(createTestApp(settings, themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      final manzilsTextFinder = find.text('7 Manzils');
      final chaptersBadgeFinder = find.text('13 Chapters');
      expect(manzilsTextFinder, findsOneWidget);
      expect(chaptersBadgeFinder, findsOneWidget);

      final manzilsText = tester.widget<Text>(manzilsTextFinder);
      final chaptersText = tester.widget<Text>(chaptersBadgeFinder);

      // Light mode text color must match Color(0xFF3F7A63)
      expect(chaptersText.style?.color, equals(const Color(0xFF3F7A63)));
      expect(manzilsText.style?.color, equals(chaptersText.style?.color));
      expect(chaptersText.style?.fontSize, equals(11));
      expect(chaptersText.style?.fontWeight, equals(FontWeight.bold));

      // Container background and border radius
      final manzilsContainer = tester.widget<Container>(
        find.ancestor(of: manzilsTextFinder, matching: find.byType(Container)).first,
      );
      final chaptersContainer = tester.widget<Container>(
        find.ancestor(of: chaptersBadgeFinder, matching: find.byType(Container)).first,
      );

      final manzilsBox = manzilsContainer.decoration as BoxDecoration;
      final chaptersBox = chaptersContainer.decoration as BoxDecoration;

      expect(chaptersBox.color, equals(const Color(0xFF3F7A63).withValues(alpha: 0.15)));
      expect(manzilsBox.color, equals(chaptersBox.color));
      expect(chaptersBox.borderRadius, equals(BorderRadius.circular(8)));
      expect(manzilsBox.borderRadius, equals(chaptersBox.borderRadius));
      expect(chaptersContainer.padding, equals(const EdgeInsets.symmetric(horizontal: 8, vertical: 3)));
      expect(manzilsContainer.padding, equals(chaptersContainer.padding));

      // 2. Verify in Dark Mode
      await tester.pumpWidget(createTestApp(settings, themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      final darkManzilsText = tester.widget<Text>(find.text('7 Manzils'));
      final darkChaptersText = tester.widget<Text>(find.text('13 Chapters'));

      // Dark mode text color must match Color(0xFF6BB396)
      expect(darkChaptersText.style?.color, equals(const Color(0xFF6BB396)));
      expect(darkManzilsText.style?.color, equals(darkChaptersText.style?.color));
    });
  });

  group('SettingsProvider Ahmiyat-e-Ramzan Reading Position', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('updateAhmiyatRamzanReadingPosition persists page and notifies listeners', () async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();
      expect(settings.ahmiyatRamzanLastPage, isNull);

      bool notified = false;
      settings.addListener(() {
        notified = true;
      });

      await settings.updateAhmiyatRamzanReadingPosition(45);
      expect(settings.ahmiyatRamzanLastPage, equals(45));
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('ahmiyat_ramzan_last_page'), equals(45));

      // Reload into a fresh provider
      final freshSettings = SettingsProvider();
      await freshSettings.loadFromPrefs();
      expect(freshSettings.ahmiyatRamzanLastPage, equals(45));
    });
  });
}
