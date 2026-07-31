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
      // Just the city - the widgets are small, and "Sindh, Pakistan" only
      // crowded the line (and overlapped the clock on the smallest ones).
      final locMode = prefs.getString('location_mode');
      String locationStr = 'Sukkur';

      if (locMode == 'world' && prefs.getString('city_name') != null) {
        locationStr = prefs.getString('city_name')!;
      } else {
        if (language == 'urdu') {
          locationStr = 'سکھر';
        } else if (language == 'sindhi') {
          locationStr = 'سکر';
        } else if (language == 'arabic') {
          locationStr = 'سكر';
        } else {
          locationStr = worldTranslations[language]?['Sukkur'] ?? 'Sukkur';
        }
      }
      await prefs.setString('location_string', locationStr);


      // Ensure TimingsData is loaded (crucial for background task)
      await TimingsData.instance.load();

      // The timings' own clock, so the widget's countdown agrees with the app
      // and the notification rather than reading a world city on device time.
      final now = TimingsData.instance.nowForTimings();
      final today = TimingsData.instance.timingFor(now);
      if (today == null) return;

      final state = computePrayerState(now, today);

      await HomeWidget.saveWidgetData('prayer_name', state?.prayer.name ?? 'Fajr');
      // displayTime, not time: the widget layouts expect the Jantri's 12-hour
      // form, which a calculated city no longer stores natively.
      await HomeWidget.saveWidgetData('prayer_time', state?.prayer.displayTime ?? '');
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
            'time_${p.name.replaceAll(' ', '_')}', p.displayTime);
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
