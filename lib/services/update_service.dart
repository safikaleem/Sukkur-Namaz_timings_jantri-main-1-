import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../l10n/world_translations.dart';

/// Tells the user when a newer build is on the Play Store.
///
/// The app cannot ask the Play Store what the latest version is, so the
/// version lives in a small JSON file we host ourselves - the same approach
/// [AnnouncementService] already uses for pamphlets. After publishing a build,
/// edit that file's `latestVersion` and every user is prompted on their next
/// launch.
///
/// The prompt is deliberately not remembered: "Later" closes it for now and it
/// returns on the next launch, and keeps returning until the user actually
/// updates. Once they do, the installed version matches and it stops on its
/// own.
class UpdateService {
  // TODO: Replace with the raw URL of your hosted update JSON, e.g. a GitHub
  // Gist raw link. Expected shape:
  //   {
  //     "latestVersion": "1.1.5",
  //     "playStoreUrl": "https://play.google.com/store/apps/details?id=pk.sukkur.salah"
  //   }
  // "playStoreUrl" is optional and falls back to [_defaultStoreUrl].
  static const String updateUrl =
      'https://gist.githubusercontent.com/safikaleem/REPLACE_ME/raw/update.json';

  static const String _defaultStoreUrl =
      'https://play.google.com/store/apps/details?id=pk.sukkur.salah';

  static bool hasPendingUpdate = false;
  static String? pendingVersion;
  static String? pendingStoreUrl;

  /// Prompts for an update when the hosted version is newer than the installed
  /// one. Silent on every failure: no network, a slow link, a malformed file or
  /// a deleted Gist all leave the app exactly as it was, because a prayer-times
  /// app must open normally whether or not the check succeeds.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final data = await _fetchUpdateInfo();
      if (data == null) return;

      final latest = (data['latestVersion'] as String?)?.trim();
      if (latest == null || latest.isEmpty) return;

      final info = await PackageInfo.fromPlatform();
      if (!isNewerVersion(latest, info.version)) {
        hasPendingUpdate = false;
        return;
      }

      final hosted = (data['playStoreUrl'] as String?)?.trim();
      final storeUrl =
          (hosted == null || hosted.isEmpty) ? _defaultStoreUrl : hosted;

      hasPendingUpdate = true;
      pendingVersion = latest;
      pendingStoreUrl = storeUrl;

      if (!context.mounted) return;
      await _showUpdateDialog(context, latest, storeUrl);
    } catch (e) {
      debugPrint('Failed to check for update: $e');
    }
  }

  /// Opens the pending update dialog directly if an update is available.
  static Future<void> openPendingUpdateDialog(BuildContext context) async {
    if (pendingVersion != null && pendingStoreUrl != null) {
      await _showUpdateDialog(context, pendingVersion!, pendingStoreUrl!);
    } else {
      await manualCheckForUpdate(context);
    }
  }

  /// Called when user taps "Check for Update" in the side menu.
  /// Checks for a newer version; if found, shows the update dialog.
  /// If no update exists or placeholder/network failed, opens Play Store directly.
  static Future<void> manualCheckForUpdate(BuildContext context) async {
    if (hasPendingUpdate && pendingVersion != null && pendingStoreUrl != null) {
      await _showUpdateDialog(context, pendingVersion!, pendingStoreUrl!);
      return;
    }

    try {
      final data = await _fetchUpdateInfo();
      if (data != null) {
        final latest = (data['latestVersion'] as String?)?.trim();
        final info = await PackageInfo.fromPlatform();
        if (latest != null && isNewerVersion(latest, info.version)) {
          final hosted = (data['playStoreUrl'] as String?)?.trim();
          final storeUrl =
              (hosted == null || hosted.isEmpty) ? _defaultStoreUrl : hosted;
          hasPendingUpdate = true;
          pendingVersion = latest;
          pendingStoreUrl = storeUrl;
          if (context.mounted) {
            await _showUpdateDialog(context, latest, storeUrl);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error during manual check for update: $e');
    }

    // Always fallback to opening the Play Store listing directly!
    await openStore();
  }

  /// Public method to open the store listing directly.
  static Future<void> openStore([String? url]) async {
    hasPendingUpdate = false;
    final storeUrl = (url != null && url.isNotEmpty) ? url : _defaultStoreUrl;
    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not open store listing: $e');
    }
  }

  /// True when [remote] is a later version than [installed].
  ///
  /// Compares dotted parts numerically, so 1.1.10 correctly beats 1.1.9 where a
  /// string comparison would not. Any build suffix ("1.1.5+23") is ignored,
  /// since the store shows only the version name. Anything unparseable returns
  /// false: a typo in the hosted file must never nag users who are already up
  /// to date.
  static bool isNewerVersion(String remote, String installed) {
    final a = _parseVersion(remote);
    final b = _parseVersion(installed);
    if (a == null || b == null) return false;

    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final left = i < a.length ? a[i] : 0;
      final right = i < b.length ? b[i] : 0;
      if (left != right) return left > right;
    }
    return false;
  }

  /// Splits "1.1.5+23" into [1, 1, 5], or null if it is not a dotted number.
  static List<int>? _parseVersion(String value) {
    final name = value.trim().split('+').first.trim();
    if (name.isEmpty) return null;

    final parts = <int>[];
    for (final part in name.split('.')) {
      final n = int.tryParse(part.trim());
      if (n == null || n < 0) return null;
      parts.add(n);
    }
    return parts.isEmpty ? null : parts;
  }

  /// Reads the hosted JSON. Short timeout so a dead link never delays the
  /// prompt behind a spinner the user cannot see.
  static Future<Map<String, dynamic>?> _fetchUpdateInfo() async {
    if (updateUrl.contains('REPLACE_ME')) return null;
    try {
      final response = await http
          .get(Uri.parse(updateUrl))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (e) {
      debugPrint('Error fetching update JSON: $e');
    }
    return null;
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    String latestVersion,
    String storeUrl,
  ) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isUrdu = settings.isUrdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final font = AppTheme.getFontForLanguage(context, settings.language);

    final title = translateFor(
        settings.language, 'Update Available', 'Update Available', 'اپ ڈیٹ دستیاب ہے');
    final body = translateFor(
        settings.language,
        'A new version of the app is available.',
        'A new version of the app is available.',
        'ایپ کا نیا ورژن دستیاب ہے۔');
    final laterText = translateFor(settings.language, 'Later', 'Later', 'بعد میں');
    final updateText =
        translateFor(settings.language, 'Update', 'Update', 'اپ ڈیٹ کریں');

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
          title: Row(
            children: [
              // Not const: AppTheme.accent tracks the user's chosen theme.
              Icon(Icons.system_update_rounded,
                  color: AppTheme.accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isUrdu ? 19 : 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: font,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                body,
                style: TextStyle(
                  fontSize: isUrdu ? 16 : 14,
                  fontFamily: font,
                  height: isUrdu ? 1.6 : null,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // Version numbers are digits either way, so they stay outside
              // translate() and read the same in every language.
              Text(
                'v$latestVersion',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                laterText,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: isUrdu ? 16 : 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _openStore(storeUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
              ),
              child: Text(
                updateText,
                style: TextStyle(
                  fontFamily: font,
                  fontWeight: FontWeight.bold,
                  fontSize: isUrdu ? 15 : 13,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Opens the store listing outside the app, which hands off to the Play
  /// Store app when it is installed.
  static Future<void> _openStore(String storeUrl) async {
    hasPendingUpdate = false;
    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not open store listing: $e');
    }
  }
}
