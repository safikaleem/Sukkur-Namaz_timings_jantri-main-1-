import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';
import 'package:sukkur_prayer_timings/screens/onboarding_screen.dart';

/// Sizes that must show the whole checklist without scrolling, smallest first.
const devices = <String, Size>{
  'very small (iPhone SE 1st gen)': Size(320, 568),
  'compact android': Size(360, 640),
  'pixel-class': Size(393, 786),
  'large (6.7in)': Size(430, 932),
  'tablet': Size(768, 1024),
};

/// Too short to fit at any legible font size. These must degrade to scrolling -
/// never clip, never overflow.
const scrollingDevices = <String, Size>{
  'landscape': Size(740, 360),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  Future<void> pumpAt(WidgetTester tester, Size size,
      {double textScale = 1.0}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  double scrollExtent(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .maxScrollExtent;

  /// The content column must not be taller than the viewport - if it is, the
  /// user has to scroll, which is exactly what this screen must avoid.
  void expectNoScrollNeeded(WidgetTester tester, String label) {
    final extent = scrollExtent(tester);
    expect(extent, 0.0, reason: '$label needs ${extent}px of scrolling');
  }

  for (final entry in devices.entries) {
    testWidgets('fits without scrolling on ${entry.key}', (tester) async {
      await pumpAt(tester, entry.value);
      expect(tester.takeException(), isNull);
      expectNoScrollNeeded(tester, entry.key);
    });
  }

  for (final entry in scrollingDevices.entries) {
    testWidgets('scrolls instead of overflowing on ${entry.key}',
        (tester) async {
      await pumpAt(tester, entry.value);
      // No overflow exception: the content scrolls rather than being clipped.
      expect(tester.takeException(), isNull);
      expect(scrollExtent(tester), greaterThan(0.0),
          reason: '${entry.key} should be scrollable');
    });
  }

  testWidgets('a huge system font scale never overflows', (tester) async {
    // The screen clamps system text scaling to 1.1; push well past it to prove
    // the clamp holds and the layout still degrades to scrolling, not clipping.
    await pumpAt(tester, const Size(360, 640), textScale: 2.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders every section', (tester) async {
    await pumpAt(tester, const Size(393, 786));
    expect(find.text('App Setup'), findsOneWidget);
    expect(find.text('Select Prayer Timings'), findsOneWidget);
    expect(find.text('Required Permissions'), findsOneWidget);
    expect(find.text('Location Access'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Background Execution'), findsOneWidget);
    expect(find.text('Allow Permissions'), findsOneWidget);
  });
}
