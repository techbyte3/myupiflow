import 'package:flutter_test/flutter_test.dart';
import 'package:myupiflow/src/services/ml_service.dart';
import 'package:myupiflow/src/core/constants.dart';

void main() {
  group('MLService', () {
    late MLService mlService;

    setUp(() {
      mlService = MLService();
    });

    group('parseText', () {
      test('should parse UPI debit transaction correctly', () async {
        const smsContent =
            'Rs.450.00 debited from account XXXXXX1234 on 26-Sep-25 at ZOMATO BANGALORE using UPI Ref No 123456789012. Available bal: Rs.2550.00';

        final result = await mlService.parseText(smsContent);

        expect(result.amount, equals(450.00));
        expect(result.type, equals(TransactionType.expense));
        expect(result.merchantName, isNotNull);
        expect(result.referenceNumber, isNotNull);
        expect(result.confidence, greaterThan(0.5));
      });

      test('should parse UPI credit transaction correctly', () async {
        const smsContent =
            'Rs.2500.00 credited to your account XXXXXX1234 from COMPANY SALARY on 01-Oct-25. Available balance: Rs.15000.00';

        final result = await mlService.parseText(smsContent);

        expect(result.amount, equals(2500.00));
        expect(result.type, equals(TransactionType.income));
        expect(result.confidence, greaterThan(0.5));
      });

      test('should handle invalid SMS content gracefully', () async {
        const smsContent = 'This is not a transaction SMS message';

        final result = await mlService.parseText(smsContent);

        expect(result.confidence, lessThan(0.5));
        expect(result.amount, isNull);
      });

      test('should extract merchant information correctly', () async {
        const smsContent =
            'Paid Rs.150.00 to STARBUCKS COFFEE via UPI on 26-Sep-25. UPI Ref: 123456789. Balance: Rs.5000.00';

        final result = await mlService.parseText(smsContent);

        expect(result.amount, equals(150.00));
        expect(result.merchantName, contains('STARBUCKS'));
        expect(result.metadata?['category'], equals('Food'));
      });

      test('should handle different currency formats', () async {
        const testCases = [
          'Rs.100.50 debited from account',
          '₹100.50 debited from account',
          'INR 100.50 debited from account',
          '100.50 rupees debited from account'
        ];

        for (final testCase in testCases) {
          final result = await mlService.parseText(testCase);
          expect(result.amount, equals(100.50),
              reason: 'Failed for: $testCase');
        }
      });
    });

    group('isTransactionMessage', () {
      test('should identify transaction messages correctly', () {
        const validMessages = [
          'Rs.100 debited from account',
          'Amount credited to your account',
          'UPI payment successful',
          'Transaction completed successfully'
        ];

        for (final message in validMessages) {
          expect(mlService.isTransactionMessage(message), isTrue,
              reason: 'Should identify as transaction: $message');
        }
      });

      test('should reject non-transaction messages', () {
        const invalidMessages = [
          'Happy birthday to you!',
          'Meeting scheduled for tomorrow',
          'How are you doing?',
          'Please call me back'
        ];

        for (final message in invalidMessages) {
          expect(mlService.isTransactionMessage(message), isFalse,
              reason: 'Should not identify as transaction: $message');
        }
      });
    });

    group('getModelInfo', () {
      test('should return valid model information', () {
        final modelInfo = mlService.getModelInfo();

        expect(modelInfo, isA<Map<String, dynamic>>());
        expect(modelInfo['version'], isNotNull);
        expect(modelInfo['type'], isNotNull);
        expect(modelInfo['accuracy'], isNotNull);
      });
    });
  });
}
