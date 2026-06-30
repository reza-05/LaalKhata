import 'package:flutter/material.dart';
import 'package:laalkhata/core/theme/app_colors.dart';
import 'package:laalkhata/features/ledger/domain/source_identity.dart';

enum SourceType {
  cash('Cash', Icons.payments_outlined),
  mobileBanking('Mobile Banking', Icons.account_balance_wallet_outlined),
  bank('Bank', Icons.account_balance_outlined),
  card('Card', Icons.credit_card_outlined),
  crypto('Crypto', Icons.currency_bitcoin_outlined),
  savings('Savings', Icons.savings_outlined),
  investment('Investment', Icons.trending_up_rounded),
  other('Other', Icons.wallet_outlined);

  const SourceType(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum EntryType {
  expense('Expense'),
  income('Income'),
  transfer('Transfer'),
  lent('Lent'),
  borrowed('Borrowed'),
  project('Project/List Item'),
  balanceAdjustment('Balance Adjustment');

  const EntryType(this.label);

  final String label;
}

class ManualEntry {
  const ManualEntry({
    required this.type,
    required this.reason,
    required this.sourceName,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    this.destinationSourceName,
  });

  final EntryType type;
  final String reason;
  final String sourceName;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String? destinationSourceName;
}

class MoneySource {
  MoneySource({
    required String name,
    required this.type,
    required this.balance,
    required this.color,
    required this.icon,
  }) : name = normalizeSourceDisplayName(
          name,
          typeName: type.name,
        );

  final String name;
  final SourceType type;
  double? balance;
  final Color color;
  final IconData icon;
  bool archived = false;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'balance': balance,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
      'archived': archived,
    };
  }

  static MoneySource? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.trim().isEmpty) return null;

    final type = SourceType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => SourceType.other,
    );
    final source = MoneySource(
      name: name,
      type: type,
      balance: (json['balance'] as num?)?.toDouble(),
      color: Color(
          (json['color'] as num?)?.toInt() ?? AppColors.primary.toARGB32()),
      icon: type.icon,
    );
    source.archived = json['archived'] == true;
    return source;
  }
}

class ActivityItem {
  const ActivityItem({
    required this.name,
    required this.source,
    required this.amount,
    required this.time,
    required this.icon,
    required this.occurredAt,
    required this.category,
    required this.type,
  });

  final String name;
  final String source;
  final double amount;
  final String time;
  final IconData icon;
  final DateTime occurredAt;
  final String category;
  final String type;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source,
      'amount': amount,
      'time': time,
      'icon': icon.codePoint,
      'occurredAt': occurredAt.toIso8601String(),
      'category': category,
      'type': type,
    };
  }

  static ActivityItem? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final source = json['source'] as String?;
    final amount = (json['amount'] as num?)?.toDouble();
    final occurredAt = DateTime.tryParse('${json['occurredAt']}');
    if (name == null ||
        source == null ||
        amount == null ||
        occurredAt == null) {
      return null;
    }

    return ActivityItem(
      name: name,
      source: source,
      amount: amount,
      time: json['time'] as String? ?? '',
      icon: Icons.receipt_long_outlined,
      occurredAt: occurredAt,
      category: json['category'] as String? ?? 'Others',
      type: json['type'] as String? ?? 'expense',
    );
  }
}

class BreakdownItem {
  const BreakdownItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

bool isExpenseActivity(ActivityItem activity) {
  return const {
    'expense',
    'lent',
    'project',
    'debit',
  }.contains(activity.type);
}

bool isIncomeActivity(ActivityItem activity) {
  return const {
    'income',
    'borrowed',
    'credit',
  }.contains(activity.type);
}

String formatMoney(double value) {
  final isNegative = value < 0;
  final rounded = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final reverseIndex = rounded.length - i;
    buffer.write(rounded[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
  }
  return '${isNegative ? '-' : ''}৳${buffer.toString()}';
}

class ShortfallResolution {
  const ShortfallResolution({
    required this.deficit,
    this.coverSource,
  });

  final double deficit;
  final MoneySource? coverSource;
}

class TransferRequest {
  const TransferRequest({
    required this.from,
    required this.to,
    required this.amount,
  });

  final MoneySource from;
  final MoneySource to;
  final double amount;
}

String formatActivityDate(DateTime occurredAt) {
  final localTime = occurredAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateOnly = DateTime(localTime.year, localTime.month, localTime.day);

  final hourStr = localTime.hour.toString().padLeft(2, '0');
  final minuteStr = localTime.minute.toString().padLeft(2, '0');
  final timeStr = '$hourStr:$minuteStr';

  if (dateOnly == today) {
    return 'Today, $timeStr';
  } else if (dateOnly == yesterday) {
    return 'Yesterday, $timeStr';
  } else {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[localTime.month - 1];
    return '${localTime.day} $monthStr ${localTime.year}, $timeStr';
  }
}
