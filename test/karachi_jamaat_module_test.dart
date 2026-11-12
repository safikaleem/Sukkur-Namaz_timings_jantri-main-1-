import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations_extra.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';
import 'package:sukkur_prayer_timings/services/jamaat_times_service.dart';
import 'package:sukkur_prayer_timings/utils/urdu_strings.dart';
import 'package:sukkur_prayer_timings/widgets/settings_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Version and Changelog Configuration', () {
    test('Current app version is 1.5.0', () {
      expect(S.versionValue, equals('1.5.0'));
    });
  });

  group('SettingsProvider Karachi & Jamaat Module Integration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default mode is Sukkur with Jamaat module enabled', () async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      expect(settings.isSukkur, isTrue);
      expect(settings.isKarachi, isFalse);
      expect(settings.hasJamaatModule, isTrue);
      expect(settings.currentCity, equals('sukkur'));
    });

    test('Selecting Karachi activates Karachi mode and Jamaat module', () async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      await settings.useKarachiCity();

      expect(settings.isSukkur, isFalse);
      expect(settings.isKarachi, isTrue);
      expect(settings.hasJamaatModule, isTrue);
      expect(settings.currentCity, equals('karachi'));
      expect(settings.cityName, equals('Karachi'));
    });

    test('Switching back and forth between Sukkur and Karachi restores state properly', () async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      await settings.useKarachiCity();
      expect(settings.isKarachi, isTrue);
      expect(settings.isSukkur, isFalse);

      await settings.useSukkurJantri();
      expect(settings.isKarachi, isFalse);
      expect(settings.isSukkur, isTrue);
      expect(settings.currentCity, equals('sukkur'));
      expect(settings.hasJamaatModule, isTrue);

      await settings.useKarachiCity();
      expect(settings.isKarachi, isTrue);
      expect(settings.isSukkur, isFalse);
      expect(settings.currentCity, equals('karachi'));
      expect(settings.hasJamaatModule, isTrue);
    });

    test('World city outside Karachi and Sukkur has no Jamaat module', () async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      // Set world mode and London coordinates
      await settings.setLocationMode(LocationMode.world);
      await settings.setLocation(51.5074, -0.1278, 'London');

      expect(settings.isSukkur, isFalse);
      expect(settings.isKarachi, isFalse);
      expect(settings.hasJamaatModule, isFalse);
      expect(settings.cityName, equals('London'));
    });

    test('KarachiLocation precision: Karachiya (India) is rejected, Karachi and nearby areas are accepted', () {
      // Karachiya in Gujarat, India (lat 22.3786, lng 73.1328)
      expect(KarachiLocation.covers(22.3786, 73.1328, 'Karachiya'), isFalse);
      expect(KarachiLocation.matchesName('Karachiya'), isFalse);

      // Actual Karachi coordinates and names
      expect(KarachiLocation.covers(24.8608, 67.0104, 'Karachi'), isTrue);
      expect(KarachiLocation.covers(24.8608, 67.0104, 'کراچی'), isTrue);
      expect(KarachiLocation.matchesName('Karachi, Pakistan'), isTrue);
      expect(KarachiLocation.matchesName('Karachi'), isTrue);
      expect(KarachiLocation.matchesName('کراچی'), isTrue);
      expect(KarachiLocation.matchesName('ڪراچي'), isTrue);
      expect(KarachiLocation.matchesName('كراتشي'), isTrue);

      // Karachi metropolitan suburbs within 60 km
      // DHA / Clifton (24.8150, 67.0300)
      expect(KarachiLocation.covers(24.8150, 67.0300, 'Clifton'), isTrue);
      // Malir / Airport (24.9000, 67.1600)
      expect(KarachiLocation.covers(24.9000, 67.1600, 'Malir'), isTrue);
    });
  });

  group('JamaatTimesService City-Scoped Masjid List & Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      JamaatTimesService.instance.setSelectedCity('sukkur');
    });

    test('Sukkur city lists only Sukkur masjids (built-in count matches)', () {
      final sukkurList = JamaatTimesService.instance.getMasjidList(city: 'sukkur');
      final expectedVisible = JamaatTimesService.sukkurMasjids.where((m) => !m.isHidden).length;
      expect(sukkurList.length, equals(expectedVisible));
      expect(sukkurList.every((m) => m.city != 'karachi'), isTrue);

      final allSukkurList = JamaatTimesService.instance.getMasjidList(city: 'sukkur', includeHidden: true);
      expect(allSukkurList.length, equals(JamaatTimesService.sukkurMasjids.length));
    });

    test('Karachi city lists only Karachi masjids and does NOT contain Sukkur masjids', () {
      final karachiList = JamaatTimesService.instance.getMasjidList(city: 'karachi');
      expect(karachiList.every((m) => m.city == 'karachi'), isTrue);
      // Explicitly verify none of the Sukkur masjids appear
      expect(karachiList.any((m) => m.id == 'babul_islam'), isFalse);
      expect(karachiList.any((m) => m.id == 'gol_masjid'), isFalse);
    });

    test('Dynamic masjid tagged with karachi is segregated to Karachi list only', () async {
      const karachiMasjid = JamaatMasjidInfo(
        id: 'tooba_masjid_karachi',
        nameKey: 'Masjid e Tooba',
        addressKey: 'DHA Phase 2, Karachi',
        city: 'karachi',
        defaultTimings: JamaatTiming(
          fajr: '05:30 AM',
          zuhar: '01:30 PM',
          asar: '04:45 PM',
          maghrib: 'Sunset',
          isha: '08:00 PM',
          jummah: '01:30 PM',
        ),
      );

      await JamaatTimesService.instance.registerDynamicMasjid(karachiMasjid);

      final karachiList = JamaatTimesService.instance.getMasjidList(city: 'karachi');
      expect(karachiList.any((m) => m.id == 'tooba_masjid_karachi'), isTrue);

      final sukkurList = JamaatTimesService.instance.getMasjidList(city: 'sukkur');
      expect(sukkurList.any((m) => m.id == 'tooba_masjid_karachi'), isFalse);

      // findMasjidById finds it across cities
      final found = JamaatTimesService.instance.findMasjidById('tooba_masjid_karachi');
      expect(found, isNotNull);
      expect(found!.city, equals('karachi'));

      // getMasjidList with city: 'all' contains both
      final allList = JamaatTimesService.instance.getMasjidList(includeHidden: true, city: 'all');
      expect(allList.any((m) => m.id == 'tooba_masjid_karachi'), isTrue);
      expect(allList.any((m) => m.id == 'babul_islam'), isTrue);

      // exportRawGistJson contains both cities and exports the city field
      final jsonRaw = JamaatTimesService.instance.exportRawGistJson();
      final decoded = json.decode(jsonRaw) as Map<String, dynamic>;
      final masjids = decoded['masjids'] as List;
      final exportedKarachi = masjids.firstWhere((m) => m['id'] == 'tooba_masjid_karachi');
      expect(exportedKarachi['city'], equals('karachi'));
      // Visible Karachi masjids are no longer force-hidden in the legacy list
      expect(exportedKarachi['hidden'], isNull);
      // Dedicated karachi_masjids section preserves true visibility for 1.4.8+
      final karachiMasjids = decoded['karachi_masjids'] as List;
      final kSectionEntry = karachiMasjids.firstWhere((m) => m['id'] == 'tooba_masjid_karachi');
      expect(kSectionEntry['city'], equals('karachi'));
      expect(kSectionEntry['hidden'], isNull); // not hidden
    });
  });

  group('Smart City Resolution & Data Leak Prevention', () {
    test('JamaatMasjidInfo.resolveCity resolves Karachi without city in ID', () {
      // ID without city name (e.g. ghafooria_pakola)
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_pakola',
          address: 'Karachi, Sindh',
        ),
        equals('karachi'),
      );

      // Urdu address (کراچی)
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_pakola',
          address: 'ناظم آباد، کراچی',
        ),
        equals('karachi'),
      );

      // Sindhi address (ڪراچي)
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_pakola',
          address: 'ڪراچي، سنڌ',
        ),
        equals('karachi'),
      );

      // Arabic address (كراتشي)
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_pakola',
          address: 'شارع فيصل، كراتشي',
        ),
        equals('karachi'),
      );

      // In localizedAddresses map
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_pakola',
          address: 'Main Boulevard',
          addresses: {'urdu': 'کراچی'},
        ),
        equals('karachi'),
      );

      // Sukkur masjid defaults to sukkur
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_pakola',
          address: 'Station Road, Sukkur',
        ),
        equals('sukkur'),
      );

      // Edge Case A: Sukkur masjid on Karachi Road (must NOT be misclassified as Karachi!)
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'masjid_karachi_road_sukkur',
          address: 'Karachi Road, Sukkur',
        ),
        equals('sukkur'),
        reason: 'ID ending in _sukkur and address in Sukkur must resolve to Sukkur even if Karachi is in the road name',
      );

      // Edge Case B: Explicit Urdu city "سکھر" takes precedence over "Karachi Road" address
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_road',
          address: 'Karachi Road, Near Bus Stand',
          city: 'سکھر',
        ),
        equals('sukkur'),
        reason: 'Explicit city "سکھر" must override street name containing Karachi',
      );

      // Edge Case C: Explicit Sindhi city "سکر" takes precedence
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_road',
          address: 'Karachi Bus Stop',
          city: 'سکر',
        ),
        equals('sukkur'),
      );

      // Edge Case D: Karachi masjid with Karachi marker ONLY in localized names map
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_pakola',
          address: 'Main Chowk',
          names: {'urdu': 'جامع مسجد کراچی'},
        ),
        equals('karachi'),
        reason: 'Karachi marker in localized names map must be detected',
      );

      // Edge Case E: Karachi marker in Sindhi localized address map
      expect(
        JamaatMasjidInfo.resolveCity(
          id: 'ghafooria_pakola',
          address: 'Street 4',
          addresses: {'sd': 'ڪراچي، سنڌ'},
        ),
        equals('karachi'),
      );
    });

    test('JamaatMasjidInfo.copyWith preserves city and all fields', () {
      const original = JamaatMasjidInfo(
        id: 'ghafooria_pakola',
        nameKey: 'Ghafooria Masjid',
        addressKey: 'Karachi',
        city: 'karachi',
        defaultTimings: JamaatTiming(
          fajr: '05:30 AM',
          zuhar: '01:30 PM',
          asar: '04:45 PM',
          maghrib: 'Sunset',
          isha: '08:00 PM',
          jummah: '01:30 PM',
        ),
      );

      final modified = original.copyWith(
        isHidden: true,
      );

      expect(modified.city, equals('karachi'));
      expect(modified.isHidden, isTrue);
      expect(modified.id, equals('ghafooria_pakola'));
    });

    test('Dual-Section Gist Ingestion & v1.4.7 Backward Compatibility', () async {
      // Gist JSON simulated: legacy 'masjids' list has Karachi masjid with hidden: true
      // Dedicated 'karachi_masjids' has the same masjid with hidden: false
      final gistPayload = json.encode({
        'master_pin': '25081989',
        'masjids': [
          {
            'id': 'babul_islam',
            'name': 'Masjid Babul Islam',
            'address': 'Sukkur',
            'city': 'sukkur',
            'fajr': '06:15 AM',
            'zuhar': '01:15 PM',
            'asar': '04:30 PM',
            'maghrib': 'Sunset',
            'isha': '07:15 PM',
            'jummah': '01:15 PM',
            'hidden': false,
          },
          {
            'id': 'ghafooria_pakola',
            'name': 'Ghafooria Masjid',
            'address': 'Karachi',
            'city': 'karachi',
            'fajr': '05:45 AM',
            'zuhar': '01:30 PM',
            'asar': '04:45 PM',
            'maghrib': 'Sunset',
            'isha': '08:00 PM',
            'jummah': '01:30 PM',
            'hidden': true, // Legacy 1.4.7 client will hide this in Sukkur!
          }
        ],
        'karachi_masjids': [
          {
            'id': 'ghafooria_pakola',
            'name': 'Ghafooria Masjid',
            'address': 'Karachi',
            'city': 'karachi',
            'fajr': '05:45 AM',
            'zuhar': '01:30 PM',
            'asar': '04:45 PM',
            'maghrib': 'Sunset',
            'isha': '08:00 PM',
            'jummah': '01:30 PM',
            'hidden': false, // 1.4.8+ displays this in Karachi!
          }
        ]
      });

      // 1. Ingest via local cache parser
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(JamaatTimesService.prefKeyJamaatCache, gistPayload);
      await JamaatTimesService.instance.loadLocalCache();

      // 2. In Sukkur mode: ghafooria_pakola MUST NOT appear in Sukkur list
      final sukkurList = JamaatTimesService.instance.getMasjidList(city: 'sukkur');
      expect(sukkurList.any((m) => m.id == 'ghafooria_pakola'), isFalse);
      expect(sukkurList.any((m) => m.id == 'babul_islam'), isTrue);

      // 3. In Karachi mode: ghafooria_pakola MUST appear and be visible (not hidden)
      final karachiList = JamaatTimesService.instance.getMasjidList(city: 'karachi');
      expect(karachiList.any((m) => m.id == 'ghafooria_pakola'), isTrue);
      final kMasjid = karachiList.firstWhere((m) => m.id == 'ghafooria_pakola');
      expect(kMasjid.isHidden, isFalse);
      expect(kMasjid.city, equals('karachi'));
      // No Sukkur masjids in Karachi list
      expect(karachiList.any((m) => m.id == 'babul_islam'), isFalse);

      // 4. Backward Compatibility Verification for v1.4.7 clients:
      // A v1.4.7 client only parses 'masjids' and filters '!m.isHidden':
      final decodedGist = json.decode(gistPayload) as Map<String, dynamic>;
      final legacyMasjids = (decodedGist['masjids'] as List)
          .where((m) => m['hidden'] != true)
          .map((m) => m['id'])
          .toList();
      expect(legacyMasjids.contains('ghafooria_pakola'), isFalse,
          reason: 'v1.4.7 clients MUST NOT display Karachi masjids because hidden is true in legacy masjids array');
    });
  });

  group('10-Language Localization Coverage for Karachi Module', () {
    const requiredLanguages = [
      'english', 'urdu', 'sindhi', 'arabic', 'bengali',
      'hindi', 'turkish', 'indonesian', 'french', 'persian',
    ];

    test('All 10 languages have Karachi header and module descriptions in additionalTranslations', () {
      for (final lang in requiredLanguages) {
        final map = additionalTranslations[lang];
        expect(map, isNotNull, reason: 'Language $lang must have additionalTranslations map');

        expect(
          map!.containsKey("Masajid Jama'at Times (Karachi)"),
          isTrue,
          reason: 'Language $lang missing Masajid Jama\'at Times (Karachi)',
        );
        expect(
          map.containsKey("All timings calculated for Karachi with separate Jama'at module"),
          isTrue,
          reason: 'Language $lang missing Karachi timings setting description',
        );
        expect(
          map.containsKey("Karachi Prayer Timings & Jama'at Module"),
          isTrue,
          reason: 'Language $lang missing Karachi drawer subtitle',
        );
        expect(
          map.containsKey("Karachi module is active. Mosque Jama'at times will be added soon."),
          isTrue,
          reason: 'Language $lang missing Karachi empty state subtitle',
        );
      }
    });
  });

  group('Bulk Prayer Timing Shifter Cross-City Support', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      JamaatTimesService.instance.setSelectedCity('sukkur');
    });

    test('bulkShiftPrayerTiming shifts timings for both Sukkur and Karachi masjids', () async {
      const kMasjid = JamaatMasjidInfo(
        id: 'shift_test_karachi',
        nameKey: 'Shift Test Karachi',
        addressKey: 'Karachi',
        city: 'karachi',
        defaultTimings: JamaatTiming(
          fajr: '05:00 AM',
          zuhar: '01:00 PM',
          asar: '04:00 PM',
          maghrib: 'Sunset',
          isha: '07:30 PM',
          jummah: '01:00 PM',
        ),
      );
      await JamaatTimesService.instance.registerDynamicMasjid(kMasjid);

      // Shift Fajr +15 minutes across all cities
      final count = await JamaatTimesService.instance.bulkShiftPrayerTiming(
        prayerKey: 'fajr',
        deltaMinutes: 15,
        targetMasjidIds: ['shift_test_karachi'],
      );

      expect(count, equals(1));
      final updated = JamaatTimesService.instance.findMasjidById('shift_test_karachi');
      expect(updated, isNotNull);
      final timing = JamaatTimesService.instance.getTimingFor(updated!);
      expect(timing.fajr, equals('05:15 AM'));
    });
  });

  group('SettingsDrawer Karachi Quick-Switch Interaction', () {
    testWidgets('Tapping Karachi invokes onTapKarachi and does NOT call onTapSukkur', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      bool sukkurTapped = false;
      bool karachiTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SettingsProvider>.value(
            value: settings,
            child: Scaffold(
              drawer: SettingsDrawer(
                onTapSukkur: () {
                  sukkurTapped = true;
                },
                onTapKarachi: () {
                  karachiTapped = true;
                },
              ),
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  child: const Text('Open Drawer'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open Drawer
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // The Karachi quick-switch item was intentionally removed from the drawer.
      expect(find.text('Karachi'), findsNothing);
      expect(karachiTapped, isFalse);
      expect(sukkurTapped, isFalse);
    });
  });
}
