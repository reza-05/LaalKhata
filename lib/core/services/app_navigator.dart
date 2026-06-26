import 'package:flutter/material.dart';

class AppNavigator {
  const AppNavigator._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static void popToRootSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.popUntil((route) => route.isFirst);
    });
  }
}
