import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus {
  idle,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.message,
  });

  const AuthState.idle() : this(status: AuthStatus.idle);

  final AuthStatus status;
  final User? user;
  final String? message;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? message,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message,
    );
  }
}
