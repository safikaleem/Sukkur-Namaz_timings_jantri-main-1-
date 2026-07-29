import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  /// Every page in these juz files is a single ~856x1303 pixel scan - not
  /// vector text - so rendering far above the screen's own pixel width only
  /// interpolates, it cannot recover detail the scan does not hold. Render once
  /// at the screen's real pixels plus a little headroom for pinch-zoom, so the
  /// page is resampled exactly once (by the PDF renderer, which filters
  /// properly) rather than twice as it was at the old flat 1.2x.
  static const double _zoomHeadroom = 1.5;

  /// Guards the decoded bitmap. A page costs roughly width^2 * 6 bytes in
  /// Flutter's image cache, which holds 100 MB by default - 2000 px keeps
  /// several pages resident so swiping back never re-decodes.
  static const double _minRenderWidth = 1000;
  static const double _maxRenderWidth = 2000;

  final TextEditingController _pageSearchController = TextEditingController();
  PdfController? _pdfController;
  PdfDocument? _document;
  int _pageCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  /// Set before the first build, so the renderer callback always has a real
  /// figure rather than a guess.
  double _renderWidthPx = _minRenderWidth;

  String get _assetName =>
      'Colour_Coded_Quran_Juz_${widget.parahNumber.toString().padLeft(2, '0')}.pdf';

  String get _assetPath => 'assets/quran_pdfs/$_assetName';

  /// Opens the juz, unpacking it to a stable file on first use.
  ///
  /// pdfx's openAsset/openData both re-copy the whole 5 MB file on every open -
  /// its cache filename is a fresh UUID each call, so its own "already
  /// extracted?" check can never hit. Extracting once ourselves and then
  /// opening by path makes every subsequent open effectively instant.
  Future<PdfDocument> _openDocument() async {
    if (kIsWeb) return PdfDocument.openAsset(_assetPath); // no file system
    final file = await _cachedPdf();
    return PdfDocument.openFile(file.path);
  }

  Future<File> _cachedPdf() async {
    final support = await getApplicationSupportDirectory();
    // Keyed by build number so an app update never serves stale pages.
    final info = await PackageInfo.fromPlatform();
    final dir = Directory('${support.path}/quran_pdfs/v${info.buildNumber}');
    final file = File('${dir.path}/$_assetName');
    if (await file.exists()) return file;

    await dir.create(recursive: true);
    await _dropStaleVersions(dir);

    // Write to a sibling then rename: an interrupted copy can never be
    // mistaken for a complete one on the next launch.
    final bytes = await rootBundle.load(_assetPath);
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return partial.rename(file.path);
  }

  Future<void> _dropStaleVersions(Directory current) async {
    try {
      await for (final entry in current.parent.list()) {
        if (entry is! Directory) continue;
        // identical() resolves the paths: a plain string compare is wrong on
        // Windows, where list() yields backslashes and current.path does not.
        if (await FileSystemEntity.identical(entry.path, current.path)) continue;
        await entry.delete(recursive: true);
      }
    } catch (_) {
      // Housekeeping only - never block opening the Quran.
    }
  }

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    _renderWidthPx =
        (media.size.width * media.devicePixelRatio * _zoomHeadroom)
            .clamp(_minRenderWidth, _maxRenderWidth);
  }

  Future<void> _initPdf() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    PdfDocument? document;
    try {
      // Awaited here, not handed to PdfController: pdfx swallows anything that
      // isn't a Dart Exception (a missing asset throws a FlutterError, which is
      // an Error) and reports it as the useless "Exception: Unknown error".
      document = await _openDocument();

      final int pageCount = document.pagesCount;
      final int initialPage = widget.initialPage.clamp(1, pageCount);

      if (!mounted) {
        await document.close();
        return;
      }

      setState(() {
        _document = document;
        _pageCount = pageCount;
        _pdfController = PdfController(
          document: Future.value(document),
          initialPage: initialPage,
        );
        _isLoading = false;
      });
    } catch (e) {
      await document?.close();
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageSearchController.dispose();
    _pdfController?.dispose();
    _document?.close();
    super.dispose();
  }

  /// Same as pdfx's own page builder except for [filterQuality]: photo_view
  /// defaults to [FilterQuality.none], i.e. nearest-neighbour, so the moment a
  /// page is scaled at all - which it always is, the scan never matches the
  /// screen exactly - the thin Arabic strokes and tajweed colouring break up
  /// into hard steps. Proper filtering costs nothing and is the single biggest
  /// improvement available without shipping larger scans.
  PhotoViewGalleryPageOptions _buildPage(
    BuildContext context,
    Future<PdfPageImage> pageImage,
    int index,
    PdfDocument document,
  ) =>
      PhotoViewGalleryPageOptions(
        imageProvider: PdfPageImageProvider(pageImage, index, document.id),
        filterQuality: FilterQuality.high,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.contained * 3.0,
        initialScale: PhotoViewComputedScale.contained,
        heroAttributes: PhotoViewHeroAttributes(tag: '${document.id}-$index'),
      );

  void _onPageSubmitted(String value) {
    final page = int.tryParse(value);
    if (page == null || page < 1 || page > 549) return;

    FocusScope.of(context).unfocus();
    final parahNum = QuranData.getParahForPage(page);
    if (parahNum == widget.parahNumber) {
      final int pdfStartPage =
          (parahNum == 1) ? 1 : QuranData.parahs[parahNum - 1].startPage;
      final localPage = (page - pdfStartPage + 1).clamp(1, _pageCount);
      _pdfController?.jumpToPage(localPage);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: widget.isDark ? Colors.white : Colors.black),
      );
    }

    if (_errorMessage != null || _pdfController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.settings.translate(
                  'Could not open this Parah.',
                  'یہ پارہ کھولا نہیں جا سکا۔',
                  'هي پارو کولهي نه سگهيو.',
                  'تعذر فتح هذا الجزء.',
                ),
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$_assetPath\n${_errorMessage ?? ''}',
                style: TextStyle(
                  color: widget.isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _initPdf,
                child: Text(widget.settings.translate('Retry', 'دوبارہ کوشش کریں', 'ٻيهر ڪوشش ڪريو', 'إعادة المحاولة')),
              ),
            ],
          ),
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
                onSubmitted: _onPageSubmitted,
              ),
            ),
          ),
          Expanded(
            child: PdfView(
              controller: _pdfController!,
              scrollDirection: Axis.horizontal,
              pageSnapping: true,
              reverse: true, // RTL reading direction
              physics: const BouncingScrollPhysics(),
              builders: PdfViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                pageBuilder: _buildPage,
              ),
              // pdfx keeps every rendered page for the life of this widget, so
              // the higher resolution is paid once per page, not on each swipe.
              renderer: (PdfPage page) {
                final scale = _renderWidthPx / page.width;
                return page.render(
                  width: page.width * scale,
                  height: page.height * scale,
                  format: PdfPageImageFormat.jpeg,
                  // The scan inside the PDF is itself a JPEG; at 100 the
                  // re-encode skips chroma subsampling, so the colour-coded
                  // tajweed marks do not pick up a second generation of fringing.
                  quality: 100,
                  backgroundColor: '#ffffff',
                );
              },
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
