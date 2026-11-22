import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SmsMessageModel {
  final String id;
  final String threadId;
  final String address;
  final String body;
  final int date;
  final int type; // 1 = inbox, 2 = sent
  final bool read;

  SmsMessageModel({
    required this.id,
    required this.threadId,
    required this.address,
    required this.body,
    required this.date,
    required this.type,
    required this.read,
  });

  factory SmsMessageModel.fromMap(Map<dynamic, dynamic> map) {
    return SmsMessageModel(
      id: map['id']?.toString() ?? '',
      threadId: map['threadId']?.toString() ?? '',
      address: map['address']?.toString() ?? 'Unknown',
      body: map['body']?.toString() ?? '',
      date: map['date'] is int ? map['date'] : int.tryParse(map['date']?.toString() ?? '0') ?? 0,
      type: map['type'] is int ? map['type'] : int.tryParse(map['type']?.toString() ?? '1') ?? 1,
      read: map['read'] == true,
    );
  }
}

class SmsChannel {
  static const MethodChannel _channel = MethodChannel('com.ktsms.app/sms');

  static Future<List<SmsMessageModel>> getSmsMessages() async {
    if (kIsWeb) {
      // Return realistic sample SMS messages for Web / GitHub Pages demonstration
      final now = DateTime.now().millisecondsSinceEpoch;
      return [
        SmsMessageModel(
          id: '1',
          threadId: 't1',
          address: 'HDFC-BANK',
          body: 'Your A/C X1234 has been debited by \$150.00 on 24-Oct-24 at Amazon. Avail Bal: \$2,450.00.',
          date: now - 3600000,
          type: 1,
          read: false,
        ),
        SmsMessageModel(
          id: '2',
          threadId: 't2',
          address: 'CITY-POWER',
          body: 'Your electricity bill of \$75.50 is due on Oct 28, 2024. Please pay online to avoid disconnection.',
          date: now - 7200000,
          type: 1,
          read: true,
        ),
        SmsMessageModel(
          id: '3',
          threadId: 't3',
          address: 'GOOGLE',
          body: 'G-849201 is your Google verification code. Do not share it with anyone.',
          date: now - 10800000,
          type: 1,
          read: false,
        ),
        SmsMessageModel(
          id: '4',
          threadId: 't4',
          address: 'AMAZON',
          body: 'Exclusive Offer! Get 50% off on your next purchase using code KT50. Valid till end of month.',
          date: now - 14400000,
          type: 1,
          read: true,
        ),
        SmsMessageModel(
          id: '5',
          threadId: 't5',
          address: 'John Doe',
          body: 'Hey! Are we still meeting for lunch tomorrow at 1 PM?',
          date: now - 18000000,
          type: 1,
          read: true,
        ),
      ];
    }

    try {
      final List<dynamic>? result = await _channel.invokeMethod('getSmsMessages');
      if (result == null) return [];
      return result.map((item) => SmsMessageModel.fromMap(item as Map<dynamic, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching SMS messages: $e');
      return [];
    }
  }

  static Future<bool> sendSms(String address, String body) async {
    if (kIsWeb) {
      debugPrint('Web simulation: Sending SMS to $address: $body');
      return true;
    }

    try {
      final bool? result = await _channel.invokeMethod('sendSms', {
        'address': address,
        'body': body,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }
}
