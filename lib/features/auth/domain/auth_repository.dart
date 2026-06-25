import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  User? get currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String department,
    String? studentId,
    String? batch,
  });

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset({
    required String email,
  });

  Future<void> signOut();
}
