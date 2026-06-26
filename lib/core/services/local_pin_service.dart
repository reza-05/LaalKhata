import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum PinVerifyStatus {
  success,
  failed,
  locked,
}

class PinVerifyResult {
  const PinVerifyResult({
    required this.status,
    this.lockedFor,
    this.message,
  });

  final PinVerifyStatus status;
  final Duration? lockedFor;
  final String? message;
}

class LocalPinService {
  LocalPinService({
    FlutterSecureStorage? secureStorage,
    Random? random,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _random = random ?? Random.secure();

  final FlutterSecureStorage _secureStorage;
  final Random _random;

  static const _pinHashKey = 'local_pin_hash';
  static const _pinSaltKey = 'local_pin_salt';
  static const _failedAttemptsKey = 'local_pin_failed_attempts';
  static const _lockStageKey = 'local_pin_lock_stage';
  static const _lockedUntilKey = 'local_pin_locked_until';

  Future<bool> isPinSet() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);
    return hash != null && salt != null;
  }

  Future<void> setPin(String pin) async {
    _validatePin(pin);
    final salt = _newSalt();
    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: _hash(pin, salt));
    await _resetFailures();
  }

  Future<PinVerifyResult> verifyPin(String pin) async {
    final lockout = await remainingLockout();
    if (lockout != null) {
      return PinVerifyResult(
        status: PinVerifyStatus.locked,
        lockedFor: lockout,
      );
    }

    if (pin.length != 5) {
      return const PinVerifyResult(
        status: PinVerifyStatus.failed,
        message: 'Enter your 5-digit PIN.',
      );
    }

    final salt = await _secureStorage.read(key: _pinSaltKey);
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    if (salt == null || storedHash == null) {
      return const PinVerifyResult(
        status: PinVerifyStatus.failed,
        message: 'Local PIN is not set up yet.',
      );
    }

    if (_hash(pin, salt) == storedHash) {
      await _resetFailures();
      return const PinVerifyResult(status: PinVerifyStatus.success);
    }

    return _recordFailure();
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await _resetFailures();
  }

  Future<Duration?> remainingLockout() async {
    final raw = await _secureStorage.read(key: _lockedUntilKey);
    if (raw == null) return null;

    final lockedUntil = DateTime.tryParse(raw);
    if (lockedUntil == null) {
      await _secureStorage.delete(key: _lockedUntilKey);
      return null;
    }

    final now = DateTime.now();
    if (!lockedUntil.isAfter(now)) {
      await _secureStorage.delete(key: _lockedUntilKey);
      return null;
    }

    return lockedUntil.difference(now);
  }

  Future<PinVerifyResult> _recordFailure() async {
    final attempts = await _readInt(_failedAttemptsKey) + 1;
    await _secureStorage.write(
      key: _failedAttemptsKey,
      value: attempts.toString(),
    );

    if (attempts < 5) {
      return PinVerifyResult(
        status: PinVerifyStatus.failed,
        message: 'PIN did not match. ${5 - attempts} attempts left.',
      );
    }

    final stage = await _readInt(_lockStageKey);
    final lockDuration = _lockDurationForStage(stage);
    await _secureStorage.write(key: _failedAttemptsKey, value: '0');
    await _secureStorage.write(key: _lockStageKey, value: '${stage + 1}');
    await _secureStorage.write(
      key: _lockedUntilKey,
      value: DateTime.now().add(lockDuration).toIso8601String(),
    );

    return PinVerifyResult(
      status: PinVerifyStatus.locked,
      lockedFor: lockDuration,
    );
  }

  Future<void> _resetFailures() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockedUntilKey);
  }

  Future<int> _readInt(String key) async {
    final raw = await _secureStorage.read(key: key);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Duration _lockDurationForStage(int stage) {
    if (stage <= 0) return const Duration(seconds: 30);
    if (stage == 1) return const Duration(minutes: 1);
    return const Duration(minutes: 5);
  }

  String _newSalt() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin:LaalKhataLocalPin');
    return sha256.convert(bytes).toString();
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{5}$').hasMatch(pin)) {
      throw ArgumentError('PIN must be exactly 5 digits.');
    }
  }
}
