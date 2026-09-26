import 'dart:io';

void main() async {
  final file = File('assets/quran_pdfs/AlQuran15Lines-SaudiColor.pdf');
  final bytes = await file.readAsBytes();
  final content = String.fromCharCodes(bytes);

  // Find all page objects and their offsets
  final pageRegExp = RegExp(r'\d+\s+0\s+obj\s*<<[^>]*?/Type\s*/Page\b[^>]*?>>', multiLine: true);
  final matches = pageRegExp.allMatches(content).take(20).toList();
  print('First 20 page objects:');
  for (int i = 0; i < matches.length; i++) {
    print('Page ${i + 1}: ${matches[i].group(0)}');
  }
}
