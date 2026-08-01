import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every asset and font pubspec.yaml declares must actually exist on disk.
///
/// Flutter does not fail the build when a declared asset is missing from the
/// tree - it fails at runtime, on the device, when the asset is first loaded.
/// That makes a deleted asset the one cleanup mistake that survives both
/// `flutter analyze` and a green release build. This test closes that gap.
///
/// Parsed straight out of pubspec.yaml rather than hard-coded, so adding an
/// asset later automatically brings it under the guard.

/// Pulls the `- ` list entries out of the `assets:` block, and the
/// `- asset:` paths out of the `fonts:` block. Deliberately hand-rolled: the
/// app has no YAML parser dependency and this cleanup must not add one.
({List<String> assets, List<String> fonts}) _readManifest() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final assets = <String>[];
  final fonts = <String>[];

  var inAssets = false;
  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;

    if (RegExp(r'^\s+assets:\s*$').hasMatch(line)) {
      inAssets = true;
      continue;
    }
    // Any other key at the same or shallower indent ends the assets block.
    if (inAssets && RegExp(r'^\s*[A-Za-z_-]+:\s*$').hasMatch(line)) {
      inAssets = false;
    }

    final entry = RegExp(r'^\s*-\s+(.+)$').firstMatch(line);
    final fontAsset = RegExp(r'^\s*-\s+asset:\s+(.+)$').firstMatch(line);

    if (fontAsset != null) {
      fonts.add(_unquote(fontAsset.group(1)!));
    } else if (inAssets && entry != null) {
      assets.add(_unquote(entry.group(1)!));
    }
  }
  return (assets: assets, fonts: fonts);
}

String _unquote(String v) {
  final s = v.trim();
  if (s.length >= 2 &&
      ((s.startsWith("'") && s.endsWith("'")) ||
          (s.startsWith('"') && s.endsWith('"')))) {
    return s.substring(1, s.length - 1);
  }
  return s;
}

void main() {
  final manifest = _readManifest();

  test('pubspec declares the assets and fonts we expect to find', () {
    // Guards the parser itself: if this drops to zero the checks below would
    // vacuously pass and the whole suite would stop protecting anything.
    expect(manifest.assets, isNotEmpty);
    expect(manifest.fonts, isNotEmpty);
  });

  group('declared assets exist on disk', () {
    for (final path in manifest.assets) {
      test(path, () {
        if (path.endsWith('/')) {
          final dir = Directory(path);
          expect(dir.existsSync(), isTrue,
              reason: 'asset directory $path is declared but missing');
          expect(dir.listSync().whereType<File>(), isNotEmpty,
              reason: 'asset directory $path exists but is empty');
        } else {
          final file = File(path);
          expect(file.existsSync(), isTrue,
              reason: 'asset file $path is declared but missing');
          expect(file.lengthSync(), greaterThan(0),
              reason: 'asset file $path is empty');
        }
      });
    }
  });

  group('declared fonts exist on disk', () {
    for (final path in manifest.fonts) {
      test(path, () {
        final file = File(path);
        expect(file.existsSync(), isTrue,
            reason: 'font $path is declared but missing');
        expect(file.lengthSync(), greaterThan(0),
            reason: 'font $path is empty');
      });
    }
  });

  group('the Sukkur Jantri data is present and intact', () {
    test('timings.json is bundled and non-trivial', () {
      final f = File('assets/data/timings.json');
      expect(f.existsSync(), isTrue,
          reason: 'the Jantri timings are the core of the app');
      // A full year of prayer times; a truncated or emptied file would be
      // far smaller than this.
      expect(f.lengthSync(), greaterThan(10000));
    });

    test('the offline city list is bundled', () {
      final f = File('assets/data/cities.txt');
      expect(f.existsSync(), isTrue);
      expect(f.lengthSync(), greaterThan(0));
    });

    test('the azan audio files are all present', () {
      for (final name in const [
        'assets/azan_1.mp3',
        'assets/azan_2.mp3',
        'assets/makkah_azan.mp3',
        'assets/hayya_alas_salah.mp3',
      ]) {
        final f = File(name);
        expect(f.existsSync(), isTrue, reason: '$name is missing');
        expect(f.lengthSync(), greaterThan(0), reason: '$name is empty');
      }
    });
  });

  test('the release signing config is still in place', () {
    // Not bundled into the app, but losing either of these means no further
    // Play Store updates are possible. Cheap to assert, catastrophic to miss.
    expect(File('android/key.properties').existsSync(), isTrue,
        reason: 'android/key.properties is required to sign a release build');
    expect(File('android/app/release-keystore.jks').existsSync(), isTrue,
        reason: 'the upload keystore is required to sign a release build');
  });
}
