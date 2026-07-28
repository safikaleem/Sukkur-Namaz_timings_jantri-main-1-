import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';
import 'package:sukkur_prayer_timings/widgets/dr_slogan_footer.dart';

/// IMPORTANT: flutter_test lays text out with a placeholder font whose glyphs
/// are all one em wide, so text measures far wider here than on a device.
/// These tests therefore assert the footer's *invariants* - it never asks for
/// more than four lines, never shrinks past the floor, and only ever runs out
/// of room once it has already shrunk all the way down - rather than absolute
/// line counts, which would be meaningless under the test font.

const widths = <double>[320, 360, 400, 412];
const hardMaxLines = 4;
const minSize = 6.0;

Future<SettingsProvider> providerFor(String language, LocationMode mode) async {
  SharedPreferences.setMockInitialValues({
    'language_code': language,
    'location_mode': mode.name,
  });
  final s = SettingsProvider();
  await s.loadFromPrefs();
  await s.setLanguage(language);
  await s.setLocationMode(mode);
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final languages = [...languageNamesMap.keys];

  for (final mode in LocationMode.values) {
    for (final width in widths) {
      testWidgets('${mode.name} footer holds its limits at ${width}px',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        for (final lang in languages) {
          final settings = await providerFor(lang, mode);
          await tester.pumpWidget(
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settings,
              child: MaterialApp(
                home: Scaffold(
                  body: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [DrSloganFooter()],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final textWidget = tester.widget<Text>(find.byType(Text).first);
          final rendered =
              tester.renderObject<RenderBox>(find.byType(RichText).first);
          final style = textWidget.style!;
          final where = '$lang/${mode.name}@${width}px';

          // Never request more than four lines.
          expect(textWidget.maxLines, hardMaxLines, reason: where);

          // Never shrink below the readable floor.
          expect(style.fontSize, greaterThanOrEqualTo(minSize), reason: where);

          // The laid-out box never exceeds four lines' worth of height.
          // Tolerance because a paragraph's height comes from font metrics,
          // which sit slightly above fontSize * height.
          final lineBox = style.fontSize! * style.height!;
          expect(rendered.size.height,
              lessThanOrEqualTo(lineBox * hardMaxLines * 1.15),
              reason: '$where exceeded $hardMaxLines lines of height');

          // If it still overflows, it must already be at the floor - i.e. the
          // widget shrank as far as it was allowed to before giving up.
          final paragraph = rendered as RenderParagraph;
          if (paragraph.didExceedMaxLines) {
            expect(style.fontSize, minSize,
                reason: '$where overflowed without shrinking to the floor');
          }
        }
      });
    }
  }

  testWidgets('Nastaliq scripts get a taller line box than Latin',
      (tester) async {
    double lineHeightFor(String lang) => lang == 'urdu' || lang == 'sindhi'
        ? 1.9
        : 1.4;

    for (final lang in ['urdu', 'sindhi', 'english', 'bengali']) {
      final settings = await providerFor(lang, LocationMode.world);
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: const MaterialApp(
            home: Scaffold(body: Column(children: [DrSloganFooter()])),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final style = tester.widget<Text>(find.byType(Text).first).style!;
      expect(style.height, lineHeightFor(lang), reason: lang);
    }
  });

  testWidgets('world footer follows the selected language for direction',
      (tester) async {
    for (final entry in {
      'english': TextDirection.ltr,
      'bengali': TextDirection.ltr,
      'turkish': TextDirection.ltr,
      'urdu': TextDirection.rtl,
      'sindhi': TextDirection.rtl,
      'arabic': TextDirection.rtl,
      'persian': TextDirection.rtl,
    }.entries) {
      final settings = await providerFor(entry.key, LocationMode.world);
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: const MaterialApp(
            home: Scaffold(body: Column(children: [DrSloganFooter()])),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.byType(Text).first);
      expect(text.textDirection, entry.value, reason: entry.key);
    }
  });
}
