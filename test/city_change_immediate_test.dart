import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in const [
      'home_widget',
      'dexterous.com/flutter/local_notifications',
      'flutter.baseflow.com/geocoding',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async => null);
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('pk.sukkur.salah/native_helper'),
      (call) async => true,
    );
  });

  test('Setting city updates location_mode, coordinates, cache, and widgets immediately without delay', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.loadFromPrefs();

    // Change to Karachi
    final result = await settings.setLocation(24.8607, 67.0011, 'Karachi');
    expect(result, isTrue);
    expect(settings.locationMode, LocationMode.world);
    expect(settings.cityName, 'Karachi');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('location_mode'), 'world');
    expect(prefs.getString('city_name'), 'Karachi');
    expect(prefs.getString('world_timings_cache'), isNotNull);
    expect(prefs.getString('location_string'), 'Karachi');
  });

  test('Switching back to Sukkur Jantri clears cache and updates widgets immediately', () async {
    SharedPreferences.setMockInitialValues({
      'location_mode': 'world',
      'city_name': 'Karachi',
      'latitude': 24.8607,
      'longitude': 67.0011,
      'world_timings_cache': '{}',
      'location_string': 'Karachi',
    });
    final settings = SettingsProvider();
    await settings.loadFromPrefs();

    await settings.useSukkurJantri();
    expect(settings.locationMode, LocationMode.sukkur);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('location_mode'), 'sukkur');
    expect(prefs.getString('world_timings_cache'), isNull);
    expect(prefs.getString('location_string'), 'Sukkur');
  });
}
