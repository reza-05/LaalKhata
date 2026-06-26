import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricAuthStatus {
  success,
  unavailable,
  failed,
  locked,
}

class FingerprintAvailability {
  const FingerprintAvailability({
    required this.isAvailable,
    required this.message,
  });

  final bool isAvailable;
  final String message;
}

class BiometricAuthResult {
  const BiometricAuthResult({
    required this.status,
    this.lockedFor,
    this.message,
  });

  final BiometricAuthStatus status;
  final Duration? lockedFor;
  final String? message;
}

class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const _enabledKey = 'fingerprint_enabled';
  static const _failedAttemptsKey = 'fingerprint_failed_attempts';
  static const _lockStageKey = 'fingerprint_lock_stage';
  static const _lockedUntilKey = 'fingerprint_locked_until';

  Future<bool> canUseFingerprint() async {
    final availability = await fingerprintAvailability();
    return availability.isAvailable;
  }

  Future<FingerprintAvailability> fingerprintAvailability() async {
    if (!Platform.isAndroid) {
      return const FingerprintAvailability(
        isAvailable: false,
        message: 'Fingerprint login is only enabled for Android right now.',
      );
    }

    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) {
        return const FingerprintAvailability(
          isAvailable: false,
          message: 'Fingerprint is not supported on this Android device.',
        );
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      final hasAndroidBiometric =
          biometrics.contains(BiometricType.fingerprint) ||
              biometrics.contains(BiometricType.strong) ||
              biometrics.contains(BiometricType.weak);

      if (!hasAndroidBiometric) {
        return const FingerprintAvailability(
          isAvailable: false,
          message:
              'No fingerprint is enrolled. Add a fingerprint in Android Settings first.',
        );
      }

      return const FingerprintAvailability(
        isAvailable: true,
        message: 'Fingerprint is ready on this device.',
      );
    } catch (_) {
      return const FingerprintAvailability(
        isAvailable: false,
        message: 'Fingerprint check failed. Please try again.',
      );
    }
  }

  Future<bool> isFingerprintEnabled() async {
    return await _secureStorage.read(key: _enabledKey) == 'true';
  }

  Future<void> enableFingerprint() async {
    await _secureStorage.write(key: _enabledKey, value: 'true');
    await _resetFailures();
  }

  Future<void> disableFingerprint() async {
    await _secureStorage.delete(key: _enabledKey);
    await _resetFailures();
  }

  Future<BiometricAuthResult> authenticate({
    required String reason,
  }) async {
    final lockout = await remainingLockout();
    if (lockout != null) {
      return BiometricAuthResult(
        status: BiometricAuthStatus.locked,
        lockedFor: lockout,
      );
    }

    final available = await canUseFingerprint();
    if (!available) {
      return const BiometricAuthResult(
        status: BiometricAuthStatus.unavailable,
        message: 'Fingerprint is not available on this device.',
      );
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        await _resetFailures();
        return const BiometricAuthResult(status: BiometricAuthStatus.success);
      }

      return _recordFailure();
    } catch (_) {
      return _recordFailure();
    }
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

  Future<BiometricAuthResult> _recordFailure() async {
    final attempts = await _readInt(_failedAttemptsKey) + 1;
    await _secureStorage.write(
      key: _failedAttemptsKey,
      value: attempts.toString(),
    );

    if (attempts < 5) {
      return const BiometricAuthResult(
        status: BiometricAuthStatus.failed,
        message: 'Fingerprint did not match. Try again or use password.',
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

    return BiometricAuthResult(
      status: BiometricAuthStatus.locked,
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
}
