import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/services/biometric_auth_service.dart';
import '../../../../core/services/cached_auth_user_service.dart';
import '../../../../core/services/local_pin_service.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const SupabaseAuthRepository();
});

final cachedAuthUserServiceProvider = Provider<CachedAuthUserService>((ref) {
  return CachedAuthUserService();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(cachedAuthUserServiceProvider),
  );
});

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

final localPinServiceProvider = Provider<LocalPinService>((ref) {
  return LocalPinService();
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._cachedAuthUserService)
      : super(const AuthState.idle());

  final AuthRepository _repository;
  final CachedAuthUserService _cachedAuthUserService;

  Future<void> loadSession() async {
    final user = _repository.currentUser;
    if (user != null) {
      await _cachedAuthUserService.writeUser(user);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
      return;
    }

    final cachedUser = await _cachedAuthUserService.readUser();
    state = AuthState(
      status: cachedUser == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated,
      user: cachedUser,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String department,
    String? studentId,
    String? batch,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    try {
      await _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        department: department,
        studentId: studentId,
        batch: batch,
      );
      await loadSession();
      if (state.status == AuthStatus.unauthenticated) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          message: 'Account created. Confirm your email before signing in.',
        );
      }
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        message: _friendlyError(error),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    try {
      await _repository.signIn(email: email, password: password);
      await loadSession();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Password reset request failed: $error');
      }
      state = AuthState(
        status: AuthStatus.error,
        message: _friendlyPasswordResetError(error),
      );
    }
  }

  Future<void> sendPasswordReset({
    required String email,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    try {
      await _repository.sendPasswordReset(email: email);
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        message: 'Password recovery link sent. Check your IUT email.',
      );
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        message: _friendlyError(error),
      );
    }
  }

  Future<void> updatePassword({
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    try {
      await _repository.updatePassword(password: password);
      await loadSession();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        message: 'Password updated successfully.',
      );
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        user: state.user,
        message: _friendlyError(error),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    try {
      await _repository.signOut();
      await _cachedAuthUserService.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        user: state.user,
        message: _friendlyError(error),
      );
    }
  }

  String _friendlyError(Object error) {
    if (error is AppFailure) return error.message;

    final raw = error.toString().replaceFirst('Exception: ', '');
    final normalized = raw.toLowerCase();

    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid_credentials') ||
        normalized.contains('user not found')) {
      return 'No matching account found. Please check your password or create an account.';
    }

    if (normalized.contains('email not confirmed')) {
      return 'Please confirm your IUT email before logging in.';
    }

    if (normalized.contains('session') ||
        normalized.contains('expired') ||
        normalized.contains('not found')) {
      return 'This recovery session is no longer valid. Please request a new password reset link.';
    }

    if (normalized.contains('already registered') ||
        normalized.contains('user already registered')) {
      return 'An account already exists with this IUT email. Please log in instead.';
    }

    return 'Something went wrong. Please try again.';
  }

  String _friendlyPasswordResetError(Object error) {
    if (error is AppFailure) return error.message;

    final raw = error.toString().replaceFirst('Exception: ', '');
    final normalized = raw.toLowerCase();

    if (normalized.contains('redirect') ||
        normalized.contains('not allowed') ||
        normalized.contains('invalid url') ||
        normalized.contains('uri')) {
      return 'Password reset could not be sent. Please check the Supabase redirect URL settings and try again.';
    }

    if (normalized.contains('rate') ||
        normalized.contains('too many') ||
        normalized.contains('limit')) {
      return 'Too many reset requests. Please wait a few minutes before trying again.';
    }

    if (normalized.contains('network') ||
        normalized.contains('socket') ||
        normalized.contains('connection') ||
        normalized.contains('timeout')) {
      return 'Network connection failed. Please check your internet and try again.';
    }

    if (normalized.contains('email')) {
      return 'Password reset could not be sent to this email. Please check the address and try again.';
    }

    return 'Password reset could not be sent right now. Please try again.';
  }
}
