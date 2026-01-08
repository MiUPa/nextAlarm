import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class NotificationServiceWeb {
  static Future<bool> requestPermission() async {
    if (!kIsWeb) return false;

    try {
      final permission = await html.Notification.requestPermission();
      debugPrint('Notification permission: $permission');
      return permission == 'granted';
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  static Future<void> showNotification(String title, String body) async {
    if (!kIsWeb) return;

    try {
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body);
      }
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
}
