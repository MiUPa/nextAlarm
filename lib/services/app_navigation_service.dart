import 'package:flutter/widgets.dart';

class AppNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void popToRoot() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.popUntil((route) => route.isFirst);
  }
}
