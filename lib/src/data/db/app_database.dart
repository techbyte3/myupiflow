import 'dart:async';
import 'package:myupiflow/src/data/models/transaction_model.dart';
import 'package:myupiflow/src/data/db/simple_database.dart';

/// Lightweight AppDatabase wrapper that delegates to SimpleDatabase.
/// This avoids code-generation (Drift) while keeping the same app-facing API.
class AppDatabase {
  final SimpleDatabase _db = SimpleDatabase.instance;
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await _db.initialize();
      _initialized = true;
    }
  }

  // -------------------- Transactions --------------------
  Future<List<Transaction>> getAllTransactions() async {
    await _ensureInit();
    final list = await _db.getAllTransactions();
    // Sort by date desc to mimic SQL ordering used in UI
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<Transaction?> getTransactionById(String id) async {
    await _ensureInit();
    return _db.getTransactionById(id);
  }

  Future<void> insertTransaction(Transaction transaction) async {
    await _ensureInit();
    await _db.insertTransaction(transaction);
  }

  Future<bool> updateTransaction(String id, Transaction updated) async {
    await _ensureInit();
    return _db.updateTransaction(id, updated);
  }

  Future<bool> deleteTransaction(String id) async {
    await _ensureInit();
    return _db.deleteTransaction(id);
  }

  Future<List<Transaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) async {
    await _ensureInit();
    final list = await _db.getTransactionsByDateRange(start, end);
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<List<Transaction>> searchTransactions(String searchTerm) async {
    await _ensureInit();
    final list = await _db.searchTransactions(searchTerm);
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<List<Transaction>> getTransactionsByCategory(String category) async {
    await _ensureInit();
    final list = await _db.getTransactionsByCategory(category);
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<List<Transaction>> getTransactionsByType(String type) async {
    await _ensureInit();
    final list = await _db.getTransactionsByType(type);
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  // -------------------- Settings --------------------
  Future<String?> getSetting(String key) async {
    await _ensureInit();
    return _db.getSetting(key);
  }

  Future<void> setSetting(String key, String value) async {
    await _ensureInit();
    await _db.setSetting(key, value);
  }

  Future<Map<String, String>> getAllSettings() async {
    await _ensureInit();
    return _db.getAllSettings();
  }

  // -------------------- Categories --------------------
  Future<List<CategoryData>> getAllCategories() async {
    await _ensureInit();
    return _db.getAllCategories();
  }

  Future<void> addCategory(String name, {String? icon, String? color}) async {
    await _ensureInit();
    await _db.addCategory(name, icon: icon, color: color);
  }

  // -------------------- Analytics --------------------
  Future<double> getTotalBalance() async {
    await _ensureInit();
    return _db.getTotalBalance();
  }

  Future<Map<String, double>> getCategoryTotals(
      DateTime start, DateTime end) async {
    await _ensureInit();
    return _db.getCategoryTotals(start, end);
  }

  Future<Map<String, int>> getTransactionCounts() async {
    await _ensureInit();
    final txns = await _db.getAllTransactions();
    final counts = <String, int>{};
    for (final t in txns) {
      counts[t.type.name] = (counts[t.type.name] ?? 0) + 1;
    }
    return counts;
  }

  // -------------------- Data management --------------------
  Future<void> clearAllTransactions() async {
    await _ensureInit();
    await _db.clearAllTransactions();
  }

  Future<void> clearAllData() async {
    await _ensureInit();
    await _db.clearAllData();
  }

  Future<List<Map<String, dynamic>>> exportTransactions() async {
    await _ensureInit();
    return _db.exportTransactions();
  }

  // No-op close for API compatibility
  Future<void> close() async {}
}
