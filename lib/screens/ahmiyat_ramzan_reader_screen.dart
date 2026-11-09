import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ahmiyat_ramzan_download_service.dart';
import '../utils/app_theme.dart';

class AhmiyatRamzanReaderScreen extends StatefulWidget {
  final int initialPage;
  final String title;

  const AhmiyatRamzanReaderScreen({
    super.key,
    required this.initialPage,
    required this.title,
  });

  @override
  State<AhmiyatRamzanReaderScreen> createState() => _AhmiyatRamzanReaderScreenState();
}

class _AhmiyatRamzanReaderScreenState extends State<AhmiyatRamzanReaderScreen> {
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
    _currentPage = widget.initialPage;
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

  String _getPressBackExitMessage(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return 'بند کرنے کے لیے دوبارہ واپس جائیں';
      case 'sindhi': return 'بند ڪرڻ لاءِ ٻيهر واپس وڃو';
      case 'arabic': return 'اضغط رجوع مرة أخرى للخروج';
      case 'bengali': return 'প্রস্থান করতে আবার ব্যাক চাপুন';
      case 'hindi': return 'बाहर निकलने के लिए फिर से वापस दबाएं';
      case 'indonesian': return 'Tekan kembali lagi untuk keluar';
      case 'turkish': return 'Çıkmak için tekrar geri basın';
      case 'french': return 'Appuyez à nouveau pour quitter';
      case 'persian': return 'برای خروج دوباره دکمه برگشت را بزنید';
      default: return 'Press back again to exit';
    }
  }

  String _getSearchPageHint(SettingsProvider settings, int maxPage) {
    switch (settings.language) {
      case 'urdu': return 'صفحہ نمبر تلاش کریں (1-$maxPage)...';
      case 'sindhi': return 'صفحو نمبر ڳوليو (1-$maxPage)...';
      case 'arabic': return 'ابحث برقم الصفحة (1-$maxPage)...';
      case 'bengali': return 'পৃষ্ঠা নম্বর খুঁজুন (1-$maxPage)...';
      case 'hindi': return 'पृष्ठ संख्या खोजें (1-$maxPage)...';
      case 'indonesian': return 'Cari No Halaman (1-$maxPage)...';
      case 'turkish': return 'Sayfa No Ara (1-$maxPage)...';
      case 'french': return 'Rechercher page (1-$maxPage)...';
      case 'persian': return 'جستجوی شماره صفحه (1-$maxPage)...';
      default: return 'Search Page No (1-$maxPage)...';
    }
  }

  String _getInvalidPageMessage(SettingsProvider settings) {
    switch (settings.language) {
      case 'urdu': return 'غلط صفحہ نمبر';
      case 'sindhi': return 'غلط صفحو نمبر';
      case 'arabic': return 'رقم الصفحة غير صالح';
      case 'bengali': return 'ভুল পৃষ্ঠা নম্বর';
      case 'hindi': return 'अमान्य पृष्ठ संख्या';
      case 'indonesian': return 'Nomor halaman tidak valid';
      case 'turkish': return 'Geçersiz sayfa numarası';
      case 'french': return 'Numéro de page invalide';
      case 'persian': return 'شماره صفحه نامعتبر است';
      default: return 'Invalid page number';
    }
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

  int _clampPage(int page) {
    if (page < 1) return 1;
    if (_totalPages > 0 && page > _totalPages) return _totalPages;
    return page;
  }

  Future<void> _initPdf() async {
    try {
      Future<PdfDocument> docFuture;
      if (!kIsWeb) {
        final localFile = await AhmiyatRamzanDownloadService.instance.getExistingLocalFile();
        if (localFile != null && await localFile.exists()) {
          docFuture = PdfDocument.openFile(localFile.path);
        } else {
          final bytes = await AhmiyatRamzanDownloadService.instance.getPdfBytes();
          if (bytes != null && bytes.isNotEmpty) {
            docFuture = PdfDocument.openData(bytes);
          } else {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Ahmiyat-e-Ramzan PDF file not available.';
              });
            }
            return;
          }
        }
      } else {
        final bytes = await AhmiyatRamzanDownloadService.instance.getPdfBytes();
        if (bytes == null || bytes.isEmpty) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Ahmiyat-e-Ramzan PDF file not available.';
            });
          }
          return;
        }
        docFuture = PdfDocument.openData(bytes);
      }

      final startPage = widget.initialPage < 1 ? 1 : widget.initialPage;
      _pdfController = PdfController(
        document: docFuture,
        initialPage: startPage,
      );

      // Brief micro-delay to let the frame pump before heavy render starts
      await Future<void>.delayed(const Duration(milliseconds: 32));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentPage = startPage;
        });
        context.read<SettingsProvider>().updateAhmiyatRamzanReadingPosition(startPage);
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
                _getPressBackExitMessage(settings),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                ),
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
                              if (mounted) {
                                setState(() {
                                  _currentPage = page;
                                });
                                context.read<SettingsProvider>().updateAhmiyatRamzanReadingPosition(page);
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                    ),
                  ),
                  if (_totalPages > 0)
                    Text(
                      '${settings.translate('Page', 'صفحہ', 'صفحو', 'صفحة')} $_currentPage / $_totalPages',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontFamily: AppTheme.getFontForLanguage(context, settings.language),
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
    final maxPage = _totalPages > 0 ? _totalPages : 137;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: SizedBox(
        height: 38,
        child: TextField(
          controller: _pageSearchController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: AppTheme.getFontForLanguage(context, settings.language),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: _getSearchPageHint(settings, maxPage),
            hintStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 13,
              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
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
            final pageNum = int.tryParse(val.trim());
            if (pageNum != null && pageNum >= 1 && pageNum <= maxPage) {
              final target = _clampPage(pageNum);
              _pdfController?.animateToPage(
                target,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _getInvalidPageMessage(settings),
                    style: TextStyle(
                      fontFamily: AppTheme.getFontForLanguage(context, settings.language),
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
