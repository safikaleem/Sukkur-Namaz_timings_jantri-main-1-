import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/timings_data.dart';
import '../utils/prayer_state.dart';
import '../l10n/world_translations.dart';

class WidgetService {
  static const _appGroupId = 'group.pk.sukkur.salah';
  static const _iOSWidgetName = 'PrayerWidget';

  static const _androidProviders = [
    'pk.sukkur.salah.PrayerWidgetSmallProvider',
    'pk.sukkur.salah.PrayerWidgetMediumProvider',
    'pk.sukkur.salah.PrayerWidgetLargeProvider',
    'pk.sukkur.salah.PrayerWidgetTinyProvider',
    'pk.sukkur.salah.PrayerWidgetSlimProvider',
    'pk.sukkur.salah.PrayerWidgetCircleProvider',
  ];

  static Future<void> updateWidget() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      
      // Load current settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Get language code
      final langRaw = prefs.getString('language_code');
      String language = 'english';
      if (langRaw != null) {
        language = langRaw;
      } else {
        if (prefs.getBool('is_sindhi') == true) {
          language = 'sindhi';
        } else if (prefs.getBool('is_urdu') == true) {
          language = 'urdu';
        }
      }
      
      // Save it to HomeWidget immediately
      await HomeWidget.saveWidgetData('language_code', language);
      
      // Get time format
      final tf = prefs.getInt('time_format') ?? 0;
      await HomeWidget.saveWidgetData('time_format', tf);

      // Compute and save location_string for Kotlin widget
      final locMode = prefs.getString('location_mode');
      String locationStr = 'Sukkur, Sindh, Pakistan';
      
      if (locMode == 'world' && prefs.getString('city_name') != null) {
        locationStr = prefs.getString('city_name')!;
      } else {
        if (language == 'urdu') {
          locationStr = 'سکھر، سندھ، پاکستان';
        } else if (language == 'sindhi') {
          locationStr = 'سکر، سنڌ، پاڪستان';
        } else if (language == 'arabic') {
          locationStr = 'سكر، السند، باكستان';
        } else if (worldTranslations.containsKey(language) && worldTranslations[language]!.containsKey('Sukkur, Sindh, Pakistan')) {
          locationStr = worldTranslations[language]!['Sukkur, Sindh, Pakistan']!;
        }
      }
      await prefs.setString('location_string', locationStr);


      // Ensure TimingsData is loaded (crucial for background task)
      await TimingsData.instance.load();

      final now = DateTime.now();
      final today = TimingsData.instance.timingFor(now);
      if (today == null) return;

      final state = computePrayerState(now, today);

      await HomeWidget.saveWidgetData('prayer_name', state?.prayer.name ?? 'Fajr');
      await HomeWidget.saveWidgetData('prayer_time', state?.prayer.time ?? '');
      await HomeWidget.saveWidgetData('is_elapsed', state?.isElapsed ?? false);

      Duration duration = state?.duration ?? Duration.zero;
      if (state != null && !state.isElapsed) {
        final ms = duration.inMilliseconds;
        final seconds = ms <= 0 ? 0 : (ms / 1000).ceil();
        duration = Duration(seconds: seconds);
      }
      final h = duration.inHours;
      final m = duration.inMinutes.remainder(60);
      final s = duration.inSeconds.remainder(60);

      final timeStr = h > 0
          ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
          : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

      final countdown = state == null
          ? '--:--'
          : state.isElapsed
              ? '+$timeStr'
              : '-$timeStr';

      await HomeWidget.saveWidgetData('countdown', countdown);

      // Save all prayer times
      for (final p in today.allTimings) {
        await HomeWidget.saveWidgetData(
            'time_${p.name.replaceAll(' ', '_')}', p.time);
      }

      // Notify every registered widget provider
      for (final provider in _androidProviders) {
        await HomeWidget.updateWidget(
          qualifiedAndroidName: provider,
          iOSName: _iOSWidgetName,
        );
      }
    } catch (_) {}
  }
}
