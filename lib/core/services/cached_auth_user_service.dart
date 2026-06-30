import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CachedAuthUserService {
  CachedAuthUserService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _storageKey = 'cached_auth_user_v1';

  Future<User?> readUser() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return User.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeUser(User user) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<void> clear() {
    return _storage.delete(key: _storageKey);
  }
}
