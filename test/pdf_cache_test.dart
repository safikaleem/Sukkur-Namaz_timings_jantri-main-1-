import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Mirrors _cachedPdf() in PdfMushafReader: extract once to a build-keyed
/// directory, then reuse. Exercised here against the real bundled asset so the
/// extract-once behaviour and the atomic rename are actually verified.
Future<File> cachedPdf(Directory support, String build, String asset) async {
  final dir = Directory('${support.path}/quran_pdfs/v$build');
  final file = File('${dir.path}/$asset');
  if (await file.exists()) return file;

  await dir.create(recursive: true);
  await for (final entry in dir.parent.list()) {
    if (entry is! Directory) continue;
    if (await FileSystemEntity.identical(entry.path, dir.path)) continue;
    await entry.delete(recursive: true);
  }

  final bytes = await rootBundle.load('assets/quran_pdfs/$asset');
  final partial = File('${file.path}.part');
  await partial.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  return partial.rename(file.path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  const asset = 'Colour_Coded_Quran_Juz_02.pdf';

  setUp(() => support = Directory.systemTemp.createTempSync('pdfcache'));
  tearDown(() => support.deleteSync(recursive: true));

  test('extracts a complete, valid PDF on first open', () async {
    final file = await cachedPdf(support, '20', asset);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), 5220080);
    expect(String.fromCharCodes(file.readAsBytesSync().take(5)), '%PDF-');
  });

  test('reuses the extracted file instead of re-copying', () async {
    final first = await cachedPdf(support, '20', asset);
    final stamp = first.statSync().modified;

    final second = await cachedPdf(support, '20', asset);
    expect(second.path, first.path);
    // Untouched: the second open did no copying at all.
    expect(second.statSync().modified, stamp);
  });

  test('leaves no .part file behind', () async {
    await cachedPdf(support, '20', asset);
    final leftovers = Directory('${support.path}/quran_pdfs/v20')
        .listSync()
        .where((e) => e.path.endsWith('.part'));
    expect(leftovers, isEmpty);
  });

  test('a new build number re-extracts and drops the old copy', () async {
    await cachedPdf(support, '20', asset);
    final upgraded = await cachedPdf(support, '21', asset);

    expect(upgraded.path, contains('v21'));
    expect(Directory('${support.path}/quran_pdfs/v20').existsSync(), isFalse);
  });
}
