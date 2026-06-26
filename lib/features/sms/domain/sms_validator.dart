import 'sms_transaction_models.dart';

class SmsValidationResult {
  const SmsValidationResult({
    required this.isValid,
    required this.confidenceBoost,
  });

  final bool isValid;
  final double confidenceBoost;
}

class SmsTransactionValidator {
  const SmsTransactionValidator();

  SmsValidationResult validate({
    required ParsedSmsTransaction parsed,
    required double? currentBalance,
  }) {
    if (parsed.amount <= 0) {
      return const SmsValidationResult(isValid: false, confidenceBoost: 0);
    }

    if (parsed.newBalance == null || currentBalance == null) {
      return const SmsValidationResult(isValid: true, confidenceBoost: 0);
    }

    final expectedDifference =
        parsed.direction == SmsTransactionDirection.credit
            ? parsed.amount
            : -parsed.amount;
    final smsDifference = parsed.newBalance! - currentBalance;
    final closeEnough = (smsDifference - expectedDifference).abs() <= 1.0;

    return SmsValidationResult(
      isValid: true,
      confidenceBoost: closeEnough ? 0.2 : -0.08,
    );
  }
}
