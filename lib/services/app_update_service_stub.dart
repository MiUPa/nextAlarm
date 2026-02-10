import 'package:flutter/material.dart';

/// No-op stub for platforms where in-app updates are not supported (Web).
class AppUpdateService {
  AppUpdateService._();

  static Future<void> checkForUpdate(BuildContext context) async {
    // In-app update is not available on this platform.
  }
}
