import 'package:flutter/material.dart';

import 'core/services/app_navigator.dart';
import 'core/services/password_recovery_signal.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/auth_gate.dart';

class LaalKhataApp extends StatelessWidget {
  const LaalKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaalKhata',
      navigatorKey: AppNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (name.startsWith('/?code=') || name.contains('code=')) {
          PasswordRecoverySignal.markEmailCallbackPending();
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AuthGate(),
        );
      },
    );
  }
}
