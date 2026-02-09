import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewPromptService {
  static const String _keyFirstLaunchDate = 'review_first_launch_date';
  static const String _keyNextPromptDate = 'review_next_prompt_date';
  static const String _keyDismissedUntil = 'review_dismissed_until';

  static const int _initialDelayDays = 3;
  static const int _regularIntervalDays = 7;
  static const int _dismissedIntervalDays = 90;

  /// Check if review prompt should be shown and return true if so.
  static Future<bool> shouldShowPrompt() async {
    if (kIsWeb) return false;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Record first launch date if not set
    final firstLaunchStr = prefs.getString(_keyFirstLaunchDate);
    if (firstLaunchStr == null) {
      await prefs.setString(_keyFirstLaunchDate, now.toIso8601String());
      // Set the first prompt date to 3 days from now
      final nextPrompt = now.add(const Duration(days: _initialDelayDays));
      await prefs.setString(_keyNextPromptDate, nextPrompt.toIso8601String());
      return false;
    }

    // Check if dismissed (user selected "already reviewed" or "don't show again")
    final dismissedUntilStr = prefs.getString(_keyDismissedUntil);
    if (dismissedUntilStr != null) {
      final dismissedUntil = DateTime.parse(dismissedUntilStr);
      if (now.isBefore(dismissedUntil)) {
        return false;
      }
      // Dismissed period expired, clear it and allow prompt
      await prefs.remove(_keyDismissedUntil);
    }

    // Check next prompt date
    final nextPromptStr = prefs.getString(_keyNextPromptDate);
    if (nextPromptStr == null) {
      // Should not happen, but set it now
      final nextPrompt = now.add(const Duration(days: _initialDelayDays));
      await prefs.setString(_keyNextPromptDate, nextPrompt.toIso8601String());
      return false;
    }

    final nextPromptDate = DateTime.parse(nextPromptStr);
    return now.isAfter(nextPromptDate);
  }

  /// User chose "Later" - schedule next prompt in 7 days.
  static Future<void> remindLater() async {
    final prefs = await SharedPreferences.getInstance();
    final nextPrompt = DateTime.now().add(const Duration(days: _regularIntervalDays));
    await prefs.setString(_keyNextPromptDate, nextPrompt.toIso8601String());
  }

  /// User chose "Don't show again" - suppress for 90 days.
  static Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedUntil = DateTime.now().add(const Duration(days: _dismissedIntervalDays));
    await prefs.setString(_keyDismissedUntil, dismissedUntil.toIso8601String());
  }

  /// User chose "Rate now" - open store listing and suppress for 90 days.
  static Future<void> rateNow() async {
    final inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      await inAppReview.openStoreListing(
        appStoreId: '', // iOS App Store ID (not needed for Android)
      );
    }

    // Suppress for 90 days after rating
    await dismiss();
  }
}
