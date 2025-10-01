import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/core/utils/date_utils.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';
import 'package:myupiflow/src/data/repositories/transaction_repository.dart';

/// Transaction Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// All Transactions Provider
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  final transactions = await repository.getAllTransactions();

  // Initialize with mock data if enabled and no transactions exist
  if (Config.useMockData && transactions.isEmpty) {
    await repository.generateMockData();
    return await repository.getAllTransactions();
  }

  return transactions;
});

/// Transaction Summary Provider
final transactionSummaryProvider =
    FutureProvider.family<TransactionSummary, DateTimeRange?>(
        (ref, dateRange) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.getTransactionSummary(
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});

/// Recent Transactions Provider
final recentTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.getRecentTransactions(10);
});

/// Top Merchants Provider
final topMerchantsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTimeRange?>(
        (ref, dateRange) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.getTopMerchants(
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});

/// Daily Spending Provider for Charts
final dailySpendingProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateTimeRange?>(
        (ref, dateRange) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.getDailySpending(
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});

/// Transaction Search State
class TransactionSearchState {
  final String query;
  final List<Transaction> results;
  final bool isLoading;
  final String? error;

  const TransactionSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  TransactionSearchState copyWith({
    String? query,
    List<Transaction>? results,
    bool? isLoading,
    String? error,
  }) {
    return TransactionSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Transaction Search Provider
class TransactionSearchNotifier extends StateNotifier<TransactionSearchState> {
  final TransactionRepository _repository;

  TransactionSearchNotifier(this._repository)
      : super(const TransactionSearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const TransactionSearchState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    try {
      final results = await _repository.searchTransactions(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearSearch() {
    state = const TransactionSearchState();
  }
}

final transactionSearchProvider =
    StateNotifierProvider<TransactionSearchNotifier, TransactionSearchState>(
        (ref) {
  final repository = ref.read(transactionRepositoryProvider);
  return TransactionSearchNotifier(repository);
});

/// Transaction Filter State
class TransactionFilterState {
  final DateTimeRange? dateRange;
  final String? category;
  final TransactionType? type;
  final double? minAmount;
  final double? maxAmount;
  final String? merchant;

  const TransactionFilterState({
    this.dateRange,
    this.category,
    this.type,
    this.minAmount,
    this.maxAmount,
    this.merchant,
  });

  TransactionFilterState copyWith({
    DateTimeRange? dateRange,
    String? category,
    TransactionType? type,
    double? minAmount,
    double? maxAmount,
    String? merchant,
  }) {
    return TransactionFilterState(
      dateRange: dateRange ?? this.dateRange,
      category: category ?? this.category,
      type: type ?? this.type,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      merchant: merchant ?? this.merchant,
    );
  }

  bool get hasActiveFilters {
    return dateRange != null ||
        category != null ||
        type != null ||
        minAmount != null ||
        maxAmount != null ||
        merchant != null;
  }

  /// Filter transactions based on current state
  List<Transaction> filterTransactions(List<Transaction> transactions) {
    var filtered = transactions;

    if (dateRange != null) {
      filtered = filtered
          .where((t) =>
              t.dateTime.isAfter(
                  dateRange!.start.subtract(const Duration(days: 1))) &&
              t.dateTime.isBefore(dateRange!.end.add(const Duration(days: 1))))
          .toList();
    }

    if (category != null) {
      filtered = filtered.where((t) => t.category == category).toList();
    }

    if (type != null) {
      filtered = filtered.where((t) => t.type == type).toList();
    }

    if (minAmount != null) {
      filtered = filtered.where((t) => t.amount >= minAmount!).toList();
    }

    if (maxAmount != null) {
      filtered = filtered.where((t) => t.amount <= maxAmount!).toList();
    }

    if (merchant != null && merchant!.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.merchantName?.toLowerCase().contains(merchant!.toLowerCase()) ==
              true)
          .toList();
    }

    return filtered;
  }
}

/// Transaction Filter Provider
class TransactionFilterNotifier extends StateNotifier<TransactionFilterState> {
  TransactionFilterNotifier() : super(const TransactionFilterState());

  void setDateRange(DateTimeRange? dateRange) {
    state = state.copyWith(dateRange: dateRange);
  }

  void setCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void setType(TransactionType? type) {
    state = state.copyWith(type: type);
  }

  void setAmountRange(double? minAmount, double? maxAmount) {
    state = state.copyWith(minAmount: minAmount, maxAmount: maxAmount);
  }

  void setMerchant(String? merchant) {
    state = state.copyWith(merchant: merchant);
  }

  void clearFilters() {
    state = const TransactionFilterState();
  }

  void setQuickFilter(String period) {
    final dateRange = AppDateUtils.getDateRange(period);
    setDateRange(dateRange);
  }
}

final transactionFilterProvider =
    StateNotifierProvider<TransactionFilterNotifier, TransactionFilterState>(
        (ref) {
  return TransactionFilterNotifier();
});

/// Filtered Transactions Provider
final filteredTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final allTransactions = await ref.watch(transactionsProvider.future);
  final filterState = ref.watch(transactionFilterProvider);

  return filterState.filterTransactions(allTransactions);
});

/// Transaction CRUD Operations
class TransactionCrudNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;

  TransactionCrudNotifier(this._repository)
      : super(const AsyncValue.data(null));

  Future<bool> addTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addTransaction(transaction);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.updateTransaction(transaction);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.deleteTransaction(id);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<Transaction?> parseTransaction(String smsContent) async {
    state = const AsyncValue.loading();
    try {
      final transaction =
          await _repository.parseAndCreateTransaction(smsContent);
      state = const AsyncValue.data(null);
      return transaction;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
}

final transactionCrudProvider =
    StateNotifierProvider<TransactionCrudNotifier, AsyncValue<void>>((ref) {
  final repository = ref.read(transactionRepositoryProvider);
  return TransactionCrudNotifier(repository);
});

/// Individual Transaction Provider
final transactionByIdProvider =
    FutureProvider.family<Transaction?, String>((ref, id) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.getTransactionById(id);
});

/// Refresh Transactions
final refreshTransactionsProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(transactionsProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(transactionSummaryProvider);
    ref.invalidate(topMerchantsProvider);
    ref.invalidate(dailySpendingProvider);
  };
});

/// Transaction Statistics Provider
final transactionStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  final transactions = await repository.getAllTransactions();

  if (transactions.isEmpty) return {};

  final totalTransactions = transactions.length;
  final totalIncome = transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
  final totalExpense = transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  final categoryStats = <String, Map<String, dynamic>>{};
  for (final transaction in transactions) {
    final category = transaction.category ?? 'Other';
    if (!categoryStats.containsKey(category)) {
      categoryStats[category] = {'count': 0, 'amount': 0.0};
    }
    categoryStats[category]!['count'] = categoryStats[category]!['count'] + 1;
    categoryStats[category]!['amount'] =
        categoryStats[category]!['amount'] + transaction.amount;
  }

  return {
    'total_transactions': totalTransactions,
    'total_income': totalIncome,
    'total_expense': totalExpense,
    'net_balance': totalIncome - totalExpense,
    'categories': categoryStats,
    'average_transaction': totalTransactions > 0
        ? (totalIncome + totalExpense) / totalTransactions
        : 0.0,
    'first_transaction': transactions.isNotEmpty
        ? transactions.last.dateTime.toIso8601String()
        : null,
    'last_transaction': transactions.isNotEmpty
        ? transactions.first.dateTime.toIso8601String()
        : null,
  };
});
