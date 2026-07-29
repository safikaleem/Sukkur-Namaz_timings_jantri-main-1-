import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';

/// Sukkur is not selectable from World Prayer Timings - not by name, not by
/// coordinates, not by GPS. What these cover is the other half of that rule:
/// a refusal must leave the current selection exactly as it was, and the
/// selection the user did make has to survive until they change it themselves.
///
/// Exercises the real SettingsProvider rather than a copy of its rules, so the
/// tests fail if the provider drifts.

const karachiLat = 24.8607;
const karachiLng = 67.0011;
const sukkurLat = 27.7052;
const sukkurLng = 68.8574;
// Rohri sits across the river, inside the 20 km radius, under another name.
const rohriLat = 27.6926;
const rohriLng = 68.8964;

/// setLocation and useSukkurJantri push work onto the home-screen widget and
/// the notification scheduler, both of which are plugin channels with no
/// implementation under `flutter test`. Swallow the calls so the state
/// transitions - the actual subject here - can be asserted.
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

/// setLocation defers its write behind a 150 ms debounce. Nothing here asserts
/// on prefs before this, so the wait keeps the pending timer from firing into
/// a torn-down test.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 250));

Future<SettingsProvider> providerWith(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final settings = SettingsProvider();
  await settings.loadFromPrefs();
  return settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(silencePluginChannels);

  group('a rejected Sukkur attempt leaves the selection alone', () {
    test('Karachi stays in charge when Sukkur is offered by coordinates',
        () async {
      final settings = await providerWith({});
      expect(await settings.setLocation(karachiLat, karachiLng, 'Karachi'), isTrue);
      await settings.setLocationMode(LocationMode.world);
      await settle();

      expect(await settings.setLocation(sukkurLat, sukkurLng, 'Sukkur'), isFalse);

      expect(settings.cityName, 'Karachi');
      expect(settings.locationMode, LocationMode.world);
      expect(settings.usesCalculatedTimings, isTrue);
      await settle();
    });

    test('Rohri is refused too, and still does not disturb Karachi', () async {
      final settings = await providerWith({});
      await settings.setLocation(karachiLat, karachiLng, 'Karachi');
      await settings.setLocationMode(LocationMode.world);
      await settle();

      expect(await settings.setLocation(rohriLat, rohriLng, 'Rohri'), isFalse);

      expect(settings.cityName, 'Karachi');
      expect(settings.usesCalculatedTimings, isTrue);
      await settle();
    });

    test('the Jantri keeps showing when there is no city to fall back on',
        () async {
      final settings = await providerWith({});
      expect(await settings.setLocation(sukkurLat, sukkurLng, 'Sukkur'), isFalse);

      expect(settings.cityName, isNull);
      expect(settings.hasStoredWorldCity, isFalse);
      expect(settings.locationMode, LocationMode.sukkur);
    });
  });

  group('the side bar switches to the Jantri without losing the city', () {
    test('Karachi is remembered but no longer in charge', () async {
      final settings = await providerWith({});
      await settings.setLocation(karachiLat, karachiLng, 'Karachi');
      await settings.setLocationMode(LocationMode.world);
      await settle();

      await settings.useSukkurJantri();

      expect(settings.locationMode, LocationMode.sukkur,
          reason: 'Times, Today and Monthly must draw the Jantri');
      expect(settings.usesCalculatedTimings, isFalse);
      expect(settings.hasStoredWorldCity, isTrue,
          reason: 'the World screen offers it back as "last selected"');
      expect(settings.cityName, 'Karachi');
    });

    test('the widget cache is dropped so the home screen follows', () async {
      SharedPreferences.setMockInitialValues({'world_timings_cache': '{"stale":1}'});
      final settings = SettingsProvider();
      await settings.loadFromPrefs();
      await settings.setLocation(karachiLat, karachiLng, 'Karachi');
      await settings.setLocationMode(LocationMode.world);
      await settle();

      await settings.useSukkurJantri();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('world_timings_cache'), isNull,
          reason: 'a stale cache keeps the widget on the old city');
    });

    test('the Jantri holds until the user chooses otherwise', () async {
      final settings = await providerWith({});
      await settings.setLocation(karachiLat, karachiLng, 'Karachi');
      await settings.setLocationMode(LocationMode.world);
      await settle();
      await settings.useSukkurJantri();

      // A refused Sukkur search in between must not tip it either way.
      expect(await settings.setLocation(sukkurLat, sukkurLng, 'Sukkur'), isFalse);
      expect(settings.locationMode, LocationMode.sukkur);

      expect(await settings.useLastWorldCity(), isTrue);
      await settle();
      expect(settings.locationMode, LocationMode.world);
      expect(settings.cityName, 'Karachi');
      expect(settings.usesCalculatedTimings, isTrue);
    });

    test('there is nothing to restore when no city was ever picked', () async {
      final settings = await providerWith({});
      expect(await settings.useLastWorldCity(), isFalse);
      expect(settings.locationMode, LocationMode.sukkur);
    });
  });

  group('Sukkur left on file by an older build', () {
    test('is erased at launch, even when parked in Sukkur mode', () async {
      final settings = await providerWith({
        'location_mode': 'sukkur',
        'latitude': sukkurLat,
        'longitude': sukkurLng,
        'city_name': 'Sukkur',
      });

      expect(settings.hasStoredWorldCity, isFalse,
          reason: 'otherwise it resurfaces as "last selected"');
      expect(settings.cityName, isNull);
      expect(settings.locationMode, LocationMode.sukkur);
    });

    test('is erased at launch when parked in world mode', () async {
      final settings = await providerWith({
        'location_mode': 'world',
        'latitude': rohriLat,
        'longitude': rohriLng,
        'city_name': 'Rohri',
      });

      expect(settings.hasStoredWorldCity, isFalse);
      expect(settings.usesCalculatedTimings, isFalse);
    });

    test('a real city parked behind the Jantri survives the launch repair',
        () async {
      final settings = await providerWith({
        'location_mode': 'sukkur',
        'latitude': karachiLat,
        'longitude': karachiLng,
        'city_name': 'Karachi',
      });

      expect(settings.hasStoredWorldCity, isTrue);
      expect(settings.cityName, 'Karachi');
      expect(settings.locationMode, LocationMode.sukkur,
          reason: 'stored is not the same as in charge');
    });

    test('world mode with no coordinates falls back without erasing anything',
        () async {
      final settings = await providerWith({'location_mode': 'world'});

      expect(settings.locationMode, LocationMode.sukkur);
      expect(settings.usesCalculatedTimings, isFalse);
    });
  });
}
