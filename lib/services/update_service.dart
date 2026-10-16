import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';

/// Manages fast, immediate in-app updates via Google Play's official
/// Play Core In-App Updates API, with complete 10-language localizations.
class UpdateService {
  // Optional remote fallback JSON url (if needed)
  static const String updateUrl =
      'https://gist.githubusercontent.com/safikaleem/REPLACE_ME/raw/update.json';

  static const String _defaultStoreUrl =
      'https://play.google.com/store/apps/details?id=pk.sukkur.salah';

  static const String _marketUrl = 'market://details?id=pk.sukkur.salah';

  /// ValueNotifier allows widgets (like the hamburger icon and drawer) to
  /// reactively show/hide the red notification dot and red update banner.
  static final ValueNotifier<bool> hasPendingUpdateNotifier =
      ValueNotifier<bool>(false);

  static bool get hasPendingUpdate => hasPendingUpdateNotifier.value;
  static set hasPendingUpdate(bool value) =>
      hasPendingUpdateNotifier.value = value;

  static String? pendingVersion;
  static String? pendingStoreUrl;
  static AppUpdateInfo? _cachedUpdateInfo;
  static bool _hasPromptedThisSession = false;

  /// Complete localizations for all 10 supported languages
  static const Map<String, Map<String, String>> _strings = {
    'dialogTitle': {
      'english': 'Time to Update!',
      'urdu': 'ایپ اپ ڈیٹ کرنے کا وقت!',
      'sindhi': 'ايپ اپڊيٽ ڪرڻ جو وقت!',
      'arabic': 'حان وقت التحديث!',
      'bengali': 'অ্যাপ আপডেট করার সময় হয়েছে!',
      'indonesian': 'Saatnya Memperbarui!',
      'turkish': 'Güncelleme Zamanı!',
      'french': 'Mise à jour disponible !',
      'hindi': 'ऐप अपडेट करने का समय!',
      'persian': 'زمان به‌روزرسانی است!',
    },
    'dialogBody': {
      'english':
          'A new version of Sukkur Salah is available on Google Play! Please update now to get the latest timings, accurate calculations, and improvements.',
      'urdu':
          'گوگل پلے پر سکھر صلاۃ کا نیا ورژن دستیاب ہے! تازہ ترین اوقات، درست حساب اور نئی خصوصیات حاصل کرنے کے لیے برائے مہربانی ابھی اپ ڈیٹ کریں۔',
      'sindhi':
          'گوگل پلي تي سکر صلاۃ جو نئون ورجن دستياب آهي! تازين اوقاتن، صحيح حساب ۽ نئين خوبين لاءِ مهرباني ڪري هاڻي اپڊيٽ ڪريو.',
      'arabic':
          'يتوفر إصدار جديد من سكر صلاة على Google Play! يرجى التحديث الآن للحصول على أحدث المواقيت والتحسينات.',
      'bengali':
          'গুগল প্লে-তে সুক্কুর সাلاহ-এর নতুন সংস্করণ উপলব্ধ! সর্বশেষ সময়সূচী ও নতুন সুবিধা পেতে এখনই আপডেট করুন।',
      'indonesian':
          'Versi baru Sukkur Salah tersedia di Google Play! Silakan perbarui sekarang untuk mendapatkan jadwal dan fitur terbaru.',
      'turkish':
          'Google Play\'de Sukkur Salah\'ın yeni bir sürümü mevcut! En güncel vakitler ve geliştirmeler için lütfen şimdi güncelleyin.',
      'french':
          'Une nouvelle version de Sukkur Salah est disponible sur Google Play ! Veuillez mettre à jour maintenant pour profiter des derniers horaires et fonctionnalités.',
      'hindi':
          'गूगल प्ले पर सुक्कुर सलाह का नया संस्करण उपलब्ध है! नवीनतम समय और नई सुविधाओं के लिए कृपया अभी अपडेट करें।',
      'persian':
          'نسخه جدیدی از سکر صلاة در گوگل پلی در دسترس است! لطفاً برای بهره‌مندی از جدیدترین اوقات و بهبودها اکنون به‌روزرسانی کنید.',
    },
    'updateBtn': {
      'english': 'UPDATE NOW',
      'urdu': 'ابھی اپ ڈیٹ کریں',
      'sindhi': 'هاڻي اپڊيٽ ڪريو',
      'arabic': 'التحديث الآن',
      'bengali': 'এখনই আপডেট করুন',
      'indonesian': 'PERBARUI SEKARANG',
      'turkish': 'ŞİMDİ GÜNCELLE',
      'french': 'METTRE À JOUR',
      'hindi': 'अभी अपडेट करें',
      'persian': 'به‌روزرسانی هم‌اکنون',
    },
    'laterBtn': {
      'english': 'LATER',
      'urdu': 'بعد میں',
      'sindhi': 'پوءِ',
      'arabic': 'لاحقاً',
      'bengali': 'পরে করবো',
      'indonesian': 'NANTI',
      'turkish': 'SONRA',
      'french': 'PLUS TARD',
      'hindi': 'बाद में',
      'persian': 'بعداً',
    },
    'drawerBannerTitle': {
      'english': 'New Update Available!',
      'urdu': 'نیا اپ ڈیٹ دستیاب ہے!',
      'sindhi': 'نئون اپڊيٽ دستياب آهي!',
      'arabic': 'تحديث جديد متوفر!',
      'bengali': 'নতুন আপডেট উপলব্ধ!',
      'indonesian': 'Pembaruan Baru Tersedia!',
      'turkish': 'Yeni Güncelleme Mevcut!',
      'french': 'Mise à jour disponible !',
      'hindi': 'नया अपडेट उपलब्ध है!',
      'persian': 'به‌روزرسانی جدید موجود است!',
    },
    'drawerBannerSub': {
      'english': 'Tap here to update to the latest version',
      'urdu': 'تازہ ترین ورژن پر اپ ڈیٹ کرنے کے لیے یہاں ٹیپ کریں',
      'sindhi': 'تازه ترين ورجن تي اپڊيٽ ڪرڻ لاءِ هتي ٽيپ ڪريو',
      'arabic': 'اضغط هنا للتحديث إلى أحدث إصدار',
      'bengali': 'সর্বশেষ সংস্করণে আপডেট করতে এখানে ট্যাপ করুন',
      'indonesian': 'Ketuk di sini untuk memperbarui ke versi terbaru',
      'turkish': 'En son sürüme güncellemek için buraya dokunun',
      'french': 'Appuyez ici pour installer la dernière version',
      'hindi': 'नवीनतम संस्करण में अपडेट करने के लिए यहाँ टैप करें',
      'persian': 'برای به‌روزرسانی به جدیدترین نسخه اینجا را لمس کنید',
    },
    'downloadedSnack': {
      'english': 'Update downloaded! Restart the app to finish.',
      'urdu': 'اپ ڈیٹ ڈاؤن لوڈ ہو گیا۔ مکمل کرنے کے لیے ایپ دوبارہ شروع کریں۔',
      'sindhi': 'اپڊيٽ ڊائون لوڊ ٿي ويو! مڪمل ڪرڻ لاءِ ايپ ٻيهر شروع ڪريو.',
      'arabic': 'تم تنزيل التحديث! أعد تشغيل التطبيق للإنهاء.',
      'bengali': 'আপডেট ডাউনলোড হয়েছে! সম্পন্ন করতে অ্যাপ পুনরায় চালু করুন।',
      'indonesian': 'Pembaruan selesai diunduh! Mulai ulang aplikasi untuk menyelesaikan.',
      'turkish': 'Güncelleme indirildi! Tamamlamak için uygulamayı yeniden başlatın.',
      'french': 'Mise à jour téléchargée ! Redémarrez l\'application pour terminer.',
      'hindi': 'अपडेट डाउनलोड हो गया! पूरा करने के लिए ऐप को पुनः प्रारंभ करें।',
      'persian': 'به‌روزرسانی بارگیری شد! برای تکمیل، برنامه را مجدداً راه‌اندازی کنید.',
    },
    'restartBtn': {
      'english': 'RESTART',
      'urdu': 'دوبارہ شروع کریں',
      'sindhi': 'ٻيهر شروع ڪريو',
      'arabic': 'إعادة التشغيل',
      'bengali': 'পুনরায় চালু',
      'indonesian': 'MULAI ULANG',
      'turkish': 'YENİDEN BAŞLAT',
      'french': 'REDÉMARRER',
      'hindi': 'पुनः प्रारंभ',
      'persian': 'راه‌اندازی مجدد',
    },
  };

