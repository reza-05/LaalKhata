import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/ledger/data/local/ledger_database.dart';
import '../../features/ledger/data/remote/normalized_ledger_remote_data_source.dart';
import '../../features/ledger/domain/ledger_document.dart';
import '../../features/ledger/domain/ledger_repository.dart';
import 'supabase_service.dart';

class LedgerSnapshotRepository implements LedgerRepository {
  LedgerSnapshotRepository({
    FlutterSecureStorage? storage,
    LedgerDatabase? database,
    NormalizedLedgerRemoteDataSource? normalizedRemote,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _database = database ?? sharedLedgerDatabase,
        _normalizedRemote = normalizedRemote ??
            const SupabaseNormalizedLedgerRemoteDataSource();

  final FlutterSecureStorage _storage;
  final LedgerDatabase _database;
  final NormalizedLedgerRemoteDataSource _normalizedRemote;

  static final Set<String> _syncingUsers = {};
  final Map<String, int> _knownCloudRevisions = {};

  @override
  Future<LedgerLoadResult> load(String userId) async {
    final localPayload = await _readLocalPayload(userId);
    if (!SupabaseService.isConfigured) {
      return _finishLoad(
        userId,
        localPayload,
        cloudAvailable: false,
        syncNormalized: localPayload != null,
      );
    }

    return _loadWithCloud(userId, localPayload);
  }

  Future<LedgerLoadResult> loadLocal(String userId) async {
    final localPayload = await _readLocalPayload(userId);
    return _finishLoad(
      userId,
      localPayload,
      cloudAvailable: false,
      syncNormalized: localPayload != null,
    );
  }

  Future<LedgerLoadResult> refreshFromCloud(String userId) async {
    if (!SupabaseService.isConfigured) {
      return loadLocal(userId);
    }

    final localPayload = await _readLocalPayload(userId);
    return _loadWithCloud(userId, localPayload);
  }

  Future<LedgerLoadResult> _loadWithCloud(
    String userId,
    Map<String, dynamic>? localPayload,
  ) async {
    Map<String, dynamic>? cloudPayload;
    var snapshotCloudAvailable = false;
    try {
      final response = await SupabaseService.client
          .from('ledger_snapshots')
          .select('payload, updated_at')
          .eq('user_id', userId)
          .maybeSingle();
      snapshotCloudAvailable = true;
      cloudPayload = _asStringKeyedMap(response?['payload']);
    } catch (_) {
      snapshotCloudAvailable = false;
    }

    NormalizedLedgerCloudDocument? normalizedCloud;
    var normalizedCloudAvailable = false;
    try {
      normalizedCloud = await _normalizedRemote.loadDocument();
      normalizedCloudAvailable = true;
      if (normalizedCloud != null) {
        _knownCloudRevisions[userId] = normalizedCloud.revision;
      }
    } catch (_) {
      normalizedCloudAvailable = false;
    }

    final normalizedPayload = normalizedCloud?.document.toJson();
    final preferred = _newestPayload([
      localPayload,
      cloudPayload,
      normalizedPayload,
    ]);
    final syncNormalized = preferred != null &&
        (normalizedPayload == null ||
            _payloadUpdatedAt(preferred)
                .isAfter(_payloadUpdatedAt(normalizedPayload)));

    if (preferred != null &&
        (cloudPayload == null ||
            _payloadUpdatedAt(preferred)
                .isAfter(_payloadUpdatedAt(cloudPayload)))) {
      try {
        await _saveCloud(userId, preferred);
        snapshotCloudAvailable = true;
      } catch (_) {
        // The normalized and local copies remain available.
      }
    }

    return _finishLoad(
      userId,
      preferred,
      cloudAvailable: snapshotCloudAvailable || normalizedCloudAvailable,
      syncNormalized: syncNormalized,
    );
  }

  Future<Map<String, dynamic>?> _readLocalPayload(String userId) async {
    final securePayload = await _readSecureSnapshot(userId);
    final databasePayload = await _readDatabaseSnapshot(userId);
    return _newerOptionalPayload(
      securePayload,
      databasePayload,
    );
  }

  @override
  Future<bool> save(String userId, LedgerDocument document) async {
    final payload = document.toJson();
    await _writeLocalCopies(userId, payload);
    await _queueNormalizedSync(
      userId,
      document,
      expectedRevision: _knownCloudRevisions[userId],
    );
    if (!SupabaseService.isConfigured) return false;

    try {
      await _saveCloud(userId, payload);
      unawaited(_flushNormalizedSync(userId));
      return true;
    } catch (_) {
      unawaited(_flushNormalizedSync(userId));
      return false;
    }
  }

  Future<LedgerLoadResult> _finishLoad(
    String userId,
    Map<String, dynamic>? payload, {
    required bool cloudAvailable,
    required bool syncNormalized,
  }) async {
    await _writeLocalCopies(userId, payload);
    final document = _toDocument(payload);
    if (document != null && syncNormalized) {
      await _queueNormalizedSync(
        userId,
        document,
        expectedRevision: _knownCloudRevisions[userId],
      );
      if (SupabaseService.isConfigured) {
        unawaited(_flushNormalizedSync(userId));
      }
    }
    return LedgerLoadResult(
      document: document,
      cloudAvailable: cloudAvailable,
    );
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

  Future<Map<String, dynamic>?> _readSecureSnapshot(String userId) async {
    var raw = await _storage.read(key: _storageKey(userId));
    raw ??= await _storage.read(key: 'ledger_snapshot_v2_$userId');
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final payload = _asStringKeyedMap(jsonDecode(raw));
      if (payload != null) {
        await _writeSecureSnapshot(userId, payload);
      }
      return payload;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSecureSnapshot(
    String userId,
    Map<String, dynamic> payload,
  ) {
    return _storage.write(
      key: _storageKey(userId),
      value: jsonEncode(payload),
    );
  }

  Future<Map<String, dynamic>?> _readDatabaseSnapshot(String userId) async {
    try {
      return (await _database.readDocument(userId))?.toJson();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocalCopies(
    String userId,
    Map<String, dynamic>? payload,
  ) async {
    if (payload == null) return;
    await _writeSecureSnapshot(userId, payload);
    try {
      await _database.replaceDocument(
        userId,
        LedgerDocument.fromJson(payload),
      );
    } catch (_) {
      // The established secure snapshot remains the compatibility fallback.
    }
  }

  Future<void> _queueNormalizedSync(
    String userId,
    LedgerDocument document, {
    required int? expectedRevision,
  }) async {
    try {
      await _database.enqueueDocumentSync(
        userId: userId,
        payloadJson: jsonEncode({
          'document': document.toJson(),
          'expectedRevision': expectedRevision,
        }),
      );
    } catch (_) {
      // The compatibility snapshot remains available if the outbox cannot write.
    }
  }

  Future<void> _flushNormalizedSync(String userId) async {
    if (!SupabaseService.isConfigured || !_syncingUsers.add(userId)) return;
    try {
      final operations = await _database.pendingDocumentSyncs(userId);
      for (final operation in operations) {
        try {
          final decoded = jsonDecode(operation.payloadJson);
          final payload = _asStringKeyedMap(decoded);
          if (payload == null) {
            await _database.deferSyncOperation(
              operation.operationId,
              errorCode: 'invalid_payload',
            );
            continue;
          }
          final documentPayload =
              _asStringKeyedMap(payload['document']) ?? payload;
          final expectedRevision =
              (payload['expectedRevision'] as num?)?.toInt();
          final document = LedgerDocument.fromJson(documentPayload);
          var result = await _normalizedRemote.syncDocument(
            document,
            expectedRevision: expectedRevision,
          );

          if (!result.accepted) {
            final remoteDocument = result.currentDocument;
            if (remoteDocument == null) {
              await _database.deferSyncOperation(
                operation.operationId,
                errorCode: 'revision_conflict',
              );
              break;
            }

            if (document.updatedAt.isAfter(remoteDocument.updatedAt)) {
              result = await _normalizedRemote.syncDocument(
                document,
                expectedRevision: result.revision,
              );
              if (!result.accepted) {
                await _database.deferSyncOperation(
                  operation.operationId,
                  errorCode: 'revision_conflict',
                );
                break;
              }
            } else {
              await _writeLocalCopies(userId, remoteDocument.toJson());
              try {
                await _saveCloud(userId, remoteDocument.toJson());
              } catch (_) {
                // The normalized document is already safely stored.
              }
              _knownCloudRevisions[userId] = result.revision;
              await _database.completeSyncOperation(operation.operationId);
              continue;
            }
          }

          _knownCloudRevisions[userId] = result.revision;
          try {
            await _saveCloud(userId, document.toJson());
          } catch (_) {
            // The outbox operation succeeded against the normalized store.
          }
          await _database.completeSyncOperation(operation.operationId);
        } catch (_) {
          await _database.deferSyncOperation(
            operation.operationId,
            errorCode: 'remote_sync_failed',
          );
          break;
        }
      }
    } catch (_) {
      // A later load or save will retry the durable outbox.
    } finally {
      _syncingUsers.remove(userId);
    }
  }

  Map<String, dynamic>? _newestPayload(
    Iterable<Map<String, dynamic>?> candidates,
  ) {
    Map<String, dynamic>? newest;
    for (final candidate in candidates) {
      if (candidate == null) continue;
      if (newest == null ||
          _payloadUpdatedAt(candidate).isAfter(_payloadUpdatedAt(newest))) {
        newest = candidate;
      }
    }
    return newest;
  }

  Map<String, dynamic>? _newerOptionalPayload(
    Map<String, dynamic>? first,
    Map<String, dynamic>? second,
  ) {
    if (first == null) return second;
    if (second == null) return first;
    return _newerPayload(first, second);
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

  LedgerDocument? _toDocument(Map<String, dynamic>? payload) {
    return payload == null ? null : LedgerDocument.fromJson(payload);
  }

  String _storageKey(String userId) => 'ledger_snapshot_v3_$userId';
}
