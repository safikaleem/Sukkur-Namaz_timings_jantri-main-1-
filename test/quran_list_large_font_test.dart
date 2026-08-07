import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';
import 'package:sukkur_prayer_timings/screens/quran_screen.dart';

/// A Quran list row is icon -> name -> progress pill -> page pill -> heart.
/// The pills used to take whatever width they wanted, and only the name was
/// allowed to shrink, so raising the system font size squeezed the name below
/// the width of a single word: "Tilkal Rusul" rendered as "Til / ka / l / Ru /
/// su / l" on phones with a larger Font size or Display size setting.
///
/// These pump the real screen at real device sizes and font scales.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Narrow and/or scaled-up combinations that reproduced the break.
  const cases = <String, (Size, double)>{
    'compact android, normal font': (Size(360, 640), 1.0),
    'compact android, large font': (Size(360, 640), 1.3),
    'compact android, largest font': (Size(360, 640), 1.6),
    'narrow display-size setting': (Size(320, 568), 1.3),
    'narrow and largest font': (Size(320, 568), 1.6),
  };

  Future<void> pumpQuran(WidgetTester tester, Size size, double scale) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settings = SettingsProvider();
    await settings.loadFromPrefs();

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: const QuranScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  /// Width the name column actually gets. Measured off a real parah name in the
  /// rendered tree, not computed - the whole bug was a gap between the two.
  double nameWidth(WidgetTester tester) {
    final name = find.text('Alif Lam Meem');
    expect(name, findsWidgets, reason: 'the parah list should be on screen');
    return tester.getSize(name.first).width;
  }

  for (final entry in cases.entries) {
    final (size, scale) = entry.value;

    testWidgets('parah name keeps usable width - ${entry.key}', (tester) async {
      await pumpQuran(tester, size, scale);
      expect(tester.takeException(), isNull);

      final width = nameWidth(tester);
      // The bug crushed this to roughly 36px - narrower than the word "Tilkal",
      // which is why it broke into single letters. 80px clears that on the
      // narrowest screen this app supports.
      expect(width, greaterThanOrEqualTo(80.0),
          reason: '${entry.key}: name column collapsed to ${width}px');
    });
  }

  /// The heart of the bug: the pills grew with the font setting and took the
  /// space out of the name. Fixed shares mean the name's width is now decided
  /// by the screen alone, so turning the font up cannot shrink it.
  for (final size in const [Size(360, 640), Size(320, 568)]) {
    testWidgets('name width does not depend on font scale at ${size.width}px',
        (tester) async {
      await pumpQuran(tester, size, 1.0);
      final atNormal = nameWidth(tester);

      await pumpQuran(tester, size, 1.6);
      final atLargest = nameWidth(tester);

      expect(atLargest, closeTo(atNormal, 0.5),
          reason: 'name shrank from $atNormal to $atLargest when the font grew');
    });
  }

  testWidgets('column headings never wrap', (tester) async {
    // "Name" wrapping to "Nam" over "e" was the visible symptom in the header.
    await pumpQuran(tester, const Size(320, 568), 1.6);
    expect(tester.takeException(), isNull);

    for (final heading in ['No.', 'Name', 'Read', 'Page']) {
      final finder = find.text(heading);
      expect(finder, findsWidgets, reason: '$heading heading missing');
      final widget = tester.widget<Text>(finder.first);
      expect(widget.maxLines, 1, reason: '$heading may wrap');
    }
  });
}
