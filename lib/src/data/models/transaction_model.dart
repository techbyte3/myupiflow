import 'package:myupiflow/src/core/constants.dart';

class Transaction {
  final String id;
  final double amount;
  final String description;
  final String? merchantName;
  final String? category;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime dateTime;
  final String? upiId;
  final String? bankAccount;
  final String? referenceNumber;
  final String? rawMessage;
  final double? balanceAfter;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.description,
    this.merchantName,
    this.category,
    required this.type,
    required this.status,
    required this.dateTime,
    this.upiId,
    this.bankAccount,
    this.referenceNumber,
    this.rawMessage,
    this.balanceAfter,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    String? description,
    String? merchantName,
    String? category,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? dateTime,
    String? upiId,
    String? bankAccount,
    String? referenceNumber,
    String? rawMessage,
    double? balanceAfter,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      type: type ?? this.type,
      status: status ?? this.status,
      dateTime: dateTime ?? this.dateTime,
      upiId: upiId ?? this.upiId,
      bankAccount: bankAccount ?? this.bankAccount,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      rawMessage: rawMessage ?? this.rawMessage,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'merchantName': merchantName,
      'category': category,
      'type': type.name,
      'status': status.name,
      'dateTime': dateTime.toIso8601String(),
      'upiId': upiId,
      'bankAccount': bankAccount,
      'referenceNumber': referenceNumber,
      'rawMessage': rawMessage,
      'balanceAfter': balanceAfter,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      merchantName: json['merchantName'] as String?,
      category: json['category'] as String?,
      type: TransactionType.values.byName(json['type'] as String),
      status: TransactionStatus.values.byName(json['status'] as String),
      dateTime: DateTime.parse(json['dateTime'] as String),
      upiId: json['upiId'] as String?,
      bankAccount: json['bankAccount'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
      rawMessage: json['rawMessage'] as String?,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, description: $description, type: $type, status: $status, dateTime: $dateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Get formatted amount with currency symbol
  String get formattedAmount {
    final symbol = type == TransactionType.expense ? '-' : '+';
    return '$symbol₹${amount.toStringAsFixed(2)}';
  }

  /// Get transaction icon based on category and type
  String get icon {
    if (category != null) {
      switch (category!.toLowerCase()) {
        case 'food':
          return '🍽️';
        case 'transport':
          return '🚗';
        case 'shopping':
          return '🛍️';
        case 'entertainment':
          return '🎬';
        case 'bills':
          return '📄';
        case 'health':
          return '🏥';
        case 'education':
          return '📚';
        case 'investment':
          return '📈';
        case 'salary':
          return '💰';
        default:
          return _getDefaultIcon();
      }
    }
    return _getDefaultIcon();
  }

  String _getDefaultIcon() {
    switch (type) {
      case TransactionType.income:
        return '💰';
      case TransactionType.expense:
        return '💸';
      case TransactionType.transfer:
        return '🔄';
    }
  }

  /// Get color based on transaction type
  String get typeColor {
    switch (type) {
      case TransactionType.income:
        return '#2E7D6C'; // Green
      case TransactionType.expense:
        return '#E53E3E'; // Red
      case TransactionType.transfer:
        return '#4A90B8'; // Blue
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case TransactionStatus.completed:
        return '#2E7D6C'; // Green
      case TransactionStatus.pending:
        return '#F59E0B'; // Orange
      case TransactionStatus.failed:
        return '#E53E3E'; // Red
      case TransactionStatus.cancelled:
        return '#9CA3AF'; // Gray
    }
  }
}

/// Transaction parsing result from ML service
class ParsedTransaction {
  final double? amount;
  final String? merchantName;
  final String? description;
  final TransactionType? type;
  final DateTime? dateTime;
  final String? upiId;
  final String? referenceNumber;
  final String? bankAccount;
  final double confidence;
  final Map<String, dynamic>? metadata;

  const ParsedTransaction({
    this.amount,
    this.merchantName,
    this.description,
    this.type,
    this.dateTime,
    this.upiId,
    this.referenceNumber,
    this.bankAccount,
    required this.confidence,
    this.metadata,
  });

  /// Convert to Transaction object
  Transaction toTransaction({String? id, String? rawMessage}) {
    final now = DateTime.now();
    return Transaction(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount ?? 0.0,
      description: description ?? 'Unknown transaction',
      merchantName: merchantName,
      type: type ?? TransactionType.expense,
      status: TransactionStatus.completed,
      dateTime: dateTime ?? now,
      upiId: upiId,
      bankAccount: bankAccount,
      referenceNumber: referenceNumber,
      rawMessage: rawMessage,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'merchantName': merchantName,
      'description': description,
      'type': type?.name,
      'dateTime': dateTime?.toIso8601String(),
      'upiId': upiId,
      'referenceNumber': referenceNumber,
      'bankAccount': bankAccount,
      'confidence': confidence,
      'metadata': metadata,
    };
  }
}

/// Transaction summary for dashboard
class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<CategorySummary> categoryBreakdown;

  const TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
    required this.periodStart,
    required this.periodEnd,
    required this.categoryBreakdown,
  });

  double get netFlow => totalIncome - totalExpense;
  String get formattedBalance => '₹${balance.toStringAsFixed(2)}';
  String get formattedIncome => '₹${totalIncome.toStringAsFixed(2)}';
  String get formattedExpense => '₹${totalExpense.toStringAsFixed(2)}';
}

class CategorySummary {
  final String category;
  final double amount;
  final int count;
  final double percentage;

  const CategorySummary({
    required this.category,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
}
