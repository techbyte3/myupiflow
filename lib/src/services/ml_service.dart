import 'dart:math' as math;
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';

/// ML Service for parsing transaction messages
/// This is a mock implementation using regex patterns
/// TODO: Replace with actual TensorFlow Lite model in production
class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  // Indian currency regex patterns
  static final List<RegExp> _amountPatterns = [
    RegExp(r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
    RegExp(r'₹\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
    RegExp(r'INR\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
    RegExp(r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*(?:rs|rupees)', caseSensitive: false),
  ];

  // UPI ID patterns
  static final List<RegExp> _upiPatterns = [
    RegExp(r'([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)', caseSensitive: false),
    RegExp(r'UPI ID:?\s*([a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+)',
        caseSensitive: false),
  ];

  // Reference number patterns
  static final List<RegExp> _refPatterns = [
    RegExp(
        r'(?:ref|reference|txn|transaction|utr)\.?\s*(?:no\.?|id\.?|#)?\s*:?\s*([a-zA-Z0-9]+)',
        caseSensitive: false),
    RegExp(r'([0-9]{12,16})', caseSensitive: false), // 12-16 digit numbers
  ];

  // Date and time patterns
  static final List<RegExp> _dateTimePatterns = [
    RegExp(
        r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\s*(?:at\s*)?(\d{1,2}:\d{2}(?::\d{2})?(?:\s*[AP]M)?)',
        caseSensitive: false),
    RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})', caseSensitive: false),
    RegExp(r'(\d{1,2}:\d{2}(?::\d{2})?(?:\s*[AP]M)?)', caseSensitive: false),
  ];

  // Bank account patterns
  static final List<RegExp> _accountPatterns = [
    RegExp(r'(?:a\/c|account|acc)\.?\s*(?:no\.?|#)?\s*:?\s*([x*]*\d{4,})',
        caseSensitive: false),
    RegExp(r'([x*]+\d{4})', caseSensitive: false),
  ];

  // Transaction type keywords
  static final Map<TransactionType, List<String>> _typeKeywords = {
    TransactionType.income: [
      'received',
      'credited',
      'deposit',
      'salary',
      'refund',
      'cashback',
      'bonus',
      'dividend',
      'interest',
      'payment received',
      'money added'
    ],
    TransactionType.expense: [
      'debited',
      'paid',
      'withdrawn',
      'purchase',
      'bought',
      'spending',
      'bill payment',
      'transfer to',
      'sent',
      'payment made',
      'charged'
    ],
    TransactionType.transfer: [
      'transferred',
      'transfer',
      'moved',
      'fund transfer'
    ],
  };

  // Common merchant patterns
  static final Map<String, List<String>> _merchantPatterns = {
    'Food': [
      'zomato',
      'swiggy',
      'ubereats',
      'foodpanda',
      'dominos',
      'pizza',
      'restaurant',
      'cafe',
      'food'
    ],
    'Transport': [
      'uber',
      'ola',
      'metro',
      'bus',
      'taxi',
      'petrol',
      'fuel',
      'parking'
    ],
    'Shopping': [
      'amazon',
      'flipkart',
      'myntra',
      'jabong',
      'shop',
      'store',
      'mall'
    ],
    'Entertainment': [
      'netflix',
      'spotify',
      'youtube',
      'movie',
      'cinema',
      'bookmyshow'
    ],
    'Bills': [
      'electricity',
      'water',
      'gas',
      'mobile',
      'broadband',
      'wifi',
      'recharge'
    ],
    'Investment': [
      'sip',
      'mutual fund',
      'share',
      'stock',
      'trading',
      'zerodha',
      'groww'
    ],
  };

  /// Parse SMS message to extract transaction details
  Future<ParsedTransaction> parseText(String message) async {
    try {
      // Clean the message
      final cleanedMessage = message.trim().replaceAll(RegExp(r'\s+'), ' ');

      // Extract various components
      final amount = _extractAmount(cleanedMessage);
      final upiId = _extractUpiId(cleanedMessage);
      final referenceNumber = _extractReferenceNumber(cleanedMessage);
      final bankAccount = _extractBankAccount(cleanedMessage);
      final dateTime = _extractDateTime(cleanedMessage);
      final type = _determineTransactionType(cleanedMessage);
      final merchantInfo = _extractMerchantInfo(cleanedMessage);

      // Calculate confidence based on extracted information
      double confidence = _calculateConfidence(
        amount: amount,
        upiId: upiId,
        referenceNumber: referenceNumber,
        type: type,
        merchantInfo: merchantInfo,
        message: cleanedMessage,
      );

      // Add some randomness to simulate ML uncertainty
      confidence = _addMLNoise(confidence);

      return ParsedTransaction(
        amount: amount,
        merchantName: merchantInfo['name'],
        description: _generateDescription(cleanedMessage, merchantInfo, type),
        type: type,
        dateTime: dateTime,
        upiId: upiId,
        referenceNumber: referenceNumber,
        bankAccount: bankAccount,
        confidence: confidence,
        metadata: {
          'category': merchantInfo['category'],
          'original_message': message,
          'extracted_keywords': _extractKeywords(cleanedMessage),
        },
      );
    } catch (e) {
      // Return low-confidence parsed transaction on error
      return ParsedTransaction(
        amount: 0.0,
        description:
            'Failed to parse: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
        type: TransactionType.expense,
        confidence: 0.1,
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Extract amount from message
  double? _extractAmount(String message) {
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
        return double.tryParse(amountStr);
      }
    }
    return null;
  }

  /// Extract UPI ID from message
  String? _extractUpiId(String message) {
    for (final pattern in _upiPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Extract reference number from message
  String? _extractReferenceNumber(String message) {
    for (final pattern in _refPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final ref = match.group(1);
        if (ref != null && ref.length >= 8) {
          return ref;
        }
      }
    }
    return null;
  }

  /// Extract bank account from message
  String? _extractBankAccount(String message) {
    for (final pattern in _accountPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Extract date and time from message
  DateTime? _extractDateTime(String message) {
    for (final pattern in _dateTimePatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        try {
          // For MVP, return current time if we can't parse properly
          // TODO: Implement proper date/time parsing
          return DateTime.now();
        } catch (e) {
          continue;
        }
      }
    }
    return DateTime.now(); // Default to current time
  }

  /// Determine transaction type from message
  TransactionType _determineTransactionType(String message) {
    final lowerMessage = message.toLowerCase();

    for (final entry in _typeKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return TransactionType.expense; // Default to expense
  }

  /// Extract merchant information
  Map<String, String?> _extractMerchantInfo(String message) {
    final lowerMessage = message.toLowerCase();

    for (final entry in _merchantPatterns.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          return {
            'name': _extractMerchantName(message, keyword),
            'category': entry.key,
          };
        }
      }
    }

    return {'name': null, 'category': 'Other'};
  }

  /// Extract merchant name from message
  String? _extractMerchantName(String message, String keyword) {
    // Try to extract text around the keyword
    final keywordIndex = message.toLowerCase().indexOf(keyword.toLowerCase());
    if (keywordIndex == -1) return null;

    // Look for text in the vicinity of the keyword
    final start = math.max(0, keywordIndex - 20);
    final end = math.min(message.length, keywordIndex + keyword.length + 20);
    final context = message.substring(start, end);

    // Extract words that might be merchant names
    final words = context.split(RegExp(r'[\s,.-]+'));
    for (final word in words) {
      if (word.length > 3 && !RegExp(r'^\d+$').hasMatch(word)) {
        return word.toUpperCase();
      }
    }

    return keyword.toUpperCase();
  }

  /// Generate description from extracted information
  String _generateDescription(String message, Map<String, String?> merchantInfo,
      TransactionType? type) {
    final merchantName = merchantInfo['name'];
    final category = merchantInfo['category'];

    if (merchantName != null) {
      switch (type) {
        case TransactionType.income:
          return 'Money received from $merchantName';
        case TransactionType.expense:
          return 'Payment to $merchantName';
        case TransactionType.transfer:
          return 'Transfer to $merchantName';
        default:
          return 'Transaction with $merchantName';
      }
    }

    if (category != null && category != 'Other') {
      switch (type) {
        case TransactionType.income:
          return '$category income';
        case TransactionType.expense:
          return '$category expense';
        case TransactionType.transfer:
          return '$category transfer';
        default:
          return '$category transaction';
      }
    }

    // Fallback to truncated original message
    return message.length > 50 ? '${message.substring(0, 47)}...' : message;
  }

  /// Extract keywords from message for metadata
  List<String> _extractKeywords(String message) {
    final words = message.toLowerCase().split(RegExp(r'[\s,.-]+'));
    final keywords = <String>[];

    for (final word in words) {
      if (word.length > 4 && !RegExp(r'^\d+$').hasMatch(word)) {
        keywords.add(word);
      }
    }

    return keywords.take(5).toList(); // Limit to 5 keywords
  }

  /// Calculate confidence score based on extracted information
  double _calculateConfidence({
    double? amount,
    String? upiId,
    String? referenceNumber,
    TransactionType? type,
    Map<String, String?>? merchantInfo,
    required String message,
  }) {
    double confidence = 0.0;

    // Amount extraction confidence
    if (amount != null && amount > 0) {
      confidence += 0.3;
    }

    // UPI ID confidence
    if (upiId != null && upiId.contains('@')) {
      confidence += 0.25;
    }

    // Reference number confidence
    if (referenceNumber != null && referenceNumber.length >= 8) {
      confidence += 0.2;
    }

    // Transaction type confidence
    if (type != null) {
      confidence += 0.15;
    }

    // Merchant information confidence
    if (merchantInfo?['name'] != null) {
      confidence += 0.1;
    }

    // Ensure confidence is between 0 and 1
    return math.min(1.0, math.max(0.0, confidence));
  }

  /// Add ML-like noise to confidence for realism
  double _addMLNoise(double confidence) {
    final random = math.Random();
    final noise = (random.nextDouble() - 0.5) * 0.1; // ±5% noise
    return math.min(1.0, math.max(0.0, confidence + noise));
  }

  /// Validate if message is likely a transaction SMS
  bool isTransactionMessage(String message) {
    final lowerMessage = message.toLowerCase();

    // Check for transaction indicators
    final transactionIndicators = [
      'rs.',
      '₹',
      'inr',
      'debited',
      'credited',
      'paid',
      'received',
      'upi',
      'transfer',
      'transaction',
      'bank',
      'account'
    ];

    int indicatorCount = 0;
    for (final indicator in transactionIndicators) {
      if (lowerMessage.contains(indicator)) {
        indicatorCount++;
      }
    }

    return indicatorCount >= 2; // At least 2 indicators for high confidence
  }

  /// Get supported ML models info (placeholder)
  Map<String, dynamic> getModelInfo() {
    return {
      'version': '1.0.0-mock',
      'type': 'regex-based-mock',
      'accuracy': '~75%',
      'supported_languages': ['English', 'Hindi (transliterated)'],
      'supported_banks': ['All major Indian banks'],
      'last_updated': DateTime.now().toIso8601String(),
      'notes':
          'This is a mock implementation using regex patterns. Replace with TensorFlow Lite model for production.',
    };
  }
}
