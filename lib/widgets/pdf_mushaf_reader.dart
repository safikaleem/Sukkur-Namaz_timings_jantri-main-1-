import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../providers/settings_provider.dart';
import '../data/quran_data.dart';
import '../screens/quran_reader_screen.dart';

class PdfMushafReader extends StatefulWidget {
  final SettingsProvider settings;
  final bool isDark;
  final int initialPage;
  final int parahNumber;

  const PdfMushafReader({
    super.key,
    required this.settings,
    required this.isDark,
    this.initialPage = 1,
    required this.parahNumber,
  });

  @override
  State<PdfMushafReader> createState() => _PdfMushafReaderState();
}

class _PdfMushafReaderState extends State<PdfMushafReader> {
  late PdfController _pdfController;
  final TextEditingController _pageSearchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Delay loading the PDF slightly to ensure smooth screen transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _initPdf();
      }
    });
  }

  Future<void> _initPdf() async {
    try {
      final String assetPath = 'assets/quran_pdfs/Colour_Coded_Quran_Juz_${widget.parahNumber.toString().padLeft(2, '0')}.pdf';
      
      _pdfController = PdfController(
        document: PdfDocument.openAsset(assetPath),
        initialPage: widget.initialPage, // pdfx uses 1-indexed pages for initialPage
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageSearchController.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: widget.isDark ? Colors.white : Colors.black),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Error loading PDF: $_errorMessage',
          style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black87),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      color: widget.isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFDFBF7),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _pageSearchController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.settings.translate('Search Page No (1-549)...', 'صفحہ نمبر تلاش کریں...', 'صفحو نمبر ڳوليو...', 'ابحث برقم الصفحة...'),
                  hintStyle: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black54),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00897B)),
                  filled: true,
                  fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null && page >= 1 && page <= 549) {
                  FocusScope.of(context).unfocus();
                  final parahNum = QuranData.getParahForPage(page);
                  if (parahNum == widget.parahNumber) {
                     int pdfStartPage = (parahNum == 1) ? 1 : QuranData.parahs[parahNum - 1].startPage;
                     final localPage = page - pdfStartPage + 1;
                     _pdfController.jumpToPage(localPage);
                  } else {
                     _pageSearchController.clear();
                     final parah = QuranData.parahs[parahNum - 1];
                     Navigator.pushReplacement(
                       context,
                       MaterialPageRoute(
                         builder: (_) => QuranReaderScreen(
                           surahNumber: parah.surahId,
                           surahNameEn: 'Parah ${parah.number} – ${parah.english}',
                           surahNameArabic: parah.arabic,
                           surahNameLocal: 'پارہ ${parah.number}',
                           initialPage: page,
                           initialAyah: parah.ayahId,
                           parahNumber: parah.number,
                         ),
                       ),
                     );
                  }
                }
              },
            ),
          ),
        ),
        Expanded(
            child: PdfView(
              controller: _pdfController,
              scrollDirection: Axis.horizontal,
              pageSnapping: true,
              reverse: true, // RTL reading direction
              physics: const BouncingScrollPhysics(),
              renderer: (PdfPage page) => page.render(
                width: page.width * 1.2, // Reduced from default 2.0x for much faster swiping
                height: page.height * 1.2,
                format: PdfPageImageFormat.jpeg,
                backgroundColor: '#ffffff',
              ),
              backgroundDecoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFDFBF7),
              ),
              onPageChanged: (page) {
                final int localPage = page; // pdfx onPageChanged gives 1-indexed page number
                final int pdfStartPage = (widget.parahNumber == 1) ? 1 : QuranData.parahs[widget.parahNumber - 1].startPage;
                final int globalPage = localPage + pdfStartPage - 1;
                widget.settings.updateParahProgress(widget.parahNumber, globalPage);
              },
            ),
          ),
        ],
      ),
    );
  }
}
