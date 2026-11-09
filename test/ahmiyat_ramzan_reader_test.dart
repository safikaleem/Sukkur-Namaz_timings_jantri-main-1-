import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';
import 'package:sukkur_prayer_timings/screens/ahmiyat_ramzan_reader_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AhmiyatRamzanReaderScreen Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createReaderApp(SettingsProvider settings, {int initialPage = 5, String title = "Ta'aaruf"}) {
      return ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          home: AhmiyatRamzanReaderScreen(
            initialPage: initialPage,
            title: title,
          ),
        ),
      );
    }

    testWidgets('AhmiyatRamzanReaderScreen displays progress indicator while loading', (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      await tester.pumpWidget(createReaderApp(settings, initialPage: 8, title: 'Blessings of Ramadan'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AhmiyatRamzanReaderScreen pumps initial frame and unmounts cleanly', (tester) async {
      final settings = SettingsProvider();
      await settings.loadFromPrefs();

      await tester.pumpWidget(createReaderApp(settings, initialPage: 5, title: "Ta'aaruf"));
      await tester.pump(const Duration(milliseconds: 50));

      // Pump an empty container to trigger dispose cleanly
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
