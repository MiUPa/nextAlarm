import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service to check for Google Play updates and prompt the user to visit
/// the Play Store when a new version is available.
///
/// Does NOT download in the background — simply notifies the user and
/// opens the store page if they choose to update.
class AppUpdateService {
  AppUpdateService._();

  /// Check whether a newer version is available on Google Play.
  /// If so, show a SnackBar that links to the Play Store.
  ///
  /// Only runs on Android. Silently returns on Web / iOS / desktop.
  static Future<void> checkForUpdate(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

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
          onPressed: () {
            // Opens the Play Store listing via the in_app_update plugin.
            // This is an immediate update intent that brings up the store.
            InAppUpdate.performImmediateUpdate().catchError((_) {
              // User cancelled or error — ignore.
            });
          },
        ),
      ),
    );
  }
}
