import 'dart:convert';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/core/utils/encryption_helper.dart';
import 'package:myupiflow/src/data/db/app_database.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';
import 'package:myupiflow/src/services/export_saver.dart';
import 'package:myupiflow/src/services/file_loader.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final AppDatabase _database = AppDatabase();

  Future<ExportResult> exportAsEncryptedJson({
    required String password,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    TransactionType? type,
  }) async {
    try {
      final transactions = await _getFilteredTransactions(
        startDate: startDate,
        endDate: endDate,
        category: category,
        type: type,
      );

      final exportData = {
        'version': Config.appVersion,
        'exported_at': DateTime.now().toIso8601String(),
        'filters': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'category': category,
          'type': type?.name,
        },
        'transaction_count': transactions.length,
        'transactions':
            transactions.map((t) => _transactionToExportMap(t)).toList(),
        'categories': await _getCategories(),
        'settings': await _getExportSettings(),
      };

      final jsonData = jsonEncode(exportData);
      final encryptedData =
          EncryptionHelper.encryptForExport(jsonData, password);
      final saved = await saveStringToFile(encryptedData, 'json');

      return ExportResult(
        success: true,
        filePath: saved.path,
        fileSize: saved.size,
        transactionCount: transactions.length,
        format: ExportFormat.encryptedJson,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'Export failed: $e',
        transactionCount: 0,
        format: ExportFormat.encryptedJson,
      );
    }
  }

  Future<ExportResult> exportAsCSV({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    TransactionType? type,
  }) async {
    try {
      final transactions = await _getFilteredTransactions(
        startDate: startDate,
        endDate: endDate,
        category: category,
        type: type,
      );

      final csvData = _generateCSV(transactions);
      final saved = await saveStringToFile(csvData, 'csv');

      return ExportResult(
        success: true,
        filePath: saved.path,
        fileSize: saved.size,
        transactionCount: transactions.length,
        format: ExportFormat.csv,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'CSV export failed: $e',
        transactionCount: 0,
        format: ExportFormat.csv,
      );
    }
  }

  Future<ImportResult> importFromEncryptedJson({
    required String filePath,
    required String password,
    bool skipDuplicates = true,
  }) async {
    try {
      final encryptedData = await readFileString(filePath);
      final jsonData =
          EncryptionHelper.decryptFromExport(encryptedData, password);
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      if (data['version'] == null || data['transactions'] == null) {
        throw Exception('Invalid export file format');
      }

      final transactionData = data['transactions'] as List;
      int imported = 0;
      int skipped = 0;

      for (final transactionJson in transactionData) {
        try {
          final transaction = _transactionFromExportMap(
            Map<String, dynamic>.from(transactionJson as Map),
          );

          if (skipDuplicates) {
            final existing = await _database.getTransactionById(transaction.id);
            if (existing != null) {
              skipped++;
              continue;
            }
          }

          await _database.insertTransaction(transaction);
          imported++;
        } catch (_) {
          skipped++;
          continue;
        }
      }

      return ImportResult(
        success: true,
        importedCount: imported,
        skippedCount: skipped,
        totalCount: transactionData.length,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Import failed: $e',
        importedCount: 0,
        skippedCount: 0,
        totalCount: 0,
      );
    }
  }

  Future<List<Transaction>> _getFilteredTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    TransactionType? type,
  }) async {
    if (startDate != null && endDate != null) {
      return await _database.getTransactionsByDateRange(startDate, endDate);
    } else if (category != null) {
      return await _database.getTransactionsByCategory(category);
    } else if (type != null) {
      return await _database.getTransactionsByType(type.name);
    } else {
      return await _database.getAllTransactions();
    }
  }

  Future<List<Map<String, dynamic>>> _getCategories() async {
    final categories = await _database.getAllCategories();
    return categories
        .map((c) => {
              'name': c.name,
              'icon': c.icon,
              'color': c.color,
              'is_default': c.isDefault,
            })
        .toList();
  }

  Future<Map<String, dynamic>> _getExportSettings() async {
    final settings = await _database.getAllSettings();
    return {
      'currency': settings['currency'] ?? 'INR',
      'date_format': settings['date_format'] ?? 'dd/MM/yyyy',
      'app_version': Config.appVersion,
    };
  }

  Map<String, dynamic> _transactionToExportMap(Transaction transaction) {
    return {
      'id': transaction.id,
      'amount': transaction.amount,
      'description': transaction.description,
      'merchant_name': transaction.merchantName,
      'category': transaction.category,
      'type': transaction.type.name,
      'status': transaction.status.name,
      'date_time': transaction.dateTime.toIso8601String(),
      'upi_id': transaction.upiId,
      'bank_account': transaction.bankAccount,
      'reference_number': transaction.referenceNumber,
      'balance_after': transaction.balanceAfter,
      'created_at': transaction.createdAt.toIso8601String(),
      'updated_at': transaction.updatedAt.toIso8601String(),
    };
  }

  Transaction _transactionFromExportMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      merchantName: map['merchant_name'] as String?,
      category: map['category'] as String?,
      type: TransactionType.values.byName(map['type'] as String),
      status: TransactionStatus.values.byName(map['status'] as String),
      dateTime: DateTime.parse(map['date_time'] as String),
      upiId: map['upi_id'] as String?,
      bankAccount: map['bank_account'] as String?,
      referenceNumber: map['reference_number'] as String?,
      balanceAfter: (map['balance_after'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String _generateCSV(List<Transaction> transactions) {
    final buffer = StringBuffer();

    buffer.writeln(
        'ID,Date,Description,Merchant,Category,Type,Status,Amount,UPI_ID,Account,Reference,Balance_After,Created_At');

    for (final transaction in transactions) {
      buffer.writeln([
        _csvEscape(transaction.id),
        _csvEscape(transaction.dateTime.toIso8601String()),
        _csvEscape(transaction.description),
        _csvEscape(transaction.merchantName ?? ''),
        _csvEscape(transaction.category ?? ''),
        _csvEscape(transaction.type.name),
        _csvEscape(transaction.status.name),
        transaction.amount,
        _csvEscape(transaction.upiId ?? ''),
        _csvEscape(transaction.bankAccount ?? ''),
        _csvEscape(transaction.referenceNumber ?? ''),
        transaction.balanceAfter ?? '',
        _csvEscape(transaction.createdAt.toIso8601String()),
      ].join(','));
    }

    return buffer.toString();
  }

  String _csvEscape(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  Future<ExportStatistics> getExportStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await _getFilteredTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    double totalAmount = 0;
    final typeCounts = <String, int>{};
    final categoryCounts = <String, int>{};

    for (final transaction in transactions) {
      totalAmount += transaction.amount;

      typeCounts[transaction.type.name] =
          (typeCounts[transaction.type.name] ?? 0) + 1;

      final category = transaction.category ?? 'Other';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return ExportStatistics(
      totalTransactions: transactions.length,
      totalAmount: totalAmount,
      dateRange: startDate != null && endDate != null
          ? '${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}'
          : 'All time',
      typeCounts: typeCounts,
      categoryCounts: categoryCounts,
    );
  }
}

enum ExportFormat { encryptedJson, csv }

class ExportResult {
  final bool success;
  final String? filePath;
  final int? fileSize;
  final int transactionCount;
  final String? error;
  final ExportFormat format;

  const ExportResult({
    required this.success,
    this.filePath,
    this.fileSize,
    required this.transactionCount,
    this.error,
    required this.format,
  });

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) return '${fileSize!} B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ImportResult {
  final bool success;
  final int importedCount;
  final int skippedCount;
  final int totalCount;
  final String? error;

  const ImportResult({
    required this.success,
    required this.importedCount,
    required this.skippedCount,
    required this.totalCount,
    this.error,
  });

  double get successRate => totalCount > 0 ? importedCount / totalCount : 0.0;
}

class ExportStatistics {
  final int totalTransactions;
  final double totalAmount;
  final String dateRange;
  final Map<String, int> typeCounts;
  final Map<String, int> categoryCounts;

  const ExportStatistics({
    required this.totalTransactions,
    required this.totalAmount,
    required this.dateRange,
    required this.typeCounts,
    required this.categoryCounts,
  });

  String get formattedTotalAmount => '₹${totalAmount.toStringAsFixed(2)}';
}
