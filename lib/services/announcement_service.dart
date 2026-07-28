import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

class AnnouncementService {
  // TODO: Replace this URL with your hosted JSON file URL.
  // This can be a GitHub raw link, Firebase hosting, or your own website URL.
  static const String announcementUrl =
      'https://gist.githubusercontent.com/safikaleem/dec1a7453d964e89edc0832d09774cf8/raw/announcement.json';

  /// Checks if there is a new remote announcement/pamphlet and shows it in a popup.
  /// If remote announcement is not active, falls back to the local Ramzan pamphlet.
  static Future<void> checkForAnnouncement(BuildContext context) async {
    try {
      final announcement = await _fetchAnnouncement();
      if (announcement != null) {
        final bool enabled = announcement['enabled'] as bool? ?? false;
        final String? id = announcement['id'] as String?;
        if (enabled && id != null && id.isNotEmpty) {
          // Show each announcement only once: skip if this id was already shown.
          final prefs = await SharedPreferences.getInstance();
          if (prefs.getString('last_announcement_id') == id) return;
          if (context.mounted) {
            // Persist before showing so it isn't re-shown on next launch even
            // if the user dismisses it.
            await prefs.setString('last_announcement_id', id);
            await _showAnnouncementDialog(context, id, announcement, isLocal: false);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to check remote announcement: $e');
    }

  }

  /// Fetches the JSON file from the hosted URL using package:http.
  static Future<Map<String, dynamic>?> _fetchAnnouncement() async {
    try {
      final response = await http.get(Uri.parse(announcementUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Error fetching announcement JSON: $e');
    }
    return null;
  }

  /// Downloads or loads the image and shares it using share_plus.
  /// This triggers the native share sheet, allowing the user to share or save to gallery.
  static Future<void> _saveAndShareImage(
    BuildContext context,
    bool isLocal,
    String? imageUrl,
    String? title,
  ) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isUrdu = settings.isUrdu;
    final messenger = ScaffoldMessenger.of(context);

    BuildContext? loadingCtx;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext lCtx) {
        loadingCtx = lCtx;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      Uint8List bytes;
      if (isLocal) {
        final byteData = await rootBundle.load('assets/images/ramzan_pamphlet.jpg');
        bytes = byteData.buffer.asUint8List();
      } else {
        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('Image URL is empty');
        }
        final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image (Status: ${response.statusCode})');
        }
        bytes = response.bodyBytes;
      }

      final tempDir = await getTemporaryDirectory();
      String ext = 'jpg';
      if (!isLocal && imageUrl != null) {
        final uri = Uri.parse(imageUrl);
        final path = uri.path;
        if (path.contains('.')) {
          final parts = path.split('.');
          if (parts.isNotEmpty) {
            final possibleExt = parts.last.toLowerCase();
            if (possibleExt == 'jpg' || possibleExt == 'jpeg' || possibleExt == 'png' || possibleExt == 'gif') {
              ext = possibleExt;
            }
          }
        }
      }

      final file = File('${tempDir.path}/ramzan_pamphlet.$ext');
      await file.writeAsBytes(bytes);

      if (loadingCtx != null && loadingCtx!.mounted) {
        Navigator.pop(loadingCtx!);
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: title ?? (isUrdu ? 'رمضان المبارک کا ٹائم ٹیبل' : 'Ramzan Timetable'),
        ),
      );
    } catch (e) {
      if (loadingCtx != null && loadingCtx!.mounted) {
        Navigator.pop(loadingCtx!);
      }
      debugPrint('Error sharing image: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? 'فائل محفوظ یا شیئر کرنے میں خرابی پیش آئی: $e'
                : 'Error sharing/saving image: $e',
            style: TextStyle(fontFamily: AppTheme.getFontForLanguage(context, settings.language)),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Displays the announcement popup dialog.
  static Future<void> _showAnnouncementDialog(
    BuildContext context,
    String announcementId,
    Map<String, dynamic> data, {
    required bool isLocal,
  }) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isUrdu = settings.isUrdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String? imageUrl = data['imageUrl'] as String?;
    final String? actionUrl = data['actionUrl'] as String?;
    final String? title = data['title'] as String?;
    final String? description = data['description'] as String?;

    final String closeText = isUrdu ? 'بند کریں' : 'Close';
    final String actionText = isUrdu ? 'تفصیلات دیکھیں' : 'View Details';
    final String shareText = isUrdu ? 'محفوظ / شیئر کریں' : 'Save / Share';

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 10,
          backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Image/Pamphlet section
              if (isLocal || (imageUrl != null && imageUrl.isNotEmpty))
                GestureDetector(
                  onTap: () async {
                    if (!isLocal && actionUrl != null && actionUrl.isNotEmpty) {
                      final uri = Uri.parse(actionUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    color: isDark ? Colors.black26 : const Color(0xFFF0F0F0),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: isLocal
                          ? Image.asset(
                              'assets/images/ramzan_pamphlet.jpg',
                              fit: BoxFit.contain,
                            )
                          : Image.network(
                              imageUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 48,
                                    color: AppTheme.greyText,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),

              // 2. Text Content (Title & Description)
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null && title.isNotEmpty)
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                              color: isDark ? Colors.white70 : Colors.black54,
                              height: isUrdu ? 1.4 : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    // Close button (Dismiss)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: Text(
                        closeText,
                        style: TextStyle(
                          fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: isUrdu ? 16 : 14,
                        ),
                      ),
                    ),
                    // Save / Share button (hidden on web due to file system limitations)
                    if (!kIsWeb)
                      ElevatedButton.icon(
                      onPressed: () {
                        _saveAndShareImage(context, isLocal, imageUrl, title);
                      },
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: Text(
                        shareText,
                        style: TextStyle(
                          fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                          fontWeight: FontWeight.bold,
                          fontSize: isUrdu ? 15 : 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      ),
                    ),
                    
                    // Action button (if actionUrl is set and it's a remote announcement)
                    if (!isLocal && actionUrl != null && actionUrl.isNotEmpty) ...[
                      ElevatedButton(
                        onPressed: () async {
                          final uri = Uri.parse(actionUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        ),
                        child: Text(
                          actionText,
                          style: TextStyle(
                            fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                            fontWeight: FontWeight.bold,
                            fontSize: isUrdu ? 15 : 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
