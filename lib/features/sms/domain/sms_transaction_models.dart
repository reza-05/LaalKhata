enum SmsFinancialProvider {
  bkash('bKash', 'bKash'),
  nagad('Nagad', 'Nagad'),
  rocket('Rocket', 'Rocket'),
  abBank('AB Bank', 'AB Bank');

  const SmsFinancialProvider(this.label, this.defaultSourceName);

  final String label;
  final String defaultSourceName;
}

enum SmsTransactionDirection {
  credit('Income'),
  debit('Expense');

  const SmsTransactionDirection(this.label);

  final String label;
}

enum SmsSuggestionStatus {
  pending,
  ignored,
}

class RawSmsMessage {
  const RawSmsMessage({
    required this.sender,
    required this.body,
    required this.receivedAt,
  });

  final String sender;
  final String body;
  final DateTime receivedAt;
}

class ParsedSmsTransaction {
  const ParsedSmsTransaction({
    required this.provider,
    required this.amount,
    required this.direction,
    required this.reason,
    required this.newBalance,
    required this.occurredAt,
    required this.senderId,
    required this.confidence,
    this.transactionId,
  });

  final SmsFinancialProvider provider;
  final double amount;
  final SmsTransactionDirection direction;
  final String reason;
  final double? newBalance;
  final DateTime occurredAt;
  final String senderId;
  final String? transactionId;
  final double confidence;
}

class SmsTransactionSuggestion {
  const SmsTransactionSuggestion({
    required this.id,
    required this.provider,
    required this.amount,
    required this.direction,
    required this.reason,
    required this.sourceName,
    required this.detectedBalance,
    required this.occurredAt,
    required this.senderId,
    required this.confidence,
    required this.status,
    required this.createdAt,
    required this.duplicateWarning,
    this.transactionId,
  });

  final String id;
  final SmsFinancialProvider provider;
  final double amount;
  final SmsTransactionDirection direction;
  final String reason;
  final String sourceName;
  final double? detectedBalance;
  final DateTime occurredAt;
  final String senderId;
  final String? transactionId;
  final double confidence;
  final SmsSuggestionStatus status;
  final DateTime createdAt;
  final bool duplicateWarning;

  SmsTransactionSuggestion copyWith({
    double? amount,
    SmsTransactionDirection? direction,
    String? reason,
    String? sourceName,
    double? detectedBalance,
    SmsSuggestionStatus? status,
    bool? duplicateWarning,
  }) {
    return SmsTransactionSuggestion(
      id: id,
      provider: provider,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      reason: reason ?? this.reason,
      sourceName: sourceName ?? this.sourceName,
      detectedBalance: detectedBalance ?? this.detectedBalance,
      occurredAt: occurredAt,
      senderId: senderId,
      transactionId: transactionId,
      confidence: confidence,
      status: status ?? this.status,
      createdAt: createdAt,
      duplicateWarning: duplicateWarning ?? this.duplicateWarning,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider.name,
      'amount': amount,
      'direction': direction.name,
      'reason': reason,
      'sourceName': sourceName,
      'detectedBalance': detectedBalance,
      'occurredAt': occurredAt.toIso8601String(),
      'senderId': senderId,
      'transactionId': transactionId,
      'confidence': confidence,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'duplicateWarning': duplicateWarning,
    };
  }

  static SmsTransactionSuggestion? fromJson(Map<String, dynamic> json) {
    final provider = _enumByName(SmsFinancialProvider.values, json['provider']);
    final direction =
        _enumByName(SmsTransactionDirection.values, json['direction']);
    final status = _enumByName(SmsSuggestionStatus.values, json['status']);
    final occurredAt = DateTime.tryParse('${json['occurredAt']}');
    final createdAt = DateTime.tryParse('${json['createdAt']}');
    final amount = (json['amount'] as num?)?.toDouble();
    if (provider == null ||
        direction == null ||
        status == null ||
        occurredAt == null ||
        createdAt == null ||
        amount == null) {
      return null;
    }

    return SmsTransactionSuggestion(
      id: '${json['id']}',
      provider: provider,
      amount: amount,
      direction: direction,
      reason: '${json['reason']}',
      sourceName: '${json['sourceName']}',
      detectedBalance: (json['detectedBalance'] as num?)?.toDouble(),
      occurredAt: occurredAt,
      senderId: '${json['senderId']}',
      transactionId: json['transactionId'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.6,
      status: status,
      createdAt: createdAt,
      duplicateWarning: json['duplicateWarning'] == true,
    );
  }

  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
