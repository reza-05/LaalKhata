import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'app_navigator.dart';
import 'password_recovery_signal.dart';

class SupabaseService {
  static bool get isConfigured => AppConfig.hasSupabaseConfig;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!isConfigured) return;

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );

    client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        PasswordRecoverySignal.activate();
        AppNavigator.popToRootSoon();
        return;
      }

      if (data.event == AuthChangeEvent.initialSession ||
          data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.userUpdated) {
        PasswordRecoverySignal.authEventVersion.value++;
      }

      if (data.event == AuthChangeEvent.signedIn) {
        final confirmedFromEmail =
            PasswordRecoverySignal.confirmEmailIfCallbackPending();
        if (confirmedFromEmail) {
          unawaited(client.auth.signOut());
          AppNavigator.popToRootSoon();
        }
        return;
      }

      if (data.event == AuthChangeEvent.signedOut) {
        PasswordRecoverySignal.authEventVersion.value++;
      }
    });
  }
}
