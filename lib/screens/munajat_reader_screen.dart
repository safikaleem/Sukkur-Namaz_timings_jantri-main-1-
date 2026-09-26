import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/munajat_download_service.dart';

class MunajatReaderScreen extends StatefulWidget {
  final int initialPage;
  final String title;

  const MunajatReaderScreen({
    super.key,
    required this.initialPage,
    required this.title,
  });

  @override
  State<MunajatReaderScreen> createState() => _MunajatReaderScreenState();
}

class _MunajatReaderScreenState extends State<MunajatReaderScreen> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    try {
      Future<PdfDocument> docFuture;
      if (kIsWeb) {
        try {
          docFuture = PdfDocument.openAsset('assets/quran_pdfs/MUNAJAT_E_MAQBOOL.pdf');
        } catch (_) {
          final bytes = await MunajatDownloadService.instance.getPdfBytes();
          if (bytes == null || bytes.isEmpty) throw 'Munajat PDF file not available.';
          docFuture = PdfDocument.openData(bytes);
        }
      } else {
        final bytes = await MunajatDownloadService.instance.getPdfBytes();
        if (bytes == null || bytes.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Munajat PDF file not available.';
          });
          return;
        }
        docFuture = PdfDocument.openData(bytes);
      }

      _pdfController = PdfController(
        document: docFuture,
        initialPage: widget.initialPage,
      );

      setState(() {
        _isLoading = false;
        _currentPage = widget.initialPage;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading PDF: $e';
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.isRtl;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_totalPages > 0)
              Text(
                '${settings.translate('Page', 'صفحہ', 'صفحو', 'صفحة')} ${_currentPage + 1} / $_totalPages',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Directionality(
            textDirection: TextDirection.ltr,
            child: Icon(isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
                )
              : Directionality(
                  textDirection: TextDirection.ltr,
                  child: PdfView(
                    controller: _pdfController!,
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    onDocumentLoaded: (doc) {
                      setState(() {
                        _totalPages = doc.pagesCount;
                      });
                    },
                  ),
                ),
    );
  }
}
