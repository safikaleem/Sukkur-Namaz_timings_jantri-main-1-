import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Production-hardened URL launcher helper.
///
/// Prevents Android ANRs ("Input dispatching timed out / Slow Binder call") by:
/// 1. Debouncing user taps so rapid consecutive taps don't flood Android's Binder IPC.
/// 2. Yielding execution briefly so Android's InputDispatcher finishes the MotionEvent cycle.
/// 3. Avoiding redundant `canLaunchUrl` Binder IPC queries to PackageManager.
/// 4. Enforcing strict timeouts so a lagging external app never freezes the event loop.
class UrlHelper {
  UrlHelper._();

  static DateTime _lastLaunchTime = DateTime.fromMillisecondsSinceEpoch(0);
  static bool _isLaunching = false;

  /// Safely launches [uri] with anti-ANR guards and fallback handling.
  static Future<bool> safeLaunch(
    Uri uri, {
    LaunchMode mode = LaunchMode.externalApplication,
    bool fallbackToDefault = true,
  }) async {
    final now = DateTime.now();
    if (_isLaunching || now.difference(_lastLaunchTime).inMilliseconds < 1000) {
      debugPrint('UrlHelper: Ignored rapid duplicate launch request for $uri');
      return false;
    }

    _isLaunching = true;
    _lastLaunchTime = now;

    try {
      // Yield briefly to let Android's InputDispatcher complete the touch event dispatching
      // cycle before triggering a heavy system Binder IPC call.
      await Future<void>.delayed(const Duration(milliseconds: 64));

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: mode).timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            debugPrint('UrlHelper: launchUrl timed out for $uri with mode $mode');
            return false;
          },
        );
      } catch (e) {
        debugPrint('UrlHelper: Primary launch failed: $e');
        launched = false;
      }

      if (!launched && fallbackToDefault && mode != LaunchMode.platformDefault) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault).timeout(
            const Duration(seconds: 4),
            onTimeout: () => false,
          );
        } catch (e) {
          debugPrint('UrlHelper: Fallback launch failed: $e');
          launched = false;
        }
      }

      return launched;
    } finally {
      // Brief cooldown before allowing another URL launch
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        _isLaunching = false;
      });
    }
  }

  /// Safely launches an email client without redundant PackageManager IPC calls.
  static Future<bool> safeLaunchEmail({
    required String email,
    String? subject,
    String? body,
  }) async {
    final queryParameters = <String, String>{};
    if (subject != null && subject.isNotEmpty) {
      queryParameters['subject'] = subject;
    }
    if (body != null && body.isNotEmpty) {
      queryParameters['body'] = body;
    }

    // Standard mailto URI
    final mailtoUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    return safeLaunch(mailtoUri, mode: LaunchMode.externalApplication);
  }

  /// Safely opens the Google Play Store or web fallback.
  static Future<bool> safeLaunchPlayStore(
    String appId, {
    String? webFallbackUrl,
  }) async {
    final marketUri = Uri.parse('market://details?id=$appId');
    final webUri = Uri.parse(
      webFallbackUrl ?? 'https://play.google.com/store/apps/details?id=$appId',
    );

    // Try market:// first, if it fails, launch web URL
    final ok = await safeLaunch(marketUri, mode: LaunchMode.externalApplication, fallbackToDefault: false);
    if (!ok) {
      return safeLaunch(webUri, mode: LaunchMode.externalApplication);
    }
    return true;
  }

  /// Safely opens WhatsApp chat with [phoneNumber] and pre-filled [message].
  /// Sanitizes phone numbers by stripping non-digit characters and leading 00.
  static Future<bool> safeLaunchWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('00')) {
      cleanNumber = cleanNumber.substring(2);
    }

    final queryParameters = <String, String>{};
    if (message != null && message.isNotEmpty) {
      queryParameters['text'] = message;
    }

    // Standard wa.me universal link (works across Android, iOS, and Web)
    final waUri = Uri.https(
      'wa.me',
      '/$cleanNumber',
      queryParameters.isEmpty ? null : queryParameters,
    );

    bool launched = await safeLaunch(waUri, mode: LaunchMode.externalApplication);

    // Fallback to whatsapp:// intent scheme if wa.me wasn't handled
    if (!launched) {
      final nativeUri = Uri.parse(
        'whatsapp://send?phone=$cleanNumber${message != null ? '&text=${Uri.encodeComponent(message)}' : ''}',
      );
      launched = await safeLaunch(nativeUri, mode: LaunchMode.externalApplication);
    }

    return launched;
  }
}

