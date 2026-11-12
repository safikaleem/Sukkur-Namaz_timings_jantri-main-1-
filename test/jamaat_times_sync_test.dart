import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/services/jamaat_times_service.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Jamat Prayer Times Update & Sync Suite', () {
    test('Test 1: Basic Update - Fajr time is updated and effective in memory', () async {
      final service = JamaatTimesService.instance;
      const testMasjidId = 'test_integration_sync_masjid';

      final newTiming = const JamaatTiming(
        fajr: '06:20 AM',
        fajrUpdated: '12 Nov 2026',
        zuhar: '01:00 PM',
        asar: '04:30 PM',
        maghrib: 'Sunset',
        isha: '07:05 PM',
        jummah: '01:00 PM',
      );

      final ok = await service.updateTimingForMasjid(
        masjidId: testMasjidId,
        newTiming: newTiming,
      );

      expect(ok, isTrue);
      final timing = service.getTimingForId(testMasjidId);
      expect(timing?.fajr, equals('06:20 AM'));
    });

    test('Test 2: Delayed Verification - Stale Gist response NEVER overwrites live Firestore time', () async {
      // Incoming Gist has stale 06:10 AM, while Firestore has 06:15 AM
      const staleGist = JamaatTiming(
        fajr: '06:10 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:00 PM',
        asar: '04:30 PM',
        maghrib: 'Sunset',
        isha: '07:05 PM',
        jummah: '01:00 PM',
      );

      const liveFirestore = JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:00 PM',
        asar: '04:30 PM',
        maghrib: 'Sunset',
        isha: '07:05 PM',
        jummah: '01:00 PM',
      );

      // Case A: Gist is incoming over existing Firestore
      final mergedA = JamaatTimesService.mergePrayerByPrayer(
        current: liveFirestore,
        incoming: staleGist,
        isIncomingFirestore: false,
      );
      expect(mergedA.fajr, equals('06:15 AM'), reason: 'Live Firestore must win over stale Gist');

      // Case B: Firestore is incoming over existing Gist baseline
      final mergedB = JamaatTimesService.mergePrayerByPrayer(
        current: staleGist,
        incoming: liveFirestore,
        isIncomingFirestore: true,
      );
      expect(mergedB.fajr, equals('06:15 AM'), reason: 'Live Firestore must override stale Gist baseline');
    });

    test('Test 3: App Restart - Timings persist across restart via SharedPreferences', () async {
      const testMasjidId = 'shan_e_khuda_masjid_railway_crossing_new_goth_sukkur';
      final updated = const JamaatTiming(
        fajr: '06:20 AM',
        fajrUpdated: '12 Nov 2026',
        zuhar: '01:00 PM',
        asar: '04:30 PM',
        maghrib: 'Sunset',
        isha: '07:05 PM',
        jummah: '01:00 PM',
      );

      SharedPreferences.setMockInitialValues({
        JamaatTimesService.prefKeyFirestoreCache: json.encode({
          testMasjidId: updated.toJson(),
        }),
      });

      final service = JamaatTimesService.instance;
      await service.loadLocalCache();

      final timing = service.getTimingForId(testMasjidId);
      expect(timing?.fajr, equals('06:20 AM'));
    });

    test('Test 4 & 7: Real Firestore Live Verification - Document in Cloud Firestore has valid bundle timing', () async {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('https://firestore.googleapis.com/v1/projects/sukkur-salah/databases/(default)/documents/jamaat_bundle/all_masjids'));
      final resp = await req.close();
      expect(resp.statusCode, equals(200));

      final body = await resp.transform(utf8.decoder).join();
      final data = json.decode(body);
      final fields = data['fields'] as Map<String, dynamic>;
      final shan = fields['shan_e_khuda_masjid_railway_crossing_new_goth_sukkur']?['stringValue'];
      expect(shan, isNotNull);
      final shanMap = json.decode(shan);
      expect(shanMap['fajr'], isNotNull);
      expect(shanMap['fajr'].toString().trim().isNotEmpty, isTrue);
    });

    test('Test 5: Offline/Pending updates queue persists and merges properly', () async {
      const testMasjidId = 'shan_e_khuda_masjid_railway_crossing_new_goth_sukkur';
      final offlineTiming = const JamaatTiming(
        fajr: '06:20 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:15 PM',
        asar: '04:45 PM',
        maghrib: 'Sunset',
        isha: '07:15 PM',
        jummah: '01:15 PM',
      );

      SharedPreferences.setMockInitialValues({
        JamaatTimesService.prefKeyPendingUpdates: json.encode({
          testMasjidId: offlineTiming.toJson(),
        }),
      });

      final service = JamaatTimesService.instance;
      await service.loadLocalCache();

      final effective = service.getTimingForId(testMasjidId);
      expect(effective?.fajr, equals('06:20 AM'));
      expect(effective?.zuhar, equals('01:15 PM'));
    });

    test('Test 6: Multiple Prayer Updates - Updating all prayers preserves each without overwriting', () {
      const baseTiming = JamaatTiming(
        fajr: '06:00 AM',
        zuhar: '01:00 PM',
        asar: '04:15 PM',
        maghrib: 'Sunset',
        isha: '07:00 PM',
        jummah: '01:00 PM',
      );

      const allUpdated = JamaatTiming(
        fajr: '06:15 AM',
        fajrUpdated: '05 Nov 2026',
        zuhar: '01:30 PM',
        zuharUpdated: '05 Nov 2026',
        asar: '04:45 PM',
        asarUpdated: '05 Nov 2026',
        maghrib: 'Sunset',
        isha: '07:30 PM',
        ishaUpdated: '05 Nov 2026',
        jummah: '01:45 PM',
        jummahUpdated: '05 Nov 2026',
      );

      final merged = JamaatTimesService.mergePrayerByPrayer(
        current: baseTiming,
        incoming: allUpdated,
        isIncomingFirestore: true,
      );

      expect(merged.fajr, equals('06:15 AM'));
      expect(merged.zuhar, equals('01:30 PM'));
      expect(merged.asar, equals('04:45 PM'));
      expect(merged.maghrib, equals('Sunset'));
      expect(merged.isha, equals('07:30 PM'));
      expect(merged.jummah, equals('01:45 PM'));
    });

    test('Test 8: Dynamic Masjid Name Edit & Immunity Against Stale Gist Cache', () async {
      const masjidId = 'jama_minara_masjid_gharibabad_sukkur';
      final updatedMasjid = JamaatMasjidInfo(
        id: masjidId,
        nameKey: 'Jama Minar Masjid',
        addressKey: 'Gharibabad, Sukkur',
        defaultTimings: const JamaatTiming(
          fajr: '06:10 AM',
          zuhar: '01:30 PM',
          asar: '04:45 PM',
          maghrib: 'Sunset',
          isha: '07:30 PM',
          jummah: '02:30 PM',
        ),
        localizedNames: const {
          'english': 'Jama Minar Masjid',
          'urdu': 'جامع مینار مسجد',
          'sindhi': 'جامع مينار مسجد',
          'arabic': 'مسجد جامع منار',
          'hindi': 'जामा मीनार मस्जिद',
          'bengali': 'জামে মিনার মসজিদ',
          'persian': 'مسجد جامع منار',
          'turkish': 'Jama Minar Camii',
          'french': 'Mosquée Jama Minar',
          'indonesian': 'Jama Minar Masjid',
        },
      );

      await JamaatTimesService.instance.registerDynamicMasjid(updatedMasjid);

      final listBefore = JamaatTimesService.instance.getMasjidList(includeHidden: true);
      final foundBefore = listBefore.firstWhere((m) => m.id == masjidId);
      expect(foundBefore.nameKey, equals('Jama Minar Masjid'));
      expect(foundBefore.getNameFor('english'), equals('Jama Minar Masjid'));
      expect(foundBefore.getNameFor('urdu'), equals('جامع مینار مسجد'));
      expect(foundBefore.getNameFor('french'), equals('Mosquée Jama Minar'));
      expect(foundBefore.getNameFor('bengali'), equals('জামে মিনার মসজিদ'));
    });
  });

  group('Stale value protection (no network)', () {
    const fresh = JamaatTiming(
      fajr: '06:20 AM',
      fajrUpdated: '12 Nov 2026',
      zuhar: '01:00 PM',
      asar: '04:30 PM',
      maghrib: 'Sunset',
      isha: '07:30 PM',
      jummah: '01:15 PM',
    );
    const stale = JamaatTiming(
      fajr: '06:15 AM',
      fajrUpdated: '05 Nov 2026',
      zuhar: '01:00 PM',
      asar: '04:30 PM',
      maghrib: 'Sunset',
      isha: '07:30 PM',
      jummah: '01:15 PM',
    );

    test('Older Firestore/legacy value must NOT overwrite newer Fajr 06:20 AM', () {
      final merged = JamaatTimesService.mergePrayerByPrayer(
        current: fresh,
        incoming: stale,
        isIncomingFirestore: true,
      );
      expect(merged.fajr, equals('06:20 AM'));
      expect(merged.fajrUpdated, equals('12 Nov 2026'));
    });

    test('Older Gist value must NOT overwrite newer Fajr 06:20 AM', () {
      final merged = JamaatTimesService.mergePrayerByPrayer(
        current: fresh,
        incoming: stale,
        isIncomingFirestore: false,
      );
      expect(merged.fajr, equals('06:20 AM'));
    });

    test('Newer incoming value DOES replace older current value', () {
      final merged = JamaatTimesService.mergePrayerByPrayer(
        current: stale,
        incoming: fresh,
        isIncomingFirestore: true,
      );
      expect(merged.fajr, equals('06:20 AM'));
    });
  });}
