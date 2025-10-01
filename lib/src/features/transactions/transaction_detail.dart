import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/core/utils/date_utils.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';
import 'package:myupiflow/src/providers/transaction_provider.dart';
import 'package:myupiflow/src/routes.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionByIdProvider(transactionId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Transaction Details'),
        actions: [
          transactionAsync.when(
            data: (transaction) => transaction != null
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          AppNavigation.toTransactionForm(
                            context,
                            transactionId: transaction.id,
                          );
                          break;
                        case 'delete':
                          _showDeleteDialog(context, ref, transaction);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 12),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: transactionAsync.when(
        data: (transaction) {
          if (transaction == null) {
            return const _TransactionNotFoundWidget();
          }
          return _TransactionDetailView(transaction: transaction);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorWidget(
          message: 'Failed to load transaction: $error',
          onRetry: () => ref.refresh(transactionByIdProvider(transactionId)),
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this transaction?\n\n${transaction.description}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(transactionCrudProvider.notifier)
                  .deleteTransaction(transaction.id);

              if (success && context.mounted) {
                ref.read(refreshTransactionsProvider)();
                context.pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TransactionDetailView extends StatefulWidget {
  final Transaction transaction;

  const _TransactionDetailView({required this.transaction});

  @override
  State<_TransactionDetailView> createState() => _TransactionDetailViewState();
}

class _TransactionDetailViewState extends State<_TransactionDetailView> {
  bool _showRawMessage = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaction = widget.transaction;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Card
          _AmountCard(transaction: transaction),

          const SizedBox(height: 24),

          // Transaction Details
          _DetailSection(
            title: 'Transaction Details',
            children: [
              _DetailRow(
                label: 'Description',
                value: transaction.description,
                icon: Icons.description_outlined,
              ),
              if (transaction.merchantName != null)
                _DetailRow(
                  label: 'Merchant',
                  value: transaction.merchantName!,
                  icon: Icons.store_outlined,
                ),
              if (transaction.category != null)
                _DetailRow(
                  label: 'Category',
                  value: transaction.category!,
                  icon: Icons.category_outlined,
                ),
              _DetailRow(
                label: 'Type',
                value: _getTypeDisplayName(transaction.type),
                icon: _getTypeIcon(transaction.type),
                valueColor: Color(
                    int.parse(transaction.typeColor.replaceFirst('#', '0xFF'))),
              ),
              _DetailRow(
                label: 'Status',
                value: _getStatusDisplayName(transaction.status),
                icon: _getStatusIcon(transaction.status),
                valueColor: Color(int.parse(
                    transaction.statusColor.replaceFirst('#', '0xFF'))),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Payment Details
          _DetailSection(
            title: 'Payment Details',
            children: [
              _DetailRow(
                label: 'Date & Time',
                value: transaction.dateTime.formattedWithTime,
                icon: Icons.access_time_outlined,
              ),
              if (transaction.upiId != null)
                _DetailRow(
                  label: 'UPI ID',
                  value: transaction.upiId!,
                  icon: Icons.account_circle_outlined,
                ),
              if (transaction.bankAccount != null)
                _DetailRow(
                  label: 'Bank Account',
                  value: transaction.bankAccount!,
                  icon: Icons.account_balance_outlined,
                ),
              if (transaction.referenceNumber != null)
                _DetailRow(
                  label: 'Reference Number',
                  value: transaction.referenceNumber!,
                  icon: Icons.confirmation_number_outlined,
                ),
              if (transaction.balanceAfter != null)
                _DetailRow(
                  label: 'Balance After',
                  value: '₹${transaction.balanceAfter!.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet_outlined,
                ),
            ],
          ),

          const SizedBox(height: 24),

          // System Information
          _DetailSection(
            title: 'System Information',
            children: [
              _DetailRow(
                label: 'Created',
                value: transaction.createdAt.formattedWithTime,
                icon: Icons.add_circle_outlined,
              ),
              if (transaction.createdAt != transaction.updatedAt)
                _DetailRow(
                  label: 'Last Modified',
                  value: transaction.updatedAt.formattedWithTime,
                  icon: Icons.edit_outlined,
                ),
              _DetailRow(
                label: 'Transaction ID',
                value: transaction.id,
                icon: Icons.tag_outlined,
                isMonospace: true,
              ),
            ],
          ),

          // Raw Message Section
          if (transaction.rawMessage != null) ...[
            const SizedBox(height: 24),
            _DetailSection(
              title: 'Raw Message',
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Show original SMS',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Switch(
                      value: _showRawMessage,
                      onChanged: (value) {
                        setState(() {
                          _showRawMessage = value;
                        });
                      },
                    ),
                  ],
                ),
                if (_showRawMessage) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      transaction.rawMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
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

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up_outlined;
      case TransactionType.expense:
        return Icons.trending_down_outlined;
      case TransactionType.transfer:
        return Icons.swap_horiz_outlined;
    }
  }

  String _getStatusDisplayName(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Icons.check_circle_outlined;
      case TransactionStatus.pending:
        return Icons.pending_outlined;
      case TransactionStatus.failed:
        return Icons.error_outline;
      case TransactionStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

class _AmountCard extends StatelessWidget {
  final Transaction transaction;

  const _AmountCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor =
        Color(int.parse(transaction.typeColor.replaceFirst('#', '0xFF')));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            typeColor.withValues(alpha: 0.1),
            typeColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Transaction Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                transaction.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Amount
          Text(
            transaction.formattedAmount,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            transaction.merchantName ?? transaction.description,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Date
          Text(
            transaction.dateTime.formattedWithTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final bool isMonospace;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: valueColor ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionNotFoundWidget extends StatelessWidget {
  const _TransactionNotFoundWidget();

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
              Icons.search_off_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Transaction Not Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The transaction you are looking for does not exist or has been deleted.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
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
