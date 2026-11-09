import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
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
  final List<Completer<Uint8List?>> _activeCompleters = [];

  Stream<double> get progressStream => _progressController.stream;
  double get currentProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;

  /// Checks if Munajat PDF is downloaded and available in memory, assets, or disk
  Future<bool> isMunajatAvailable() async {
    if (_cachedBytes != null && _cachedBytes!.isNotEmpty) {
      return true;
    }

    if (!kIsWeb) {
      final local = await getExistingLocalFile();
      if (local != null) return true;
    }

    // Try loading bundled asset (Web and fallback)
    try {
      final assetData = await rootBundle.load('assets/quran_pdfs/MUNAJAT_E_MAQBOOL.pdf');
      if (assetData.lengthInBytes > 0) {
        _cachedBytes = assetData.buffer.asUint8List(assetData.offsetInBytes, assetData.lengthInBytes);
        return true;
      }
    } catch (e) {
      debugPrint('Bundled asset load attempt: $e');
    }

    return false;
  }

  /// Finds existing local File if downloaded (Native only)
  Future<io.File?> getExistingLocalFile() async {
    if (kIsWeb) return null;

    // Check debug Downloads directory on Windows
    final possiblePaths = [
      'C:\\Users\\Lenovo\\Downloads\\MUNAJAT_E_MAQBOOL.pdf',
      'C:\\Users\\Lenovo\\Downloads\\MUNAJAT_E_MAQBOOL (1).pdf',
    ];
    for (final p in possiblePaths) {
      try {
        final localFile = io.File(p);
        if (await localFile.exists() && (await localFile.length()) > 0) {
          return localFile;
        }
      } catch (_) {}
    }

    try {
      final file = await getLocalFile();
      if (await file.exists() && (await file.length()) > 0) {
        return file;
      }
    } catch (e) {
      debugPrint('Error checking local file: $e');
    }
    return null;
  }

  /// Gets local File object (Native only)
  Future<io.File> getLocalFile() async {
    final support = await getApplicationSupportDirectory();
    final dir = io.Directory('${support.path}/munajat_pdfs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return io.File('${dir.path}/$munajatFileName');
  }

  /// Returns PDF bytes for PDF Viewer (Web and Native fallback)
  Future<Uint8List?> getPdfBytes() async {
    if (_cachedBytes != null && _cachedBytes!.isNotEmpty) {
      return _cachedBytes;
    }
    if (!kIsWeb) {
      final local = await getExistingLocalFile();
      if (local != null) {
        final bytes = await local.readAsBytes();
        _cachedBytes = bytes;
        return bytes;
      }
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
      onProgress?.call(_cachedBytes!.length, _cachedBytes!.length, 1.0);
      return _cachedBytes;
    }

    if (await isMunajatAvailable()) {
      final bytes = await getPdfBytes();
      if (bytes != null && bytes.isNotEmpty) {
        onProgress?.call(bytes.length, bytes.length, 1.0);
        return bytes;
      }
    }

    if (_isDownloading) {
      final completer = Completer<Uint8List?>();
      _activeCompleters.add(completer);
      StreamSubscription? sub;
      sub = progressStream.listen((p) {
        onProgress?.call((p * 100).toInt(), 100, p);
      });
      return completer.future.whenComplete(() {
        sub?.cancel();
      });
    }

    _isDownloading = true;
    _downloadProgress = 0.05;
    _progressController.add(0.05);
    onProgress?.call(5, 100, 0.05);

    Uint8List? resultBytes;
    try {
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
        final client = http.Client();
        try {
          debugPrint('Downloading Munajat PDF from: $urlStr');
          final request = http.Request('GET', Uri.parse(urlStr));
          final response = await client.send(request).timeout(const Duration(seconds: 25));

          if (response.statusCode != 200 && response.statusCode != 302 && response.statusCode != 301) {
            continue;
          }

          final totalBytes = response.contentLength ?? (28 * 1024 * 1024);
          int downloadedBytes = 0;

          if (!kIsWeb) {
            final file = await getLocalFile();
            final partFile = io.File('${file.path}.part');
            if (await partFile.exists()) {
              await partFile.delete();
            }
            final sink = partFile.openWrite();
            try {
              await for (final chunk in response.stream.timeout(const Duration(seconds: 40))) {
                sink.add(chunk);
                downloadedBytes += chunk.length;
                double p = totalBytes > 0 ? (downloadedBytes / totalBytes) : 0.1;
                if (p > 0.99) p = 0.99;
                _downloadProgress = p;
                _progressController.add(p);
                onProgress?.call(downloadedBytes, totalBytes, p);
              }
              await sink.flush();
              await sink.close();

              if (await partFile.length() > 0) {
                if (await file.exists()) {
                  await file.delete();
                }
                await partFile.rename(file.path);
                final bytes = await file.readAsBytes();
                if (bytes.isNotEmpty) {
                  _cachedBytes = bytes;
                  resultBytes = bytes;
                  break;
                }
              }
            } catch (e) {
              await sink.close();
              if (await partFile.exists()) {
                await partFile.delete();
              }
              rethrow;
            }
          } else {
            final builder = BytesBuilder(copy: false);
            await for (final chunk in response.stream.timeout(const Duration(seconds: 40))) {
              builder.add(chunk);
              downloadedBytes += chunk.length;
              double p = totalBytes > 0 ? (downloadedBytes / totalBytes) : 0.1;
              if (p > 0.99) p = 0.99;
              _downloadProgress = p;
              _progressController.add(p);
              onProgress?.call(downloadedBytes, totalBytes, p);
            }
            final bytes = builder.takeBytes();
            if (bytes.isNotEmpty) {
              _cachedBytes = bytes;
              resultBytes = bytes;
              break;
            }
          }
        } catch (e) {
          debugPrint('Download error for $urlStr: $e');
        } finally {
          client.close();
        }
      }
    } finally {
      _isDownloading = false;
      if (resultBytes != null && resultBytes.isNotEmpty) {
        _downloadProgress = 1.0;
        _progressController.add(1.0);
        onProgress?.call(resultBytes.length, resultBytes.length, 1.0);
      } else {
        _downloadProgress = 0.0;
        _progressController.add(0.0);
      }
      final completers = List<Completer<Uint8List?>>.from(_activeCompleters);
      _activeCompleters.clear();
      for (final c in completers) {
        if (!c.isCompleted) {
          c.complete(resultBytes);
        }
      }
    }

    return resultBytes;
  }
}
