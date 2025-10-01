import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/core/utils/date_utils.dart';
import 'package:myupiflow/src/data/db/app_database.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';
import 'package:myupiflow/src/services/ml_service.dart';

class TransactionRepository {
  final AppDatabase _database;
  final MLService _mlService;

  TransactionRepository({
    AppDatabase? database,
    MLService? mlService,
  })  : _database = database ?? AppDatabase(),
        _mlService = mlService ?? MLService();

  // Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    return _database.getAllTransactions();
  }

  // Get transaction by ID
  Future<Transaction?> getTransactionById(String id) async {
    return _database.getTransactionById(id);
  }

  // Add new transaction
  Future<String> addTransaction(Transaction transaction) async {
    await _database.insertTransaction(transaction);
    return transaction.id;
  }

  // Update existing transaction
  Future<bool> updateTransaction(Transaction transaction) async {
    return _database.updateTransaction(transaction.id, transaction);
  }

  // Delete transaction
  Future<bool> deleteTransaction(String id) async {
    return _database.deleteTransaction(id);
  }

  /// Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _database.getTransactionsByDateRange(start, end);
  }

  /// Search transactions
  Future<List<Transaction>> searchTransactions(String query) async {
    return _database.searchTransactions(query);
  }

  /// Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory(String category) async {
    return _database.getTransactionsByCategory(category);
  }

  /// Get transactions by type
  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    return _database.getTransactionsByType(type.name);
  }

  /// Parse SMS and create transaction
  Future<Transaction> parseAndCreateTransaction(String smsContent) async {
    final parsed = await _mlService.parseText(smsContent);
    final transaction = parsed.toTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rawMessage: smsContent,
    );

    await addTransaction(transaction);
    return transaction;
  }

  /// Get transaction statistics
  Future<TransactionSummary> getTransactionSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? AppDateUtils.startOfMonth(DateTime.now());
    final end = endDate ?? AppDateUtils.endOfMonth(DateTime.now());

    final transactions = await getTransactionsByDateRange(start, end);

    double totalIncome = 0;
    double totalExpense = 0;
    final categoryMap = <String, CategorySummary>{};

    for (final transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          totalIncome += transaction.amount;
          break;
        case TransactionType.expense:
          totalExpense += transaction.amount;
          break;
        case TransactionType.transfer:
          // Transfers are neutral for balance calculation
          break;
      }

      // Update category breakdown
      final category = transaction.category ?? 'Other';
      if (categoryMap.containsKey(category)) {
        final existing = categoryMap[category]!;
        categoryMap[category] = CategorySummary(
          category: category,
          amount: existing.amount + transaction.amount,
          count: existing.count + 1,
          percentage: existing.percentage, // Will be calculated later
        );
      } else {
        categoryMap[category] = CategorySummary(
          category: category,
          amount: transaction.amount,
          count: 1,
          percentage: 0, // Will be calculated later
        );
      }
    }

    // Calculate percentages
    final totalCategoryAmount = totalExpense; // For expense categories
    final categoryBreakdown = categoryMap.values.map((summary) {
      final percentage = totalCategoryAmount > 0
          ? (summary.amount / totalCategoryAmount) * 100
          : 0.0;
      return CategorySummary(
        category: summary.category,
        amount: summary.amount,
        count: summary.count,
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return TransactionSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      transactionCount: transactions.length,
      periodStart: start,
      periodEnd: end,
      categoryBreakdown: categoryBreakdown,
    );
  }

  /// Get recent transactions
  Future<List<Transaction>> getRecentTransactions([int limit = 10]) async {
    final allTransactions = await getAllTransactions();
    return allTransactions.take(limit).toList();
  }

  /// Get top merchants
  Future<List<Map<String, dynamic>>> getTopMerchants({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
  }) async {
    final start = startDate ?? AppDateUtils.startOfMonth(DateTime.now());
    final end = endDate ?? AppDateUtils.endOfMonth(DateTime.now());

    final transactions = await getTransactionsByDateRange(start, end);
    final merchantMap = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.merchantName != null &&
          transaction.type == TransactionType.expense) {
        merchantMap[transaction.merchantName!] =
            (merchantMap[transaction.merchantName!] ?? 0) + transaction.amount;
      }
    }

    final sortedMerchants = merchantMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMerchants
        .take(limit)
        .map((entry) => {
              'name': entry.key,
              'amount': entry.value,
              'formattedAmount': '₹${entry.value.toStringAsFixed(2)}',
            })
        .toList();
  }

  /// Get spending by day for charts
  Future<List<Map<String, dynamic>>> getDailySpending({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? AppDateUtils.startOfMonth(DateTime.now());
    final end = endDate ?? AppDateUtils.endOfMonth(DateTime.now());

    final transactions = await getTransactionsByDateRange(start, end);
    final dailyMap = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        final day = AppDateUtils.formatForStorage(transaction.dateTime);
        dailyMap[day] = (dailyMap[day] ?? 0) + transaction.amount;
      }
    }

    return dailyMap.entries
        .map((entry) => {
              'date': entry.key,
              'amount': entry.value,
            })
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// Clear all transactions (for testing)
  Future<void> clearAllTransactions() async {
    await _database.clearAllTransactions();
  }

  /// Generate mock data for demo
  Future<void> generateMockData() async {
    if (!Config.useMockData) return;

    final mockTransactions = _generateMockTransactions();
    for (final transaction in mockTransactions) {
      await addTransaction(transaction);
    }
  }

  /// Generate realistic mock transactions for demo
  List<Transaction> _generateMockTransactions() {
    // ...existing code...
    final transactions = <Transaction>[];

    final mockData = [
      // Recent transactions (last 7 days)
      _createMockTransaction(
        id: '1',
        amount: 450.00,
        description: 'Lunch at Zomato',
        merchantName: 'ZOMATO',
        category: 'Food',
        type: TransactionType.expense,
        daysAgo: 0,
      ),
      _createMockTransaction(
        id: '2',
        amount: 25000.00,
        description: 'Salary credit',
        merchantName: 'COMPANY LTD',
        category: 'Salary',
        type: TransactionType.income,
        daysAgo: 1,
      ),
      _createMockTransaction(
        id: '3',
        amount: 1200.00,
        description: 'Uber ride to airport',
        merchantName: 'UBER INDIA',
        category: 'Transport',
        type: TransactionType.expense,
        daysAgo: 2,
      ),
      _createMockTransaction(
        id: '4',
        amount: 2500.00,
        description: 'Amazon purchase',
        merchantName: 'AMAZON PAY',
        category: 'Shopping',
        type: TransactionType.expense,
        daysAgo: 3,
      ),
      _createMockTransaction(
        id: '5',
        amount: 150.00,
        description: 'Coffee at Starbucks',
        merchantName: 'STARBUCKS',
        category: 'Food',
        type: TransactionType.expense,
        daysAgo: 4,
      ),
      _createMockTransaction(
        id: '6',
        amount: 800.00,
        description: 'Grocery shopping',
        merchantName: 'BIG BAZAAR',
        category: 'Groceries',
        type: TransactionType.expense,
        daysAgo: 5,
      ),
      _createMockTransaction(
        id: '7',
        amount: 3000.00,
        description: 'Mutual fund SIP',
        merchantName: 'HDFC MF',
        category: 'Investment',
        type: TransactionType.expense,
        daysAgo: 6,
      ),
      _createMockTransaction(
        id: '8',
        amount: 500.00,
        description: 'Movie tickets',
        merchantName: 'BOOKMYSHOW',
        category: 'Entertainment',
        type: TransactionType.expense,
        daysAgo: 7,
      ),
      // Older transactions (this month)
      _createMockTransaction(
        id: '9',
        amount: 2000.00,
        description: 'Electricity bill',
        merchantName: 'BESCOM',
        category: 'Bills',
        type: TransactionType.expense,
        daysAgo: 15,
      ),
      _createMockTransaction(
        id: '10',
        amount: 5000.00,
        description: 'Freelance payment',
        merchantName: 'CLIENT ABC',
        category: 'Business',
        type: TransactionType.income,
        daysAgo: 20,
      ),
    ];

    transactions.addAll(mockData);
    return transactions;
  }

  Transaction _createMockTransaction({
    required String id,
    required double amount,
    required String description,
    required String merchantName,
    required String category,
    required TransactionType type,
    required int daysAgo,
  }) {
    final dateTime = DateTime.now().subtract(Duration(days: daysAgo));
    final now = DateTime.now();

    return Transaction(
      id: id,
      amount: amount,
      description: description,
      merchantName: merchantName,
      category: category,
      type: type,
      status: TransactionStatus.completed,
      dateTime: dateTime,
      upiId: '${merchantName.toLowerCase().replaceAll(' ', '')}@paytm',
      referenceNumber: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );
  }
}

// Type alias for Drift transaction to avoid naming conflicts
typedef DriftTransaction = Transaction;
