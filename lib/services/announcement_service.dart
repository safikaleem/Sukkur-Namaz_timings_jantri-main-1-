import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../l10n/world_translations.dart';

class AnnouncementService {
  // The hosted announcement file. Deliberately the revision-less raw link: a
  // Gist raw URL that carries a commit SHA is frozen at that revision, so
  // edits would never reach anyone. This form always serves the latest save.
  //
  // Set "enabled": false in the Gist to stop the popup. It has no memory of
  // what a user has already seen, so while enabled it shows on every launch.
  static const String announcementUrl =
      'https://gist.githubusercontent.com/safikaleem/2afecaa5e4b86ab5227ee00a7416646a/raw/announcement.json';

  static bool _isDialogOpen = false;

  /// Known city aliases for robust matching across English and Urdu inputs.
  static const Map<String, List<String>> _cityAliases = {
    'karachi': ['karachi', 'کراچی'],
    'sukkur': ['sukkur', 'sukur', 'sukkar', 'sakkhar', 'سکھر', 'سکر', 'سكر'],
    'lahore': ['lahore', 'لاہور'],
    'islamabad': ['islamabad', 'اسلام آباد', 'اسلام اباد'],
    'rawalpindi': ['rawalpindi', 'راولپنڈی'],
    'multan': ['multan', 'ملتان'],
    'peshawar': ['peshawar', 'پشاور'],
    'quetta': ['quetta', 'کوئٹہ'],
    'faisalabad': ['faisalabad', 'فیصل آباد', 'فیصل اباد'],
    'hyderabad': ['hyderabad', 'حیدرآباد', 'حیدر اباد'],
    'larkana': ['larkana', 'لاڑکانہ'],
  };

