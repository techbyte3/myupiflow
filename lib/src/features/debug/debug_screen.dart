import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/providers/settings_provider.dart';
import 'package:myupiflow/src/providers/transaction_provider.dart';
import 'package:myupiflow/src/services/ml_service.dart';
import 'package:myupiflow/src/services/storage_service.dart';
import 'package:myupiflow/src/services/auth_service.dart';
import 'package:myupiflow/src/core/utils/encryption_helper.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  bool _isGeneratingData = false;
  final _mlService = MLService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final debugSettings = ref.watch(debugSettingsProvider);
    final transactionStats = ref.watch(transactionStatsProvider);

    // Hide debug screen in production
    if (!Config.useMockData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug')),
        body: const Center(
          child: Text('Debug tools are only available in development mode.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Debug Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Status
          _DebugSection(
            title: 'App Status',
            children: [
              _DebugTile(
                title: 'Build Mode',
                subtitle: debugSettings['debug_mode'] ? 'Debug' : 'Release',
                trailing: Icon(
                  debugSettings['debug_mode']
                      ? Icons.bug_report
                      : Icons.verified,
                  color: debugSettings['debug_mode']
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
              _DebugTile(
                title: 'Mock Data',
                subtitle:
                    debugSettings['mock_data_enabled'] ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: debugSettings['mock_data_enabled'],
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setMockDataEnabled(value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Database Stats
          _DebugSection(
            title: 'Database Statistics',
            children: [
              transactionStats.when(
                data: (stats) => Column(
                  children: [
                    _DebugTile(
                      title: 'Total Transactions',
                      subtitle: stats['total_transactions']?.toString() ?? '0',
                      trailing: const Icon(Icons.receipt_long),
                    ),
                    _DebugTile(
                      title: 'Total Income',
                      subtitle:
                          '₹${stats['total_income']?.toStringAsFixed(2) ?? '0.00'}',
                      trailing: const Icon(Icons.trending_up),
                    ),
                    _DebugTile(
                      title: 'Total Expense',
                      subtitle:
                          '₹${stats['total_expense']?.toStringAsFixed(2) ?? '0.00'}',
                      trailing: const Icon(Icons.trending_down),
                    ),
                    _DebugTile(
                      title: 'Net Balance',
                      subtitle:
                          '₹${stats['net_balance']?.toStringAsFixed(2) ?? '0.00'}',
                      trailing: Icon(
                        Icons.account_balance_wallet,
                        color: (stats['net_balance'] ?? 0) >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                loading: () => const _DebugTile(
                  title: 'Loading...',
                  subtitle: 'Fetching database statistics',
                  trailing: CircularProgressIndicator(),
                ),
                error: (_, __) => const _DebugTile(
                  title: 'Error',
                  subtitle: 'Failed to load statistics',
                  trailing: Icon(Icons.error),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Management
          _DebugSection(
            title: 'Data Management',
            children: [
              _DebugTile(
                title: 'Generate Mock Data',
                subtitle: 'Add sample transactions for testing',
                trailing: _isGeneratingData
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                onTap: _isGeneratingData ? null : _generateMockData,
              ),
              _DebugTile(
                title: 'Clear All Transactions',
                subtitle: 'Delete all transaction data',
                trailing: const Icon(Icons.delete_outline),
                onTap: _showClearDataDialog,
              ),
              _DebugTile(
                title: 'Reset App State',
                subtitle: 'Clear all data and settings',
                trailing: const Icon(Icons.restore),
                onTap: _showResetDialog,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ML Service Info
          _DebugSection(
            title: 'ML Service',
            children: [
              _MLServiceInfo(),
            ],
          ),

          const SizedBox(height: 24),

          // Test SMS Parsing
          _DebugSection(
            title: 'SMS Parsing Test',
            children: [
              _SMSParsingTest(),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateMockData() async {
    setState(() {
      _isGeneratingData = true;
    });

    try {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.generateMockData();

      // Refresh all providers
      ref.read(refreshTransactionsProvider)();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock data generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate mock data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingData = false;
        });
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Transactions'),
        content: const Text(
          'This will delete all transaction data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final repository = ref.read(transactionRepositoryProvider);
                await repository.clearAllTransactions();
                ref.read(refreshTransactionsProvider)();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All transactions cleared!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to clear data: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App State'),
        content: const Text(
          'This will clear all data, settings, and authentication. The app will restart in initial setup mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final storage = StorageService();
                await storage.initialize();
                await storage.clearAll();
                await AuthService.clearAuthData();
                await EncryptionHelper.clearKeys();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'App state reset. Restart the app to re-onboard.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to reset: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _DebugSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DebugSection({
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
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DebugTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _DebugTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _MLServiceInfo extends StatefulWidget {
  @override
  State<_MLServiceInfo> createState() => _MLServiceInfoState();
}

class _MLServiceInfoState extends State<_MLServiceInfo> {
  final _mlService = MLService();
  Map<String, dynamic>? _modelInfo;

  @override
  void initState() {
    super.initState();
    _loadModelInfo();
  }

  void _loadModelInfo() {
    setState(() {
      _modelInfo = _mlService.getModelInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_modelInfo == null) {
      return const _DebugTile(
        title: 'Loading...',
        subtitle: 'Fetching ML service info',
        trailing: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        _DebugTile(
          title: 'Model Version',
          subtitle: _modelInfo!['version'] ?? 'Unknown',
          trailing: const Icon(Icons.model_training),
        ),
        _DebugTile(
          title: 'Model Type',
          subtitle: _modelInfo!['type'] ?? 'Unknown',
          trailing: const Icon(Icons.psychology),
        ),
        _DebugTile(
          title: 'Accuracy',
          subtitle: _modelInfo!['accuracy'] ?? 'Unknown',
          trailing: const Icon(Icons.analytics),
        ),
      ],
    );
  }
}

class _SMSParsingTest extends StatefulWidget {
  @override
  State<_SMSParsingTest> createState() => _SMSParsingTestState();
}

class _SMSParsingTestState extends State<_SMSParsingTest> {
  final _testSmsController = TextEditingController();
  final _mlService = MLService();
  bool _isParsing = false;
  String? _parseResult;

  final String _sampleSms =
      'Rs.450.00 debited from account XXXXXX1234 on 26-Sep-25 at ZOMATO BANGALORE using UPI Ref No 123456789012. Available bal: Rs.2550.00';

  @override
  void dispose() {
    _testSmsController.dispose();
    super.dispose();
  }

  Future<void> _testParsing() async {
    if (_testSmsController.text.trim().isEmpty) return;

    setState(() {
      _isParsing = true;
      _parseResult = null;
    });

    try {
      final result = await _mlService.parseText(_testSmsController.text);
      setState(() {
        _parseResult =
            'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%\n'
            'Amount: ${result.amount ?? 'Not found'}\n'
            'Merchant: ${result.merchantName ?? 'Not found'}\n'
            'Type: ${result.type?.name ?? 'Not found'}\n'
            'UPI ID: ${result.upiId ?? 'Not found'}';
      });
    } catch (e) {
      setState(() {
        _parseResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isParsing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Test SMS'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _testSmsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Paste SMS content here...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _testSmsController.text = _sampleSms;
                    },
                    child: const Text('Use Sample'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isParsing ? null : _testParsing,
                    child: _isParsing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Parse'),
                  ),
                ],
              ),
              if (_parseResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _parseResult!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
