import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/core/utils/date_utils.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';
import 'package:myupiflow/src/providers/transaction_provider.dart';
import 'package:myupiflow/src/routes.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(transactionSearchProvider.notifier).search(query);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(transactionSearchProvider.notifier).clearSearch();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(transactionSearchProvider);
    final filterState = ref.watch(transactionFilterProvider);
    final filteredTransactionsAsync = ref.watch(filteredTransactionsProvider);

    // Use search results if searching, otherwise use filtered transactions
    final transactionsToShow = searchState.query.isNotEmpty
        ? searchState.results
        : filteredTransactionsAsync.value ?? [];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Transactions'),
        actions: [
          IconButton(
            onPressed: _toggleFilters,
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: filterState.hasActiveFilters
                  ? theme.colorScheme.primary
                  : null,
            ),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                  ),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),

          // Filters
          if (_showFilters) _FilterSection(),

          // Transaction List
          Expanded(
            child: _TransactionList(
              transactions: transactionsToShow,
              isLoading:
                  searchState.isLoading || filteredTransactionsAsync.isLoading,
              error: searchState.error ??
                  filteredTransactionsAsync.error?.toString(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('${Routes.transactions}/form'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterState = ref.watch(transactionFilterProvider);
    final filterNotifier = ref.read(transactionFilterProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (filterState.hasActiveFilters)
                TextButton(
                  onPressed: () => filterNotifier.clearFilters(),
                  child: const Text('Clear All'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Date Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Today',
                'Yesterday',
                'This Week',
                'This Month',
                'Last Month',
                'Last 3 Months',
              ].map((period) {
                final isActive = filterState.dateRange != null &&
                    _isDateRangeForPeriod(filterState.dateRange!, period);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(period),
                    selected: isActive,
                    onSelected: (selected) {
                      if (selected) {
                        filterNotifier.setQuickFilter(period);
                      } else {
                        filterNotifier.setDateRange(null);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Transaction Type Filter
          Row(
            children: TransactionType.values.map((type) {
              final isSelected = filterState.type == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_getTypeDisplayName(type)),
                  selected: isSelected,
                  onSelected: (selected) {
                    filterNotifier.setType(selected ? type : null);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _isDateRangeForPeriod(DateTimeRange range, String period) {
    final expectedRange = AppDateUtils.getDateRange(period);
    return range.start.day == expectedRange.start.day &&
        range.start.month == expectedRange.start.month &&
        range.end.day == expectedRange.end.day &&
        range.end.month == expectedRange.end.month;
  }

  String _getTypeDisplayName(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}

class _TransactionList extends ConsumerWidget {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;

  const _TransactionList({
    required this.transactions,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _ErrorWidget(
        message: error!,
        onRetry: () => ref.read(refreshTransactionsProvider)(),
      );
    }

    if (transactions.isEmpty) {
      return const _EmptyTransactionsWidget();
    }

    // Group transactions by date
    final groupedTransactions = _groupTransactionsByDate(transactions);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(refreshTransactionsProvider)();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: groupedTransactions.length,
        itemBuilder: (context, index) {
          final dateKey = groupedTransactions.keys.elementAt(index);
          final dayTransactions = groupedTransactions[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              _DateHeader(date: dateKey),

              // Transactions for this date
              ...dayTransactions.map(
                  (transaction) => _TransactionTile(transaction: transaction)),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByDate(
      List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};

    for (final transaction in transactions) {
      final dateKey = DateTime(
        transaction.dateTime.year,
        transaction.dateTime.month,
        transaction.dateTime.day,
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    // Sort by date descending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <DateTime, List<Transaction>>{};

    for (final key in sortedKeys) {
      // Sort transactions within each date by time descending
      grouped[key]!.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = date.isToday;
    final isYesterday = date.difference(DateTime.now()).inDays == -1;

    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isYesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = date.formatted;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        dateText,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => AppNavigation.toTransactionDetail(context, transaction.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // Transaction Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(
                          transaction.typeColor.replaceFirst('#', '0xFF')))
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    transaction.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchantName ?? transaction.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (transaction.category != null) ...[
                          Text(
                            transaction.category!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const Text(' • '),
                        ],
                        Text(
                          AppDateUtils.formatTime(transaction.dateTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    if (transaction.status != TransactionStatus.completed) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(int.parse(transaction.statusColor
                                  .replaceFirst('#', '0xFF')))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          transaction.status.name.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse(transaction.statusColor
                                .replaceFirst('#', '0xFF'))),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Amount and Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.formattedAmount,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(int.parse(
                          transaction.typeColor.replaceFirst('#', '0xFF'))),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactionsWidget extends StatelessWidget {
  const _EmptyTransactionsWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Transactions Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start tracking your expenses by adding your first transaction or parsing an SMS.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('${Routes.transactions}/form'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Transaction'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go(Routes.pasteParser),
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Parse SMS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
