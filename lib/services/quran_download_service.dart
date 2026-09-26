import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class QuranDownloadService {
  static final QuranDownloadService instance = QuranDownloadService._();
  QuranDownloadService._();

  static const String baseUrl =
      'https://github.com/safikaleem/Sukkur-Namaz_timings_jantri-main-1-/releases/download/v1.0.0/';

  /// 15 Line single PDF asset name
  static const String quran15LineFileName = 'AlQuran15Lines-SaudiColor.pdf';

  /// 16 Line PDF asset name format
  static String quran16LineFileName(int juz) =>
      'Colour.Coded.Quran.Juz.${juz.toString().padLeft(2, '0')}.pdf';

  /// Returns local directory where downloadable Quran PDFs are cached.
  Future<Directory> getQuranStorageDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/quran_pdfs_downloaded');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Gets the local File object for a given PDF filename.
  Future<File> getLocalPdfFile(String fileName) async {
    // Check local Downloads folder in debug mode for local testing
    if (kDebugMode && !kIsWeb) {
      final localDownloadFile = File('C:\\Users\\Lenovo\\Downloads\\$fileName');
      if (await localDownloadFile.exists()) {
        return localDownloadFile;
      }
    }

    // Check app support storage directory
    final storageDir = await getQuranStorageDir();
    return File('${storageDir.path}/$fileName');
  }

  /// Checks whether a PDF file is present locally.
  Future<bool> isPdfAvailable(String fileName) async {
    if (kIsWeb) return true;
    final file = await getLocalPdfFile(fileName);
    return (await file.exists()) && (await file.length()) > 0;
  }

  /// Checks if all 16-Line Juz files are available locally.
  Future<bool> is16LineQuranAvailable() async {
    if (kIsWeb) return true;
    for (int i = 1; i <= 30; i++) {
      final file = await getLocalPdfFile(quran16LineFileName(i));
      if (!await file.exists()) return false;
    }
    return true;
  }

  /// Downloads a PDF file from GitHub Releases with progress callbacks.
  Future<File?> downloadPdf({
    required String fileName,
    required void Function(int bytesDownloaded, int totalBytes, double progress)
        onProgress,
  }) async {
    try {
      final targetFile = await getLocalPdfFile(fileName);
      if (await targetFile.exists()) {
        onProgress(1, 1, 1.0);
        return targetFile;
      }

      final url = Uri.parse('$baseUrl$fileName');
      final client = HttpClient();
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Download failed with status code ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      int downloadedBytes = 0;

      final tempFile = File('${targetFile.path}.part');
      final sink = tempFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        double progress = totalBytes > 0 ? (downloadedBytes / totalBytes) : 0.0;
        onProgress(downloadedBytes, totalBytes, progress);
      }

      await sink.flush();
      await sink.close();

      return await tempFile.rename(targetFile.path);
    } catch (e) {
      debugPrint('Error downloading PDF $fileName: $e');
      return null;
    }
  }

  /// Helper to ensure a specific Quran script is ready before opening.
  /// If missing, pops up a download dialog. Returns true if ready/downloaded.
  Future<bool> ensureQuranReady(
    BuildContext context, {
    required String quranType, // '15_line' or '16_line'
    int? parahNumber,
  }) async {
    if (kIsWeb) return true;

    final fileName = quranType == '15_line'
        ? quran15LineFileName
        : quran16LineFileName(parahNumber ?? 1);

    final available = await isPdfAvailable(fileName);
    if (available) return true;

    if (!context.mounted) return false;

    // Show download modal
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuranDownloadDialog(
        fileName: fileName,
        quranType: quranType,
        parahNumber: parahNumber,
      ),
    );

    return success ?? false;
  }

  // ── Auto Background Download ─────────────────────────────────────────────
  final ValueNotifier<AutoDownloadStatus> downloadStatus =
      ValueNotifier<AutoDownloadStatus>(const AutoDownloadStatus());

  bool _isAutoDownloading = false;

  Future<void> startAutoDownloadAll(String quranType) async {
    if (kIsWeb || _isAutoDownloading) return;
    _isAutoDownloading = true;

    if (quranType == '15_line') {
      final fileName = quran15LineFileName;
      if (await isPdfAvailable(fileName)) {
        downloadStatus.value = const AutoDownloadStatus(
          isDownloading: false,
          progress: 1.0,
          statusText: '15 Line Quran Ready',
          isComplete: true,
        );
        _isAutoDownloading = false;
        return;
      }

      downloadStatus.value = const AutoDownloadStatus(
        isDownloading: true,
        progress: 0.0,
        statusText: 'Downloading 15 Line Quran...',
      );

      final file = await downloadPdf(
        fileName: fileName,
        onProgress: (downloaded, total, prog) {
          downloadStatus.value = AutoDownloadStatus(
            isDownloading: true,
            progress: prog,
            statusText: 'Downloading 15 Line Quran (${(prog * 100).toInt()}%)...',
          );
        },
      );

      if (file != null && await file.exists()) {
        downloadStatus.value = const AutoDownloadStatus(
          isDownloading: false,
          progress: 1.0,
          statusText: '15 Line Quran Downloaded',
          isComplete: true,
        );
      } else {
        downloadStatus.value = const AutoDownloadStatus(
          isDownloading: false,
          error: 'Download failed',
        );
      }
    } else {
      int missingCount = 0;
      for (int i = 1; i <= 30; i++) {
        if (!await isPdfAvailable(quran16LineFileName(i))) {
          missingCount++;
        }
      }

      if (missingCount == 0) {
        downloadStatus.value = const AutoDownloadStatus(
          isDownloading: false,
          progress: 1.0,
          statusText: 'All 30 Parahs Ready',
          isComplete: true,
        );
        _isAutoDownloading = false;
        return;
      }

      int completed = 30 - missingCount;
      for (int i = 1; i <= 30; i++) {
        final name = quran16LineFileName(i);
        if (await isPdfAvailable(name)) continue;

        downloadStatus.value = AutoDownloadStatus(
          isDownloading: true,
          progress: completed / 30.0,
          statusText: 'Downloading Parah $i / 30...',
        );

        final file = await downloadPdf(
          fileName: name,
          onProgress: (downloaded, total, prog) {
            final overall = (completed + prog) / 30.0;
            downloadStatus.value = AutoDownloadStatus(
              isDownloading: true,
              progress: overall,
              statusText: 'Downloading Parah $i / 30 (${(overall * 100).toInt()}%)...',
            );
          },
        );

        if (file != null && await file.exists()) {
          completed++;
        }
      }

      downloadStatus.value = const AutoDownloadStatus(
        isDownloading: false,
        progress: 1.0,
        statusText: 'All Parahs Downloaded',
        isComplete: true,
      );
    }
    _isAutoDownloading = false;
  }
}

