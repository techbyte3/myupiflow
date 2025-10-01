import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/services/auth_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  final List<String> _enteredPin = [];
  String? _errorMessage;
  bool _isProcessing = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  int _failedAttempts = 0;
  bool _isAppLocked = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _setupAnimations();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  Future<void> _initializeAuth() async {
    try {
      final authStatus = await AuthService.getAuthStatus();

      setState(() {
        _isBiometricAvailable = authStatus.isBiometricAvailable;
        _isBiometricEnabled = authStatus.isBiometricEnabled;
        _failedAttempts = authStatus.failedAttempts;
        _isAppLocked = authStatus.isAppLocked;
      });

      // Try biometric authentication if available and enabled
      if (_isBiometricAvailable && _isBiometricEnabled && !_isAppLocked) {
        _authenticateWithBiometric();
      }
    } catch (e) {
      // Handle initialization error
      debugPrint('Lock screen initialization error: $e');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService.authenticateWithBiometric();

      if (success) {
        _onAuthenticationSuccess();
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Biometric authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Biometric authentication error';
      });
    }
  }

  void _onNumberPressed(String number) {
    if (_isProcessing || _isAppLocked) return;

    HapticFeedback.lightImpact();

    setState(() {
      _errorMessage = null;
      _enteredPin.add(number);

      if (_enteredPin.length == Config.pinLength) {
        _verifyPin();
      }
    });
  }

  void _onBackspacePressed() {
    if (_isProcessing || _enteredPin.isEmpty || _isAppLocked) return;

    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin.removeLast();
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    final enteredPinStr = _enteredPin.join();

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await AuthService.verifyPin(enteredPinStr);

      if (success) {
        _onAuthenticationSuccess();
      } else {
        _onAuthenticationFailed();
      }
    } catch (e) {
      _onAuthenticationError();
    }
  }

  void _onAuthenticationSuccess() {
    HapticFeedback.heavyImpact();
    context.go(Routes.dashboard);
  }

  void _onAuthenticationFailed() {
    setState(() {
      _isProcessing = false;
      _failedAttempts++;
      _enteredPin.clear();
      _errorMessage =
          'Incorrect PIN. ${Config.maxFailedAttempts - _failedAttempts} attempts remaining.';

      if (_failedAttempts >= Config.maxFailedAttempts) {
        _isAppLocked = true;
        _errorMessage = 'Too many failed attempts. App is locked.';
      }
    });

    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });

    HapticFeedback.heavyImpact();
  }

  void _onAuthenticationError() {
    setState(() {
      _isProcessing = false;
      _enteredPin.clear();
      _errorMessage = 'Authentication error. Please try again.';
    });

    HapticFeedback.heavyImpact();
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text(
          'This will delete all your data and reset the app. You will need to set up everything again. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset App'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.resetPin();
        if (mounted) {
          context.go(Routes.onboarding);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reset failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // App icon and title
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: theme.colorScheme.primary,
              ),

              const SizedBox(height: 24),

              Text(
                Config.appName,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Enter your PIN to continue',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 64),

              // PIN dots with shake animation
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                        _shakeAnimation.value *
                            (_enteredPin.isNotEmpty && _errorMessage != null
                                ? 1
                                : 0),
                        0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(Config.pinLength, (index) {
                        final isFilled = index < _enteredPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline
                                    .withValues(alpha: 0.3),
                            border: Border.all(
                              color: _errorMessage != null
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.outline,
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Error message or lock message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAppLocked ? Icons.lock_outline : Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Processing indicator
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: CircularProgressIndicator(),
                ),

              const Spacer(),

              // Biometric button
              if (_isBiometricAvailable && _isBiometricEnabled && !_isAppLocked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: OutlinedButton.icon(
                    onPressed:
                        _isProcessing ? null : _authenticateWithBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use Biometric'),
                  ),
                ),

              // Number pad
              if (!_isAppLocked)
                _NumberPad(
                  onNumberPressed: _onNumberPressed,
                  onBackspacePressed: _onBackspacePressed,
                  isEnabled: !_isProcessing,
                  canDelete: _enteredPin.isNotEmpty,
                ),

              // Reset button for locked state
              if (_isAppLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Column(
                    children: [
                      Text(
                        'App is locked due to too many failed attempts.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _showResetDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                        child: const Text('Reset App'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onBackspacePressed;
  final bool isEnabled;
  final bool canDelete;

  const _NumberPad({
    required this.onNumberPressed,
    required this.onBackspacePressed,
    required this.isEnabled,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Rows 1-3
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 1; col <= 3; col++)
                  _NumberButton(
                    number: '${row * 3 + col}',
                    onPressed: isEnabled
                        ? () => onNumberPressed('${row * 3 + col}')
                        : null,
                  ),
              ],
            ),
          ),

        // Bottom row (0 and backspace)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 80), // Spacer
              _NumberButton(
                number: '0',
                onPressed: isEnabled ? () => onNumberPressed('0') : null,
              ),
              SizedBox(
                width: 80,
                child: IconButton(
                  onPressed: isEnabled && canDelete ? onBackspacePressed : null,
                  icon: Icon(
                    Icons.backspace_outlined,
                    color: isEnabled && canDelete
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String number;
  final VoidCallback? onPressed;

  const _NumberButton({
    required this.number,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 80,
      height: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: onPressed != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
