import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/providers/settings_provider.dart';
import 'package:myupiflow/src/routes.dart';
import 'package:myupiflow/theme.dart';

class myupiflowApp extends ConsumerWidget {
  const myupiflowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: Config.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,

      // Routing configuration
      routerConfig: ref.watch(routerProvider),

      // App-wide configuration
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0), // Prevent text scaling issues
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Loading App Widget for initialization
class LoadingApp extends StatelessWidget {
  final String? message;

  const LoadingApp({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: Scaffold(
        backgroundColor: lightTheme.colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: lightTheme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                Config.appName,
                style: lightTheme.textTheme.headlineMedium?.copyWith(
                  color: lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: lightTheme.textTheme.bodyMedium?.copyWith(
                    color:
                        lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error App Widget for initialization errors
class ErrorApp extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorApp({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: Scaffold(
        backgroundColor: lightTheme.colorScheme.surface,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: lightTheme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'App Initialization Failed',
                style: lightTheme.textTheme.headlineMedium?.copyWith(
                  color: lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: lightTheme.textTheme.bodyMedium?.copyWith(
                  color:
                      lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              const SizedBox(height: 16),
              Text(
                'If this problem persists, please restart the app.',
                style: lightTheme.textTheme.bodySmall?.copyWith(
                  color:
                      lightTheme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App Initializer - handles app setup and initialization
class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Initialize encryption
      // await EncryptionHelper.generateAndStoreKey(); // Called when needed

      // Initialize mock data if enabled
      if (Config.useMockData) {
        // Mock data will be generated by providers when needed
      }

      // Additional initialization can go here
      // - Database migrations
      // - Background services setup
      // - Permission checks
    } catch (e) {
      // Log error but don't prevent app from starting
      debugPrint('App initialization warning: $e');
    }
  }
}

/// Root App Widget with Provider Scope
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isInitialized = false;
  String? _initError;
  String _initMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _initMessage = 'Setting up encryption...';
      });

      await AppInitializer.initialize();

      setState(() {
        _initMessage = 'Loading settings...';
      });

      // Small delay to show loading state
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _initError = e.toString();
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _isInitialized = false;
      _initError = null;
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return ErrorApp(
        error: _initError!,
        onRetry: _retryInitialization,
      );
    }

    if (!_isInitialized) {
      return LoadingApp(message: _initMessage);
    }

    return ProviderScope(
      child: const myupiflowApp(),
    );
  }
}
