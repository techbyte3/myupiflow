import 'dart:async';
import 'package:flutter/services.dart';

/// SMS Service for Android SMS parsing
/// This is a stub implementation for the MVP
/// TODO: Implement actual SMS parsing with platform channels
class SMSService {
  static const MethodChannel _channel = MethodChannel('upi_tracker/sms');

  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();

  final StreamController<String> _smsStreamController =
      StreamController<String>.broadcast();

  /// Stream of incoming SMS messages
  Stream<String> get smsStream => _smsStreamController.stream;

  /// Initialize SMS monitoring
  /// Returns true if SMS monitoring is supported and enabled
  Future<bool> initialize() async {
    try {
      // TODO: Implement platform channel for SMS monitoring
      // For MVP, this is a stub implementation

      // Set up method channel listener
      _channel.setMethodCallHandler(_handleMethodCall);

      return true;
    } catch (e) {
      print('SMS Service initialization failed: $e');
      return false;
    }
  }

  /// Handle method calls from platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSmsReceived':
        final String smsContent = call.arguments['content'] as String;
        _smsStreamController.add(smsContent);
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Check if SMS monitoring is available on this platform
  Future<bool> isAvailable() async {
    try {
      // TODO: Implement platform-specific availability check
      return await _channel.invokeMethod('isAvailable') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Start SMS monitoring
  Future<bool> startMonitoring() async {
    try {
      // TODO: Implement SMS monitoring start
      return await _channel.invokeMethod('startMonitoring') ?? false;
    } catch (e) {
      print('Failed to start SMS monitoring: $e');
      return false;
    }
  }

  /// Stop SMS monitoring
  Future<bool> stopMonitoring() async {
    try {
      // TODO: Implement SMS monitoring stop
      return await _channel.invokeMethod('stopMonitoring') ?? false;
    } catch (e) {
      print('Failed to stop SMS monitoring: $e');
      return false;
    }
  }

  /// Check if SMS monitoring is currently active
  Future<bool> isMonitoring() async {
    try {
      return await _channel.invokeMethod('isMonitoring') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get recent SMS messages (for manual processing)
  Future<List<String>> getRecentSMS({int limit = 50}) async {
    try {
      final List<dynamic> messages =
          await _channel.invokeMethod('getRecentSMS', {
                'limit': limit,
              }) ??
              [];

      return messages.cast<String>();
    } catch (e) {
      print('Failed to get recent SMS: $e');
      return [];
    }
  }

  /// Filter SMS messages that might be transaction-related
  List<String> filterTransactionSMS(List<String> messages) {
    final transactionKeywords = [
      'debited',
      'credited',
      'paid',
      'received',
      'upi',
      'transaction',
      'bank',
      'account',
      'balance',
      'rupees',
      'rs.',
      '₹',
      'paytm',
      'phonepe',
      'googlepay',
      'bhim',
      'ref',
      'reference'
    ];

    return messages.where((message) {
      final lowerMessage = message.toLowerCase();
      return transactionKeywords
          .any((keyword) => lowerMessage.contains(keyword));
    }).toList();
  }

  /// Dispose resources
  void dispose() {
    _smsStreamController.close();
  }

  /// Mock method to simulate SMS for testing
  void simulateSMS(String content) {
    _smsStreamController.add(content);
  }

  /// Get supported banks/services for SMS parsing
  List<String> getSupportedServices() {
    return [
      'State Bank of India',
      'HDFC Bank',
      'ICICI Bank',
      'Axis Bank',
      'Kotak Bank',
      'Yes Bank',
      'PNB',
      'Bank of Baroda',
      'Paytm',
      'PhonePe',
      'Google Pay',
      'BHIM',
      'Amazon Pay',
      'Mobikwik',
      'Freecharge',
    ];
  }
}

/// SMS Message model
class SMSMessage {
  final String content;
  final String sender;
  final DateTime timestamp;
  final bool isTransactionRelated;

  const SMSMessage({
    required this.content,
    required this.sender,
    required this.timestamp,
    required this.isTransactionRelated,
  });

  factory SMSMessage.fromMap(Map<String, dynamic> map) {
    return SMSMessage(
      content: map['content'] as String,
      sender: map['sender'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isTransactionRelated: map['isTransactionRelated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'sender': sender,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isTransactionRelated': isTransactionRelated,
    };
  }

  @override
  String toString() {
    return 'SMSMessage(sender: $sender, timestamp: $timestamp, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}
