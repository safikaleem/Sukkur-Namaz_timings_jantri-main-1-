import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukkur_prayer_timings/providers/settings_provider.dart';
import 'package:sukkur_prayer_timings/screens/quran_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  Future<void> pumpQuran(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: const MaterialApp(home: QuranScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The green column-header bar; it and the search field collapse together.
  final header = find.text('No.');
  final searchField = find.byType(TextField);

  /// Drags the parah list itself. Targeting a point low on the screen avoids
  /// picking up any other scrollable in the tree.
  Future<void> dragList(WidgetTester tester, double dy) async {
    await tester.dragFrom(const Offset(200, 650), Offset(0, dy));
    await tester.pumpAndSettle();
  }

  testWidgets('header and search are visible at rest', (tester) async {
    await pumpQuran(tester);
    expect(header, findsOneWidget);
    expect(searchField, findsWidgets);
  });

  testWidgets('they hide when scrolling further down the list',
      (tester) async {
    await pumpQuran(tester);

    // Drag upwards = move forward through the parah list.
    await dragList(tester, -300);

    expect(header, findsNothing);
    expect(searchField, findsNothing);
  });

  testWidgets('they come back when scrolling the other way', (tester) async {
    await pumpQuran(tester);

    await dragList(tester, -300);
    expect(header, findsNothing, reason: 'should be hidden first');

    // Drag back down without reaching the very top.
    await dragList(tester, 80);

    expect(header, findsOneWidget);
    expect(searchField, findsWidgets);
  });

  testWidgets('an active search keeps them pinned open', (tester) async {
    await pumpQuran(tester);

    await tester.enterText(searchField.first, 'Ha');
    await tester.pumpAndSettle();

    await dragList(tester, -300);

    // Hiding the search box mid-query would strand the user with a filtered
    // list and no visible reason why.
    expect(searchField, findsWidgets);
    expect(header, findsOneWidget);
  });
}
