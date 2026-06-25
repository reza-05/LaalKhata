import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_validator.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository();

  SupabaseClient get _client => SupabaseService.client;

  @override
  User? get currentUser {
    if (!SupabaseService.isConfigured) return null;
    return _client.auth.currentUser;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String department,
    String? studentId,
    String? batch,
  }) async {
    _ensureConfigured();
    _validateEmail(email);

    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        'display_name': displayName.trim(),
        'role': role,
        'department': department.trim(),
        'student_id': studentId?.trim(),
        'batch': batch?.trim(),
      },
    );

    final user = response.user;
    if (user == null) {
      throw const AppFailure('Check your inbox to confirm your account.');
    }
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    _validateEmail(email);

    await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  @override
  Future<void> sendPasswordReset({
    required String email,
  }) async {
    _ensureConfigured();
    _validateEmail(email);

    await _client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
    );
  }

  @override
  Future<void> signOut() async {
    _ensureConfigured();
    await _client.auth.signOut();
  }

  void _ensureConfigured() {
    if (!SupabaseService.isConfigured) {
      throw const AppFailure(
        'Supabase is not configured yet. Add SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }

  void _validateEmail(String email) {
    final validationMessage = AuthValidator.validateIutEmail(email);
    if (validationMessage != null) {
      throw AppFailure(validationMessage);
    }
  }
}
