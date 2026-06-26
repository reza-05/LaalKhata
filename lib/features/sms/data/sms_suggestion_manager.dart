import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/sms_duplicate_detector.dart';
import '../domain/sms_parser.dart';
import '../domain/sms_transaction_models.dart';
import '../domain/sms_validator.dart';
import 'sms_platform_service.dart';

final smsSuggestionManagerProvider =
    StateNotifierProvider<SmsSuggestionManager, List<SmsTransactionSuggestion>>(
  (ref) => SmsSuggestionManager()..load(),
);

final smsPlatformServiceProvider = Provider<SmsPlatformService>((ref) {
  return const SmsPlatformService();
});

class SmsSuggestionManager
    extends StateNotifier<List<SmsTransactionSuggestion>> {
  SmsSuggestionManager({
    FlutterSecureStorage? secureStorage,
    SmsParser? parser,
    SmsTransactionValidator? validator,
    SmsDuplicateDetector? duplicateDetector,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _parser = parser ?? SmsParser(),
        _validator = validator ?? const SmsTransactionValidator(),
        _duplicateDetector = duplicateDetector ?? const SmsDuplicateDetector(),
        super(const []);

  final FlutterSecureStorage _secureStorage;
  final SmsParser _parser;
  final SmsTransactionValidator _validator;
  final SmsDuplicateDetector _duplicateDetector;

  static const _storageKey = 'local_sms_suggestions_v1';

  List<SmsTransactionSuggestion> get pending {
    return state
        .where((item) => item.status == SmsSuggestionStatus.pending)
        .toList();
  }

  List<SmsTransactionSuggestion> get ignored {
    return state
        .where((item) => item.status == SmsSuggestionStatus.ignored)
        .toList();
  }

  Future<void> load() async {
    final raw = await _secureStorage.read(key: _storageKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded
          .whereType<Map<String, dynamic>>()
          .map(SmsTransactionSuggestion.fromJson)
          .whereType<SmsTransactionSuggestion>()
          .toList();
    } catch (_) {
      state = const [];
    }
  }

  Future<int> scanMessages({
    required Iterable<RawSmsMessage> messages,
    required double? Function(String sourceName) currentBalanceForSource,
    required Iterable<ExistingTransactionSnapshot> existingTransactions,
  }) async {
    var added = 0;
    final next = [...state];

    for (final message in messages) {
      final parsed = _parser.parse(message);
      if (parsed == null) continue;

      final currentBalance =
          currentBalanceForSource(parsed.provider.defaultSourceName);
      final validation = _validator.validate(
        parsed: parsed,
        currentBalance: currentBalance,
      );
      if (!validation.isValid) continue;

      final duplicateWarning = _duplicateDetector.isLikelyDuplicate(
        parsed: parsed,
        pending: next,
        existingTransactions: existingTransactions,
      );

      final suggestion = SmsTransactionSuggestion(
        id: _stableId(parsed),
        provider: parsed.provider,
        amount: parsed.amount,
        direction: parsed.direction,
        reason: parsed.reason,
        sourceName: parsed.provider.defaultSourceName,
        detectedBalance: parsed.newBalance,
        occurredAt: parsed.occurredAt,
        senderId: parsed.senderId,
        transactionId: parsed.transactionId,
        confidence: (parsed.confidence + validation.confidenceBoost)
            .clamp(0.1, 0.99)
            .toDouble(),
        status: SmsSuggestionStatus.pending,
        createdAt: DateTime.now(),
        duplicateWarning: duplicateWarning,
      );

      if (next.any((item) => item.id == suggestion.id)) continue;
      next.add(suggestion);
      added++;
    }

    if (added > 0) {
      state = next;
      await _save();
    }
    return added;
  }

  Future<void> updateSuggestion(SmsTransactionSuggestion suggestion) async {
    state = [
      for (final item in state)
        if (item.id == suggestion.id) suggestion else item,
    ];
    await _save();
  }

  Future<void> ignoreSuggestion(String id) async {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(status: SmsSuggestionStatus.ignored)
        else
          item,
    ];
    await _save();
  }

  Future<void> removeSuggestion(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _save();
  }

  Future<void> _save() async {
    final serialized = jsonEncode(state.map((item) => item.toJson()).toList());
    await _secureStorage.write(key: _storageKey, value: serialized);
  }

  String _stableId(ParsedSmsTransaction parsed) {
    final trx = parsed.transactionId;
    if (trx != null && trx.trim().isNotEmpty) {
      return '${parsed.provider.name}:${trx.trim().toLowerCase()}';
    }
    final roundedMinute = parsed.occurredAt.millisecondsSinceEpoch ~/ 60000;
    return '${parsed.provider.name}:$roundedMinute:${parsed.amount.toStringAsFixed(2)}:${parsed.direction.name}';
  }
}
