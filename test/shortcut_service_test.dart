import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sukkur_prayer_timings/services/shortcut_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('pk.sukkur.salah/native_helper'),
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        if (methodCall.method == 'getInitialShortcut') {
          return 'qibla';
        }
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('pk.sukkur.salah/native_helper'),
      null,
    );
  });

  test('ShortcutService fetches initial shortcut correctly', () async {
    final shortcut = await ShortcutService.instance.getInitialShortcut();
    expect(shortcut, 'qibla');
  });

  test('ShortcutService syncs dynamic shortcuts in Urdu', () async {
    await ShortcutService.instance.syncDynamicShortcuts('urdu');
    expect(methodCalls.any((call) => call.method == 'updateDynamicShortcuts'), isTrue);

    final call = methodCalls.firstWhere((call) => call.method == 'updateDynamicShortcuts');
    final shortcuts = (call.arguments['shortcuts'] as List)
        .map((e) => Map<String, String>.from(e as Map))
        .toList();
    expect(shortcuts.length, 4);

    final qibla = shortcuts.firstWhere((s) => s['id'] == 'qibla');
    expect(qibla['shortLabel'], 'قبلہ');
    expect(qibla['longLabel'], 'قبلہ رخ');

    final quran = shortcuts.firstWhere((s) => s['id'] == 'quran');
    expect(quran['shortLabel'], 'قرآن');
    expect(quran['longLabel'], 'قرآن مجید');

    final tasbeeh = shortcuts.firstWhere((s) => s['id'] == 'tasbeeh');
    expect(tasbeeh['shortLabel'], 'تسبیح');
    expect(tasbeeh['longLabel'], 'تسبیح کاؤنٹر');

    final today = shortcuts.firstWhere((s) => s['id'] == 'today');
    expect(today['shortLabel'], 'اوقات');
    expect(today['longLabel'], 'آج کے اوقات');
  });

  test('ShortcutService syncs dynamic shortcuts in Sindhi', () async {
    await ShortcutService.instance.syncDynamicShortcuts('sindhi');
    final call = methodCalls.lastWhere((call) => call.method == 'updateDynamicShortcuts');
    final shortcuts = (call.arguments['shortcuts'] as List)
        .map((e) => Map<String, String>.from(e as Map))
        .toList();

    final qibla = shortcuts.firstWhere((s) => s['id'] == 'qibla');
    expect(qibla['shortLabel'], 'قبلو');

    final quran = shortcuts.firstWhere((s) => s['id'] == 'quran');
    expect(quran['shortLabel'], 'قرآن');
    expect(quran['longLabel'], 'قرآن پاڪ');

    final tasbeeh = shortcuts.firstWhere((s) => s['id'] == 'tasbeeh');
    expect(tasbeeh['shortLabel'], 'تسبيح');
    expect(tasbeeh['longLabel'], 'تسبيح ڪائونٽر');
  });

  test('ShortcutService syncs dynamic shortcuts in Arabic', () async {
    await ShortcutService.instance.syncDynamicShortcuts('arabic');
    final call = methodCalls.lastWhere((call) => call.method == 'updateDynamicShortcuts');
    final shortcuts = (call.arguments['shortcuts'] as List)
        .map((e) => Map<String, String>.from(e as Map))
        .toList();

    final qibla = shortcuts.firstWhere((s) => s['id'] == 'qibla');
    expect(qibla['shortLabel'], 'القبلة');
    expect(qibla['longLabel'], 'اتجاه القبلة');

    final quran = shortcuts.firstWhere((s) => s['id'] == 'quran');
    expect(quran['shortLabel'], 'القرآن');
    expect(quran['longLabel'], 'القرآن الكريم');
  });

  test('ShortcutService syncs dynamic shortcuts in English', () async {
    await ShortcutService.instance.syncDynamicShortcuts('english');
    final call = methodCalls.lastWhere((call) => call.method == 'updateDynamicShortcuts');
    final shortcuts = (call.arguments['shortcuts'] as List)
        .map((e) => Map<String, String>.from(e as Map))
        .toList();

    final qibla = shortcuts.firstWhere((s) => s['id'] == 'qibla');
    expect(qibla['shortLabel'], 'Qibla');
    expect(qibla['longLabel'], 'Qibla Direction');

    final quran = shortcuts.firstWhere((s) => s['id'] == 'quran');
    expect(quran['shortLabel'], 'Quran');
    expect(quran['longLabel'], 'Holy Quran');
  });
}
