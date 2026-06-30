import '../../../../core/services/supabase_service.dart';
import '../../domain/ledger_document.dart';

abstract interface class NormalizedLedgerRemoteDataSource {
  Future<NormalizedLedgerCloudDocument?> loadDocument();

  Future<NormalizedLedgerSyncResult> syncDocument(
    LedgerDocument document, {
    int? expectedRevision,
  });
}

class SupabaseNormalizedLedgerRemoteDataSource
    implements NormalizedLedgerRemoteDataSource {
  const SupabaseNormalizedLedgerRemoteDataSource();

  @override
  Future<NormalizedLedgerCloudDocument?> loadDocument() async {
    final response = await SupabaseService.client.rpc('get_ledger_document');
    final payload = _stringKeyedMap(response);
    if (payload == null) return null;
    final revision = (payload['revision'] as num?)?.toInt();
    if (revision == null) return null;
    return NormalizedLedgerCloudDocument(
      document: LedgerDocument.fromJson(payload),
      revision: revision,
    );
  }

  @override
  Future<NormalizedLedgerSyncResult> syncDocument(
    LedgerDocument document, {
    int? expectedRevision,
  }) async {
    final response = await SupabaseService.client.rpc(
      'sync_ledger_document_v2',
      params: {
        'p_document': NormalizedLedgerPayloadBuilder.build(document),
        'p_expected_revision': expectedRevision,
      },
    );
    final payload = _stringKeyedMap(response);
    if (payload == null) {
      throw const FormatException('Invalid normalized sync response.');
    }
    final revision = (payload['revision'] as num?)?.toInt();
    if (revision == null) {
      throw const FormatException('Normalized sync revision is missing.');
    }
    final currentPayload = _stringKeyedMap(payload['currentDocument']);
    return NormalizedLedgerSyncResult(
      accepted: payload['accepted'] == true,
      revision: revision,
      currentDocument: currentPayload == null
          ? null
          : LedgerDocument.fromJson(currentPayload),
    );
  }
}

class NormalizedLedgerCloudDocument {
  const NormalizedLedgerCloudDocument({
    required this.document,
    required this.revision,
  });

  final LedgerDocument document;
  final int revision;
}

class NormalizedLedgerSyncResult {
  const NormalizedLedgerSyncResult({
    required this.accepted,
    required this.revision,
    required this.currentDocument,
  });

  final bool accepted;
  final int revision;
  final LedgerDocument? currentDocument;
}

class NormalizedLedgerPayloadBuilder {
  const NormalizedLedgerPayloadBuilder._();

  static Map<String, dynamic> build(LedgerDocument document) {
    final occurrences = <String, int>{};
    final sourceKeys = buildLedgerSourceKeys(document.sources);
    return {
      'updatedAt': document.updatedAt.toUtc().toIso8601String(),
      'smsTransactionCutoffAt':
          document.smsTransactionCutoffAt?.toUtc().toIso8601String(),
      'monthlyTargets': document.monthlyTargets.map(
        (key, value) => MapEntry(key, value),
      ),
      'sources': [
        for (var index = 0; index < document.sources.length; index++)
          {
            ...document.sources[index].toJson(),
            'sourceKey': sourceKeys[index],
            'sortPosition': index,
          },
      ],
      'activities': [
        for (var index = 0; index < document.activities.length; index++)
          _activityPayload(
            document.activities[index],
            index,
            occurrences,
          ),
      ],
    };
  }

  static Map<String, dynamic> _activityPayload(
    LedgerActivityRecord activity,
    int index,
    Map<String, int> occurrences,
  ) {
    final fingerprint = '${activity.occurredAt.toIso8601String()}:'
        '${activity.source}:${activity.amount}:${activity.type}';
    final occurrence = occurrences.update(
      fingerprint,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    return {
      ...activity.toJson(),
      'activityKey': activity.stableKey(occurrence),
      'sortPosition': index,
    };
  }
}

Map<String, dynamic>? _stringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry('$key', item));
  }
  return null;
}
