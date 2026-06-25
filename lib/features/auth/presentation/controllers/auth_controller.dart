import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const SupabaseAuthRepository();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider))..loadSession();
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.idle());

  final AuthRepository _repository;

  void loadSession() {
    final user = _repository.currentUser;
    state = AuthState(
      status: user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      user: user,
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
      loadSession();
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
      loadSession();
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        message: _friendlyError(error),
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

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    try {
      await _repository.signOut();
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
    return error.toString().replaceFirst('Exception: ', '');
  }
}
