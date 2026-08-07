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
    testWidgets('never clips or overflows on ${entry.key}', (tester) async {
      await pumpAt(tester, entry.value);
      // Splitting setup into two steps made each one short enough to fit even
      // here, so scrolling is no longer required - only that nothing is ever
      // clipped or overflowed, which was always the point.
      expect(tester.takeException(), isNull);
      expect(scrollExtent(tester), greaterThanOrEqualTo(0.0));
    });
  }

  testWidgets('a huge system font scale never overflows', (tester) async {
    // The screen clamps system text scaling to 1.1; push well past it to prove
    // the clamp holds and the layout still degrades to scrolling, not clipping.
    await pumpAt(tester, const Size(360, 640), textScale: 2.0);
    expect(tester.takeException(), isNull);
  });

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
  }

  /// Setup is two steps: choose the timings, then grant permissions. Keeping
  /// them apart is what lets each one fit on a small screen, so these check the
  /// separation as much as the contents.
  testWidgets('step 1 asks only for the timings', (tester) async {
    await pumpAt(tester, const Size(393, 786));
    expect(find.text('App Setup'), findsOneWidget);
    expect(find.text('Select Prayer Timings'), findsOneWidget);
    expect(find.text('Sukkur'), findsOneWidget);
    expect(find.text('Other Cities'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Permissions belong to step 2 and must not crowd this one.
    expect(find.text('Location Access'), findsNothing);
    expect(find.text('Allow Permissions'), findsNothing);
  });

  testWidgets('nothing is chosen for the user', (tester) async {
    await pumpAt(tester, const Size(393, 786));
    // Sukkur used to arrive pre-selected, so anyone who skipped the section had
    // "chosen" it without knowing. Neither card may be ticked at the start.
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('Next explains itself when nothing is selected', (tester) async {
    await pumpAt(tester, const Size(393, 786));
    await tap(tester, 'Next');

    expect(find.text('Please select Sukkur or Other Cities'), findsOneWidget);
    // And it does not move on.
    expect(find.text('Required Permissions'), findsNothing);
  });

  testWidgets('choosing Sukkur reaches the permissions step', (tester) async {
    await pumpAt(tester, const Size(393, 786));
    await tap(tester, 'Sukkur');
    await tap(tester, 'Next');

    expect(find.text('Required Permissions'), findsOneWidget);
    expect(find.text('Location Access'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Background Execution'), findsOneWidget);
    expect(find.text('Allow Permissions'), findsOneWidget);
    // The timings choice is behind us now.
    expect(find.text('Other Cities'), findsNothing);
  });

  testWidgets('Other Cities cannot continue without a city', (tester) async {
    await pumpAt(tester, const Size(393, 786));
    await tap(tester, 'Other Cities');

    expect(find.text('No city selected'), findsOneWidget);
    expect(find.text('Search city...'), findsOneWidget);
    expect(find.text('Get Current Location'), findsOneWidget);

    await tap(tester, 'Next');
    expect(find.text('Choose a city to continue'), findsOneWidget);
    expect(find.text('Required Permissions'), findsNothing);
  });

  testWidgets('the timings choice can be revisited', (tester) async {
    await pumpAt(tester, const Size(393, 786));
    await tap(tester, 'Sukkur');
    await tap(tester, 'Next');
    expect(find.text('Required Permissions'), findsOneWidget);

    // The back link is labelled with where it goes.
    await tap(tester, 'Select Prayer Timings');
    expect(find.text('Other Cities'), findsOneWidget);
    expect(find.text('Required Permissions'), findsNothing);
  });

  /// Both steps have to fit unaided on every size, including the taller variant
  /// where Other Cities opens the city panel.
  for (final entry in devices.entries) {
    testWidgets('step 1 with city panel fits on ${entry.key}', (tester) async {
      await pumpAt(tester, entry.value);
      await tap(tester, 'Other Cities');
      expect(tester.takeException(), isNull);
      expectNoScrollNeeded(tester, '${entry.key} step 1 with city panel');
    });

    testWidgets('step 2 fits on ${entry.key}', (tester) async {
      await pumpAt(tester, entry.value);
      await tap(tester, 'Sukkur');
      await tap(tester, 'Next');
      expect(tester.takeException(), isNull);
      expectNoScrollNeeded(tester, '${entry.key} step 2');
    });
  }
}
