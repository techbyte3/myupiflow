import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/providers/settings_provider.dart';
import 'package:myupiflow/src/services/auth_service.dart';
import 'package:myupiflow/src/services/export_service.dart';
import 'package:myupiflow/src/services/storage_service.dart';
import 'package:myupiflow/src/core/utils/encryption_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Security Section
          _SettingsSection(
            title: 'Security',
            children: [
              _SecuritySettings(),
            ],
          ),

          const SizedBox(height: 24),

          // Appearance Section
          _SettingsSection(
            title: 'Appearance',
            children: [
              _AppearanceSettings(),
            ],
          ),

          const SizedBox(height: 24),

          // Data Management Section
          _SettingsSection(
            title: 'Data Management',
            children: [
              _DataManagementSettings(),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _SettingsSection(
            title: 'About',
            children: [
              _AboutSettings(),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SecuritySettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securitySettings = ref.watch(securitySettingsProvider);

    return securitySettings.when(
      data: (settings) => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your security PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePinDialog(context, ref),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric Authentication'),
            subtitle: Text(settings['biometric_available']
                ? 'Use fingerprint or face unlock'
                : 'Not available on this device'),
            value: settings['biometric_enabled'] ?? false,
            onChanged: settings['biometric_available']
                ? (value) => _toggleBiometric(context, ref, value)
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Auto-lock Timeout'),
            subtitle:
                Text('Lock after ${settings['auto_lock_timeout']} minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showTimeoutDialog(context, ref, settings['auto_lock_timeout']),
          ),
        ],
      ),
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Loading security settings...'),
      ),
      error: (_, __) => const ListTile(
        leading: Icon(Icons.error),
        title: Text('Failed to load security settings'),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isProcessing = false;
          String? errorText;

          Future<void> submit() async {
            final oldPin = oldPinController.text.trim();
            final newPin = newPinController.text.trim();
            final confirmPin = confirmPinController.text.trim();

            if (newPin != confirmPin) {
              setState(
                  () => errorText = 'New PIN and confirmation do not match');
              return;
            }
            if (newPin.length != Config.pinLength) {
              setState(
                  () => errorText = 'PIN must be ${Config.pinLength} digits');
              return;
            }

            setState(() {
              isProcessing = true;
              errorText = null;
            });
            final ok = await AuthService.changePin(oldPin, newPin);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(ok
                        ? 'PIN updated successfully'
                        : 'Failed to change PIN')),
              );
            }
          }

          return AlertDialog(
            title: const Text('Change PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Current PIN',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'New PIN',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New PIN',
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isProcessing ? null : submit,
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleBiometric(BuildContext context, WidgetRef ref, bool value) async {
    final success =
        await ref.read(settingsProvider.notifier).setBiometricEnabled(value);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update biometric setting')),
      );
    }
  }

  void _showTimeoutDialog(
      BuildContext context, WidgetRef ref, int currentTimeout) {
    final timeouts = ref.read(autoLockTimeoutOptionsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-lock Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: timeouts.map((option) {
            final minutes = option['minutes'] as int;
            final display = option['display'] as String;

            return RadioListTile<int>(
              value: minutes,
              groupValue: currentTimeout,
              title: Text(display),
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setAutoLockTimeout(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AppearanceSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(currentThemeProvider);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Theme'),
          subtitle: Text(_getThemeDisplayName(currentTheme)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(context, ref, currentTheme),
        ),
      ],
    );
  }

  String _getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.system:
        return 'System default';
    }
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, AppTheme currentTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppTheme.values.map((theme) {
            return RadioListTile<AppTheme>(
              value: theme,
              groupValue: currentTheme,
              title: Text(_getThemeDisplayName(theme)),
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateTheme(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DataManagementSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Export Data'),
          subtitle: const Text('Download your transaction data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showExportDialog(context, ref),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Clear All Data'),
          subtitle: const Text('Delete all transactions and settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showClearDataDialog(context, ref),
        ),
      ],
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Encrypted JSON'),
              subtitle: Text('Secure export with password protection'),
            ),
            ListTile(
              leading: Icon(Icons.table_chart_outlined),
              title: Text('CSV File'),
              subtitle: Text('Spreadsheet-compatible format'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportData(context, ref);
            },
            child: const Text('Export JSON'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, WidgetRef ref) async {
    final exportService = ExportService();

    // Show password dialog
    final password = await _showPasswordDialog(context);
    if (password == null) return;

    try {
      final result =
          await exportService.exportAsEncryptedJson(password: password);

      if (result.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported successfully to ${result.filePath}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter a password to encrypt your data',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your transactions and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Clear app data
                final storage = StorageService();
                await storage.initialize();
                await storage.clearAll();
                await AuthService.clearAuthData();
                await EncryptionHelper.clearKeys();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('All data cleared successfully.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to clear data: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
}

class _AboutSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfo = ref.watch(appInfoProvider);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: Text(appInfo['version'] ?? 'Unknown'),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.security_outlined),
          title: const Text('Privacy Level'),
          subtitle: Text(appInfo['privacy_level'] ?? 'Unknown'),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('Database'),
          subtitle: Text(appInfo['database'] ?? 'Unknown'),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: const Text('Privacy Policy'),
          subtitle: const Text('View our privacy policy'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Privacy policy is embedded in the app - all data stays local!'),
              ),
            );
          },
        ),
      ],
    );
  }
}
