import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../l10n/world_translations.dart';

/// Manages Android Launcher App Shortcuts and Google Assistant actions,
/// ensuring shortcut titles dynamically match the user's selected language.
class ShortcutService {
  static final ShortcutService instance = ShortcutService._();
  ShortcutService._();

  static const MethodChannel _channel = MethodChannel('pk.sukkur.salah/native_helper');

  final StreamController<String> _shortcutStreamController = StreamController<String>.broadcast();
  Stream<String> get onShortcutTriggered => _shortcutStreamController.stream;

  bool _initialized = false;

  void init() {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShortcutTriggered') {
        final action = call.arguments as String?;
        if (action != null && action.isNotEmpty) {
          _shortcutStreamController.add(action);
        }
      }
    });
  }

  /// Checks if the app was launched directly from an app shortcut or Google Assistant intent.
  Future<String?> getInitialShortcut() async {
    if (kIsWeb) return null;
    try {
      final action = await _channel.invokeMethod<String>('getInitialShortcut');
      return action;
    } catch (e) {
      debugPrint('Failed to get initial shortcut: $e');
      return null;
    }
  }

  /// Updates dynamic shortcuts on Android so their labels match the current app language.
  Future<void> syncDynamicShortcuts(String language) async {
    if (kIsWeb) return;
    try {
      final shortcuts = [
        {
          'id': 'qibla',
          'shortLabel': translateFor(language, 'Qibla', 'قبلہ', 'قبلو', 'القبلة'),
          'longLabel': translateFor(language, 'Qibla Direction', 'قبلہ رخ', 'قبلو رخ', 'اتجاه القبلة'),
        },
        {
          'id': 'quran',
          'shortLabel': translateFor(language, 'Quran', 'قرآن', 'قرآن', 'القرآن'),
          'longLabel': translateFor(language, 'Holy Quran', 'قرآن مجید', 'قرآن پاڪ', 'القرآن الكريم'),
        },
        {
          'id': 'tasbeeh',
          'shortLabel': translateFor(language, 'Tasbeeh', 'تسبیح', 'تسبيح', 'التسبيح'),
          'longLabel': translateFor(language, 'Tasbeeh Counter', 'تسبیح کاؤنٹر', 'تسبيح ڪائونٽر', 'مسبحة الأذكار'),
        },
        {
          'id': 'today',
          'shortLabel': translateFor(language, 'Today', 'اوقات', 'وقت', 'مواقيت'),
          'longLabel': translateFor(language, "Today's Timings", 'آج کے اوقات', 'اڄ جا وقت', 'مواقيت اليوم'),
        },
      ];

      await _channel.invokeMethod('updateDynamicShortcuts', {
        'shortcuts': shortcuts,
      });
    } catch (e) {
      debugPrint('Failed to sync dynamic shortcuts: $e');
    }
  }
}
