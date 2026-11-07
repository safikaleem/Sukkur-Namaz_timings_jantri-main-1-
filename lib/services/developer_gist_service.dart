import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing GitHub Gist updates for Announcements & Hijri Calendar
/// Exclusively used in Developer / Admin Mode.
class DeveloperGistService {
  DeveloperGistService._();
  static final DeveloperGistService instance = DeveloperGistService._();

  static const String gistId = '2afecaa5e4b86ab5227ee00a7416646a';
  static const String prefKeyGistToken = 'dev_github_gist_token';

  static const String announcementRawUrl =
      'https://gist.githubusercontent.com/safikaleem/$gistId/raw/announcement.json';
  static const String hijriCalendarRawUrl =
      'https://gist.githubusercontent.com/safikaleem/$gistId/raw/hijri_calendar.json';
  static const String jamaatTimesRawUrl =
      'https://gist.githubusercontent.com/safikaleem/$gistId/raw/jamaat_times.json';

  Future<String?> getGistToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(prefKeyGistToken);
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    return null;
  }

  Future<void> saveGistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = token.trim();
    if (clean.isEmpty) {
      await prefs.remove(prefKeyGistToken);
    } else {
      await prefs.setString(prefKeyGistToken, clean);
    }
  }

  /// Fetches authoritative content of a Gist file directly via GitHub REST API if token available,
  /// completely bypassing the 5-minute Fastly CDN cache on raw URLs.
  Future<String?> fetchGistFileDirect(String fileName) async {
    final token = await getGistToken();
    if (token != null && token.isNotEmpty) {
      try {
        final url = Uri.parse('https://api.github.com/gists/$gistId');
        final res = await http.get(
          url,
          headers: {
            'Accept': 'application/vnd.github+json',
            'Authorization': 'Bearer $token',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        ).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic> && decoded.containsKey('files')) {
            final files = decoded['files'] as Map<String, dynamic>;
            if (files.containsKey(fileName)) {
              final content = files[fileName]['content'] as String?;
              if (content != null && content.isNotEmpty) {
                return content;
              }
            }
          }
        }
      } catch (e) {
        // Fall back to raw URL
      }
    }
    return null;
  }

  /// Fetches raw JSON map of hijri_calendar.json
  Future<Map<String, String>> fetchHijriCalendar() async {
    final direct = await fetchGistFileDirect('hijri_calendar.json');
    if (direct != null) {
      try {
        final decoded = jsonDecode(direct);
        if (decoded is Map<String, dynamic> && decoded['month_starts'] is Map) {
          final Map<String, String> result = {};
          (decoded['month_starts'] as Map).forEach((k, v) {
            result[k.toString()] = v.toString();
          });
          return result;
        }
      } catch (_) {}
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = '$hijriCalendarRawUrl?t=$timestamp';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic> && decoded['month_starts'] is Map) {
        final Map<String, String> result = {};
        (decoded['month_starts'] as Map).forEach((k, v) {
          result[k.toString()] = v.toString();
        });
        return result;
      }
    }
    return {};
  }

  /// Fetches raw announcement.json map
  Future<Map<String, dynamic>> fetchAnnouncements() async {
    final direct = await fetchGistFileDirect('announcement.json');
    if (direct != null) {
      try {
        final decoded = jsonDecode(direct);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = '$announcementRawUrl?t=$timestamp';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return {};
  }

  /// Fetches raw JSON map of jamaat_times.json from Gist
  Future<Map<String, dynamic>> fetchJamaatTimesJson() async {
    final direct = await fetchGistFileDirect('jamaat_times.json');
    if (direct != null) {
      try {
        final decoded = jsonDecode(direct);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = '$jamaatTimesRawUrl?t=$timestamp';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return {};
  }

  /// Saves or appends a masjid map to jamaat_times.json in GitHub Gist
  Future<({bool success, String message})> saveMasjidToGist(
    Map<String, dynamic> newMasjidMap,
  ) async {
    final token = await getGistToken();
    if (token == null || token.isEmpty) {
      return (
        success: false,
        message: 'GitHub Personal Access Token is required. Please set it in Developer settings.',
      );
    }

    try {
      final currentData = await fetchJamaatTimesJson();
      final Map<String, dynamic> gistData = currentData.isNotEmpty
          ? Map<String, dynamic>.from(currentData)
          : {
              'master_pin': '25081989',
              'masjids': <Map<String, dynamic>>[],
            };

      final rawMasjids = gistData['masjids'];
      final List<Map<String, dynamic>> masjids = [];
      if (rawMasjids is List) {
        for (final item in rawMasjids) {
          if (item is Map) {
            masjids.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final newId = newMasjidMap['id']?.toString().trim() ?? '';
      if (newId.isEmpty) {
        return (success: false, message: 'Invalid masjid ID.');
      }

      final existingIndex = masjids.indexWhere((m) => m['id']?.toString().trim() == newId);
      if (existingIndex >= 0) {
        final merged = Map<String, dynamic>.from(masjids[existingIndex]);
        newMasjidMap.forEach((k, v) {
          if (v != null) merged[k] = v;
        });

        // Keep flat keys synchronized with nested multi-language dictionaries
        const langSuffixes = {
          'urdu': 'ur',
          'sindhi': 'sd',
          'arabic': 'ar',
          'hindi': 'hi',
          'bengali': 'bn',
          'persian': 'fa',
          'turkish': 'tr',
          'french': 'fr',
          'indonesian': 'id',
        };
        if (newMasjidMap['names'] is Map) {
          final nMap = newMasjidMap['names'] as Map;
          langSuffixes.forEach((lang, suffix) {
            if (nMap[lang] != null && nMap[lang].toString().trim().isNotEmpty) {
              merged['name_$suffix'] = nMap[lang].toString().trim();
            }
          });
        }
        if (newMasjidMap['addresses'] is Map) {
          final aMap = newMasjidMap['addresses'] as Map;
          langSuffixes.forEach((lang, suffix) {
            if (aMap[lang] != null && aMap[lang].toString().trim().isNotEmpty) {
              merged['address_$suffix'] = aMap[lang].toString().trim();
            }
          });
        }

        masjids[existingIndex] = merged;
      } else {
        masjids.add(newMasjidMap);
      }

      gistData['masjids'] = masjids;
      if (!gistData.containsKey('master_pin')) {
        gistData['master_pin'] = '25081989';
      }

      const encoder = JsonEncoder.withIndent('  ');
      final updatedJsonStr = encoder.convert(gistData);

      return await updateGistFiles(jamaatTimesContent: updatedJsonStr);
    } catch (e) {
      return (success: false, message: 'Failed to update Gist: $e');
    }
  }

  /// Updates the master admin PIN in GitHub Gist (jamaat_times.json)
  Future<({bool success, String message})> updateMasterPinOnGist(String newMasterPin) async {
    final token = await getGistToken();
    if (token == null || token.isEmpty) {
      return (
        success: false,
        message: 'GitHub Personal Access Token is required. Please set it in Developer settings.',
      );
    }

    try {
      final currentData = await fetchJamaatTimesJson();
      final Map<String, dynamic> gistData = currentData.isNotEmpty
          ? Map<String, dynamic>.from(currentData)
          : {
              'master_pin': '25081989',
              'masjids': <Map<String, dynamic>>[],
            };

      gistData['master_pin'] = newMasterPin.trim();

      const encoder = JsonEncoder.withIndent('  ');
      final updatedJsonStr = encoder.convert(gistData);

      return await updateGistFiles(jamaatTimesContent: updatedJsonStr);
    } catch (e) {
      return (success: false, message: 'Failed to update Master PIN on Gist: $e');
    }
  }

  /// Updates files in GitHub Gist via GitHub REST API (PATCH)
  Future<({bool success, String message})> updateGistFiles({
    String? announcementContent,
    String? hijriCalendarContent,
    String? jamaatTimesContent,
  }) async {
    final token = await getGistToken();
    if (token == null || token.isEmpty) {
      return (
        success: false,
        message: 'GitHub Personal Access Token is required. Please set it in Developer settings.',
      );
    }

    final filesPayload = <String, dynamic>{};
    if (announcementContent != null) {
      filesPayload['announcement.json'] = {'content': announcementContent};
    }
    if (hijriCalendarContent != null) {
      filesPayload['hijri_calendar.json'] = {'content': hijriCalendarContent};
    }
    if (jamaatTimesContent != null) {
      filesPayload['jamaat_times.json'] = {'content': jamaatTimesContent};
    }

    if (filesPayload.isEmpty) {
      return (success: false, message: 'Nothing to update.');
    }

    try {
      final url = Uri.parse('https://api.github.com/gists/$gistId');
      final body = jsonEncode({'files': filesPayload});

      final response = await http.patch(
        url,
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': 'Bearer $token',
          'X-GitHub-Api-Version': '2022-11-28',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (
          success: true,
          message: 'Successfully updated GitHub Gist! Changes are now live.',
        );
      } else {
        final errBody = response.body;
        return (
          success: false,
          message: 'GitHub Error (${response.statusCode}): $errBody',
        );
      }
    } catch (e) {
      return (
        success: false,
        message: 'Network error communicating with GitHub: $e',
      );
    }
  }

  static const String firestoreProjectId = 'sukkur-salah';

  /// Syncs Hijri Calendar month starts directly to Cloud Firestore so changes propagate with 0-second delay to all users
  Future<bool> syncHijriCalendarToFirestore(Map<String, String> monthStarts) async {
    try {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firestoreProjectId/databases/(default)/documents/app_config/hijri_calendar',
      );
      final body = json.encode({
        'fields': {
          'data': {
            'stringValue': json.encode({
              'month_starts': monthStarts,
              'updated_at': DateTime.now().toIso8601String(),
            }),
          }
        }
      });
      final res = await http.patch(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  /// Syncs Announcement payload directly to Cloud Firestore so popups & banners appear with 0-second delay on user devices
  Future<bool> syncAnnouncementsToFirestore(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$firestoreProjectId/databases/(default)/documents/app_config/announcements',
      );
      final body = json.encode({
        'fields': {
          'data': {
            'stringValue': json.encode(payload),
          }
        }
      });
      final res = await http.patch(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
}
