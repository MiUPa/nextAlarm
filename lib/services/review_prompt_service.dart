import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewPromptService {
  static const String _keyFirstLaunchDate = 'review_first_launch_date';
  static const String _keyNextPromptDate = 'review_next_prompt_date';
  static const String _keyDismissedUntil = 'review_dismissed_until';
  static const String _keyRated = 'review_rated';
  static const String _keyLaterCount = 'review_later_count';

  static const int _initialDelayDays = 3;
  static const int _dismissedIntervalDays = 90;

  /// Progressive intervals for "Later": 7 → 14 → 30 → 60 days
  static const List<int> _laterIntervals = [7, 14, 30, 60];

  /// Check if review prompt should be shown and return true if so.
  static Future<bool> shouldShowPrompt() async {
    if (kIsWeb) return false;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Never show again if user already rated
    if (prefs.getBool(_keyRated) == true) {
      return false;
    }

    // Record first launch date if not set
    final firstLaunchStr = prefs.getString(_keyFirstLaunchDate);
    if (firstLaunchStr == null) {
      await prefs.setString(_keyFirstLaunchDate, now.toIso8601String());
      final nextPrompt = now.add(const Duration(days: _initialDelayDays));
      await prefs.setString(_keyNextPromptDate, nextPrompt.toIso8601String());
      return false;
    }

    // Check if dismissed (user selected "don't show again")
    final dismissedUntilStr = prefs.getString(_keyDismissedUntil);
    if (dismissedUntilStr != null) {
      final dismissedUntil = DateTime.parse(dismissedUntilStr);
      if (now.isBefore(dismissedUntil)) {
        return false;
      }
      await prefs.remove(_keyDismissedUntil);
    }

    // Check next prompt date
    final nextPromptStr = prefs.getString(_keyNextPromptDate);
    if (nextPromptStr == null) {
      final nextPrompt = now.add(const Duration(days: _initialDelayDays));
      await prefs.setString(_keyNextPromptDate, nextPrompt.toIso8601String());
      return false;
    }

    final nextPromptDate = DateTime.parse(nextPromptStr);
    return now.isAfter(nextPromptDate);
  }

  /// User chose "Later" - progressive interval (7 → 14 → 30 → 60 days).
  static Future<void> remindLater() async {
    final prefs = await SharedPreferences.getInstance();
    final laterCount = prefs.getInt(_keyLaterCount) ?? 0;

    final intervalIndex = laterCount.clamp(0, _laterIntervals.length - 1);
    final days = _laterIntervals[intervalIndex];

    final nextPrompt = DateTime.now().add(Duration(days: days));
    await prefs.setString(_keyNextPromptDate, nextPrompt.toIso8601String());
    await prefs.setInt(_keyLaterCount, laterCount + 1);
  }

  /// User chose "Don't show again" - suppress for 90 days.
  static Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedUntil = DateTime.now().add(const Duration(days: _dismissedIntervalDays));
    await prefs.setString(_keyDismissedUntil, dismissedUntil.toIso8601String());
  }

  /// User chose "Rate now" - open store listing and never show again.
  static Future<void> rateNow() async {
    final inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      await inAppReview.openStoreListing(
        appStoreId: '', // iOS App Store ID (not needed for Android)
      );
    }

    // Mark as rated - never show again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRated, true);
  }
}
