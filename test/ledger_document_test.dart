import 'package:flutter_test/flutter_test.dart';
import 'package:laalkhata/features/ledger/domain/ledger_document.dart';

void main() {
  test('ledger document preserves the compatibility snapshot shape', () {
    final updatedAt = DateTime.utc(2026, 6, 27, 12);
    final cutoff = DateTime.utc(2026, 6, 27, 10);
    final payload = <String, dynamic>{
      'sources': [
        {
          'name': 'bKash',
          'type': 'mobileBanking',
          'balance': 4580.0,
          'color': 123,
          'icon': 456,
          'archived': false,
        },
      ],
      'activities': [
        {
          'name': 'Cafeteria',
          'source': 'bKash',
          'amount': -120.0,
          'time': 'Today, 12:00',
          'icon': 789,
          'occurredAt': updatedAt.toIso8601String(),
          'category': 'Cafeteria',
          'type': 'expense',
        },
      ],
      'smsTransactionCutoffAt': cutoff.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    final document = LedgerDocument.fromJson(payload);
    final encoded = document.toJson();

    expect(document.sources.single.name, 'bKash');
    expect(document.sources.single.balance, 4580);
    expect(document.activities.single.amount, -120);
    expect(document.smsTransactionCutoffAt, cutoff);
    expect(encoded['sources'], payload['sources']);
    expect(encoded['activities'], payload['activities']);
    expect(encoded['smsTransactionCutoffAt'], cutoff.toIso8601String());
    expect(encoded['updatedAt'], updatedAt.toIso8601String());
  });

  test('invalid nested records are ignored without losing valid data', () {
    final document = LedgerDocument.fromJson({
      'sources': [
        {'name': '', 'type': 'other'},
        {
          'name': 'Cash',
          'type': 'cash',
          'balance': null,
          'color': 1,
          'icon': 2,
          'archived': false,
        },
      ],
      'activities': [
        {'name': 'Incomplete'},
      ],
      'updatedAt': 'invalid',
    });

    expect(document.sources.single.name, 'Cash');
    expect(document.sources.single.balance, isNull);
    expect(document.activities, isEmpty);
    expect(
      document.updatedAt,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  });
}
