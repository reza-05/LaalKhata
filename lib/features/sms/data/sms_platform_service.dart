import 'package:flutter/services.dart';

import '../domain/sms_transaction_models.dart';

class SmsPermissionStatus {
  const SmsPermissionStatus({
    required this.granted,
    required this.canAsk,
  });

  final bool granted;
  final bool canAsk;
}

class SmsPlatformService {
  const SmsPlatformService();

  static const _channel = MethodChannel('laalkhata/sms');

  Future<SmsPermissionStatus> permissionStatus() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('permissionStatus');
      return SmsPermissionStatus(
        granted: result?['granted'] == true,
        canAsk: result?['canAsk'] != false,
      );
    } catch (_) {
      return const SmsPermissionStatus(granted: false, canAsk: true);
    }
  }

  Future<SmsPermissionStatus> requestPermission() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('requestPermission');
      return SmsPermissionStatus(
        granted: result?['granted'] == true,
        canAsk: result?['canAsk'] != false,
      );
    } catch (_) {
      return const SmsPermissionStatus(granted: false, canAsk: false);
    }
  }

  Future<List<RawSmsMessage>> readRecentSms({int limit = 80}) async {
    try {
      final result = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'readRecentSms',
        {'limit': limit},
      );

      return (result ?? [])
          .map((item) {
            final sender = item['sender'] as String?;
            final body = item['body'] as String?;
            final timestamp = item['timestamp'] as int?;
            if (sender == null || body == null || timestamp == null) {
              return null;
            }
            return RawSmsMessage(
              sender: sender,
              body: body,
              receivedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
            );
          })
          .whereType<RawSmsMessage>()
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
