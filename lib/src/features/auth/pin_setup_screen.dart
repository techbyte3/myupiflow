import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/services/auth_service.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PageController _pageController = PageController();
  String _firstPin = '';
  String _confirmPin = '';
  bool _isProcessing = false;
  int _currentStep = 0; // 0: setup, 1: confirm

  final List<String> _enteredPin = [];
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_isProcessing) return;

    HapticFeedback.lightImpact();

    setState(() {
      _errorMessage = null;
      _enteredPin.add(number);

      if (_enteredPin.length == Config.pinLength) {
        _processPinEntry();
      }
    });
  }

  void _onBackspacePressed() {
    if (_isProcessing || _enteredPin.isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin.removeLast();
      _errorMessage = null;
    });
  }

  void _processPinEntry() {
    final enteredPinStr = _enteredPin.join();

    if (_currentStep == 0) {
      // First PIN entry
      _firstPin = enteredPinStr;
      _moveToConfirmStep();
    } else {
      // PIN confirmation
      _confirmPin = enteredPinStr;
      _validateAndSetupPin();
    }
  }

  void _moveToConfirmStep() {
    setState(() {
      _currentStep = 1;
      _enteredPin.clear();
    });

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _validateAndSetupPin() async {
    if (_firstPin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _enteredPin.clear();
      });

      HapticFeedback.heavyImpact();

      // Go back to first step after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _currentStep = 0;
            _firstPin = '';
            _confirmPin = '';
            _errorMessage = null;
          });

          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await AuthService.setupPin(_firstPin);

      if (success) {
        HapticFeedback.heavyImpact();
        _showSuccessAndProceed();
      } else {
        setState(() {
          _errorMessage = 'Failed to setup PIN. Please try again.';
          _isProcessing = false;
          _enteredPin.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isProcessing = false;
        _enteredPin.clear();
      });
    }
  }

  void _showSuccessAndProceed() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
        title: const Text('PIN Setup Complete'),
        content: const Text(
          'Your PIN has been set successfully. Your transactions are now secured.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedToNextStep();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _proceedToNextStep() {
    context.go(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Setup PIN',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _PinSetupStep(
            title: 'Create Your PIN',
            subtitle:
                'Enter a ${Config.pinLength}-digit PIN to secure your data',
            enteredPin: _enteredPin,
            errorMessage: _errorMessage,
            isProcessing: _isProcessing,
            onNumberPressed: _onNumberPressed,
            onBackspacePressed: _onBackspacePressed,
          ),
          _PinSetupStep(
            title: 'Confirm Your PIN',
            subtitle: 'Re-enter your PIN to confirm',
            enteredPin: _enteredPin,
            errorMessage: _errorMessage,
            isProcessing: _isProcessing,
            onNumberPressed: _onNumberPressed,
            onBackspacePressed: _onBackspacePressed,
          ),
        ],
      ),
    );
  }
}

class _PinSetupStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> enteredPin;
  final String? errorMessage;
  final bool isProcessing;
  final Function(String) onNumberPressed;
  final VoidCallback onBackspacePressed;

  const _PinSetupStep({
    required this.title,
    required this.subtitle,
    required this.enteredPin,
    this.errorMessage,
    required this.isProcessing,
    required this.onNumberPressed,
    required this.onBackspacePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Title and subtitle
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 64),

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(Config.pinLength, (index) {
              final isFilled = index < enteredPin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  border: Border.all(
                    color: errorMessage != null
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Error message
          if (errorMessage != null)
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
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage!,
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
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: CircularProgressIndicator(),
            ),

          const Spacer(),

          // Number pad
          _NumberPad(
            onNumberPressed: onNumberPressed,
            onBackspacePressed: onBackspacePressed,
            isEnabled: !isProcessing,
            canDelete: enteredPin.isNotEmpty,
          ),

          const SizedBox(height: 32),
        ],
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
