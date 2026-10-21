import 'package:flutter/foundation.dart';
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
  final TextEditingController _pageSearchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  int _writtenToPdfPage(int writtenPage) {
    final pdf = writtenPage - 1;
    if (pdf < 1) return 1;
    if (_totalPages > 0 && pdf > _totalPages) return _totalPages;
    return pdf;
  }

  int _pdfToWrittenPage(int pdfPage) {
    return pdfPage + 1;
  }

  Future<void> _initPdf() async {
    try {
      Future<PdfDocument> docFuture;
      if (!kIsWeb) {
        final localFile = await MunajatDownloadService.instance.getExistingLocalFile();
        if (localFile != null && await localFile.exists()) {
          docFuture = PdfDocument.openFile(localFile.path);
        } else {
          try {
            docFuture = PdfDocument.openAsset('assets/quran_pdfs/MUNAJAT_E_MAQBOOL.pdf');
          } catch (_) {
            final bytes = await MunajatDownloadService.instance.getPdfBytes();
            if (bytes == null || bytes.isEmpty) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Munajat PDF file not available.';
                });
              }
              return;
            }
            docFuture = PdfDocument.openData(bytes);
          }
        }
      } else {
        final bytes = await MunajatDownloadService.instance.getPdfBytes();
        if (bytes == null || bytes.isEmpty) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Munajat PDF file not available.';
            });
          }
          return;
        }
        docFuture = PdfDocument.openData(bytes);
      }

      final initialPdfPage = _writtenToPdfPage(widget.initialPage);
      _pdfController = PdfController(
        document: docFuture,
        initialPage: initialPdfPage,
      );

      // Brief micro-delay to let the frame pump before heavy render starts
      await Future<void>.delayed(const Duration(milliseconds: 32));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentPage = widget.initialPage;
        });
        context.read<SettingsProvider>().updateMunajatReadingPosition(widget.initialPage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading PDF: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _pageSearchController.dispose();
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
                '${settings.translate('Page', 'صفحہ', 'صفحو', 'صفحة')} $_currentPage / ${_pdfToWrittenPage(_totalPages)}',
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _pageSearchController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: settings.translate(
                              'Search Page No (1-137)...',
                              'صفحہ نمبر تلاش کریں (1-137)...',
                              'صفحو نمبر ڳوليو (1-137)...',
                              'ابحث برقم الصفحة (1-137)...',
                            ),
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF3F7A63), size: 18),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (val) {
                            final maxWritten = _totalPages > 0 ? _pdfToWrittenPage(_totalPages) : 137;
                            final writtenPage = int.tryParse(val.trim());
                            if (writtenPage != null && writtenPage >= 1 && writtenPage <= maxWritten) {
                              final targetPdfPage = _writtenToPdfPage(writtenPage);
                              _pdfController?.animateToPage(
                                targetPdfPage,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    settings.translate(
                                      'Invalid page number',
                                      'غلط صفحہ نمبر',
                                      'غلط صفحو نمبر',
                                      'رقم الصفحة غير صالحة',
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: PdfView(
                          controller: _pdfController!,
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (page) {
                            final writtenPage = _pdfToWrittenPage(page);
                            if (mounted) {
                              setState(() {
                                _currentPage = writtenPage;
                              });
                              context.read<SettingsProvider>().updateMunajatReadingPosition(writtenPage);
                            }
                          },
                          onDocumentLoaded: (doc) {
                            if (mounted) {
                              setState(() {
                                _totalPages = doc.pagesCount;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
