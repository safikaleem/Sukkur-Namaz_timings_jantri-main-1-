import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations.dart';
import 'package:sukkur_prayer_timings/l10n/world_translations_extra.dart';

/// Parses a Dart string literal starting at [start] (which must point at a
/// quote character) and returns (value, indexAfterLiteral).
(String, int)? _readLiteral(String src, int start) {
  if (start >= src.length) return null;
  final quote = src[start];
  if (quote != "'" && quote != '"') return null;
  // Triple-quoted strings are not used as translate() keys; skip them.
  if (src.startsWith(quote * 3, start)) return null;
  final buf = StringBuffer();
  var i = start + 1;
  while (i < src.length) {
    final c = src[i];
    if (c == r'\') {
      if (i + 1 >= src.length) return null;
      final esc = src[i + 1];
      buf.write(switch (esc) {
        'n' => '\n',
        't' => '\t',
        'r' => '\r',
        _ => esc,
      });
      i += 2;
      continue;
    }
    if (c == quote) return (buf.toString(), i + 1);
    if (c == r'$') return null; // interpolated - not a static key
    buf.write(c);
    i++;
  }
  return null;
}

int _skipWhitespaceAndComments(String src, int i) {
  while (i < src.length) {
    if (src.startsWith('//', i)) {
      final nl = src.indexOf('\n', i);
      i = nl == -1 ? src.length : nl + 1;
    } else if (src[i].trim().isEmpty) {
      i++;
    } else {
      break;
    }
  }
  return i;
}

/// Every distinct English key the app passes as translate()'s first argument.
Set<String> collectTranslateKeys() {
  final keys = <String>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.replaceAll(r'\', '/').contains('lib/l10n/'));

  for (final file in files) {
    final src = file.readAsStringSync();
    // translate(en, ...) puts the English string first; translateFor(lang, en,
    // ...) puts it second, so skip past that first argument.
    for (final match
        in RegExp(r'\btranslate(For)?\(').allMatches(src)) {
      var i = _skipWhitespaceAndComments(src, match.end);
      if (match.group(1) == 'For') {
        final comma = src.indexOf(',', i);
        if (comma == -1) continue;
        i = _skipWhitespaceAndComments(src, comma + 1);
      }
      // Adjacent string literals are concatenated by the Dart compiler.
      final buf = StringBuffer();
      while (true) {
        final lit = _readLiteral(src, i);
        if (lit == null) break;
        buf.write(lit.$1);
        i = _skipWhitespaceAndComments(src, lit.$2);
      }
      if (buf.isNotEmpty) keys.add(buf.toString());
    }
  }
  return keys;
}

/// Keys that reach translate() through a variable rather than a literal, so
/// the source scan above cannot see them.
const dynamicKeys = <String>[
  // monthly_screen.dart - _monthNames[...]
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
  // clock_style_screen.dart - _ThemeDef.label
  'Default', 'Sky Glow', 'Linen Stone', 'Soft Ocean', 'Emerald Masjid',
  // clock_style_screen.dart - _ClockDef.label
  'Classic', 'Minimal', 'Sketch', 'Dusk', 'Linen', 'Rose',
  'Sage', 'Carbon', 'Ocean', 'Ivory', 'Mint',
  // namaz_timing.dart - localizedName(), notification_service.dart reminders
  'Intiha e Sehar', 'Fajar', 'Tulu Aftab', 'Ishraq', 'Zawal', 'Zuhar',
  'Misl Awwal', 'Asr Hanafi', 'Asr', 'Maghrib', 'Isha', 'Zuhr', 'Fajr',
  'Dhuhr',
  // notification_service.dart - _reminderBody() templates
  'At {prayer} time',
  '{minutes} minutes before {prayer}',
  '{minutes} minutes after {prayer}',
];

void main() {
  final keys = collectTranslateKeys()..addAll(dynamicKeys);

  test('the source scan actually found the app\'s strings', () {
    expect(keys.length, greaterThan(250));
  });

  test('every world language covers every translatable string', () {
    final report = StringBuffer();
    var anyMissing = false;

    for (final lang in worldTranslations.keys) {
      final dict = worldTranslations[lang]!;
      final missing = keys.where((k) => !dict.containsKey(k)).toList()..sort();
      report.writeln(
          '$lang: ${keys.length - missing.length}/${keys.length} covered, ${missing.length} missing');
      if (missing.isNotEmpty) {
        anyMissing = true;
        for (final m in missing.take(20)) {
          report.writeln('    - ${m.replaceAll('\n', '\\n')}');
        }
      }
    }

    expect(anyMissing, isFalse,
        reason: 'Untranslated strings fall back to English at runtime, which '
            'is exactly the "language not applying everywhere" bug.\n$report');
  });

  test('the four original languages never consult the dictionary', () {
    // English, Urdu, Sindhi and Arabic must keep returning the literal passed
    // at the call site, so adding or changing dictionary entries can never
    // alter how they render.
    for (final lang in ['english', 'urdu', 'sindhi', 'arabic']) {
      expect(translateFor(lang, 'EN', 'UR', 'SD', 'AR'),
          {'english': 'EN', 'urdu': 'UR', 'sindhi': 'SD', 'arabic': 'AR'}[lang],
          reason: '$lang must resolve from its own argument');
    }
    // Arabic still falls back to Urdu when no Arabic argument is supplied.
    expect(translateFor('arabic', 'EN', 'UR', 'SD'), 'UR');
    // A world language with no entry falls back to English, not to Urdu.
    expect(translateFor('bengali', 'a string no dictionary has', 'UR', 'SD'),
        'a string no dictionary has');
  });

  test('every selectable language has a native display name', () {
    // The picker header renders languageNames[current]; a gap here is what made
    // it show "English" no matter which world language was chosen.
    for (final lang in worldTranslations.keys) {
      expect(languageNamesMap.containsKey(lang), isTrue,
          reason: '$lang is translatable but has no display name');
    }
    expect(languageNamesMap.keys.toSet().containsAll(
        ['english', 'urdu', 'sindhi', 'arabic', 'persian']), isTrue);
    // Distinct names, so no two entries in the picker look identical.
    expect(languageNamesMap.values.toSet().length, languageNamesMap.length);
  });

  test('Persian is treated as right-to-left', () {
    expect(rtlLanguages, containsAll(['urdu', 'sindhi', 'arabic', 'persian']));
    for (final ltr in ['english', 'bengali', 'indonesian', 'turkish',
      'french', 'hindi']) {
      expect(rtlLanguages.contains(ltr), isFalse, reason: '$ltr is not RTL');
    }
  });

  test('prayer-name aliases agree with their canonical entry', () {
    for (final lang in worldTranslations.keys) {
      final dict = worldTranslations[lang]!;
      prayerNameAliases.forEach((alias, canonical) {
        expect(dict[alias], dict[canonical],
            reason: '$lang: $alias should read the same as $canonical');
      });
    }
  });
}
