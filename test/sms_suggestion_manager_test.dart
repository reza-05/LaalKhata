import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laalkhata/features/sms/data/sms_suggestion_manager.dart';
import 'package:laalkhata/features/sms/domain/sms_transaction_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('only suggests transactions received after the opening balance cutoff',
      () async {
    final manager = SmsSuggestionManager();
    await manager.switchUser('user-a');
    final cutoff = DateTime(2026, 6, 27, 10);

    final added = await manager.scanMessages(
      messages: [
        RawSmsMessage(
          sender: 'bKash',
          body: 'Payment Tk 500 successful. Balance Tk 4500.',
          receivedAt: cutoff.subtract(const Duration(minutes: 5)),
        ),
        RawSmsMessage(
          sender: 'bKash',
          body: 'Payment Tk 200 successful. Balance Tk 4300.',
          receivedAt: cutoff.add(const Duration(minutes: 5)),
        ),
      ],
      currentBalanceForSource: (_) => 4500,
      existingTransactions: const [],
      notBefore: cutoff,
    );

    expect(added, 1);
    expect(manager.pending.single.amount, 200);
  });

  test('opening balance detection keeps only the latest provider balance',
      () async {
    final manager = SmsSuggestionManager();
    final first = DateTime(2026, 6, 27, 9);
    final latest = first.add(const Duration(hours: 1));

    final balances = await manager.detectLatestBalances(
      messages: [
        RawSmsMessage(
          sender: 'Nagad',
          body: 'Received Tk 100. Balance Tk 1100.',
          receivedAt: first,
        ),
        RawSmsMessage(
          sender: 'Nagad',
          body: 'Payment Tk 200. Balance Tk 900.',
          receivedAt: latest,
        ),
      ],
    );

    expect(balances, hasLength(1));
    expect(balances.single.balance, 900);
    expect(balances.single.detectedAt, latest);
  });
}
