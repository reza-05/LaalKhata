import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/ledger_document.dart';

part 'ledger_database.g.dart';

final LedgerDatabase sharedLedgerDatabase = LedgerDatabase();

class LocalLedgerStates extends Table {
  TextColumn get userId => text()();
  DateTimeColumn get smsTransactionCutoffAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class LocalMoneySources extends Table {
  TextColumn get userId => text()();
  TextColumn get sourceKey => text()();
  TextColumn get name => text()();
  TextColumn get sourceType => text()();
  RealColumn get balance => real().nullable()();
  IntColumn get colorValue => integer()();
  IntColumn get iconCodePoint => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortPosition => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, sourceKey};
}

class LocalLedgerActivities extends Table {
  TextColumn get userId => text()();
  TextColumn get activityKey => text()();
  TextColumn get name => text()();
  TextColumn get source => text()();
  RealColumn get amount => real()();
  TextColumn get displayTime => text()();
  IntColumn get iconCodePoint => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get category => text()();
  TextColumn get activityType => text()();
  IntColumn get sortPosition => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, activityKey};
}

class LocalSyncOutbox extends Table {
  TextColumn get operationId => text()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {operationId};
}

@DriftDatabase(
  tables: [
    LocalLedgerStates,
    LocalMoneySources,
    LocalLedgerActivities,
    LocalSyncOutbox,
  ],
)
class LedgerDatabase extends _$LedgerDatabase {
  LedgerDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) => migrator.createAll(),
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(
              localMoneySources,
              localMoneySources.sortPosition,
            );
            await migrator.addColumn(
              localLedgerActivities,
              localLedgerActivities.sortPosition,
            );
          }
        },
      );

  Future<void> replaceDocument(
    String userId,
    LedgerDocument document,
  ) async {
    await transaction(() async {
      await (delete(localMoneySources)
            ..where((table) => table.userId.equals(userId)))
          .go();
      await (delete(localLedgerActivities)
            ..where((table) => table.userId.equals(userId)))
          .go();

      await into(localLedgerStates).insertOnConflictUpdate(
        LocalLedgerStatesCompanion.insert(
          userId: userId,
          smsTransactionCutoffAt: Value(document.smsTransactionCutoffAt),
          updatedAt: document.updatedAt,
        ),
      );

      final sourceKeys = buildLedgerSourceKeys(document.sources);
      for (var index = 0; index < document.sources.length; index++) {
        final source = document.sources[index];
        await into(localMoneySources).insert(
          LocalMoneySourcesCompanion.insert(
            userId: userId,
            sourceKey: sourceKeys[index],
            name: source.name,
            sourceType: source.type,
            balance: Value(source.balance),
            colorValue: source.colorValue,
            iconCodePoint: source.iconCodePoint,
            archived: Value(source.archived),
            sortPosition: Value(index),
            updatedAt: document.updatedAt,
          ),
        );
      }

      final occurrences = <String, int>{};
      for (var index = 0; index < document.activities.length; index++) {
        final activity = document.activities[index];
        final fingerprint = '${activity.occurredAt.toIso8601String()}:'
            '${activity.source}:${activity.amount}:${activity.type}';
        final occurrence = occurrences.update(
          fingerprint,
          (value) => value + 1,
          ifAbsent: () => 0,
        );
        await into(localLedgerActivities).insert(
          LocalLedgerActivitiesCompanion.insert(
            userId: userId,
            activityKey: activity.stableKey(occurrence),
            name: activity.name,
            source: activity.source,
            amount: activity.amount,
            displayTime: activity.displayTime,
            iconCodePoint: activity.iconCodePoint,
            occurredAt: activity.occurredAt,
            category: activity.category,
            activityType: activity.type,
            sortPosition: Value(index),
            updatedAt: document.updatedAt,
          ),
        );
      }
    });
  }

  Future<LedgerDocument?> readDocument(String userId) async {
    final state = await (select(localLedgerStates)
          ..where((table) => table.userId.equals(userId)))
        .getSingleOrNull();
    if (state == null) return null;

    final sources = await (select(localMoneySources)
          ..where((table) => table.userId.equals(userId))
          ..orderBy([
            (table) => OrderingTerm.asc(table.sortPosition),
          ]))
        .get();
    final activities = await (select(localLedgerActivities)
          ..where((table) => table.userId.equals(userId))
          ..orderBy([
            (table) => OrderingTerm.asc(table.sortPosition),
          ]))
        .get();

    return LedgerDocument(
      sources: [
        for (final source in sources)
          LedgerSourceRecord(
            name: source.name,
            type: source.sourceType,
            balance: source.balance,
            colorValue: source.colorValue,
            iconCodePoint: source.iconCodePoint,
            archived: source.archived,
          ),
      ],
      activities: [
        for (final activity in activities)
          LedgerActivityRecord(
            name: activity.name,
            source: activity.source,
            amount: activity.amount,
            displayTime: activity.displayTime,
            iconCodePoint: activity.iconCodePoint,
            occurredAt: activity.occurredAt,
            category: activity.category,
            type: activity.activityType,
          ),
      ],
      monthlyTargets: const {},
      smsTransactionCutoffAt: state.smsTransactionCutoffAt,
      updatedAt: state.updatedAt,
    );
  }

  Future<void> enqueueDocumentSync({
    required String userId,
    required String payloadJson,
  }) async {
    final now = DateTime.now().toUtc();
    await into(localSyncOutbox).insertOnConflictUpdate(
      LocalSyncOutboxCompanion.insert(
        operationId: 'ledger-document:$userId',
        userId: userId,
        entityType: 'ledger_document',
        entityId: userId,
        operation: 'replace',
        payloadJson: payloadJson,
        status: const Value('pending'),
        attempts: const Value(0),
        lastError: const Value(null),
        createdAt: now,
        nextAttemptAt: const Value(null),
      ),
    );
  }

  Future<List<LocalSyncOutboxData>> pendingDocumentSyncs(
    String userId, {
    int limit = 10,
  }) {
    final now = DateTime.now().toUtc();
    return (select(localSyncOutbox)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.status.equals('pending') &
                (table.nextAttemptAt.isNull() |
                    table.nextAttemptAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([
            (table) => OrderingTerm.asc(table.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<void> completeSyncOperation(String operationId) {
    return (delete(localSyncOutbox)
          ..where((table) => table.operationId.equals(operationId)))
        .go();
  }

  Future<void> deferSyncOperation(
    String operationId, {
    required String errorCode,
  }) async {
    final operation = await (select(localSyncOutbox)
          ..where((table) => table.operationId.equals(operationId)))
        .getSingleOrNull();
    if (operation == null) return;

    final attempts = operation.attempts + 1;
    const retrySchedule = [1, 3, 5, 10, 30];
    final delaySeconds =
        retrySchedule[(attempts - 1).clamp(0, retrySchedule.length - 1)];
    await (update(localSyncOutbox)
          ..where((table) => table.operationId.equals(operationId)))
        .write(
      LocalSyncOutboxCompanion(
        status: const Value('pending'),
        attempts: Value(attempts),
        lastError: Value(errorCode),
        nextAttemptAt: Value(
          DateTime.now().toUtc().add(Duration(seconds: delaySeconds)),
        ),
      ),
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'laalkhata_ledger',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
