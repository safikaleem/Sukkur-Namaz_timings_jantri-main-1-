import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/hijri_converter.dart';

class HijriSyncService {
  // Remote Gist URL for Pakistan Ruet-e-Hilal calendar data.
  static const String hijriCalendarUrl =
      'https://gist.githubusercontent.com/safikaleem/2afecaa5e4b86ab5227ee00a7416646a/raw/hijri_calendar.json';

  // Also check the main announcement JSON in case moon sighting data is added there.
  static const String announcementUrl =
      'https://gist.githubusercontent.com/safikaleem/2afecaa5e4b86ab5227ee00a7416646a/raw/announcement.json';

  static const String prefKeyMonthStarts = 'custom_hijri_month_starts';
  static const String prefKeyLastSync = 'hijri_last_sync_timestamp';

  /// Loads saved custom month starts from local cache into HijriConverter.
  static Future<void> loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(prefKeyMonthStarts);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson);
        if (decoded is Map<String, dynamic>) {
          final Map<String, String> monthStarts = {};
          decoded.forEach((key, value) {
            if (value is String) {
              monthStarts[key] = value;
            }
          });
          HijriConverter.applyMonthStarts(monthStarts);
        }
      }
    } catch (e) {
      debugPrint('Failed to load cached Hijri month starts: $e');
    }
  }

  /// Syncs Pakistan Ruet-e-Hilal moon sighting calendar from online Gist.
  /// Returns true if new data was fetched and applied.
  static Future<bool> syncFromNetwork() async {
    const headers = {
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };

    // 1. Try dedicated hijri_calendar.json first
    try {
      final response = await http
          .get(Uri.parse(hijriCalendarUrl), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final starts = _extractMonthStarts(decoded);
          if (starts.isNotEmpty) {
            await _saveAndApply(starts);
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Hijri calendar direct fetch skipped/failed: $e');
    }

    // 2. Fallback: Check announcement.json for "hijri_month_starts"
    try {
      final response = await http
          .get(Uri.parse(announcementUrl), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final starts = _extractMonthStarts(decoded);
          if (starts.isNotEmpty) {
            await _saveAndApply(starts);
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Announcement Hijri check skipped/failed: $e');
    }

    return false;
  }

  static Map<String, String> _extractMonthStarts(Map<String, dynamic> data) {
    final Map<String, String> result = {};

    // Check for "month_starts" or "hijri_month_starts" key
    final dynamic starts = data['month_starts'] ?? data['hijri_month_starts'];
    if (starts is Map) {
      starts.forEach((k, v) {
        if (k is String && v is String) {
          result[k] = v;
        }
      });
    } else {
      // Maybe keys are formatted directly like "1448-04": "2026-09-14"
      data.forEach((k, v) {
        if (RegExp(r'^\d{4}-\d{2}$').hasMatch(k) && v is String) {
          result[k] = v;
        }
      });
    }

    return result;
  }

  static Future<void> _saveAndApply(Map<String, String> starts) async {
    HijriConverter.applyMonthStarts(starts);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyMonthStarts, jsonEncode(starts));
    await prefs.setString(prefKeyLastSync, DateTime.now().toIso8601String());
  }
}
