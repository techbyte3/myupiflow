import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myupiflow/src/core/constants.dart';
import 'package:myupiflow/src/data/db/app_database.dart';
import 'package:myupiflow/src/services/auth_service.dart';

/// App Settings State
class AppSettings {
  final AppTheme theme;
  final bool biometricEnabled;
  final int autoLockTimeout;
  final bool notificationsEnabled;
  final bool mockDataEnabled;
  final String dateFormat;
  final String currency;
  final bool analyticsEnabled;
  final bool debugMode;
  final String language;

  const AppSettings({
    this.theme = AppTheme.system,
    this.biometricEnabled = false,
    this.autoLockTimeout = Config.autoLockTimeoutMinutes,
    this.notificationsEnabled = true,
    this.mockDataEnabled = Config.useMockData,
    this.dateFormat = 'dd/MM/yyyy',
    this.currency = 'INR',
    this.analyticsEnabled = false,
    this.debugMode = false,
    this.language = 'en',
  });

  AppSettings copyWith({
    AppTheme? theme,
    bool? biometricEnabled,
    int? autoLockTimeout,
    bool? notificationsEnabled,
    bool? mockDataEnabled,
    String? dateFormat,
    String? currency,
    bool? analyticsEnabled,
    bool? debugMode,
    String? language,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      mockDataEnabled: mockDataEnabled ?? this.mockDataEnabled,
      dateFormat: dateFormat ?? this.dateFormat,
      currency: currency ?? this.currency,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      debugMode: debugMode ?? this.debugMode,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.name,
      'biometricEnabled': biometricEnabled,
      'autoLockTimeout': autoLockTimeout,
      'notificationsEnabled': notificationsEnabled,
      'mockDataEnabled': mockDataEnabled,
      'dateFormat': dateFormat,
      'currency': currency,
      'analyticsEnabled': analyticsEnabled,
      'debugMode': debugMode,
      'language': language,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: AppTheme.values.byName(json['theme'] ?? 'system'),
      biometricEnabled: json['biometricEnabled'] ?? false,
      autoLockTimeout: json['autoLockTimeout'] ?? Config.autoLockTimeoutMinutes,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      mockDataEnabled: json['mockDataEnabled'] ?? Config.useMockData,
      dateFormat: json['dateFormat'] ?? 'dd/MM/yyyy',
      currency: json['currency'] ?? 'INR',
      analyticsEnabled: json['analyticsEnabled'] ?? false,
      debugMode: json['debugMode'] ?? false,
      language: json['language'] ?? 'en',
    );
  }

  @override
  String toString() {
    return 'AppSettings(theme: $theme, biometricEnabled: $biometricEnabled, autoLockTimeout: $autoLockTimeout)';
  }
}

/// Settings Repository
class SettingsRepository {
  final AppDatabase _database = AppDatabase();

  static const String _settingsKey = 'app_settings';

  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(settingsJson) as Map<String, dynamic>;
        return AppSettings.fromJson(json);
      } catch (e) {
        // Return default settings if parsing fails
        return const AppSettings();
      }
    }

    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonStr);

    // Also save to database for backup
    await _database.setSetting('app_settings', jsonStr);
  }

  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    await _database.setSetting('app_settings', '');
  }
}

