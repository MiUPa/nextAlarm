import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to check for Google Play updates and prompt the user to visit
/// the Play Store when a new version is available.
///
/// Uses [InAppUpdate.checkForUpdate] to detect updates, then directs the
/// user to the Play Store via [url_launcher]. Does NOT download or install
/// anything within the app.
class AppUpdateService {
  AppUpdateService._();

  static const _playStoreUrl =
      'market://details?id=com.nextalarm.next_alarm';
  static const _playStoreWebUrl =
      'https://play.google.com/store/apps/details?id=com.nextalarm.next_alarm';

  /// Ensures the check runs at most once per app session.
  static bool _hasChecked = false;

  /// Check whether a newer version is available on Google Play.
  /// If so, show a SnackBar that links to the Play Store.
  ///
  /// Only runs on Android, and only once per app session.
  /// Silently returns on non-Android platforms.
  static Future<void> checkForUpdate(BuildContext context) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability ==
              UpdateAvailability.updateAvailable &&
          context.mounted) {
        _showUpdateAvailableSnackBar(context);
      }
    } catch (e) {
      // Non-critical — e.g. not installed via Play Store, emulator, etc.
      debugPrint('In-app update check failed: $e');
    }
  }

  /// Show a SnackBar telling the user a new version is available.
  /// Tapping "Update" opens the Play Store listing.
  static void _showUpdateAvailableSnackBar(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final message = lang == 'ja'
        ? '新しいバージョンが利用可能です'
        : 'A new version is available';
    final actionLabel = lang == 'ja' ? '更新' : 'Update';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: actionLabel,
          onPressed: () => _openPlayStore(),
        ),
      ),
    );
  }

  /// Open the Play Store listing for this app.
  /// Falls back to the web URL if the market:// scheme is unavailable.
  static Future<void> _openPlayStore() async {
    final marketUri = Uri.parse(_playStoreUrl);
    try {
      final launched = await launchUrl(
        marketUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(
          Uri.parse(_playStoreWebUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      // Last resort — try the web URL
      try {
        await launchUrl(
          Uri.parse(_playStoreWebUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Could not open Play Store: $e');
      }
    }
  }
}
