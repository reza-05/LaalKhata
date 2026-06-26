import 'sms_transaction_models.dart';

abstract class ProviderSmsParser {
  const ProviderSmsParser();

  SmsFinancialProvider get provider;

  bool matchesSender(String sender);

  ParsedSmsTransaction? parse(RawSmsMessage sms);

  String normalizeSender(String sender) {
    return sender.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  double? extractAmount(String text) {
    final amountPattern = RegExp(
      r'(?:tk|bdt|taka|৳)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final matches = amountPattern.allMatches(text);
    for (final match in matches) {
      final amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
      if (amount != null && amount > 0) return amount;
    }
    return null;
  }

  double? extractBalance(String text) {
    final balancePattern = RegExp(
      r'(?:balance|bal|available balance|current balance|avl bal)[^\d]{0,20}(?:tk|bdt|৳)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final match = balancePattern.firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  String? extractTransactionId(String text) {
    final patterns = [
      RegExp(
          r'(?:trxid|trx id|txnid|txn id|transaction id|trans id|ref|ref no)[:\s#-]*([a-z0-9]{6,})',
          caseSensitive: false),
      RegExp(r'\b([A-Z0-9]{10,})\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  SmsTransactionDirection? directionFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('cash in') ||
        lower.contains('received') ||
        lower.contains('credited') ||
        lower.contains('credit') ||
        lower.contains('deposit') ||
        lower.contains('salary') ||
        lower.contains('allowance') ||
        lower.contains('added')) {
      return SmsTransactionDirection.credit;
    }

    if (lower.contains('payment') ||
        lower.contains('sent') ||
        lower.contains('debited') ||
        lower.contains('debit') ||
        lower.contains('cash out') ||
        lower.contains('withdraw') ||
        lower.contains('purchase') ||
        lower.contains('paid') ||
        lower.contains('charge')) {
      return SmsTransactionDirection.debit;
    }

    return null;
  }

  String reasonFromText(String text, SmsTransactionDirection direction) {
    final lower = text.toLowerCase();
    if (lower.contains('cash out') || lower.contains('withdraw')) {
      return 'Cash withdrawal';
    }
    if (lower.contains('cash in') || lower.contains('deposit')) {
      return 'Cash in';
    }
    if (lower.contains('payment') || lower.contains('paid')) {
      return 'Payment';
    }
    if (lower.contains('received') || lower.contains('credited')) {
      return 'Received money';
    }
    return direction == SmsTransactionDirection.credit ? 'Income' : 'Expense';
  }
}

class BkashSmsParser extends ProviderSmsParser {
  const BkashSmsParser();

  @override
  SmsFinancialProvider get provider => SmsFinancialProvider.bkash;

  @override
  bool matchesSender(String sender) {
    final normalized = normalizeSender(sender);
    return normalized.contains('bkash');
  }

  @override
  ParsedSmsTransaction? parse(RawSmsMessage sms) {
    if (!matchesSender(sms.sender)) return null;
    final direction = directionFromText(sms.body);
    final amount = extractAmount(sms.body);
    if (direction == null || amount == null) return null;
    return ParsedSmsTransaction(
      provider: provider,
      amount: amount,
      direction: direction,
      reason: reasonFromText(sms.body, direction),
      newBalance: extractBalance(sms.body),
      occurredAt: sms.receivedAt,
      senderId: provider.label,
      transactionId: extractTransactionId(sms.body),
      confidence: 0.78,
    );
  }
}

class NagadSmsParser extends ProviderSmsParser {
  const NagadSmsParser();

  @override
  SmsFinancialProvider get provider => SmsFinancialProvider.nagad;

  @override
  bool matchesSender(String sender) {
    final normalized = normalizeSender(sender);
    return normalized.contains('nagad');
  }

  @override
  ParsedSmsTransaction? parse(RawSmsMessage sms) {
    if (!matchesSender(sms.sender)) return null;
    final direction = directionFromText(sms.body);
    final amount = extractAmount(sms.body);
    if (direction == null || amount == null) return null;
    return ParsedSmsTransaction(
      provider: provider,
      amount: amount,
      direction: direction,
      reason: reasonFromText(sms.body, direction),
      newBalance: extractBalance(sms.body),
      occurredAt: sms.receivedAt,
      senderId: provider.label,
      transactionId: extractTransactionId(sms.body),
      confidence: 0.76,
    );
  }
}

class RocketSmsParser extends ProviderSmsParser {
  const RocketSmsParser();

  @override
  SmsFinancialProvider get provider => SmsFinancialProvider.rocket;

  @override
  bool matchesSender(String sender) {
    final normalized = normalizeSender(sender);
    return normalized.contains('rocket') || normalized.contains('dbbl');
  }

  @override
  ParsedSmsTransaction? parse(RawSmsMessage sms) {
    if (!matchesSender(sms.sender)) return null;
    final direction = directionFromText(sms.body);
    final amount = extractAmount(sms.body);
    if (direction == null || amount == null) return null;
    return ParsedSmsTransaction(
      provider: provider,
      amount: amount,
      direction: direction,
      reason: reasonFromText(sms.body, direction),
      newBalance: extractBalance(sms.body),
      occurredAt: sms.receivedAt,
      senderId: provider.label,
      transactionId: extractTransactionId(sms.body),
      confidence: 0.74,
    );
  }
}

class AbBankSmsParser extends ProviderSmsParser {
  const AbBankSmsParser();

  @override
  SmsFinancialProvider get provider => SmsFinancialProvider.abBank;

  @override
  bool matchesSender(String sender) {
    final normalized = normalizeSender(sender);
    return normalized.contains('abbank') ||
        normalized.contains('abb') ||
        normalized.contains('abbankltd');
  }

  @override
  ParsedSmsTransaction? parse(RawSmsMessage sms) {
    if (!matchesSender(sms.sender)) return null;
    final direction = directionFromText(sms.body);
    final amount = extractAmount(sms.body);
    if (direction == null || amount == null) return null;
    return ParsedSmsTransaction(
      provider: provider,
      amount: amount,
      direction: direction,
      reason: reasonFromText(sms.body, direction),
      newBalance: extractBalance(sms.body),
      occurredAt: sms.receivedAt,
      senderId: provider.label,
      transactionId: extractTransactionId(sms.body),
      confidence: 0.8,
    );
  }
}
