import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import 'auth_page.dart';
import 'biometric_unlock_page.dart';
import 'phase_one_home_page.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  bool _biometricUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (_biometricUnlocked) {
        setState(() {
          _biometricUnlocked = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (!SupabaseService.isConfigured) {
      return const AuthPage(
        setupNotice:
            'Supabase keys are missing. Add --dart-define values to enable sign in.',
      );
    }

    if (authState.status == AuthStatus.authenticated) {
      return FutureBuilder<bool>(
        future: ref
            .read(biometricAuthServiceProvider)
            .isFingerprintEnabled(),
        builder: (context, snapshot) {
          final enabled = snapshot.data ?? false;
          if (enabled && !_biometricUnlocked) {
            return BiometricUnlockPage(
              onUnlocked: () {
                setState(() {
                  _biometricUnlocked = true;
                });
              },
            );
          }

          return const PhaseOneHomePage();
        },
      );
    }

    return const AuthPage();
  }
}
