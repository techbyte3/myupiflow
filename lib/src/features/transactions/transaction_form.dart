import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';
import 'package:myupiflow/src/providers/transaction_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final String? smsContent;

  const TransactionFormScreen({
    super.key,
    this.transactionId,
    this.smsContent,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _categories = [
    'Food & Dining',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Health & Fitness',
    'Education',
    'Investment',
    'Salary',
    'Business',
    'Travel',
    'Groceries',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    if (widget.smsContent != null) {
      // Parse SMS content
      await _parseSmsContent();
    } else if (widget.transactionId != null) {
      // Load existing transaction
      await _loadTransaction();
    }
  }

  Future<void> _parseSmsContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = await ref
          .read(transactionCrudProvider.notifier)
          .parseTransaction(widget.smsContent!);

      if (transaction != null) {
        _populateFormFromTransaction(transaction);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse SMS: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTransaction() async {
    final transaction = await ref.read(
      transactionByIdProvider(widget.transactionId!).future,
    );

    if (transaction != null) {
      _populateFormFromTransaction(transaction);
    }
  }

  void _populateFormFromTransaction(Transaction transaction) {
    setState(() {
      _amountController.text = transaction.amount.toString();
      _descriptionController.text = transaction.description;
      _merchantController.text = transaction.merchantName ?? '';
      _selectedType = transaction.type;
      _selectedCategory = transaction.category;
      _selectedDate = transaction.dateTime;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final now = DateTime.now();

      final transaction = Transaction(
        id: widget.transactionId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        description: _descriptionController.text.trim(),
        merchantName: _merchantController.text.trim().isNotEmpty
            ? _merchantController.text.trim()
            : null,
        category: _selectedCategory,
        type: _selectedType,
        status: TransactionStatus.completed,
        dateTime: _selectedDate,
        createdAt: now,
        updatedAt: now,
      );

      bool success;
      if (widget.transactionId != null) {
        success = await ref
            .read(transactionCrudProvider.notifier)
            .updateTransaction(transaction);
      } else {
        success = await ref
            .read(transactionCrudProvider.notifier)
            .addTransaction(transaction);
      }

      if (success && mounted) {
        ref.read(refreshTransactionsProvider)();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transactionId != null
                ? 'Transaction updated successfully'
                : 'Transaction added successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.transactionId != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveTransaction,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Merchant Field
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant (Optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Transaction Type
            Text(
              'Transaction Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.trending_down),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.trending_up),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<TransactionType> selection) {
                setState(() {
                  _selectedType = selection.first;
                });
              },
            ),

            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Date Selection
            InkWell(
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );

                if (selectedDate != null) {
                  final selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDate),
                  );

                  if (selectedTime != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                    });
                  }
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date & Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _saveTransaction,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Transaction' : 'Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
