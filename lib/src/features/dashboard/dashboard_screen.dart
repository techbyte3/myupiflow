import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/core/utils/date_utils.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';
import 'package:myupiflow/src/providers/transaction_provider.dart';
import 'package:myupiflow/src/routes.dart';
import 'package:myupiflow/src/services/auth_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _updateLastActiveTime();
  }

  Future<void> _updateLastActiveTime() async {
    await AuthService.updateLastActiveTime();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMonth = AppDateUtils.getDateRange('this month');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(refreshTransactionsProvider)();
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: theme.colorScheme.surface,
                elevation: 0,
                floating: true,
                pinned: false,
                title: Text(
                  Config.appName,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => context.go(Routes.debug),
                    icon: Icon(
                      Icons.bug_report_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    tooltip: 'Debug Tools',
                  ),
                  IconButton(
                    onPressed: () => context.go(Routes.settings),
                    icon: Icon(
                      Icons.settings_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    tooltip: 'Settings',
                  ),
                ],
              ),

              // Dashboard Content
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary Cards
                    _SummarySection(dateRange: currentMonth),

                    const SizedBox(height: 24),

                    // Quick Actions
                    const _QuickActionsSection(),

                    const SizedBox(height: 24),

                    // Recent Transactions
                    const _RecentTransactionsSection(),

                    const SizedBox(height: 24),

                    // Top Merchants
                    _TopMerchantsSection(dateRange: currentMonth),

                    const SizedBox(height: 24),

                    // Spending Chart
                    _SpendingChartSection(dateRange: currentMonth),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('${Routes.transactions}/form'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummarySection extends ConsumerWidget {
  final DateTimeRange dateRange;

  const _SummarySection({required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(transactionSummaryProvider(dateRange));

    return summaryAsync.when(
      data: (summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Balance',
                  amount: summary.balance,
                  icon: Icons.account_balance_wallet_outlined,
                  color: summary.balance >= 0
                      ? const Color(0xFF2E7D6C)
                      : const Color(0xFFE53E3E),
                  isBalance: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Income',
                  amount: summary.totalIncome,
                  icon: Icons.trending_up_outlined,
                  color: const Color(0xFF2E7D6C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Expense',
                  amount: summary.totalExpense,
                  icon: Icons.trending_down_outlined,
                  color: const Color(0xFFE53E3E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Transactions',
                  amount: summary.transactionCount.toDouble(),
                  icon: Icons.receipt_outlined,
                  color: const Color(0xFF4A90B8),
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const _SummarySkeleton(),
      error: (error, stack) =>
          _ErrorCard(message: 'Failed to load summary: $error'),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isBalance;
  final bool isCount;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.isBalance = false,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isCount
                ? amount.toInt().toString()
                : '${isBalance && amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isBalance ? color : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Add Transaction',
                subtitle: 'Manual entry',
                icon: Icons.add_circle_outline,
                color: const Color(0xFF2E7D6C),
                onTap: () => context.go('${Routes.transactions}/form'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Parse SMS',
                subtitle: 'From clipboard',
                icon: Icons.message_outlined,
                color: const Color(0xFF4A90B8),
                onTap: () => context.go(Routes.pasteParser),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'View All',
                subtitle: 'Transactions',
                icon: Icons.list_outlined,
                color: const Color(0xFF6B4FA0),
                onTap: () => context.go(Routes.transactions),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Export Data',
                subtitle: 'Backup',
                icon: Icons.download_outlined,
                color: const Color(0xFFE67E22),
                onTap: () => context.go(Routes.settings),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () => context.go(Routes.transactions),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recentTransactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return _EmptyTransactions();
            }
            return Column(
              children: transactions.take(5).map((transaction) {
                return _TransactionTile(transaction: transaction);
              }).toList(),
            );
          },
          loading: () => const _TransactionsSkeleton(),
          error: (error, stack) =>
              _ErrorCard(message: 'Failed to load transactions: $error'),
        ),
      ],
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
          ),
          child: Row(
            children: [
              // Transaction icon
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

              // Transaction details
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
                        Text(
                          transaction.category ?? 'Other',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const Text(' • '),
                        Text(
                          transaction.dateTime.relativeTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                transaction.formattedAmount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse(
                      transaction.typeColor.replaceFirst('#', '0xFF'))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopMerchantsSection extends ConsumerWidget {
  final DateTimeRange dateRange;

  const _TopMerchantsSection({required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topMerchantsAsync = ref.watch(topMerchantsProvider(dateRange));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Merchants',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        topMerchantsAsync.when(
          data: (merchants) {
            if (merchants.isEmpty) {
              return _EmptyMerchants();
            }
            return Column(
              children: merchants.map((merchant) {
                return _MerchantTile(merchant: merchant);
              }).toList(),
            );
          },
          loading: () => const _MerchantsSkeleton(),
          error: (error, stack) =>
              _ErrorCard(message: 'Failed to load merchants: $error'),
        ),
      ],
    );
  }
}

class _MerchantTile extends StatelessWidget {
  final Map<String, dynamic> merchant;

  const _MerchantTile({required this.merchant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              merchant['name'] as String,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            merchant['formattedAmount'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE53E3E),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingChartSection extends ConsumerWidget {
  final DateTimeRange dateRange;

  const _SpendingChartSection({required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailySpendingAsync = ref.watch(dailySpendingProvider(dateRange));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Spending',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        dailySpendingAsync.when(
          data: (data) => _SpendingChart(data: data),
          loading: () => const _ChartSkeleton(),
          error: (error, stack) =>
              _ErrorCard(message: 'Failed to load chart: $error'),
        ),
      ],
    );
  }
}

class _SpendingChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _SpendingChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No spending data available'),
        ),
      );
    }

    final maxAmount = data.isNotEmpty
        ? data.map((d) => d['amount'] as double).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.map((dayData) {
          final amount = dayData['amount'] as double;
          final height = maxAmount > 0 ? (amount / maxAmount) * 150 : 0.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: height.clamp(4.0, 150.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90B8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateTime.parse(dayData['date']).day.toString(),
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Skeleton and empty state widgets
class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SkeletonCard()),
            const SizedBox(width: 12),
            Expanded(child: _SkeletonCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SkeletonCard()),
            const SizedBox(width: 12),
            Expanded(child: _SkeletonCard()),
          ],
        ),
      ],
    );
  }
}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) => _SkeletonCard()).toList(),
    );
  }
}

class _MerchantsSkeleton extends StatelessWidget {
  const _MerchantsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) => _SkeletonCard()).toList(),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyMerchants extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.store_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No merchants data',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
