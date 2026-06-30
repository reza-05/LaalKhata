import 'package:flutter_test/flutter_test.dart';
import 'package:laalkhata/features/ledger/data/remote/normalized_ledger_remote_data_source.dart';
import 'package:laalkhata/features/ledger/domain/ledger_document.dart';

void main() {
  test('normalized payload preserves order and stable entity keys', () {
    final occurredAt = DateTime.utc(2026, 6, 28, 1);
    final document = LedgerDocument(
      sources: const [
        LedgerSourceRecord(
          name: 'Cash',
          type: 'cash',
          balance: 1000,
          colorValue: 1,
          iconCodePoint: 2,
          archived: false,
        ),
        LedgerSourceRecord(
          name: 'cash',
          type: 'cash',
          balance: 2000,
          colorValue: 3,
          iconCodePoint: 4,
          archived: false,
        ),
      ],
      activities: [
        for (var index = 0; index < 2; index++)
          LedgerActivityRecord(
            name: 'Cafeteria',
            source: 'Cash',
            amount: -100,
            displayTime: 'Today, 01:00',
            iconCodePoint: 5,
            occurredAt: occurredAt,
            category: 'Cafeteria',
            type: 'expense',
          ),
      ],
      monthlyTargets: const {'2026-06': 12000},
      smsTransactionCutoffAt: occurredAt,
      updatedAt: occurredAt,
    );

    final payload = NormalizedLedgerPayloadBuilder.build(document);
    final sources = payload['sources']! as List<dynamic>;
    final activities = payload['activities']! as List<dynamic>;

    expect(sources[0], containsPair('sourceKey', 'cash'));
    expect(sources[1], containsPair('sourceKey', 'cash:1'));
    expect(sources[0], containsPair('sortPosition', 0));
    expect(sources[1], containsPair('sortPosition', 1));
    expect(activities[0], containsPair('sortPosition', 0));
    expect(activities[1], containsPair('sortPosition', 1));
    expect(payload['monthlyTargets'], containsPair('2026-06', 12000));
    expect(
      (activities[0] as Map<String, dynamic>)['activityKey'],
      isNot((activities[1] as Map<String, dynamic>)['activityKey']),
    );
    expect(payload.toString(), isNot(contains('senderId')));
    expect(payload.toString(), isNot(contains('smsBody')));
  });
}
