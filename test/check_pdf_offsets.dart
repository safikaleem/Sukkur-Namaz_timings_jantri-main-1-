import 'dart:io';

void main() async {
  final file = File('assets/quran_pdfs/AlQuran15Lines-SaudiColor.pdf');
  final bytes = await file.readAsBytes();
  final str = String.fromCharCodes(bytes);

  // Search for stream objects or text markers in PDF
  print('PDF total size: ${bytes.length} bytes');
}