class AutoDownloadStatus {
  final bool isDownloading;
  final double progress;
  final String statusText;
  final bool isComplete;
  final String? error;

  const AutoDownloadStatus({
    this.isDownloading = false,
    this.progress = 0.0,
    this.statusText = '',
    this.isComplete = false,
    this.error,
  });
}

/// Download dialog showing animated progress bar
class QuranDownloadDialog extends StatefulWidget {
  final String fileName;
  final String quranType;
  final int? parahNumber;

  const QuranDownloadDialog({
    super.key,
    required this.fileName,
    required this.quranType,
    this.parahNumber,
  });

  @override
  State<QuranDownloadDialog> createState() => _QuranDownloadDialogState();
}

class _QuranDownloadDialogState extends State<QuranDownloadDialog> {
  double _progress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _error;
  bool _isDownloading = true;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    final file = await QuranDownloadService.instance.downloadPdf(
      fileName: widget.fileName,
      onProgress: (downloaded, total, progress) {
        if (mounted) {
          setState(() {
            _downloadedBytes = downloaded;
            _totalBytes = total;
            _progress = progress;
          });
        }
      },
    );

    if (!mounted) return;

    if (file != null && await file.exists()) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isDownloading = false;
        _error = 'Download failed. Please check internet connection.';
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 MB';
    double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = widget.quranType == '15_line'
        ? settings.translate('Downloading 15 Line Quran', '15 سطر قرآن ڈاؤن لوڈ ہو رہا ہے', '15 سٽر قرآن ڊائون لوڊ ٿي رهيو آهي', 'جاري تحميل القرآن 15 سطر')
        : settings.translate('Downloading 16 Line Quran', '16 سطر قرآن ڈاؤن لوڈ ہو رہا ہے', '16 سٽر قرآن ڊائون لوڊ ٿي رهيو آهي', 'جاري تحميل القرآن 16 سطر');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF2C2C3E) : Colors.white,
      title: Column(
        children: [
          Icon(Icons.cloud_download_rounded, size: 44, color: const Color(0xFFD4A574)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 10,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                color: const Color(0xFFD4A574),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${_formatSize(_downloadedBytes)} / ${_formatSize(_totalBytes)}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
          ] else if (_error != null) ...[
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(settings.translate('Cancel', 'منسوخ', 'منسوخ', 'إلغاء')),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A574),
            ),
            child: Text(settings.translate('Retry', 'دوبارہ کوشش کریں', 'ٻيهر ڪوشش ڪريو', 'إعادة المحاولة')),
          ),
        ],
      ],
    );
  }
}
