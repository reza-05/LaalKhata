import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import 'auth_page.dart';
import 'phase_one_home_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (!SupabaseService.isConfigured) {
      return const AuthPage(
        setupNotice:
            'Supabase keys are missing. Add --dart-define values to enable sign in.',
      );
    }

    if (authState.status == AuthStatus.authenticated) {
      return const PhaseOneHomePage();
    }

    return const AuthPage();
  }
}
