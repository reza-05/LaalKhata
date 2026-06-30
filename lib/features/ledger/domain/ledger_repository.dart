import 'ledger_document.dart';

class LedgerLoadResult {
  const LedgerLoadResult({
    required this.document,
    required this.cloudAvailable,
  });

  final LedgerDocument? document;
  final bool cloudAvailable;
}

abstract interface class LedgerRepository {
  Future<LedgerLoadResult> load(String userId);

  Future<bool> save(
    String userId,
    LedgerDocument document, {
    bool attemptRemote = true,
  });
}
