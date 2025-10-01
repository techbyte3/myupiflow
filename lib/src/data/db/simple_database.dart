import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';

/// Simplified database implementation using SharedPreferences
/// This is a temporary solution for MVP compilation
/// TODO: Replace with proper Drift implementation after code generation
class SimpleDatabase {
  static SimpleDatabase? _instance;
  static SimpleDatabase get instance => _instance ??= SimpleDatabase._();

  SimpleDatabase._();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // Transaction operations
  Future<List<Transaction>> getAllTransactions() async {
    final json = prefs.getString('transactions') ?? '[]';
    final List<dynamic> data = jsonDecode(json);
    return data.map((item) => Transaction.fromJson(item)).toList();
  }

  Future<Transaction?> getTransactionById(String id) async {
    final transactions = await getAllTransactions();
    try {
      return transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> insertTransaction(Transaction transaction) async {
    final transactions = await getAllTransactions();
    transactions.add(transaction);
    await _saveTransactions(transactions);
  }

  Future<bool> updateTransaction(
      String id, Transaction updatedTransaction) async {
    final transactions = await getAllTransactions();
    final index = transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      transactions[index] = updatedTransaction;
      await _saveTransactions(transactions);
      return true;
    }
    return false;
  }

  Future<bool> deleteTransaction(String id) async {
    final transactions = await getAllTransactions();
    final index = transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      transactions.removeAt(index);
      await _saveTransactions(transactions);
      return true;
    }
    return false;
  }

  Future<void> _saveTransactions(List<Transaction> transactions) async {
    final json = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await prefs.setString('transactions', json);
  }

  Future<List<Transaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) async {
    final transactions = await getAllTransactions();
    return transactions
        .where((t) =>
            t.dateTime.isAfter(start.subtract(const Duration(days: 1))) &&
            t.dateTime.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  Future<List<Transaction>> searchTransactions(String query) async {
    final transactions = await getAllTransactions();
    final lowerQuery = query.toLowerCase();
    return transactions
        .where((t) =>
            t.description.toLowerCase().contains(lowerQuery) ||
            (t.merchantName?.toLowerCase().contains(lowerQuery) ?? false))
        .toList();
  }

  Future<List<Transaction>> getTransactionsByCategory(String category) async {
    final transactions = await getAllTransactions();
    return transactions.where((t) => t.category == category).toList();
  }

  Future<List<Transaction>> getTransactionsByType(String type) async {
    final transactions = await getAllTransactions();
    return transactions.where((t) => t.type.name == type).toList();
  }

  // Settings operations
  Future<String?> getSetting(String key) async {
    return prefs.getString('setting_$key');
  }

  Future<void> setSetting(String key, String value) async {
    await prefs.setString('setting_$key', value);
  }

  Future<Map<String, String>> getAllSettings() async {
    final keys = prefs.getKeys();
    final settings = <String, String>{};

    for (final key in keys) {
      if (key.startsWith('setting_')) {
        final settingKey = key.substring(8); // Remove 'setting_' prefix
        final value = prefs.getString(key);
        if (value != null) {
          settings[settingKey] = value;
        }
      }
    }

    return settings;
  }

  // Categories operations
  Future<List<CategoryData>> getAllCategories() async {
    final json = prefs.getString('categories') ?? '[]';
    if (json == '[]') {
      // Initialize with default categories
      await _initializeDefaultCategories();
      return await getAllCategories();
    }

    final List<dynamic> data = jsonDecode(json);
    return data.map((item) => CategoryData.fromJson(item)).toList();
  }

  Future<void> addCategory(String name, {String? icon, String? color}) async {
    final categories = await getAllCategories();
    categories.add(CategoryData(
      name: name,
      icon: icon,
      color: color,
      isDefault: false,
      createdAt: DateTime.now(),
    ));
    await _saveCategories(categories);
  }

  Future<void> _saveCategories(List<CategoryData> categories) async {
    final json = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString('categories', json);
  }

  Future<void> _initializeDefaultCategories() async {
    final defaultCategories = [
      CategoryData(
          name: 'Food & Dining',
          icon: '🍽️',
          color: '#FF6B6B',
          isDefault: true,
          createdAt: DateTime.now()),
      CategoryData(
          name: 'Transport',
          icon: '🚗',
          color: '#4ECDC4',
          isDefault: true,
          createdAt: DateTime.now()),
      CategoryData(
          name: 'Shopping',
          icon: '🛍️',
          color: '#45B7D1',
          isDefault: true,
          createdAt: DateTime.now()),
      CategoryData(
          name: 'Entertainment',
          icon: '🎬',
          color: '#96CEB4',
          isDefault: true,
          createdAt: DateTime.now()),
      CategoryData(
          name: 'Bills & Utilities',
          icon: '📄',
          color: '#FECA57',
          isDefault: true,
          createdAt: DateTime.now()),
      CategoryData(
          name: 'Health & Fitness',
          icon: '🏥',
          color: '#FF9FF3',
          isDefault: true,
          createdAt: DateTime.now()),
      CategoryData(
          name: 'Education',
          icon: '📚',
          color: '#54A0FF',
          isDefault: true,
          createdAt: DateTime.now()),
      CategoryData(
          name: 'Investment',
          icon: '📈',
          color: '#5F27CD',
          isDefault: true,
          createdAt: DateTime.now()),
      CategoryData(
          name: 'Salary',
          icon: '💰',
          color: '#00D2D3',
          isDefault: true,
          createdAt: DateTime.now()),
      CategoryData(
          name: 'Other',
          icon: '📌',
          color: '#808080',
          isDefault: true,
          createdAt: DateTime.now()),
    ];

    await _saveCategories(defaultCategories);
  }

  // Statistics
  Future<double> getTotalBalance() async {
    final transactions = await getAllTransactions();
    double income = 0;
    double expense = 0;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          income += transaction.amount;
          break;
        case TransactionType.expense:
          expense += transaction.amount;
          break;
        case TransactionType.transfer:
          // Transfers are neutral
          break;
      }
    }

    return income - expense;
  }

  Future<Map<String, double>> getCategoryTotals(
      DateTime start, DateTime end) async {
    final transactions = await getTransactionsByDateRange(start, end);
    final categoryTotals = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        final category = transaction.category ?? 'Other';
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + transaction.amount;
      }
    }

    return categoryTotals;
  }

  // Data management
  Future<void> clearAllTransactions() async {
    await prefs.remove('transactions');
  }

  Future<void> clearAllData() async {
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('setting_') ||
          key == 'transactions' ||
          key == 'categories') {
        await prefs.remove(key);
      }
    }
  }

  // Export
  Future<List<Map<String, dynamic>>> exportTransactions() async {
    final transactions = await getAllTransactions();
    return transactions.map((t) => t.toJson()).toList();
  }
}

// Simple category data class
class CategoryData {
  final String name;
  final String? icon;
  final String? color;
  final bool isDefault;
  final DateTime createdAt;

  const CategoryData({
    required this.name,
    this.icon,
    this.color,
    required this.isDefault,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon,
        'color': color,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CategoryData.fromJson(Map<String, dynamic> json) => CategoryData(
        name: json['name'] as String,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        isDefault: json['isDefault'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
