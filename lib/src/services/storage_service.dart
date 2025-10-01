import 'package:myupiflow/src/core/utils/encryption_helper.dart';
import 'package:myupiflow/src/data/db/app_database.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';

/// Storage Service for centralized data access
/// This service provides a unified interface for all storage operations
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late final AppDatabase _database;
  bool _isInitialized = false;

  /// Initialize the storage service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _database = AppDatabase();

      // Initialize encryption if not already done
      await EncryptionHelper.generateAndStoreKey();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Storage service initialization failed: $e');
    }
  }

  /// Get the database instance
  AppDatabase get database {
    if (!_isInitialized) {
      throw Exception(
          'Storage service not initialized. Call initialize() first.');
    }
    return _database;
  }

  /// Check if the storage service is initialized
  bool get isInitialized => _isInitialized;

  /// Store encrypted data
  Future<void> storeEncrypted(String key, String data) async {
    final encrypted = await EncryptionHelper.encrypt(data);
    await _database.setSetting(key, encrypted);
  }

  /// Retrieve and decrypt data
  Future<String?> retrieveEncrypted(String key) async {
    final encrypted = await _database.getSetting(key);
    if (encrypted == null) return null;

    try {
      return await EncryptionHelper.decrypt(encrypted);
    } catch (e) {
      // Return null if decryption fails (corrupted data)
      return null;
    }
  }

  /// Store plain text data (use with caution)
  Future<void> storePlain(String key, String data) async {
    await _database.setSetting(key, data);
  }

  /// Retrieve plain text data
  Future<String?> retrievePlain(String key) async {
    return await _database.getSetting(key);
  }

  /// Get all settings
  Future<Map<String, String>> getAllSettings() async {
    return await _database.getAllSettings();
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _database.clearAllData();
  }

  /// Get storage statistics
  Future<StorageStats> getStorageStats() async {
    final transactionCount = (await _database.getAllTransactions()).length;
    final categoryCount = (await _database.getAllCategories()).length;
    final settingsCount = (await _database.getAllSettings()).length;

    // Calculate approximate data size (rough estimate)
    final approximateSize =
        (transactionCount * 500) + // ~500 bytes per transaction
            (categoryCount * 100) + // ~100 bytes per category
            (settingsCount * 200); // ~200 bytes per setting

    return StorageStats(
      transactionCount: transactionCount,
      categoryCount: categoryCount,
      settingsCount: settingsCount,
      approximateSizeBytes: approximateSize,
    );
  }

  /// Perform database maintenance
  Future<void> performMaintenance() async {
    if (!_isInitialized) {
      await initialize();
    }

    // 1) Deduplicate transactions by id, keeping the most recently updated
    final all = await _database.getAllTransactions();
    final Map<String, Transaction> byId = {};
    for (final t in all) {
      final existing = byId[t.id];
      if (existing == null || t.updatedAt.isAfter(existing.updatedAt)) {
        byId[t.id] = t;
      }
    }
    if (byId.length != all.length) {
      await _database.clearAllTransactions();
      for (final t in byId.values) {
        await _database.insertTransaction(t);
      }
    }

    // 2) Ensure default categories are present (SimpleDatabase lazy-initializes on first access)
    await _database.getAllCategories();

    // 3) Light-touch settings cleanup: leave as-is since SimpleDatabase has no delete API
    //    This placeholder exists for future DB engines (e.g., Drift/Isar) where vacuum/indexing is meaningful.
  }

  /// Backup data to a string
  Future<String> backupData() async {
    final transactions = await _database.exportTransactions();
    final settings = await _database.getAllSettings();
    final categories = await _database.getAllCategories();

    final backup = {
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'transactions': transactions,
      'settings': settings,
      'categories': categories
          .map((c) => {
                'name': c.name,
                'icon': c.icon,
                'color': c.color,
                'isDefault': c.isDefault,
                'createdAt': c.createdAt.toIso8601String(),
              })
          .toList(),
    };

    return backup.toString(); // JSON string
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _database.close();
      _isInitialized = false;
    }
  }

  /// Health check for storage service
  Future<StorageHealthStatus> healthCheck() async {
    try {
      if (!_isInitialized) {
        return StorageHealthStatus(
          isHealthy: false,
          message: 'Storage service not initialized',
        );
      }

      // Test database connectivity
      await _database.getAllSettings();

      // Test encryption
      final testData = 'health_check_test_data';
      final encrypted = await EncryptionHelper.encrypt(testData);
      final decrypted = await EncryptionHelper.decrypt(encrypted);

      if (decrypted != testData) {
        return StorageHealthStatus(
          isHealthy: false,
          message: 'Encryption/decryption test failed',
        );
      }

      return StorageHealthStatus(
        isHealthy: true,
        message: 'All storage systems operational',
      );
    } catch (e) {
      return StorageHealthStatus(
        isHealthy: false,
        message: 'Health check failed: $e',
      );
    }
  }
}

/// Storage statistics model
class StorageStats {
  final int transactionCount;
  final int categoryCount;
  final int settingsCount;
  final int approximateSizeBytes;

  const StorageStats({
    required this.transactionCount,
    required this.categoryCount,
    required this.settingsCount,
    required this.approximateSizeBytes,
  });

  /// Get formatted size string
  String get formattedSize {
    if (approximateSizeBytes < 1024) {
      return '$approximateSizeBytes B';
    } else if (approximateSizeBytes < 1024 * 1024) {
      return '${(approximateSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(approximateSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() {
    return 'StorageStats(transactions: $transactionCount, categories: $categoryCount, settings: $settingsCount, size: $formattedSize)';
  }
}

/// Storage health status
class StorageHealthStatus {
  final bool isHealthy;
  final String message;
  final DateTime timestamp;

  StorageHealthStatus({
    required this.isHealthy,
    required this.message,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'StorageHealthStatus(healthy: $isHealthy, message: $message, time: $timestamp)';
  }
}

/// Storage service exceptions
class StorageException implements Exception {
  final String message;
  final dynamic originalException;

  const StorageException(this.message, [this.originalException]);

  @override
  String toString() {
    return 'StorageException: $message${originalException != null ? ' (caused by: $originalException)' : ''}';
  }
}

class StorageNotInitializedException extends StorageException {
  const StorageNotInitializedException()
      : super('Storage service not initialized');
}

class StorageEncryptionException extends StorageException {
  const StorageEncryptionException(super.message, [super.originalException]);
}
