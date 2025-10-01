import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myupiflow/src/routes.dart';
import 'package:myupiflow/src/services/ml_service.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';

class PasteParserScreen extends ConsumerStatefulWidget {
  const PasteParserScreen({super.key});

  @override
  ConsumerState<PasteParserScreen> createState() => _PasteParserScreenState();
}

class _PasteParserScreenState extends ConsumerState<PasteParserScreen> {
  final _smsController = TextEditingController();
  final _mlService = MLService();
  bool _isLoading = false;
  ParsedTransaction? _parsedResult;

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      setState(() {
        _smsController.text = clipboardData!.text!;
        _parsedResult = null;
      });
    }
  }

  Future<void> _parseSms() async {
    if (_smsController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _parsedResult = null;
    });

    try {
      final result = await _mlService.parseText(_smsController.text);
      setState(() {
        _parsedResult = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Parsing failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createTransaction() {
    if (_parsedResult == null) return;

    AppNavigation.toTransactionForm(
      context,
      smsContent: _smsController.text,
    );
  }

  void _clearAll() {
    setState(() {
      _smsController.clear();
      _parsedResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Parse SMS'),
        actions: [
          if (_smsController.text.isNotEmpty || _parsedResult != null)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paste or type a UPI transaction SMS to automatically extract transaction details.',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SMS Input
            Text(
              'SMS Content',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _smsController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Paste your UPI transaction SMS here...',
                border: const OutlineInputBorder(),
                suffixIcon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.content_paste),
                      tooltip: 'Paste from clipboard',
                    ),
                  ],
                ),
              ),
              onChanged: (_) {
                setState(() {
                  _parsedResult = null;
                });
              },
            ),

            const SizedBox(height: 16),

            // Parse Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _smsController.text.trim().isEmpty || _isLoading
                    ? null
                    : _parseSms,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Parsing...' : 'Parse SMS'),
              ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_parsedResult != null) ...[
              Text(
                'Parsed Results',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Confidence Score
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Confidence: ${(_parsedResult!.confidence * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _getConfidenceColor(_parsedResult!.confidence)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getConfidenceLabel(_parsedResult!.confidence),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getConfidenceColor(
                                  _parsedResult!.confidence),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Parsed Fields
                    if (_parsedResult!.amount != null)
                      _ResultField(
                        label: 'Amount',
                        value: '₹${_parsedResult!.amount!.toStringAsFixed(2)}',
                        icon: Icons.currency_rupee,
                      ),

                    if (_parsedResult!.merchantName != null)
                      _ResultField(
                        label: 'Merchant',
                        value: _parsedResult!.merchantName!,
                        icon: Icons.store,
                      ),

                    if (_parsedResult!.description != null)
                      _ResultField(
                        label: 'Description',
                        value: _parsedResult!.description!,
                        icon: Icons.description,
                      ),

                    if (_parsedResult!.type != null)
                      _ResultField(
                        label: 'Type',
                        value: _parsedResult!.type!.name.toUpperCase(),
                        icon: Icons.category,
                      ),

                    if (_parsedResult!.upiId != null)
                      _ResultField(
                        label: 'UPI ID',
                        value: _parsedResult!.upiId!,
                        icon: Icons.account_circle,
                      ),

                    if (_parsedResult!.referenceNumber != null)
                      _ResultField(
                        label: 'Reference',
                        value: _parsedResult!.referenceNumber!,
                        icon: Icons.confirmation_number,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _parseSms,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-parse'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _createTransaction,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Transaction'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.8) return 'HIGH';
    if (confidence >= 0.5) return 'MEDIUM';
    return 'LOW';
  }
}

class _ResultField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResultField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
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
