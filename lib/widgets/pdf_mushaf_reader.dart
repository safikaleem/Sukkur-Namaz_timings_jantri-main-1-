import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import '../providers/settings_provider.dart';
import '../data/quran_data.dart';
import '../data/quran_data_15_line.dart';
import '../services/quran_download_service.dart';

/// Pages in the mushaf, numbered the way the reader's own page-search box does.
const int kQuranPageCount = 549;

/// First mushaf page of [parah].
///
/// Parah 1 is the exception: its entry in [QuranData] starts at page 2 because
/// that is where Al-Fatiha begins, but its juz file starts at page 1.
int parahFirstPage(int parah) =>
    parah <= 1 ? 1 : QuranData.parahs[parah - 1].startPage;

/// Last mushaf page of [parah].
int parahLastPage(int parah) => parah >= QuranData.parahs.length
    ? kQuranPageCount
    : parahFirstPage(parah + 1) - 1;

int parahPageCount(int parah) => parahLastPage(parah) - parahFirstPage(parah) + 1;

/// Where a mushaf page lives: which juz file, and which page inside it.
class QuranPageLocation {
  /// 1-30.
  final int parah;

  /// 1-based page within that juz's PDF.
  final int localPage;

  const QuranPageLocation(this.parah, this.localPage);

  @override
  bool operator ==(Object other) =>
      other is QuranPageLocation &&
      other.parah == parah &&
      other.localPage == localPage;

  @override
  int get hashCode => Object.hash(parah, localPage);

  @override
  String toString() => 'parah $parah, page $localPage';
}

/// Resolves a mushaf page to the juz file that holds it.
QuranPageLocation locationForPage(int page, [String quranType = '16_line']) {
  if (quranType == '15_line') {
    final clamped = page.clamp(1, kQuran15LinePageCount);
    final parah = Quran15LineData.getParahForPage(clamped);
    // PDF has 3 index pages, so printed page + 3 = PDF page
    // (bookmark pg_001 = PDF page 4, pg_002 = PDF page 5, etc.)
    return QuranPageLocation(parah, clamped + 3);
  }
  final clamped = page.clamp(1, kQuranPageCount);
  final parah = QuranData.getParahForPage(clamped);
  return QuranPageLocation(parah, clamped - parahFirstPage(parah) + 1);
}

class PdfMushafReader extends StatefulWidget {
  final SettingsProvider settings;
  final bool isDark;

  /// Mushaf page to open at
  final int initialPage;

  /// Fired when reading moves into another parah, so the screen around this
  /// reader can retitle itself.
  final ValueChanged<int>? onParahChanged;

