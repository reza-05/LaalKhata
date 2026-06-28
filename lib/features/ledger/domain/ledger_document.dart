class LedgerDocument {
  const LedgerDocument({
    required this.sources,
    required this.activities,
    required this.smsTransactionCutoffAt,
    required this.updatedAt,
  });

  final List<LedgerSourceRecord> sources;
  final List<LedgerActivityRecord> activities;
  final DateTime? smsTransactionCutoffAt;
  final DateTime updatedAt;

  factory LedgerDocument.fromJson(Map<String, dynamic> json) {
    final sources = _mapList(json['sources'], LedgerSourceRecord.fromJson);
    final activities =
        _mapList(json['activities'], LedgerActivityRecord.fromJson);

    return LedgerDocument(
      sources: sources,
      activities: activities,
      smsTransactionCutoffAt:
          DateTime.tryParse('${json['smsTransactionCutoffAt']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sources': sources.map((source) => source.toJson()).toList(),
      'activities': activities.map((activity) => activity.toJson()).toList(),
      'smsTransactionCutoffAt': smsTransactionCutoffAt?.toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  static List<T> _mapList<T>(
    Object? value,
    T? Function(Map<String, dynamic>) convert,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, nestedValue) => MapEntry('$key', nestedValue),
          ),
        )
        .map(convert)
        .whereType<T>()
        .toList();
  }
}

class LedgerSourceRecord {
  const LedgerSourceRecord({
    required this.name,
    required this.type,
    required this.balance,
    required this.colorValue,
    required this.iconCodePoint,
    required this.archived,
  });

  final String name;
  final String type;
  final double? balance;
  final int colorValue;
  final int iconCodePoint;
  final bool archived;

  String get stableKey => _stableText(name);

  static LedgerSourceRecord? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.trim().isEmpty) return null;

    return LedgerSourceRecord(
      name: name.trim(),
      type: '${json['type']}',
      balance: (json['balance'] as num?)?.toDouble(),
      colorValue: (json['color'] as num?)?.toInt() ?? 0,
      iconCodePoint: (json['icon'] as num?)?.toInt() ?? 0,
      archived: json['archived'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'color': colorValue,
      'icon': iconCodePoint,
      'archived': archived,
    };
  }
}

class LedgerActivityRecord {
  const LedgerActivityRecord({
    required this.name,
    required this.source,
    required this.amount,
    required this.displayTime,
    required this.iconCodePoint,
    required this.occurredAt,
    required this.category,
    required this.type,
  });

  final String name;
  final String source;
  final double amount;
  final String displayTime;
  final int iconCodePoint;
  final DateTime occurredAt;
  final String category;
  final String type;

  String stableKey(int occurrence) {
    final micros = occurredAt.toUtc().microsecondsSinceEpoch;
    return '$micros:${_stableText(source)}:${amount.toStringAsFixed(4)}:'
        '${_stableText(type)}:$occurrence';
  }

  static LedgerActivityRecord? fromJson(Map<String, dynamic> json) {
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

    return LedgerActivityRecord(
      name: name,
      source: source,
      amount: amount,
      displayTime: json['time'] as String? ?? '',
      iconCodePoint: (json['icon'] as num?)?.toInt() ?? 0,
      occurredAt: occurredAt,
      category: json['category'] as String? ?? 'Others',
      type: json['type'] as String? ?? 'expense',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source,
      'amount': amount,
      'time': displayTime,
      'icon': iconCodePoint,
      'occurredAt': occurredAt.toIso8601String(),
      'category': category,
      'type': type,
    };
  }
}

List<String> buildLedgerSourceKeys(List<LedgerSourceRecord> sources) {
  final occurrences = <String, int>{};
  return [
    for (final source in sources)
      _sourceKeyForOccurrence(
        source.stableKey.isEmpty ? 'source' : source.stableKey,
        occurrences,
      ),
  ];
}

String _sourceKeyForOccurrence(
  String baseKey,
  Map<String, int> occurrences,
) {
  final occurrence = occurrences.update(
    baseKey,
    (value) => value + 1,
    ifAbsent: () => 0,
  );
  return occurrence == 0 ? baseKey : '$baseKey:$occurrence';
}

String _stableText(String value) {
  final normalized = value.trim().toLowerCase();
  final collapsed = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
}
