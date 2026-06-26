import 'package:flutter/foundation.dart';

class PasswordRecoverySignal {
  const PasswordRecoverySignal._();

  static final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
  static final ValueNotifier<int> authEventVersion = ValueNotifier<int>(0);
  static final ValueNotifier<String?> authNotice = ValueNotifier<String?>(null);

  static bool _emailCallbackPending = false;

  static void activate() {
    _emailCallbackPending = false;
    authNotice.value = null;
    isActive.value = true;
    authEventVersion.value++;
  }

  static void clear() {
    isActive.value = false;
    authEventVersion.value++;
  }

  static void markEmailCallbackPending() {
    _emailCallbackPending = true;
  }

  static bool confirmEmailIfCallbackPending() {
    if (!_emailCallbackPending || isActive.value) return false;
    _emailCallbackPending = false;
    authNotice.value = 'Email confirmed successfully. You can log in now.';
    authEventVersion.value++;
    return true;
  }

  static void showAuthNotice(String message) {
    authNotice.value = message;
    authEventVersion.value++;
  }

  static void clearAuthNotice() {
    authNotice.value = null;
    authEventVersion.value++;
  }
}
