import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service to handle Google Play in-app updates (flexible update flow).
///
/// Flexible updates allow the user to continue using the app while the
/// update downloads in the background. Once downloaded, a SnackBar prompts
/// the user to restart and apply the update.
class AppUpdateService {
  AppUpdateService._();

  /// Check for an available update and start a flexible update if one exists.
  ///
  /// Should be called once during app startup (e.g., from HomeScreen.initState).
  /// Only runs on Android — silently returns on Web and other platforms.
  static Future<void> checkForUpdate(BuildContext context) async {
    // In-app updates are only available on Android via Google Play.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        // Start the flexible update flow (downloads in background).
        await InAppUpdate.startFlexibleUpdate();

        // When the download completes, show a SnackBar to prompt restart.
        if (context.mounted) {
          _showUpdateReadySnackBar(context);
        }
      }
    } catch (e) {
      // Failures here are non-critical (e.g., not installed via Play Store,
      // emulator, network issues). Log and move on.
      debugPrint('In-app update check failed: $e');
    }
  }

  /// Show a SnackBar informing the user that an update has been downloaded
  /// and is ready to install.
  static void _showUpdateReadySnackBar(BuildContext context) {
    final l10n = Localizations.localeOf(context).languageCode;
    final message = l10n == 'ja'
        ? 'アップデートの準備ができました'
        : 'Update ready to install';
    final actionLabel = l10n == 'ja' ? '再起動' : 'Restart';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: actionLabel,
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }
}
