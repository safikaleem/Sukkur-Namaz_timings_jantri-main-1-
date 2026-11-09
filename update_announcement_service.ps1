$path = "lib\services\announcement_service.dart"
$lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)

# 1. Insert import after line 12
$list = [System.Collections.Generic.List[string]]$lines
$list.Insert(13, "import 'package:shared_preferences/shared_preferences.dart';")

# In list, line 28 (which was 27 before insert) is 'static bool _isDialogOpen = false;'
# Line 89 (which was 88 before insert) is '  }'
$startIndex = 28
$endIndex = 89

Write-Host "Replacing lines $startIndex to $endIndex"

$newCode = @'
  static const String _cachedAnnouncementKey = 'cached_remote_announcement_json';
  static dynamic _cachedAnnouncementData;
  static bool _hasLoadedLocalCache = false;
  static bool _isDialogOpen = false;
  static BuildContext? _activeDialogContext;
  static String? _activeAnnouncementId;

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

  /// Loads cached announcement JSON from SharedPreferences at startup for 0ms instant display.
  static Future<void> loadLocalCache() async {
    if (_hasLoadedLocalCache) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRaw = prefs.getString(_cachedAnnouncementKey);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        _cachedAnnouncementData = jsonDecode(cachedRaw);
      }
      _hasLoadedLocalCache = true;
    } catch (e) {
      debugPrint('Error loading cached announcement: $e');
    }
  }

  /// Checks if there is an announcement and shows it in a popup.
  /// Shows cached announcement INSTANTLY (0 ms latency), while silently syncing in the background.
  static Future<void> checkForAnnouncement(BuildContext context) async {
    try {
      if (!_hasLoadedLocalCache) {
        await loadLocalCache();
      }

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final String userCity = (settings.locationMode == LocationMode.sukkur ||
              !settings.usesCalculatedTimings ||
              settings.cityName == null ||
              settings.cityName!.trim().isEmpty ||
              SukkurLocation.matchesName(settings.cityName))
          ? 'Sukkur'
          : settings.cityName!.trim();

      String? currentVersion;
      try {
        final pkg = await PackageInfo.fromPlatform();
        currentVersion = pkg.version;
      } catch (e) {
        debugPrint('Could not retrieve package version for announcement check: $e');
      }

      // ── STEP 1: INSTANT LOCAL DISPLAY (0 ms latency) ─────────────────────────
      if (_cachedAnnouncementData != null) {
        final cachedMatch = selectAnnouncementForUser(
          _cachedAnnouncementData,
          userCity,
          currentVersion: currentVersion,
        );

        if (cachedMatch != null) {
          final bool enabled = cachedMatch['enabled'] as bool? ?? false;
          final String? id = cachedMatch['id'] as String?;
          if (enabled && id != null && id.isNotEmpty && !_isDialogOpen) {
            // Precache image for instant zero-flicker render
            final String? imgUrl = cachedMatch['imageUrl'] as String?;
            if (imgUrl != null && imgUrl.isNotEmpty && context.mounted) {
              precacheImage(
                CachedNetworkImageProvider(
                  imgUrl,
                  cacheKey: '${imgUrl}_$id',
                  headers: const {
                    'User-Agent':
                        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                    'Accept': 'image/jpeg,image/png,image/*,*/*;q=0.8',
                  },
                ),
                context,
              );
            }

            if (context.mounted && !_isDialogOpen) {
              _activeAnnouncementId = id;
              _showAnnouncementDialog(context, id, cachedMatch, isLocal: false);
            }
          }
        }
      }

      // ── STEP 2: SILENT BACKGROUND SYNC (Non-blocking) ───────────────────────
      _syncRemoteAnnouncement(context, userCity, currentVersion);
    } catch (e) {
      debugPrint('Failed in checkForAnnouncement: $e');
    }
  }

  /// Silently checks remote Firestore / Gist in the background without delaying UI.
  static void _syncRemoteAnnouncement(
    BuildContext context,
    String userCity,
    String? currentVersion,
  ) async {
    try {
      final dynamic fetchedData = await _fetchAnnouncement();
      if (fetchedData == null) return;

      // Update local storage for future instant 0ms launches
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedAnnouncementKey, jsonEncode(fetchedData));
        _cachedAnnouncementData = fetchedData;
      } catch (e) {
        debugPrint('Could not save announcement cache: $e');
      }

      final freshMatch = selectAnnouncementForUser(
        fetchedData,
        userCity,
        currentVersion: currentVersion,
      );

      final bool enabled = freshMatch != null && (freshMatch['enabled'] as bool? ?? false);
      final String? freshId = freshMatch != null ? freshMatch['id'] as String? : null;

      // If remote announcement was disabled, dismiss dialog
      if (!enabled || freshId == null || freshId.isEmpty) {
        if (_isDialogOpen && _activeDialogContext != null && _activeDialogContext!.mounted) {
          Navigator.of(_activeDialogContext!).pop();
          _isDialogOpen = false;
        }
        return;
      }

      // Precache fresh image
      final String? freshImgUrl = freshMatch['imageUrl'] as String?;
      if (freshImgUrl != null && freshImgUrl.isNotEmpty && context.mounted) {
        precacheImage(
          CachedNetworkImageProvider(
            freshImgUrl,
            cacheKey: '${freshImgUrl}_$freshId',
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
              'Accept': 'image/jpeg,image/png,image/*,*/*;q=0.8',
            },
          ),
          context,
        );
      }

      // If dialog is not open yet (e.g. cold start with empty cache), show it now!
      if (!_isDialogOpen && context.mounted) {
        _activeAnnouncementId = freshId;
        await _showAnnouncementDialog(context, freshId, freshMatch, isLocal: false);
      } else if (_isDialogOpen && _activeAnnouncementId != freshId && context.mounted) {
        // If announcement changed while open, refresh to the new one
        if (_activeDialogContext != null && _activeDialogContext!.mounted) {
          Navigator.of(_activeDialogContext!).pop();
        }
        _activeAnnouncementId = freshId;
        await _showAnnouncementDialog(context, freshId, freshMatch, isLocal: false);
      }
    } catch (e) {
      debugPrint('Background announcement sync error: $e');
    }
  }
'@

$newLines = $newCode.Split("`n") | ForEach-Object { $_.TrimEnd("`r") }
$list.RemoveRange($startIndex, $endIndex - $startIndex + 1)
$list.InsertRange($startIndex, [string[]]$newLines)

# 3. Track activeDialogContext in _showAnnouncementDialog
for ($i = 0; $i -lt $list.Count; $i++) {
    if ($list[$i] -match "int reloadCount = 0;") {
        $list.Insert($i, "          _activeDialogContext = dialogContext;")
        break
    }
}

# 4. Clear in finally
for ($i = $list.Count - 1; $i -ge 0; $i--) {
    if ($list[$i] -match "_isDialogOpen = false;") {
        $list.Insert($i + 1, "      _activeDialogContext = null;")
        $list.Insert($i + 2, "      _activeAnnouncementId = null;")
        break
    }
}

[System.IO.File]::WriteAllLines($path, $list.ToArray(), [System.Text.Encoding]::UTF8)
Write-Host "announcement_service.dart written successfully!"
