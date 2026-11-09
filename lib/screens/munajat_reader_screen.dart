import 'dart:async';
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
  bool _isChromeVisible = true;
  Timer? _autoHideTimer;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _initPdf();
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _pageSearchController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isChromeVisible) {
        setState(() => _isChromeVisible = false);
      }
    });
  }

  void _toggleChrome() {
    setState(() {
      _isChromeVisible = !_isChromeVisible;
    });
    if (_isChromeVisible) {
      _startAutoHideTimer();
    } else {
      _autoHideTimer?.cancel();
    }
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
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = settings.isRtl;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = kToolbarHeight + 48.0 + topPadding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                settings.translate(
                  'Press back again to exit',
                  'بند کرنے کے لیے دوبارہ واپس جائیں',
                  'بند ڪرڻ لاءِ ٻيهر واپس وڃو',
                  'اضغط رجوع مرة أخرى للخروج',
                ),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        height: _isChromeVisible ? headerHeight : 0.0,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.bottomCenter,
                            minHeight: 0,
                            maxHeight: headerHeight,
                            child: Container(
                              decoration: settings.getThemeDecoration(isDark),
                              child: SafeArea(
                                bottom: false,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildAppBar(context, settings, isDark, isRtl),
                                    _buildSearchBar(context, settings, isDark),
                                  ],
                                ),
                              ),
                            ),
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
                            physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                            renderer: (PdfPage page) {
                              final media = MediaQuery.maybeOf(context);
                              final targetWidth = media != null
                                  ? (media.size.width * media.devicePixelRatio).clamp(800.0, 1400.0)
                                  : page.width * 1.5;
                              final scale = targetWidth / page.width;
                              return page.render(
                                width: targetWidth,
                                height: page.height * scale,
                                format: PdfPageImageFormat.jpeg,
                                backgroundColor: '#ffffff',
                                quality: 90,
                              );
                            },
                            builders: PdfViewBuilders<DefaultBuilderOptions>(
                              options: const DefaultBuilderOptions(),
                              pageBuilder: (context, pageImage, index, document) =>
                                  PhotoViewGalleryPageOptions(
                                imageProvider: PdfPageImageProvider(
                                  pageImage,
                                  index,
                                  document.id,
                                ),
                                filterQuality: FilterQuality.high,
                                minScale: PhotoViewComputedScale.contained * 1.0,
                                maxScale: PhotoViewComputedScale.contained * 3.5,
                                initialScale: PhotoViewComputedScale.contained * 1.0,
                                heroAttributes: PhotoViewHeroAttributes(tag: '${document.id}-$index'),
                                onTapUp: (context, details, controllerValue) {
                                  _toggleChrome();
                                },
                              ),
                            ),
                            onPageChanged: (page) {
                              final writtenPage = _pdfToWrittenPage(page);
                              if (mounted) {
                                setState(() {
                                  _currentPage = writtenPage;
                                });
                                context.read<SettingsProvider>().updateMunajatReadingPosition(writtenPage);
                                if (_isChromeVisible) {
                                  _startAutoHideTimer();
                                }
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
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
    bool isRtl,
  ) {
    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(
                  isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (_totalPages > 0)
                    Text(
                      '${settings.translate('Page', 'صفحہ', 'صفحو', 'صفحة')} $_currentPage / ${_pdfToWrittenPage(_totalPages)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
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
            fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
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
    );
  }
}
