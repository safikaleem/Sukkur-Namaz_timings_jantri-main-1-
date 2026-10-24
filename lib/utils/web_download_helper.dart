import 'dart:typed_data';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';

void saveImageOnWeb(Uint8List bytes, String filename) {
  downloadBytesWeb(bytes, filename);
}
