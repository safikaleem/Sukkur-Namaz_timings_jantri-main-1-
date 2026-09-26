import 'dart:io';

void main() async {
  final file = File('assets/quran_pdfs/AlQuran15Lines-SaudiColor.pdf');
  final bytes = await file.readAsBytes();
  final str = String.fromCharCodes(bytes);

  // Search for page objects /Type /Page (not /Pages)
  final pageRegExp = RegExp(r'/Type\s*/Page\b');
  final matches = pageRegExp.allMatches(str).toList();
  print('Total /Type /Page occurrences: ${matches.length}');
}