/// Settings Provider
class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTheme(AppTheme theme) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(theme: theme);
    await _updateSettings(updated);
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return false;

    // Update auth service
    final success = await AuthService.setBiometricEnabled(enabled);
    if (!success) return false;

    final updated = current.copyWith(biometricEnabled: enabled);
    await _updateSettings(updated);
    return true;
  }

  Future<void> setAutoLockTimeout(int minutes) async {
    final current = state.value;
    if (current == null) return;

    // Update auth service
    await AuthService.setAutoLockTimeout(minutes);

    final updated = current.copyWith(autoLockTimeout: minutes);
    await _updateSettings(updated);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(notificationsEnabled: enabled);
    await _updateSettings(updated);
  }

  Future<void> setMockDataEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(mockDataEnabled: enabled);
    await _updateSettings(updated);
  }

  Future<void> setDateFormat(String format) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(dateFormat: format);
    await _updateSettings(updated);
  }

  Future<void> setCurrency(String currency) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(currency: currency);
    await _updateSettings(updated);
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(analyticsEnabled: enabled);
    await _updateSettings(updated);
  }

  Future<void> setDebugMode(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(debugMode: enabled);
    await _updateSettings(updated);
  }

  Future<void> setLanguage(String language) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(language: language);
    await _updateSettings(updated);
  }

  Future<void> resetToDefaults() async {
    await _repository.resetSettings();
    state = const AsyncValue.data(AppSettings());
  }

  Future<void> _updateSettings(AppSettings settings) async {
    state = AsyncValue.data(settings);
    try {
      await _repository.saveSettings(settings);
    } catch (e) {
      // Revert on save failure
      await _loadSettings();
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  final repository = ref.read(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});

/// Theme Mode Provider (derived from settings)
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (settings) {
      switch (settings.theme) {
        case AppTheme.light:
          return ThemeMode.light;
        case AppTheme.dark:
          return ThemeMode.dark;
        case AppTheme.system:
          return ThemeMode.system;
      }
    },
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
  );
});

/// Current Theme Provider
final currentThemeProvider = Provider<AppTheme>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.theme,
    loading: () => AppTheme.system,
    error: (_, __) => AppTheme.system,
  );
});

/// Security Settings Provider
final securitySettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final authStatus = await AuthService.getAuthStatus();
  final settings = ref.watch(settingsProvider).value;

  return {
    'pin_setup': authStatus.isPinSetup,
    'biometric_available': authStatus.isBiometricAvailable,
    'biometric_enabled': authStatus.isBiometricEnabled,
    'auto_lock_timeout':
        settings?.autoLockTimeout ?? Config.autoLockTimeoutMinutes,
    'failed_attempts': authStatus.failedAttempts,
    'app_locked': authStatus.isAppLocked,
  };
});

/// Debug Settings Provider
final debugSettingsProvider = Provider<Map<String, dynamic>>((ref) {
  final settings = ref.watch(settingsProvider).value;
  return {
    'debug_mode': settings?.debugMode ?? false,
    'mock_data_enabled': settings?.mockDataEnabled ?? Config.useMockData,
    'analytics_enabled': settings?.analyticsEnabled ?? false,
  };
});

/// App Info Provider
final appInfoProvider = Provider<Map<String, String>>((ref) {
  return {
    'app_name': Config.appName,
    'version': Config.appVersion,
    'build_mode': Config.useMockData ? 'Debug' : 'Release',
    'privacy_level': 'Local Only',
    'encryption': 'AES-256',
    'database': 'SQLite with encryption',
  };
});

/// Available Languages Provider
final availableLanguagesProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी'},
    {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
    {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
    {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
    {'code': 'mr', 'name': 'Marathi', 'nativeName': 'मराठी'},
    {'code': 'gu', 'name': 'Gujarati', 'nativeName': 'ગુજરાતી'},
    {'code': 'kn', 'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ'},
  ];
});

/// Available Date Formats Provider
final availableDateFormatsProvider = Provider<List<Map<String, String>>>((ref) {
  final now = DateTime.now();
  return [
    {
      'value': 'dd/MM/yyyy',
      'display':
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'
    },
    {
      'value': 'MM/dd/yyyy',
      'display':
          '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}'
    },
    {
      'value': 'yyyy-MM-dd',
      'display':
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
    },
    {
      'value': 'dd-MM-yyyy',
      'display':
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}'
    },
  ];
});

/// Available Currencies Provider
final availableCurrenciesProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  ];
});

/// Auto Lock Timeout Options Provider
final autoLockTimeoutOptionsProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'minutes': 1, 'display': '1 minute'},
    {'minutes': 2, 'display': '2 minutes'},
    {'minutes': 5, 'display': '5 minutes'},
    {'minutes': 10, 'display': '10 minutes'},
    {'minutes': 15, 'display': '15 minutes'},
    {'minutes': 30, 'display': '30 minutes'},
    {'minutes': 60, 'display': '1 hour'},
    {'minutes': 0, 'display': 'Never'},
  ];
});
