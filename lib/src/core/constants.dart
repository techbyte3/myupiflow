class Config {
  static const bool useMockData = true; // Toggle for demo mode
  static const String appName = 'myupiflow';
  static const String appVersion = '1.0.0';

  // Security constants
  static const int pinLength = 6;
  static const int autoLockTimeoutMinutes = 5;
  static const int maxFailedAttempts = 5;

  // Database constants
  static const String dbName = 'upi_tracker.db';
  static const int dbVersion = 1;

  // Encryption constants
  static const String encryptionKeyAlias = 'upi_tracker_key';
  static const String pinKeyAlias = 'user_pin';

  // Export constants
  static const String exportFileName = 'upi_transactions_export';
}

class Routes {
  static const String onboarding = '/onboarding';
  static const String permissionExplanation = '/permission-explanation';
  static const String pinSetup = '/pin-setup';
  static const String lockScreen = '/lock-screen';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String transactionDetail = '/transaction-detail';
  static const String transactionForm = '/transaction-form';
  static const String pasteParser = '/paste-parser';
  static const String settings = '/settings';
  static const String debug = '/debug';
}

class AppStrings {
  static const String privacyFirst = 'Privacy First';
  static const String localOnly = 'Your data stays on your device';
  static const String secureEncrypted = 'Encrypted & Secure';

  // Permission explanations
  static const String smsPermissionTitle = 'SMS Access Required';
  static const String smsPermissionDescription =
      'We need SMS access to automatically detect your UPI transactions from bank messages. This helps track your spending without manual entry.';

  static const String notificationPermissionTitle = 'Notification Access';
  static const String notificationPermissionDescription =
      'Allow us to read banking app notifications to capture transaction details automatically.';

  // Error messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String permissionDenied =
      'Permission denied. Please enable in settings.';
}

enum TransactionType { income, expense, transfer }

enum TransactionStatus { pending, completed, failed, cancelled }

enum AppTheme { light, dark, system }
