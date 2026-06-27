import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'supabase_service.dart';

class LedgerSnapshotLoadResult {
  const LedgerSnapshotLoadResult({
    required this.payload,
    required this.cloudAvailable,
  });

  final Map<String, dynamic>? payload;
  final bool cloudAvailable;
}

class LedgerSnapshotRepository {
  LedgerSnapshotRepository({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<LedgerSnapshotLoadResult> load(String userId) async {
    final localPayload = await _readLocal(userId);
    if (!SupabaseService.isConfigured) {
      return LedgerSnapshotLoadResult(
        payload: localPayload,
        cloudAvailable: false,
      );
    }

    try {
      final response = await SupabaseService.client
          .from('ledger_snapshots')
          .select('payload, updated_at')
          .eq('user_id', userId)
          .maybeSingle();
      final cloudPayload = _asStringKeyedMap(response?['payload']);

      if (cloudPayload == null) {
        if (localPayload != null) {
          await _saveCloud(userId, localPayload);
        }
        return LedgerSnapshotLoadResult(
          payload: localPayload,
          cloudAvailable: true,
        );
      }

      final preferred = _newerPayload(localPayload, cloudPayload);
      await _writeLocal(userId, preferred);
      if (identical(preferred, localPayload)) {
        await _saveCloud(userId, preferred);
      }
      return LedgerSnapshotLoadResult(
        payload: preferred,
        cloudAvailable: true,
      );
    } catch (_) {
      return LedgerSnapshotLoadResult(
        payload: localPayload,
        cloudAvailable: false,
      );
    }
  }

  Future<bool> save(String userId, Map<String, dynamic> payload) async {
    await _writeLocal(userId, payload);
    if (!SupabaseService.isConfigured) return false;

    try {
      await _saveCloud(userId, payload);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveCloud(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    await SupabaseService.client.from('ledger_snapshots').upsert({
      'user_id': userId,
      'payload': payload,
      'updated_at': _payloadUpdatedAt(payload).toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> _readLocal(String userId) async {
    var raw = await _storage.read(key: _storageKey(userId));
    raw ??= await _storage.read(key: 'ledger_snapshot_v2_$userId');
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final payload = _asStringKeyedMap(jsonDecode(raw));
      if (payload != null) {
        await _writeLocal(userId, payload);
      }
      return payload;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocal(
    String userId,
    Map<String, dynamic> payload,
  ) {
    return _storage.write(
      key: _storageKey(userId),
      value: jsonEncode(payload),
    );
  }

  Map<String, dynamic> _newerPayload(
    Map<String, dynamic>? local,
    Map<String, dynamic> cloud,
  ) {
    if (local == null) return cloud;
    return _payloadUpdatedAt(cloud).isAfter(_payloadUpdatedAt(local))
        ? cloud
        : local;
  }

  DateTime _payloadUpdatedAt(Map<String, dynamic> payload) {
    return DateTime.tryParse('${payload['updatedAt']}') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry('$key', item));
    }
    return null;
  }

  String _storageKey(String userId) => 'ledger_snapshot_v3_$userId';
}
