import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<bool> requestPermission() async {
    if (!kIsWeb) return false;

    // Web notification API will be called via JS interop in the web-specific implementation
    debugPrint('Notification permission requested (Web)');
    return true;
  }

  static Future<void> showNotification(String title, String body) async {
    if (!kIsWeb) return;

    debugPrint('Notification shown (Web): $title - $body');
  }
}
