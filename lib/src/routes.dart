import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/features/onboarding/onboarding_screen.dart';
import 'package:myupiflow/src/features/onboarding/permission_explanation.dart';
import 'package:myupiflow/src/features/auth/pin_setup_screen.dart';
import 'package:myupiflow/src/features/auth/lock_screen.dart';
import 'package:myupiflow/src/features/dashboard/dashboard_screen.dart';
import 'package:myupiflow/src/features/transactions/transaction_list.dart';
import 'package:myupiflow/src/features/transactions/transaction_detail.dart';
import 'package:myupiflow/src/features/transactions/transaction_form.dart';
import 'package:myupiflow/src/features/import/paste_parser_screen.dart';
import 'package:myupiflow/src/features/settings/settings_screen.dart';
import 'package:myupiflow/src/features/debug/debug_screen.dart';
import 'package:myupiflow/src/services/auth_service.dart';

/// App Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.onboarding,
    debugLogDiagnostics: Config.useMockData,
    redirect: (context, state) async {
      // Check authentication status
      final authStatus = await AuthService.getAuthStatus();
      final currentPath = state.matchedLocation;

      // Skip authentication for onboarding and permission screens
      if (currentPath == Routes.onboarding ||
          currentPath == Routes.permissionExplanation ||
          currentPath == Routes.pinSetup) {
        return null;
      }

      // Redirect to PIN setup if not configured
      if (!authStatus.isPinSetup) {
        return Routes.pinSetup;
      }

      // Redirect to lock screen if authentication is needed
      if (authStatus.needsAuthentication && currentPath != Routes.lockScreen) {
        return Routes.lockScreen;
      }

      // If authenticated and trying to access lock screen, redirect to dashboard
      if (!authStatus.needsAuthentication && currentPath == Routes.lockScreen) {
        return Routes.dashboard;
      }

      return null;
    },
    routes: [
      // Onboarding Flow
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.permissionExplanation,
        name: 'permission-explanation',
        builder: (context, state) => const PermissionExplanationScreen(),
      ),

      // Authentication Flow
      GoRoute(
        path: Routes.pinSetup,
        name: 'pin-setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: Routes.lockScreen,
        name: 'lock-screen',
        builder: (context, state) => const LockScreen(),
      ),

      // Main App Flow
      GoRoute(
        path: Routes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: Routes.transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionListScreen(),
        routes: [
          GoRoute(
            path: 'detail/:id',
            name: 'transaction-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TransactionDetailScreen(transactionId: id);
            },
          ),
          GoRoute(
            path: 'form',
            name: 'transaction-form',
            builder: (context, state) {
              final transactionId = state.uri.queryParameters['id'];
              final smsContent = state.uri.queryParameters['sms'];
              return TransactionFormScreen(
                transactionId: transactionId,
                smsContent: smsContent,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.pasteParser,
        name: 'paste-parser',
        builder: (context, state) => const PasteParserScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Debug (Hidden in production)
      if (Config.useMockData)
        GoRoute(
          path: Routes.debug,
          name: 'debug',
          builder: (context, state) => const DebugScreen(),
        ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              '404 - Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go(Routes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Route Helper Extension
extension GoRouterHelper on GoRouter {
  void pushAndClearStack(String location) {
    while (canPop()) {
      pop();
    }
    pushReplacement(location);
  }
}

/// Navigation Helper
class AppNavigation {
  static void toOnboarding(BuildContext context) {
    context.go(Routes.onboarding);
  }

  static void toPermissionExplanation(BuildContext context) {
    context.go(Routes.permissionExplanation);
  }

  static void toPinSetup(BuildContext context) {
    context.go(Routes.pinSetup);
  }

  static void toLockScreen(BuildContext context) {
    context.go(Routes.lockScreen);
  }

  static void toDashboard(BuildContext context) {
    context.go(Routes.dashboard);
  }

  static void toTransactions(BuildContext context) {
    context.go(Routes.transactions);
  }

  static void toTransactionDetail(BuildContext context, String id) {
    context.go('${Routes.transactions}/detail/$id');
  }

  static void toTransactionForm(BuildContext context,
      {String? transactionId, String? smsContent}) {
    final query = <String, String>{};
    if (transactionId != null) query['id'] = transactionId;
    if (smsContent != null) query['sms'] = smsContent;

    final uri =
        Uri(path: '${Routes.transactions}/form', queryParameters: query);
    context.go(uri.toString());
  }

  static void toPasteParser(BuildContext context) {
    context.go(Routes.pasteParser);
  }

  static void toSettings(BuildContext context) {
    context.go(Routes.settings);
  }

  static void toDebug(BuildContext context) {
    if (Config.useMockData) {
      context.go(Routes.debug);
    }
  }

  static void logout(BuildContext context) {
    // Clear authentication and redirect to onboarding
    AuthService.lockApp().then((_) {
      context.go(Routes.lockScreen);
    });
  }

  static void showTransactionForm(BuildContext context, {String? smsContent}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: TransactionFormScreen(smsContent: smsContent),
      ),
    );
  }
}

/// Route Guard for Authentication
class AuthGuard {
  static Future<bool> canAccess(String route) async {
    final authStatus = await AuthService.getAuthStatus();

    // Public routes that don't require authentication
    const publicRoutes = [
      Routes.onboarding,
      Routes.permissionExplanation,
      Routes.pinSetup,
    ];

    if (publicRoutes.contains(route)) {
      return true;
    }

    // Check if PIN is setup
    if (!authStatus.isPinSetup) {
      return false;
    }

    // Check if authentication is needed
    return !authStatus.needsAuthentication;
  }

  static Future<String?> getRedirectRoute(String requestedRoute) async {
    final canAccess = await AuthGuard.canAccess(requestedRoute);
    if (canAccess) return null;

    final authStatus = await AuthService.getAuthStatus();

    if (!authStatus.isPinSetup) {
      return Routes.pinSetup;
    }

    if (authStatus.needsAuthentication) {
      return Routes.lockScreen;
    }

    return Routes.onboarding;
  }
}
