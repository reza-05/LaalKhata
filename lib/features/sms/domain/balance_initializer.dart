import 'sms_transaction_models.dart';

class SmsBalanceInitializer {
  const SmsBalanceInitializer();

  bool canSuggestOpeningBalance({
    required SmsTransactionSuggestion suggestion,
    required double? currentBalance,
  }) {
    return currentBalance == null && suggestion.detectedBalance != null;
  }

  double previewBalance({
    required double? currentBalance,
    required SmsTransactionSuggestion suggestion,
  }) {
    final balance = currentBalance ?? 0;
    if (suggestion.direction == SmsTransactionDirection.credit) {
      return balance + suggestion.amount;
    }
    return balance - suggestion.amount;
  }
}
