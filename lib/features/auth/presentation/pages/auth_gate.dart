import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/password_recovery_signal.dart';
import '../../../../core/services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import 'auth_page.dart';
import 'phase_one_home_page.dart';
import 'pin_setup_page.dart';
import 'pin_unlock_page.dart';
import 'update_password_page.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  bool _localUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PasswordRecoverySignal.authEventVersion.addListener(_handleAuthEvent);
  }

  @override
  void dispose() {
    PasswordRecoverySignal.authEventVersion.removeListener(_handleAuthEvent);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (_localUnlocked) {
        setState(() {
          _localUnlocked = false;
        });
      }
    }
  }

  void _handleAuthEvent() {
    ref.read(authControllerProvider.notifier).loadSession();
    if (PasswordRecoverySignal.isActive.value) {
      _localUnlocked = false;
    }
    if (mounted) setState(() {});
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

    return ValueListenableBuilder<bool>(
      valueListenable: PasswordRecoverySignal.isActive,
      builder: (context, isPasswordRecovery, _) {
        if (isPasswordRecovery) {
          return const UpdatePasswordPage();
        }

        return _buildAuthContent(authState);
      },
    );
  }

  Widget _buildAuthContent(AuthState authState) {
    if (authState.status == AuthStatus.authenticated) {
      return FutureBuilder<bool>(
        future: ref.read(localPinServiceProvider).isPinSet(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final hasPin = snapshot.data ?? false;
          if (!hasPin) {
            return PinSetupPage(
              onCompleted: () {
                setState(() {
                  _localUnlocked = true;
                });
              },
            );
          }

          if (!_localUnlocked) {
            return PinUnlockPage(
              onUnlocked: () {
                setState(() {
                  _localUnlocked = true;
                });
              },
            );
          }

          return const PhaseOneHomePage();
        },
      );
    }

    if (_localUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _localUnlocked = false;
          });
        }
      });
    }

    return AuthPage(setupNotice: PasswordRecoverySignal.authNotice.value);
  }
}
