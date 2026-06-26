import 'provider_sms_parsers.dart';
import 'sms_transaction_models.dart';

class SmsParser {
  SmsParser({
    List<ProviderSmsParser>? providerParsers,
  }) : _providerParsers = providerParsers ??
            const [
              BkashSmsParser(),
              NagadSmsParser(),
              RocketSmsParser(),
              AbBankSmsParser(),
            ];

  final List<ProviderSmsParser> _providerParsers;

  static final _ignoredPatterns = RegExp(
    r'(gp|robi|banglalink|airtel|teletalk|internet package|bonus|minute offer|campaign|promotion|bundle|recharge|offer|spam)',
    caseSensitive: false,
  );

  ParsedSmsTransaction? parse(RawSmsMessage sms) {
    if (_shouldIgnore(sms)) return null;

    for (final parser in _providerParsers) {
      if (!parser.matchesSender(sms.sender)) continue;
      return parser.parse(sms);
    }

    return null;
  }

  bool isTrustedFinancialSender(String sender) {
    return _providerParsers.any((parser) => parser.matchesSender(sender));
  }

  bool _shouldIgnore(RawSmsMessage sms) {
    final content = '${sms.sender} ${sms.body}';
    if (_ignoredPatterns.hasMatch(content)) {
      final trustedSender = isTrustedFinancialSender(sms.sender);
      return !trustedSender;
    }
    return false;
  }
}
