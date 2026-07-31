import 'dart:async';

import 'package:device_frame/device_frame.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'data/timings_data.dart';
import 'providers/settings_provider.dart' show SettingsProvider, DarkModeOption;
import 'services/notification_health.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'screens/notification_health_screen.dart';
import 'screens/today_screen.dart';
import 'screens/clock_screen.dart';
import 'screens/monthly_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/tasbeeh_screen.dart';
import 'screens/hidayat_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/translation_reader.dart' show purgeLegacySurahCache;
import 'utils/app_theme.dart';
import 'widgets/settings_drawer.dart';
import 'package:workmanager/workmanager.dart';
import 'services/announcement_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await TimingsData.instance.load();
      await NotificationService.instance.init();
      final settings = SettingsProvider();
      await settings.loadFromPrefs();
      if (settings.notificationsEnabled) {
        await NotificationService.instance.scheduleWeeklyNotifications();
      }
    } catch (e, s) {
      debugPrint('WorkManager task failed: $e\n$s');
    }
    return Future.value(true);
  });
}

void main() {
  // runZonedGuarded + FlutterError.onError ensure that a failure during
  // startup (bad timezone id, malformed data, a plugin PlatformException)
  // never becomes a permanent white screen — each step is non-fatal and the
  // app still renders. WidgetsFlutterBinding must be initialised inside the
  // same zone as runApp(), so everything lives inside the guarded body.
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _reportError(details.exception, details.stack);
    };

    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));
    }

    try {
      await TimingsData.instance.load();
    } catch (e, s) {
      _reportError(e, s);
    }
    try {
      await NotificationService.instance.init();
    } catch (e, s) {
      _reportError(e, s);
    }

    final settings = SettingsProvider();
    try {
      await settings.loadFromPrefs();
    } catch (e, s) {
      _reportError(e, s);
    }
    WidgetService.updateWidget(); // fire-and-forget

    if (!kIsWeb && settings.notificationsEnabled) {
      try {
        await NotificationService.instance.scheduleWeeklyNotifications();
      } catch (e, s) {
        _reportError(e, s);
      }
    }

    if (!kIsWeb) {
      try {
        Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: false,
        );
        Workmanager().registerPeriodicTask(
          'prayer_notification_reschedule',
          'reschedule_weekly_notifications',
          frequency: const Duration(hours: 6),
          constraints: Constraints(
            networkType: NetworkType.notRequired,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiresStorageNotLow: false,
          ),
        );
      } catch (e, s) {
        _reportError(e, s);
      }
    }

    // Drop the old per-surah blobs from SharedPreferences. Not awaited: it is
    // housekeeping and must not hold up first paint.
    if (!kIsWeb) {
      purgeLegacySurahCache()
          .catchError((Object e, StackTrace s) => _reportError(e, s));
    }

    runApp(
      ChangeNotifierProvider.value(
        value: settings,
        child: kIsWeb ? const _WebPhoneFrame() : const SukkurJantriApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    _reportError(error, stack);
  });
}

/// Central crash hook. Errors are logged in debug; wire a crash reporter
/// (Firebase Crashlytics / Sentry) here to capture them in production.
void _reportError(Object error, StackTrace? stack) {
  debugPrint('Uncaught error: $error\n$stack');
}

class _WebPhoneFrame extends StatelessWidget {
  const _WebPhoneFrame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: DeviceFrame(
            device: Devices.ios.iPhone13,
            isFrameVisible: true,
            screen: const SukkurJantriApp(),
          ),
        ),
      ),
    );
  }
}