  const PdfMushafReader({
    super.key,
    required this.settings,
    required this.isDark,
    this.initialPage = 1,
    this.onParahChanged,
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

  /// Juz files kept open at once. Three covers the page you are on plus the
  /// neighbours the pager pre-builds, so reading across a boundary never waits
  /// on a file being opened.
  static const int _maxOpenJuz = 3;

  /// Rendered pages held ready. Comfortably more than the pager keeps alive, so
  /// swiping back a few pages never re-renders.
  static const int _maxCachedPages = 12;

  final TextEditingController _pageSearchController = TextEditingController();
  PageController? _pageController;

  /// Open juz documents, most recently used last.
  final Map<int, PdfDocument> _open = {};

  /// In-flight opens, so two pages wanting the same juz share one file open.
  final Map<int, Future<PdfDocument>> _opening = {};

  /// Rendered pages by mushaf page number.
  final Map<int, Future<PdfPageImage>> _pages = {};

  /// Renders run one at a time. The native renderer is not reentrant, and
  /// firing three at once when the pager pre-builds neighbours is what makes a
  /// swipe stutter.
  Future<void> _renderQueue = Future.value();

  int _currentPage = 1;
  int _currentParah = 1;
  bool _disposed = false;
  String? _errorMessage;

  /// Set before the first build, so the renderer callback always has a real
  /// figure rather than a guess.
  double _renderWidthPx = _minRenderWidth;

  String _assetName(int parah) {
    if (widget.settings.quranType == '15_line') {
      return 'AlQuran15Lines-SaudiColor.pdf';
    }
    return 'Colour_Coded_Quran_Juz_${parah.toString().padLeft(2, '0')}.pdf';
  }

  String _assetPath(int parah) => 'assets/quran_pdfs/${_assetName(parah)}';

  @override
  void initState() {
    super.initState();
    final maxPages = widget.settings.quranType == '15_line' ? kQuran15LinePageCount : kQuranPageCount;
    _currentPage = widget.initialPage.clamp(1, maxPages);
    _currentParah = locationForPage(_currentPage, widget.settings.quranType).parah;
    _pageController = PageController(initialPage: _currentPage - 1);
    // Save straight away: opening at a page is already progress, and the pager
    // will not report a change until the reader actually moves.
    widget.settings.updateParahProgress(_currentParah, _currentPage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    _renderWidthPx =
        (media.size.width * media.devicePixelRatio * _zoomHeadroom)
            .clamp(_minRenderWidth, _maxRenderWidth);
  }

  @override
  void dispose() {
    _disposed = true;
    _pageSearchController.dispose();
    _pageController?.dispose();
    for (final document in _open.values) {
      document.close();
    }
    _open.clear();
    super.dispose();
  }

  // ── Juz files ───────────────────────────────────────────────────────────────

  /// Opens the juz, unpacking it to a stable file on first use.
  Future<PdfDocument> _openJuzFile(int parah) async {
    final is15Line = widget.settings.quranType == '15_line';
    final fileName = is15Line
        ? QuranDownloadService.quran15LineFileName
        : QuranDownloadService.quran16LineFileName(parah);

    if (kIsWeb) {
      try {
        final assetPath = 'assets/quran_pdfs/$fileName';
        final bd = await rootBundle.load(assetPath);
        return PdfDocument.openData(bd.buffer.asUint8List());
      } catch (e) {
        final url = '${QuranDownloadService.baseUrl}$fileName';
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          return PdfDocument.openData(res.bodyBytes);
        }
        rethrow;
      }
    }

    // Try local storage / downloaded file first (Android / iOS / Desktop)
    final downloadedFile = await QuranDownloadService.instance.getLocalPdfFile(fileName);
    if (await downloadedFile.exists()) {
      return PdfDocument.openFile(downloadedFile.path);
    }

    // Try alternate name for 16 Line
    if (!is15Line) {
      final dotFile = await QuranDownloadService.instance.getLocalPdfFile('Colour_Coded_Quran_Juz_${parah.toString().padLeft(2, '0')}.pdf');
      if (await dotFile.exists()) {
        return PdfDocument.openFile(dotFile.path);
      }
    }

    try {
      final file = await _cachedPdf(parah);
      return PdfDocument.openFile(file.path);
    } catch (e) {
      throw Exception('Quran PDF not found. Please download it.');
    }
  }

  Future<File> _cachedPdf(int parah) async {
    final support = await getApplicationSupportDirectory();
    final info = await PackageInfo.fromPlatform();
    final dir = Directory('${support.path}/quran_pdfs/v${info.buildNumber}');
    final file = File('${dir.path}/${_assetName(parah)}');
    if (await file.exists()) return file;

    await dir.create(recursive: true);
    await _dropStaleVersions(dir);

    try {
      final bytes = await rootBundle.load(_assetPath(parah));
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return partial.rename(file.path);
    } catch (_) {
      if (widget.settings.quranType == '15_line') {
        final fallbackAsset = 'assets/quran_pdfs/Colour_Coded_Quran_Juz_${parah.toString().padLeft(2, '0')}.pdf';
        final bytes = await rootBundle.load(fallbackAsset);
        final partial = File('${file.path}.part');
        await partial.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        return partial.rename(file.path);
      }
      rethrow;
    }
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

  /// The open document for [parah], opening it if this is the first page of it
  /// anyone has asked for.
  Future<PdfDocument> _juz(int parah) async {
    final already = _open[parah];
    if (already != null) {
      // Re-inserting moves it to the end, which is what marks it most recent.
      _open.remove(parah);
      _open[parah] = already;
      return already;
    }

    final inFlight = _opening[parah];
    if (inFlight != null) return inFlight;

    final future = _openJuzFile(parah);
    _opening[parah] = future;
    try {
      final document = await future;
      if (_disposed) {
        await document.close();
        return document;
      }
      _open[parah] = document;
      _evictJuz();
      return document;
    } finally {
      _opening.remove(parah);
    }
  }

  /// Closes the least recently used juz once more than [_maxOpenJuz] are open.
  void _evictJuz() {
    while (_open.length > _maxOpenJuz) {
      final oldest = _open.keys.first;
      final document = _open.remove(oldest);
      // Drop its rendered pages too, or they would outlive the document they
      // came from and never be reachable again.
      _pages.removeWhere((page, _) => locationForPage(page, widget.settings.quranType).parah == oldest);
      document?.close();
    }
  }

  // ── Pages ───────────────────────────────────────────────────────────────────

  /// The rendered image for a mushaf page, whichever juz holds it.
  Future<PdfPageImage> _pageImage(int page) {
    final cached = _pages[page];
    if (cached != null) return cached;

    final future = _renderPage(page);
    _pages[page] = future;
    _evictPages(around: page);
    return future;
  }

  Future<PdfPageImage> _renderPage(int page) {
    // Chained onto the queue so renders never overlap.
    final result = _renderQueue.then((_) async {
      final location = locationForPage(page, widget.settings.quranType);
      final document = await _juz(location.parah);
      final pdfPage = await document.getPage(location.localPage);
      try {
        final scale = _renderWidthPx / pdfPage.width;
        final image = await pdfPage.render(
          width: pdfPage.width * scale,
          height: pdfPage.height * scale,
          format: PdfPageImageFormat.jpeg,
          // The scan inside the PDF is itself a JPEG; at 100 the re-encode
          // skips chroma subsampling, so the colour-coded tajweed marks do not
          // pick up a second generation of fringing.
          quality: 100,
          backgroundColor: '#ffffff',
        );
        if (image == null) throw StateError('page $page did not render');
        return image;
      } finally {
        await pdfPage.close();
      }
    });
    // Keep the queue running even when one page fails, or every later page
    // would inherit the same error.
    _renderQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Forgets pages far from the one being read.
  void _evictPages({required int around}) {
    if (_pages.length <= _maxCachedPages) return;
    final byDistance = _pages.keys.toList()
      ..sort((a, b) => (b - around).abs().compareTo((a - around).abs()));
    for (final page in byDistance.take(_pages.length - _maxCachedPages)) {
      _pages.remove(page);
    }
  }

  // ── Reading position ────────────────────────────────────────────────────────

  void _onPageChanged(int index) {
    final page = index + 1;
    final parah = locationForPage(page, widget.settings.quranType).parah;
    _currentPage = page;
    widget.settings.updateParahProgress(parah, page);

    if (parah != _currentParah) {
      _currentParah = parah;
      widget.onParahChanged?.call(parah);
      // Only the title above changes; the pager itself is untouched, which is
      // what makes crossing a parah indistinguishable from turning a page.
      if (mounted) setState(() {});
    }
  }

  void _onPageSubmitted(String value) {
    final maxPages = widget.settings.quranType == '15_line' ? kQuran15LinePageCount : kQuranPageCount;
    final page = int.tryParse(value);
    if (page == null || page < 1 || page > maxPages) return;
    FocusScope.of(context).unfocus();
    _pageSearchController.clear();
    // Every page lives in the same pager now, so any page is one jump away -
    // no reload, whichever parah it belongs to.
    _pageController?.jumpToPage(page - 1);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  PhotoViewGalleryPageOptions _buildPage(BuildContext context, int index) {
    final page = index + 1;
    final location = locationForPage(page, widget.settings.quranType);
    return PhotoViewGalleryPageOptions(
      imageProvider: PdfPageImageProvider(
        _pageImage(page),
        page,
        // Identity is (page, documentId); a stable per-juz string keeps the
        // image cache keyed correctly across a document being reopened.
        'juz-${location.parah}',
      ),
      // photo_view defaults to FilterQuality.none, i.e. nearest-neighbour, so
      // the moment a page is scaled at all - which it always is, the scan never
      // matches the screen exactly - the thin Arabic strokes and tajweed
      // colouring break up into hard steps.
      filterQuality: FilterQuality.high,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.contained * 3.0,
      initialScale: PhotoViewComputedScale.contained,
      heroAttributes: PhotoViewHeroAttributes(tag: 'mushaf-$page'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null || _pageController == null) {
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
                _errorMessage ?? '',
                style: TextStyle(
                  color: widget.isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => setState(() {
                  _errorMessage = null;
                  _pages.clear();
                }),
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
                  hintText: widget.settings.translate(
                    'Search Page No (1-${widget.settings.quranType == '15_line' ? kQuran15LinePageCount : 549})...',
                    'صفحہ نمبر تلاش کریں...',
                    'صفحو نمبر ڳوليو...',
                    'ابحث برقم الصفحة...',
                  ),
                  hintStyle: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black54),
                  prefixIcon: Icon(Icons.search, color: widget.settings.quranType == '15_line' ? const Color(0xFF4C6A75) : const Color(0xFF3F7A63)),
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
            // `reverse` on a horizontal pager is resolved against the ambient
            // text direction, so under an RTL app language it cancels out the
            // reverse below and the mushaf turns the wrong way. Pinning the
            // pager to LTR keeps swipe-right on the next page in every
            // language; only the pager is wrapped, so the page-number field
            // above still lays out in the reader's own direction.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: PhotoViewGallery.builder(
                itemCount: widget.settings.quranType == '15_line' ? kQuran15LinePageCount : kQuranPageCount,
                builder: _buildPage,
                pageController: _pageController,
                onPageChanged: _onPageChanged,
                scrollDirection: Axis.horizontal,
                reverse: true, // RTL reading direction
                pageSnapping: true,
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFDFBF7),
                ),
                loadingBuilder: (context, _) => Center(
                  child: CircularProgressIndicator(
                    color: widget.isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
