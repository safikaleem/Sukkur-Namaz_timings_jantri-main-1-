import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MunajatDownloadService {
  static final MunajatDownloadService instance = MunajatDownloadService._();
  MunajatDownloadService._();

  static const String baseUrl =
      'https://github.com/safikaleem/Sukkur-Namaz_timings_jantri-main-1-/releases/download/v1.0.0/';
  static const String munajatFileName = 'MUNAJAT_E_MAQBOOL.pdf';

  Uint8List? _cachedBytes;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final StreamController<double> _progressController = StreamController<double>.broadcast();

  Stream<double> get progressStream => _progressController.stream;
  double get currentProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;

  /// Checks if Munajat PDF is downloaded and available in memory, assets, or disk
  Future<bool> isMunajatAvailable() async {
    if (_cachedBytes != null && _cachedBytes!.isNotEmpty) {
      return true;
    }

    // Try loading bundled asset first (0-second load on Chrome Web and Native)
    try {
      final assetData = await rootBundle.load('assets/quran_pdfs/MUNAJAT_E_MAQBOOL.pdf');
      if (assetData.lengthInBytes > 0) {
        _cachedBytes = assetData.buffer.asUint8List(assetData.offsetInBytes, assetData.lengthInBytes);
        return true;
      }
    } catch (e) {
      debugPrint('Bundled asset load attempt: $e');
    }

    if (!kIsWeb) {
      // Check debug Downloads directory on Windows
      final possiblePaths = [
        'C:\\Users\\Lenovo\\Downloads\\MUNAJAT_E_MAQBOOL.pdf',
        'C:\\Users\\Lenovo\\Downloads\\MUNAJAT_E_MAQBOOL (1).pdf',
      ];
      for (final p in possiblePaths) {
        try {
          final localFile = io.File(p);
          if (await localFile.exists() && (await localFile.length()) > 0) {
            _cachedBytes = await localFile.readAsBytes();
            return true;
          }
        } catch (_) {}
      }

      // Check app support storage directory
      try {
        final file = await _getLocalFile();
        if (await file.exists() && (await file.length()) > 0) {
          _cachedBytes = await file.readAsBytes();
          return true;
        }
      } catch (e) {
        debugPrint('Error checking local file: $e');
      }
    }
    return false;
  }

  /// Gets local File object (Native only)
  Future<io.File> _getLocalFile() async {
    final support = await getApplicationSupportDirectory();
    final dir = io.Directory('${support.path}/munajat_pdfs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return io.File('${dir.path}/$munajatFileName');
  }

  /// Returns PDF bytes for PDF Viewer (Web and Native)
  Future<Uint8List?> getPdfBytes() async {
    if (_cachedBytes != null && _cachedBytes!.isNotEmpty) {
      return _cachedBytes;
    }
    if (await isMunajatAvailable()) {
      return _cachedBytes;
    }
    return null;
  }

  /// Silent background auto-download on app start
  Future<void> autoDownload() async {
    if (await isMunajatAvailable()) return;
    if (_isDownloading) return;
    downloadMunajat(onProgress: (_, __, ___) {});
  }

  /// Downloads PDF with progress callback (works on Chrome Web & Native)
  Future<Uint8List?> downloadMunajat({
    void Function(int downloaded, int total, double progress)? onProgress,
  }) async {
    if (_cachedBytes != null && _cachedBytes!.isNotEmpty) {
      onProgress?.call(1, 1, 1.0);
      return _cachedBytes;
    }

    if (await isMunajatAvailable()) {
      onProgress?.call(_cachedBytes!.length, _cachedBytes!.length, 1.0);
      return _cachedBytes;
    }

    if (_isDownloading) {
      final completer = Completer<Uint8List?>();
      late StreamSubscription sub;
      sub = progressStream.listen((p) async {
        onProgress?.call((p * 100).toInt(), 100, p);
        if (p >= 1.0) {
          sub.cancel();
          completer.complete(await getPdfBytes());
        }
      });
      return completer.future;
    }

    _isDownloading = true;
    _downloadProgress = 0.05;
    _progressController.add(0.05);
    onProgress?.call(5, 100, 0.05);

    const primaryUrlStr = '$baseUrl$munajatFileName';
    final List<String> urlsToTry = kIsWeb
        ? [
            'https://corsproxy.io/?${Uri.encodeComponent(primaryUrlStr)}',
            'https://api.allorigins.win/raw?url=${Uri.encodeComponent(primaryUrlStr)}',
            primaryUrlStr,
          ]
        : [
            primaryUrlStr,
          ];

    for (final urlStr in urlsToTry) {
      try {
        debugPrint('Downloading Munajat PDF from: $urlStr');
        final client = http.Client();
        final request = http.Request('GET', Uri.parse(urlStr));
        final response = await client.send(request).timeout(const Duration(seconds: 20));

        if (response.statusCode != 200 && response.statusCode != 302 && response.statusCode != 301) {
          continue;
        }

        final totalBytes = response.contentLength ?? (28 * 1024 * 1024);
        int downloadedBytes = 0;
        final List<int> bytesList = [];

        await for (final chunk in response.stream.timeout(const Duration(seconds: 40))) {
          bytesList.addAll(chunk);
          downloadedBytes += chunk.length;
          double p = totalBytes > 0 ? (downloadedBytes / totalBytes) : 0.1;
          if (p > 0.99) p = 0.99;
          _downloadProgress = p;
          _progressController.add(p);
          onProgress?.call(downloadedBytes, totalBytes, p);
        }

        final bytes = Uint8List.fromList(bytesList);
        if (bytes.isNotEmpty) {
          _cachedBytes = bytes;
          _downloadProgress = 1.0;
          _progressController.add(1.0);
          onProgress?.call(bytes.length, bytes.length, 1.0);

          if (!kIsWeb) {
            try {
              final file = await _getLocalFile();
              await file.writeAsBytes(bytes);
            } catch (e) {
              debugPrint('Error saving file to disk: $e');
            }
          }
          _isDownloading = false;
          return bytes;
        }
      } catch (e) {
        debugPrint('Download error for $urlStr: $e');
      }
    }

    _isDownloading = false;
    _downloadProgress = 0.0;
    _progressController.add(0.0);
    return null;
  }
}
