import 'dart:async';
import 'package:flutter/services.dart';

/// Notification Service for Android notification access
/// This is a stub implementation for the MVP
/// TODO: Implement actual notification parsing with platform channels
class NotificationService {
  static const MethodChannel _channel = MethodChannel('upi_tracker/notifications');
  
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<AppNotification> _notificationStreamController = 
      StreamController<AppNotification>.broadcast();
  
  /// Stream of incoming notifications
  Stream<AppNotification> get notificationStream => _notificationStreamController.stream;

  /// Initialize notification monitoring
  /// Returns true if notification monitoring is supported and enabled
  Future<bool> initialize() async {
    try {
      // TODO: Implement platform channel for notification monitoring
      // For MVP, this is a stub implementation
      
      // Set up method channel listener
      _channel.setMethodCallHandler(_handleMethodCall);
      
      return true;
    } catch (e) {
      print('Notification Service initialization failed: $e');
      return false;
    }
  }

  /// Handle method calls from platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationReceived':
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        final notification = AppNotification.fromMap(data);
        _notificationStreamController.add(notification);
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Check if notification access is available on this platform
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod('isAvailable') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if notification access permission is granted
  Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod('hasPermission') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request notification access permission
  /// This will open the system settings for notification access
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod('requestPermission') ?? false;
    } catch (e) {
      print('Failed to request notification permission: $e');
      return false;
    }
  }

  /// Start notification monitoring
  Future<bool> startMonitoring() async {
    try {
      return await _channel.invokeMethod('startMonitoring') ?? false;
    } catch (e) {
      print('Failed to start notification monitoring: $e');
      return false;
    }
  }

  /// Stop notification monitoring
  Future<bool> stopMonitoring() async {
    try {
      return await _channel.invokeMethod('stopMonitoring') ?? false;
    } catch (e) {
      print('Failed to stop notification monitoring: $e');
      return false;
    }
  }

  /// Check if notification monitoring is currently active
  Future<bool> isMonitoring() async {
    try {
      return await _channel.invokeMethod('isMonitoring') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Filter notifications that might be transaction-related
  bool isTransactionNotification(AppNotification notification) {
    final packageNames = getSupportedPackages();
    if (!packageNames.contains(notification.packageName)) {
      return false;
    }

    final transactionKeywords = [
      'paid', 'received', 'debited', 'credited', 'transaction', 'payment',
      'money', 'rupees', 'rs.', '₹', 'upi', 'transferred', 'sent', 'balance'
    ];

    final content = '${notification.title} ${notification.content}'.toLowerCase();
    return transactionKeywords.any((keyword) => content.contains(keyword));
  }

  /// Get list of supported payment app package names
  List<String> getSupportedPackages() {
    return [
      'net.one97.paytm', // Paytm
      'com.phonepe.app', // PhonePe
      'com.google.android.apps.nfc.payment', // Google Pay
      'in.org.npci.upiapp', // BHIM
      'in.amazon.mShop.android.shopping', // Amazon Pay
      'com.mobikwik_new', // MobiKwik
      'com.freecharge.android', // FreeCharge
      'com.axis.mobile', // Axis Mobile
      'com.snapwork.hdfc', // HDFC Bank
      'com.iciciappathon.iciciappathon', // iMobile ICICI
      'com.sbi.lotza.client', // YONO SBI
      'com.csam.icici.bank.imobile', // ICICI iMobile
    ];
  }

  /// Get display names for supported apps
  Map<String, String> getSupportedAppsDisplayNames() {
    return {
      'net.one97.paytm': 'Paytm',
      'com.phonepe.app': 'PhonePe',
      'com.google.android.apps.nfc.payment': 'Google Pay',
      'in.org.npci.upiapp': 'BHIM',
      'in.amazon.mShop.android.shopping': 'Amazon Pay',
      'com.mobikwik_new': 'MobiKwik',
      'com.freecharge.android': 'FreeCharge',
      'com.axis.mobile': 'Axis Mobile',
      'com.snapwork.hdfc': 'HDFC Bank',
      'com.iciciappathon.iciciappathon': 'iMobile ICICI',
      'com.sbi.lotza.client': 'YONO SBI',
      'com.csam.icici.bank.imobile': 'ICICI iMobile',
    };
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }

  /// Mock method to simulate notification for testing
  void simulateNotification(AppNotification notification) {
    _notificationStreamController.add(notification);
  }
}

/// App Notification model
class AppNotification {
  final String packageName;
  final String title;
  final String content;
  final DateTime timestamp;
  final Map<String, String>? extras;

  const AppNotification({
    required this.packageName,
    required this.title,
    required this.content,
    required this.timestamp,
    this.extras,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      packageName: map['packageName'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      extras: map['extras'] != null 
          ? Map<String, String>.from(map['extras'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'title': title,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'extras': extras,
    };
  }

  /// Get the display name for the app that sent this notification
  String get appDisplayName {
    final supportedApps = NotificationService().getSupportedAppsDisplayNames();
    return supportedApps[packageName] ?? packageName;
  }

  /// Get combined text content for parsing
  String get fullContent => '$title $content';

  @override
  String toString() {
    return 'AppNotification(app: $appDisplayName, title: $title, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.packageName == packageName &&
        other.title == title &&
        other.content == content &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(packageName, title, content, timestamp);
  }
}