  /// Returns translated string for key in specified language.
  static String tr(String key, String language) {
    return _strings[key]?[language] ?? _strings[key]?['english'] ?? '';
  }

  /// Checks for update via Google Play In-App Updates (Android) and fallback JSON.
  /// Runs automatically on app launch.
  static Future<void> checkForUpdate(BuildContext context) async {
    if (kIsWeb) return;

    try {
      // 1. Check official Google Play In-App Updates API (Immediate, no web scraping delay)
      if (Platform.isAndroid) {
        try {
          final info = await InAppUpdate.checkForUpdate();
          _cachedUpdateInfo = info;

          if (info.updateAvailability == UpdateAvailability.updateAvailable) {
            hasPendingUpdate = true;
            pendingVersion = info.availableVersionCode != null
                ? 'Build ${info.availableVersionCode}'
                : null;
            pendingStoreUrl = _defaultStoreUrl;

            // Prompt once per launch session automatically
            if (!_hasPromptedThisSession && context.mounted) {
              _hasPromptedThisSession = true;
              await _showUpdateDialog(context);
            }
            return;
          }
        } catch (playError) {
          debugPrint('Google Play InAppUpdate check notice: $playError');
        }
      }

      // 2. Check fallback remote JSON if hosted
      final data = await _fetchUpdateInfo();
      if (data != null) {
        final latest = (data['latestVersion'] as String?)?.trim();
        if (latest != null && latest.isNotEmpty) {
          final info = await PackageInfo.fromPlatform();
          if (isNewerVersion(latest, info.version)) {
            final hosted = (data['playStoreUrl'] as String?)?.trim();
            final storeUrl =
                (hosted == null || hosted.isEmpty) ? _defaultStoreUrl : hosted;

            hasPendingUpdate = true;
            pendingVersion = latest;
            pendingStoreUrl = storeUrl;

            if (!_hasPromptedThisSession && context.mounted) {
              _hasPromptedThisSession = true;
              await _showUpdateDialog(context);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('UpdateService check error: $e');
    }
  }

  /// Opens the update dialog if an update is pending, or starts check.
  static Future<void> openPendingUpdateDialog(BuildContext context) async {
    if (context.mounted) {
      await _showUpdateDialog(context);
    }
  }

  /// Called when user taps "Check for Update" in the drawer.
  static Future<void> manualCheckForUpdate(BuildContext context) async {
    if (hasPendingUpdate) {
      await _showUpdateDialog(context);
      return;
    }

    if (Platform.isAndroid && !kIsWeb) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        _cachedUpdateInfo = info;
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          hasPendingUpdate = true;
          pendingVersion = info.availableVersionCode != null
              ? 'Build ${info.availableVersionCode}'
              : null;
          if (context.mounted) {
            await _showUpdateDialog(context);
          }
          return;
        }
      } catch (e) {
        debugPrint('Manual InAppUpdate check failed: $e');
      }
    }

    // Direct user to Google Play Store page so they can check or update directly
    await openStore();
  }

  /// Displays the localized update popup dialog with "UPDATE NOW" and "LATER".
  static Future<void> _showUpdateDialog(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.language;
    final isUrdu = settings.isUrdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final font = AppTheme.getFontForLanguage(context, lang);

    final title = tr('dialogTitle', lang);
    final body = tr('dialogBody', lang);
    final laterText = tr('laterBtn', lang);
    final updateText = tr('updateBtn', lang);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            // If dismissed with back button, user chose later: keep red dot active
            hasPendingUpdate = true;
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Color(0xFFE53935),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isUrdu ? 19 : 17,
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
                    fontSize: isUrdu ? 15 : 13.5,
                    fontFamily: font,
                    height: isUrdu ? 1.6 : 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (pendingVersion != null && pendingVersion!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pendingVersion!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              // LATER BUTTON: Dismisses dialog, but keeps red dot and red banner active
              TextButton(
                onPressed: () {
                  hasPendingUpdate = true; // Retain red dot and banner
                  Navigator.pop(dialogContext);
                },
                child: Text(
                  laterText,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: isUrdu ? 15 : 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),

              // UPDATE NOW BUTTON: Triggers Play Core update or opens Play Store
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _triggerUpdate(context, lang);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      updateText,
                      style: TextStyle(
                        fontFamily: font,
                        fontWeight: FontWeight.bold,
                        fontSize: isUrdu ? 15 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Initiates the Google Play In-App Update flow or opens the Store.
  static Future<void> _triggerUpdate(
      BuildContext context, String language) async {
    if (Platform.isAndroid && !kIsWeb && _cachedUpdateInfo != null) {
      try {
        final info = _cachedUpdateInfo!;
        if (info.flexibleUpdateAllowed) {
          // Flexible update downloads in background
          await InAppUpdate.startFlexibleUpdate();

          // When download completes, show restart notification
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tr('downloadedSnack', language)),
                duration: const Duration(days: 1), // Remains until tapped
                action: SnackBarAction(
                  label: tr('restartBtn', language),
                  textColor: Colors.amberAccent,
                  onPressed: () async {
                    await InAppUpdate.completeFlexibleUpdate();
                  },
                ),
              ),
            );
          }
          return;
        } else if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          return;
        }
      } catch (e) {
        debugPrint('Play Core in_app_update failed, falling back to store: $e');
      }
    }

    // Fallback: Open Google Play Store page directly
    await openStore();
  }

  /// Opens the store listing on Android directly using market:// or https://.
  static Future<void> openStore([String? url]) async {
    final targetUrl =
        (url != null && url.isNotEmpty) ? url : _marketUrl;
    try {
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      final fallbackUri = Uri.parse(_defaultStoreUrl);
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not open store: $e');
    }
  }

  /// True when [remote] is a higher version than [installed].
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
}
