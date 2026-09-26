import 'dart:io';

void main() async {
  final file = File('assets/quran_pdfs/AlQuran15Lines-SaudiColor.pdf');
  if (!await file.exists()) {
    print('File not found');
    return;
  }
  final bytes = await file.readAsBytes();
  final content = String.fromCharCodes(bytes.sublist(0, 10000));
  print('Header preview:');
  print(content.substring(0, 500));

  // Count /Type /Page entries in PDF
  final str = String.fromCharCodes(bytes);
  final countMatches = RegExp(r'/Count\s+(\d+)').allMatches(str);
  for (final m in countMatches) {
    print('Found /Count: ${m.group(1)}');
  }
}
