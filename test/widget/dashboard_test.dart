import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myupiflow/src/features/dashboard/dashboard_screen.dart';
import 'package:myupiflow/src/data/models/transaction_model.dart';
import 'package:myupiflow/src/core/constants.dart';

// Mock data for testing
final mockTransactions = [
  Transaction(
    id: '1',
    amount: 450.0,
    description: 'Lunch at restaurant',
    merchantName: 'ZOMATO',
    category: 'Food',
    type: TransactionType.expense,
    status: TransactionStatus.completed,
    dateTime: DateTime.now().subtract(const Duration(hours: 2)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Transaction(
    id: '2',
    amount: 25000.0,
    description: 'Monthly salary',
    merchantName: 'COMPANY LTD',
    category: 'Salary',
    type: TransactionType.income,
    status: TransactionStatus.completed,
    dateTime: DateTime.now().subtract(const Duration(days: 1)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Transaction(
    id: '3',
    amount: 1200.0,
    description: 'Grocery shopping',
    merchantName: 'BIG BAZAAR',
    category: 'Groceries',
    type: TransactionType.expense,
    status: TransactionStatus.completed,
    dateTime: DateTime.now().subtract(const Duration(days: 2)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

void main() {
  group('DashboardScreen Widget Tests', () {
    testWidgets('should display app name in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if app name is displayed
      expect(find.text(Config.appName), findsOneWidget);
    });

    testWidgets('should display summary section', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if summary section is present
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Balance'), findsWidgets);
      expect(find.text('Income'), findsWidgets);
      expect(find.text('Expense'), findsWidgets);
    });

    testWidgets('should display quick actions section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if quick actions are present
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Add Transaction'), findsWidgets);
      expect(find.text('Parse SMS'), findsWidgets);
      expect(find.text('View All'), findsWidgets);
    });

    testWidgets('should display recent transactions section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if recent transactions section is present
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('View All'), findsWidgets);
    });

    testWidgets('should have floating action button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if FAB is present
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should be scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if the main content is scrollable
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('should have refresh capability', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if RefreshIndicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    group('Quick Action Buttons', () {
      testWidgets('add transaction button should be tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: const DashboardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the add transaction button
        final addTransactionButton = find.text('Add Transaction');
        expect(addTransactionButton, findsOneWidget);

        await tester.tap(addTransactionButton);
        await tester.pumpAndSettle();

        // Verify that tapping doesn't cause any errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('parse SMS button should be tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: const DashboardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the parse SMS button
        final parseSMSButton = find.text('Parse SMS');
        expect(parseSMSButton, findsOneWidget);

        await tester.tap(parseSMSButton);
        await tester.pumpAndSettle();

        // Verify that tapping doesn't cause any errors
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('should handle loading state correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      // Don't wait for settle to test loading state
      await tester.pump();

      // Should not throw any exceptions during loading
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display settings and debug buttons in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for action buttons in app bar
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      if (Config.useMockData) {
        expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
      }
    });
  });
}