class SukkurJantriApp extends StatelessWidget {
  const SukkurJantriApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final appFont = AppTheme.getFontForLanguage(context, settings.language);
    final accent = settings.displayThemeAccent();
    return MaterialApp(
      title: 'Sukkur Salah',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      theme: AppTheme.light(
        fontFamily: appFont,
        seed: accent,
        scaffoldBg: settings.displayThemeBg(false),
      ),
      darkTheme: AppTheme.dark(
        fontFamily: appFont,
        seed: accent,
        scaffoldBg: settings.displayThemeBg(true),
      ),
      themeMode: settings.darkModeOption == DarkModeOption.on
          ? ThemeMode.dark
          : settings.darkModeOption == DarkModeOption.off
              ? ThemeMode.light
              : ThemeMode.system,
      home: settings.hasCompletedSetup ? const MainShell() : const OnboardingScreen(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastScheduled;
  NotificationHealth? _notifHealth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnnouncementService.checkForAnnouncement(context);
      _refreshNotificationHealth();
    });
  }

  /// Re-reads whether the OS will actually deliver prayer alerts on time.
  ///
  /// Checked on every launch and every resume, not just at onboarding: the
  /// notification permission, the exact-alarm permission and the battery
  /// exemption are all routinely revoked afterwards - by an OS upgrade, or by
  /// an OEM battery manager resetting itself on update. The app used to absorb
  /// that silently and simply start arriving late, which is indistinguishable
  /// from working until someone misses a prayer.
  Future<void> _refreshNotificationHealth() async {
    if (kIsWeb) return;
    final health = await NotificationHealth.check();
    if (!mounted) return;
    setState(() => _notifHealth = health);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The notification schedule is only ever rebuilt from main(), a settings
    // change, or the background job. Rescheduling on resume keeps azan and
    // reminders firing for users who leave the app open for a long stretch
    // without changing anything. No new dependencies; safe no-op on web.
    //
    // Time-gate: only reschedule if more than 1 hour has passed since the last
    // schedule, so opening and closing the app repeatedly does not churn the
    // whole batch. Rescheduling no longer clears the queue first - each id is
    // overwritten in place - so there is no window with nothing pending.
    if (state == AppLifecycleState.resumed && !kIsWeb) {
      final now = DateTime.now();
      final lastSched = _lastScheduled;
      if (lastSched == null || now.difference(lastSched).inMinutes >= 60) {
        _lastScheduled = now;
        NotificationService.instance.scheduleWeeklyNotifications();
      }
      // The user may have just come back from the very settings page that fixes
      // this, so re-read it rather than waiting for the next launch.
      _refreshNotificationHealth();
    }
  }

  void _openDrawer(bool isRtl) {
    _scaffoldKey.currentState?.openDrawer();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;
    final screens = [
      const ClockScreen(),      // 0 - Clock
      const TodayScreen(),      // 1 - Today
      const MonthlyScreen(),    // 2 - Monthly
      const RemindersScreen(),  // 3 - Reminders
      // Qibla requests location + runs the compass only while it's the active
      // tab, so a fresh install doesn't prompt for location at launch.
      QiblaScreen(isActive: _currentIndex == 4), // 4 - Qibla
      // Hidayat belongs to the Jantri, so it follows the timings actually in
      // use rather than the radio button.
      if (!settings.usesCalculatedTimings)
        const HidayatScreen(),    // 5 - Hidayat (conditionally shown)
      const QuranScreen(),      // 6 or 5 - Quran
      const TasbeehScreen(),    // 7 or 6 - Tasbeeh
    ];

    int safeIndex = _currentIndex;
    if (safeIndex >= screens.length) {
      safeIndex = screens.length - 1;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: settings.displayThemeBg(isDark),
      drawer: SettingsDrawer(
        // The side bar is the only way into the Jantri, so it has to do the
        // full switch: setLocationMode alone leaves the last world month in
        // world_timings_cache and the home-screen widget goes on serving that
        // city. The city itself stays on file for the World screen to offer
        // back.
        onTapSukkur: () {
          Navigator.pop(context);
          settings.useSukkurJantri();
          setState(() => _currentIndex = 0);
        },
        // Picking a world city lands on that city's timings, same as Sukkur.
        onWorldCitySelected: () {
          if (mounted) setState(() => _currentIndex = 0);
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // All screens
            IndexedStack(
              index: safeIndex,
              children: screens,
            ),

            // Persistent hamburger overlay on screens that don't have one
            if (screens[safeIndex] is! TasbeehScreen)
              Positioned(
                top: 12,
                left: isRtl ? null : 16,
                right: isRtl ? 16 : null,
                child: GestureDetector(
                  onTap: () => _openDrawer(isRtl),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),

            // Sits at the foot of the body rather than the top, where the
            // hamburger already lives. Shown only while something is actually
            // wrong, so it disappears by itself once the user fixes it.
            if (settings.notificationsEnabled &&
                _notifHealth != null &&
                !_notifHealth!.isHealthy)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _NotificationWarningBar(
                  health: _notifHealth!,
                  settings: settings,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationHealthScreen(),
                      ),
                    );
                    _refreshNotificationHealth();
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _SukkurNavBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// A slim, tappable strip saying prayer alerts will not arrive properly.
///
/// Deliberately not dismissible: the condition it reports is not cosmetic, and
/// it removes itself the moment the underlying permission is granted.
class _NotificationWarningBar extends StatelessWidget {
  final NotificationHealth health;
  final SettingsProvider settings;
  final VoidCallback onTap;

  const _NotificationWarningBar({
    required this.health,
    required this.settings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Silenced is a stronger claim than late, and warrants a stronger colour.
    final Color background =
        health.isSilenced ? const Color(0xFFB3261E) : const Color(0xFFB26A00);
    final String message = health.isSilenced
        ? settings.translate(
            'Prayer alerts are off. Tap to fix',
            'نماز کی اطلاعات بند ہیں۔ ٹھیک کرنے کے لیے دبائیں',
            'نماز جون اطلاعون بند آهن. درست ڪرڻ لاءِ دٻايو',
            'تنبيهات الصلاة متوقفة. اضغط للإصلاح',
          )
        : settings.translate(
            'Prayer alerts may be late. Tap to fix',
            'نماز کی اطلاعات دیر سے آ سکتی ہیں۔ ٹھیک کرنے کے لیے دبائیں',
            'نماز جون اطلاعون دير سان اچي سگهن ٿيون. درست ڪرڻ لاءِ دٻايو',
            'قد تتأخر تنبيهات الصلاة. اضغط للإصلاح',
          );

    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SukkurNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SukkurNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final isRtl = settings.isRtl;

    final items = [
      _NavItem(icon: Icons.access_time_rounded,           label: settings.translate('Times', 'اوقات', 'وقت', 'الأوقات')),       // 0
      _NavItem(icon: Icons.today_rounded,                 label: settings.translate('Today', 'آج', 'اڄ', 'اليوم')),           // 1
      _NavItem(icon: Icons.view_list_rounded,             label: settings.translate('Monthly', 'ماہانہ', 'مهينو', 'شهري')),    // 2
      _NavItem(icon: Icons.notifications_active_rounded,  label: settings.translate('Reminders', 'اطلاعات', 'اطلاعون', 'تنبيهات')), // 3
      _NavItem(icon: Icons.explore_rounded,               label: settings.translate('Qibla', 'قبلہ', 'قبلو', 'القبلة')),        // 4
      if (!settings.usesCalculatedTimings)
        _NavItem(icon: Icons.menu_book_rounded,             label: settings.translate('Instructions', 'ہدایت', 'هدايتون', 'إرشادات')),     // 5
      _NavItem(icon: Icons.menu_book,                     label: settings.translate('Quran', 'قرآن', 'قرآن', 'القرآن')),         // 6
      _NavItem(icon: Icons.fingerprint_rounded,           label: settings.translate('Tasbeeh', 'تسبیح', 'تسبیح', 'التسبيح')),      // 7
    ];

    return Container(
      decoration: BoxDecoration(
        color: settings.displayThemeNavBar(isDark),
        border: Border(
          top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12, width: 0.5),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = i == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: i == 5 ? 22 : 24,
                        color: isSelected
                            ? (i == 5 || i == 6
                                ? const Color(0xFFD4A574)
                                : settings.displayThemeAccent())
                            : (isDark ? Colors.white38 : Colors.black45),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: isRtl ? 12 : 10,
                              color: isSelected
                                  ? (i == 5 || i == 6
                                      ? const Color(0xFFD4A574)
                                      : settings.displayThemeAccent())
                                  : (isDark ? Colors.white : Colors.black),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