  /// Checks if there is a new remote announcement/pamphlet and shows it in a popup.
  /// If remote announcement is not active, falls back to the local Ramzan pamphlet.
  static Future<void> checkForAnnouncement(BuildContext context) async {
    if (_isDialogOpen) return;
    try {
      final dynamic fetchedData = await _fetchAnnouncement();
      if (fetchedData == null) return;
      if (!context.mounted || _isDialogOpen) return;

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final String userCity = (settings.locationMode == LocationMode.sukkur ||
              !settings.usesCalculatedTimings ||
              settings.cityName == null ||
              settings.cityName!.trim().isEmpty ||
              SukkurLocation.matchesName(settings.cityName))
          ? 'Sukkur'
          : settings.cityName!.trim();

      final announcement = selectAnnouncementForUser(fetchedData, userCity);
      if (announcement != null) {
        final bool enabled = announcement['enabled'] as bool? ?? false;
        final String? id = announcement['id'] as String?;
        if (enabled && id != null && id.isNotEmpty) {
          if (context.mounted && !_isDialogOpen) {
            await _showAnnouncementDialog(context, id, announcement, isLocal: false);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to check remote announcement: $e');
    }
  }

  /// Selects the best announcement matching the user's city.
  /// Priority:
  /// 1. An enabled announcement explicitly targeting userCity.
  /// 2. An enabled announcement targeting "all" or everyone (fallback).
  @visibleForTesting
  static Map<String, dynamic>? selectAnnouncementForUser(
    dynamic fetchedData,
    String userCity,
  ) {
    final candidates = <Map<String, dynamic>>[];

    if (fetchedData is Map<String, dynamic>) {
      if (fetchedData['announcements'] is List) {
        for (final item in fetchedData['announcements'] as List) {
          if (item is Map<String, dynamic>) {
            candidates.add(item);
          }
        }
      } else {
        candidates.add(fetchedData);
      }
    } else if (fetchedData is List) {
      for (final item in fetchedData) {
        if (item is Map<String, dynamic>) {
          candidates.add(item);
        }
      }
    }

    if (candidates.isEmpty) return null;

    Map<String, dynamic>? citySpecificMatch;
    Map<String, dynamic>? generalMatch;

    for (final candidate in candidates) {
      final bool enabled = candidate['enabled'] as bool? ?? false;
      final String? id = candidate['id'] as String?;
      if (!enabled || id == null || id.isEmpty) continue;

      final dynamic citiesRaw = candidate['cities'] ??
          candidate['city'] ??
          candidate['targetCities'] ??
          candidate['target_city'];

      if (matchesCitySpecifically(citiesRaw, userCity)) {
        citySpecificMatch ??= candidate;
        break; // Specific match has highest priority
      } else if (isTargetingAll(citiesRaw)) {
        generalMatch ??= candidate;
      }
    }

    return citySpecificMatch ?? generalMatch;
  }

  /// Checks if the target cities configuration targets all users worldwide.
  @visibleForTesting
  static bool isTargetingAll(dynamic citiesRaw) {
    if (citiesRaw == null) return true;
    final list = parseCityList(citiesRaw);
    if (list.isEmpty) return true;
    return list.any((c) =>
        c == 'all' ||
        c == '*' ||
        c == 'everyone' ||
        c == 'global' ||
        c == 'all cities' ||
        c == 'all_cities');
  }

  /// Checks if the announcement explicitly matches the given user city.
  @visibleForTesting
  static bool matchesCitySpecifically(dynamic citiesRaw, String userCity) {
    if (citiesRaw == null) return false;
    final list = parseCityList(citiesRaw);
    if (list.isEmpty) return false;

    final normUser = userCity.toLowerCase().trim();
    final cleanUser = normUser.split(',').first.trim();
    final bool isUserSukkur =
        normUser == 'sukkur' || SukkurLocation.matchesName(normUser);

    for (final target in list) {
      if (target.isEmpty ||
          target == 'all' ||
          target == '*' ||
          target == 'everyone' ||
          target == 'global' ||
          target == 'all cities' ||
          target == 'all_cities') {
        continue;
      }

      // Check Sukkur match
      if (isUserSukkur &&
          (target == 'sukkur' || SukkurLocation.matchesName(target))) {
        return true;
      }

      final cleanTarget = target.split(',').first.trim();

      // Direct exact match
      if (cleanTarget == cleanUser || target == normUser) {
        return true;
      }

      // Check against known alias dictionary
      for (final entry in _cityAliases.entries) {
        final aliases = entry.value;
        final targetInGroup = aliases.contains(cleanTarget) || aliases.contains(target);
        final userInGroup = aliases.contains(cleanUser) || aliases.contains(normUser);
        if (targetInGroup && userInGroup) {
          return true;
        }
      }

      // Prefix match for longer city names (>= 3 chars) to allow e.g. "Karachi, Pakistan"
      if (cleanUser.length >= 3 && cleanTarget.length >= 3) {
        if (cleanUser.startsWith(cleanTarget) || cleanTarget.startsWith(cleanUser)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Parses diverse JSON formats (List, comma-delimited String) into lowercase city names.
  @visibleForTesting
  static List<String> parseCityList(dynamic raw) {
    final List<String> result = [];
    if (raw is List) {
      for (final item in raw) {
        if (item != null) {
          result.addAll(
            item.toString().split(',').map((s) => s.trim().toLowerCase()),
          );
        }
      }
    } else if (raw is String) {
      result.addAll(
        raw.split(',').map((s) => s.trim().toLowerCase()),
      );
    }
    return result;
  }

  /// Fetches the JSON file from the hosted URL using package:http.
  /// Uses cache-busting headers and a timestamp query parameter to bypass CDN/ISP caches.
  static Future<dynamic> _fetchAnnouncement() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final headers = {
      'Accept': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final sep = announcementUrl.contains('?') ? '&' : '?';
        final freshUrl = '$announcementUrl${sep}t=$timestamp';
        final response = await (kIsWeb
                ? http.get(Uri.parse(freshUrl))
                : http.get(Uri.parse(freshUrl), headers: headers))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> || decoded is List) {
            return decoded;
          }
        }
      } catch (e) {
        debugPrint('Announcement fetch attempt $attempt failed: $e');
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        }
      }
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
    String? description,
    String announcementId,
  ) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    BuildContext? loadingCtx;

    try {
      // If there is no image, we just share text directly without showing a loading dialog
      if (!isLocal && (imageUrl == null || imageUrl.isEmpty)) {
        String shareText = '';
        if (title != null && title.isNotEmpty) shareText += '$title\n\n';
        if (description != null && description.isNotEmpty) shareText += description;

        if (shareText.trim().isEmpty) shareText = 'Sukkur Prayer Timings Announcement';

        await SharePlus.instance.share(ShareParams(text: shareText.trim()));
        return;
      }

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

      Uint8List bytes;
      if (isLocal) {
        final byteData = await rootBundle.load('assets/images/ramzan_pamphlet.jpg');
        bytes = byteData.buffer.asUint8List();
      } else {
        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('Image URL is empty');
        }
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            'Accept': 'image/jpeg,image/png,image/*,*/*;q=0.8',
          },
        ).timeout(const Duration(seconds: 25));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image (Status: ${response.statusCode})');
        }
        bytes = response.bodyBytes;
      }

