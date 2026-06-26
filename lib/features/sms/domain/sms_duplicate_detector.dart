import 'sms_transaction_models.dart';

class ExistingTransactionSnapshot {
  const ExistingTransactionSnapshot({
    required this.sourceName,
    required this.amount,
    required this.direction,
    required this.occurredAt,
    this.transactionId,
  });

  final String sourceName;
  final double amount;
  final SmsTransactionDirection direction;
  final DateTime occurredAt;
  final String? transactionId;
}

class SmsDuplicateDetector {
  const SmsDuplicateDetector();

  bool isLikelyDuplicate({
    required ParsedSmsTransaction parsed,
    required Iterable<SmsTransactionSuggestion> pending,
    required Iterable<ExistingTransactionSnapshot> existingTransactions,
  }) {
    final hasPendingMatch = pending.any((suggestion) {
      if (suggestion.status != SmsSuggestionStatus.pending) return false;
      if (suggestion.provider != parsed.provider) return false;
      if (_sameTransactionId(suggestion.transactionId, parsed.transactionId)) {
        return true;
      }

      final sameAmount = (suggestion.amount - parsed.amount).abs() <= 1.0;
      final similarTime =
          suggestion.occurredAt.difference(parsed.occurredAt).abs().inMinutes <=
              20;
      return sameAmount && similarTime;
    });

    if (hasPendingMatch) return true;

    return existingTransactions.any((transaction) {
      if (transaction.sourceName.toLowerCase() !=
          parsed.provider.defaultSourceName.toLowerCase()) {
        return false;
      }
      if (_sameTransactionId(transaction.transactionId, parsed.transactionId)) {
        return true;
      }
      final sameAmount = (transaction.amount - parsed.amount).abs() <= 1.0;
      final sameDirection = transaction.direction == parsed.direction;
      final similarTime =
          transaction.occurredAt.difference(parsed.occurredAt).abs().inHours <=
              12;
      return sameAmount && sameDirection && similarTime;
    });
  }

  bool _sameTransactionId(String? a, String? b) {
    if (a == null || b == null) return false;
    return a.trim().isNotEmpty &&
        a.trim().toLowerCase() == b.trim().toLowerCase();
  }
}
