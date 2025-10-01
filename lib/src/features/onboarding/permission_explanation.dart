import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:myupiflow/src/core/constants.dart';

class PermissionExplanationScreen extends StatefulWidget {
  const PermissionExplanationScreen({super.key});

  @override
  State<PermissionExplanationScreen> createState() =>
      _PermissionExplanationScreenState();
}

class _PermissionExplanationScreenState
    extends State<PermissionExplanationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRequestingPermissions = false;

  final List<PermissionInfo> _permissions = [
    PermissionInfo(
      title: 'SMS Access',
      subtitle: 'Read Transaction Messages',
      description:
          'We need to read your SMS messages to automatically detect UPI transactions from banks and payment apps. This helps you track spending without manual entry.',
      icon: Icons.sms_outlined,
      permission: Permission.sms,
      isRequired: true,
      androidOnly: false,
      details: [
        'Read bank transaction SMS',
        'Parse UPI payment details',
        'Extract merchant information',
        'Identify transaction amounts',
      ],
      whyNeeded:
          'SMS access allows us to automatically capture your transaction details from bank notifications, making expense tracking effortless.',
    ),
    PermissionInfo(
      title: 'Notification Access',
      subtitle: 'Read Banking App Notifications',
      description:
          'Access to notifications helps us capture transaction details from banking apps like PhonePe, Google Pay, and Paytm.',
      icon: Icons.notifications_outlined,
      permission: Permission.notification,
      isRequired: false,
      androidOnly: true,
      details: [
        'Read payment app notifications',
        'Capture real-time transactions',
        'Support multiple payment apps',
        'Enhanced transaction detection',
      ],
      whyNeeded:
          'Notification access provides comprehensive transaction tracking across all your payment apps.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequestingPermissions = true;
    });

    try {
      // On web, we skip permission requests entirely and proceed.
      if (kIsWeb) {
        _proceedToNextStep();
        return;
      }

      bool allGranted = true;

      for (final permissionInfo in _permissions) {
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            permissionInfo.androidOnly) {
          continue; // Skip Android-only permissions on iOS
        }

        final permission = permissionInfo.permission;
        final status = await permission.status;

        if (!status.isGranted) {
          final result = await permission.request();
          if (!result.isGranted && permissionInfo.isRequired) {
            allGranted = false;
            break;
          }
        }
      }

      if (allGranted || await _showPermissionDialog()) {
        _proceedToNextStep();
      }
    } catch (e) {
      _showErrorDialog('Permission request failed: $e');
    } finally {
      setState(() {
        _isRequestingPermissions = false;
      });
    }
  }

  Future<bool> _showPermissionDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Some permissions were not granted. You can continue but some features may not work properly. You can grant permissions later in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Go to Settings'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _proceedToNextStep() {
    context.go(Routes.pinSetup);
  }

  void _skipPermissions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Permissions?'),
        content: const Text(
          'Without permissions, you\'ll need to manually add all transactions. You can grant permissions later in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedToNextStep();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
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
          'Permissions',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _skipPermissions,
            child: Text(
              'Skip',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicators
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _permissions.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // Permission content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _permissions.length,
              itemBuilder: (context, index) {
                return _PermissionPageView(permission: _permissions[index]);
              },
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Platform-specific messaging (iOS only)
                if (defaultTargetPlatform == TargetPlatform.iOS &&
                    _permissions[_currentPage].androidOnly)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
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
                            'This feature is Android-only. On iOS, please use manual transaction entry.',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Navigation buttons
                Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Previous'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isRequestingPermissions
                            ? null
                            : (_currentPage == _permissions.length - 1
                                ? _requestPermissions
                                : () {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }),
                        child: _isRequestingPermissions
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _currentPage == _permissions.length - 1
                                    ? 'Grant Permissions'
                                    : 'Next',
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionPageView extends StatelessWidget {
  final PermissionInfo permission;

  const _PermissionPageView({required this.permission});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              permission.icon,
              size: 50,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            permission.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            permission.subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Required badge
          if (permission.isRequired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'REQUIRED',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (permission.androidOnly)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'ANDROID ONLY',
                style: TextStyle(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Description
          Text(
            permission.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Why we need this
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we need this:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  permission.whyNeeded,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Feature details
          ...permission.details.map((detail) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class PermissionInfo {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Permission permission;
  final bool isRequired;
  final bool androidOnly;
  final List<String> details;
  final String whyNeeded;

  const PermissionInfo({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.permission,
    required this.isRequired,
    required this.androidOnly,
    required this.details,
    required this.whyNeeded,
  });
}