      final String shareSubjectText = (title != null && title.isNotEmpty)
          ? title
          : settings.translate('Ramzan Timetable', 'رمضان المبارک کا ٹائم ٹیبل', 'Ramzan Timetable', 'Ramzan Timetable');

      if (kIsWeb) {
        if (loadingCtx != null && loadingCtx!.mounted) {
          Navigator.pop(loadingCtx!);
          loadingCtx = null;
        }
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                mimeType: 'image/jpeg',
                name: '${_shareFileName(announcementId, isLocal)}.jpg',
              )
            ],
            text: shareSubjectText,
          ),
        );
        return;
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

      final file = File('${tempDir.path}/${_shareFileName(announcementId, isLocal)}.$ext');
      await file.writeAsBytes(bytes);

      if (loadingCtx != null && loadingCtx!.mounted) {
        Navigator.pop(loadingCtx!);
        loadingCtx = null;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: shareSubjectText,
        ),
      );
    } catch (e) {
      if (loadingCtx != null && loadingCtx!.mounted) {
        Navigator.pop(loadingCtx!);
      }
      debugPrint('Error sharing image: $e');
      if (context.mounted) {
        await _showShareError(context, e);
      }
    }
  }

  /// A file name for the shared image, taken from the announcement id.
  ///
  /// Every announcement used to be written out as 'ramzan_pamphlet' whatever
  /// it actually was, so a hadith image reached the recipient named after
  /// Ramzan.
  static String _shareFileName(String announcementId, bool isLocal) {
    if (isLocal) return 'ramzan_pamphlet';
    final cleaned = announcementId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return cleaned.isEmpty ? 'announcement' : cleaned;
  }

  /// Reports a share failure on a dialog route rather than in a SnackBar.
  ///
  /// The announcement popup is still on screen when sharing fails, and a
  /// SnackBar is drawn inside the Scaffold - underneath that popup's modal
  /// barrier. The message was therefore never visible: the spinner appeared,
  /// vanished, and nothing followed, which is indistinguishable from a button
  /// that does nothing at all. A dialog goes on the Navigator, above it.
  ///
  /// The error text is selectable so it can be copied and reported.
  static Future<void> _showShareError(BuildContext context, Object error) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final font = AppTheme.getFontForLanguage(context, settings.language);

    await showDialog<void>(
      context: context,
      builder: (BuildContext errCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        title: Text(
          settings.translate(
            'Error sharing/saving image:',
            'فائل محفوظ یا شیئر کرنے میں خرابی پیش آئی:',
            'Error sharing/saving image:',
            'Error sharing/saving image:',
          ),
          style: TextStyle(
            fontFamily: font,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            '$error',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(errCtx),
            child: Text(
              settings.translate('Close', 'بند کریں', 'Close', 'Close'),
              style: TextStyle(fontFamily: font),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the announcement popup dialog.
  static Future<void> _showAnnouncementDialog(
    BuildContext context,
    String announcementId,
    Map<String, dynamic> data, {
    required bool isLocal,
  }) async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final isUrdu = settings.isUrdu;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final String? imageUrl = data['imageUrl'] as String?;
      final String? actionUrl = data['actionUrl'] as String?;
      final String? title = data['title'] as String?;
      final String? description = data['description'] as String?;

      final String closeText = translateFor(settings.language, 'Close', 'Close', 'بند کریں');
      final String actionText = translateFor(settings.language, 'View Details', 'View Details', 'تفصیلات دیکھیں');
      final String shareText = translateFor(settings.language, 'Save / Share', 'Save / Share', 'محفوظ / شیئر کریں');

      return await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          int reloadCount = 0;

          return StatefulBuilder(
            builder: (BuildContext sContext, StateSetter setDialogState) {
              final mediaQuery = MediaQuery.of(dialogContext);
              final isLandscape = mediaQuery.orientation == Orientation.landscape;
              final screenHeight = mediaQuery.size.height;
              final double imageMaxHeight = isLandscape
                  ? (screenHeight * 0.38).clamp(120.0, 220.0)
                  : (screenHeight * 0.45).clamp(180.0, 420.0);

              return Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 10,
                backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440.0,
                    maxHeight: screenHeight * 0.88,
                  ),
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
                              maxHeight: imageMaxHeight,
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
                                  : CachedNetworkImage(
                                      key: ValueKey('${imageUrl}_${announcementId}_$reloadCount'),
                                      cacheKey: '${imageUrl}_$announcementId',
                                      imageUrl: imageUrl!,
                                      fit: BoxFit.contain,
                                    httpHeaders: const {
                                      'User-Agent':
                                          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                                      'Accept': 'image/jpeg,image/png,image/*,*/*;q=0.8',
                                    },
                                    placeholder: (context, url) => const Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(strokeWidth: 2.5),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.broken_image_rounded,
                                              size: 40,
                                              color: isDark ? Colors.white38 : AppTheme.greyText,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              settings.translate(
                                                'Failed to load image',
                                                'تصویر لوڈ نہیں ہو سکی',
                                                'تصویر لوڈ نہ ٿي سگهي',
                                                'تعذر تحميل الصورة',
                                              ),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                                color: isDark ? Colors.white70 : Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                try {
                                                  await CachedNetworkImage.evictFromCache(imageUrl);
                                                } catch (_) {}
                                                setDialogState(() {
                                                  reloadCount++;
                                                });
                                              },
                                              icon: const Icon(Icons.refresh_rounded, size: 16),
                                              label: Text(
                                                settings.translate(
                                                  'Retry',
                                                  'دوبارہ کوشش کریں',
                                                  'ٻيهر ڪوشش ڪريو',
                                                  'إعادة المحاولة',
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.accent,
                                                side: BorderSide(color: AppTheme.accent),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12.0, vertical: 6.0),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
                                const SizedBox(height: 6.0),
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
                        runSpacing: 6.0,
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
                                fontSize: isUrdu ? 15 : 13,
                              ),
                            ),
                          ),
                          // Save / Share button
                          ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await _saveAndShareImage(
                                    context,
                                    isLocal,
                                    imageUrl,
                                    title,
                                    description,
                                    announcementId,
                                  );
                                } catch (e) {
                                  debugPrint('Share button failed: $e');
                                  if (context.mounted) {
                                    await _showShareError(context, e);
                                  }
                                }
                              },
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: Text(
                                shareText,
                                style: TextStyle(
                                  fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                  fontWeight: FontWeight.bold,
                                  fontSize: isUrdu ? 14 : 12,
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
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                              ),
                              child: Text(
                                actionText,
                                style: TextStyle(
                                  fontFamily: AppTheme.getFontForLanguage(context, settings.language),
                                  fontWeight: FontWeight.bold,
                                  fontSize: isUrdu ? 14 : 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    } finally {
      _isDialogOpen = false;
    }
  }
}
