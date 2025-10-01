import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:myupiflow/src/core/constants.dart';

class AuthService {
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Secure storage keys
  static const String _pinHashKey = 'pin_hash';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _autoLockTimeoutKey = 'auto_lock_timeout';
  static const String _lastActiveTimeKey = 'last_active_time';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _appLockedKey = 'app_locked';

  /// Check if PIN is set up
  static Future<bool> isPinSetup() async {
    final pinHash = await _secureStorage.read(key: _pinHashKey);
    return pinHash != null && pinHash.isNotEmpty;
  }

  /// Set up PIN
  static Future<bool> setupPin(String pin) async {
    try {
      if (pin.length != Config.pinLength) {
        throw Exception('PIN must be ${Config.pinLength} digits');
      }

      final hash = _hashPin(pin);
      await _secureStorage.write(key: _pinHashKey, value: hash);
      await _secureStorage.write(key: _failedAttemptsKey, value: '0');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify PIN
  static Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _secureStorage.read(key: _pinHashKey);
      if (storedHash == null) return false;

      final inputHash = _hashPin(pin);
      final isValid = storedHash == inputHash;

      if (isValid) {
        await _resetFailedAttempts();
        await _updateLastActiveTime();
        await _unlockApp();
      } else {
        await _incrementFailedAttempts();
      }

      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// Change PIN
  static Future<bool> changePin(String oldPin, String newPin) async {
    try {
      final isOldPinValid = await verifyPin(oldPin);
      if (!isOldPinValid) return false;

      return await setupPin(newPin);
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;

      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Enable/disable biometric authentication
  static Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled && !(await isBiometricAvailable())) {
        return false;
      }

      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometric() async {
    if (kIsWeb) return false;
    try {
      if (!(await isBiometricEnabled()) || !(await isBiometricAvailable())) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your transactions',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        await _resetFailedAttempts();
        await _updateLastActiveTime();
        await _unlockApp();
      }

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Check if app should be locked based on timeout
  static Future<bool> shouldLockApp() async {
    try {
      final isLocked = await isAppLocked();
      if (isLocked) return true;

      final lastActiveTimeStr =
          await _secureStorage.read(key: _lastActiveTimeKey);
      if (lastActiveTimeStr == null) return true;

      final lastActiveTime = DateTime.parse(lastActiveTimeStr);
      final timeoutMinutes = await getAutoLockTimeout();
      final timeoutDuration = Duration(minutes: timeoutMinutes);

      return DateTime.now().difference(lastActiveTime) > timeoutDuration;
    } catch (e) {
      return true; // Err on the side of security
    }
  }

  /// Update last active time
  static Future<void> updateLastActiveTime() async {
    await _updateLastActiveTime();
  }

  /// Set auto-lock timeout
  static Future<void> setAutoLockTimeout(int minutes) async {
    await _secureStorage.write(
        key: _autoLockTimeoutKey, value: minutes.toString());
  }

  /// Get auto-lock timeout
  static Future<int> getAutoLockTimeout() async {
    final timeout = await _secureStorage.read(key: _autoLockTimeoutKey);
    return int.tryParse(timeout ?? '') ?? Config.autoLockTimeoutMinutes;
  }

  /// Get failed attempts count
  static Future<int> getFailedAttempts() async {
    final attempts = await _secureStorage.read(key: _failedAttemptsKey);
    return int.tryParse(attempts ?? '0') ?? 0;
  }

  /// Check if app is locked due to too many failed attempts
  static Future<bool> isAppLocked() async {
    final locked = await _secureStorage.read(key: _appLockedKey);
    return locked == 'true';
  }

  /// Lock app manually
  static Future<void> lockApp() async {
    await _secureStorage.write(key: _appLockedKey, value: 'true');
  }

  /// Reset PIN (for emergency use - requires re-setup)
  static Future<void> resetPin() async {
    await _secureStorage.deleteAll();
  }

  /// Clear all authentication data
  static Future<void> clearAuthData() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _secureStorage.delete(key: _autoLockTimeoutKey);
    await _secureStorage.delete(key: _lastActiveTimeKey);
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _appLockedKey);
  }

  // Private helper methods
  static String _hashPin(String pin) {
    final bytes = utf8.encode('${pin}myupiflow_salt'); // Add salt
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> _updateLastActiveTime() async {
    await _secureStorage.write(
      key: _lastActiveTimeKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  static Future<void> _incrementFailedAttempts() async {
    final currentAttempts = await getFailedAttempts();
    final newAttempts = currentAttempts + 1;

    await _secureStorage.write(
        key: _failedAttemptsKey, value: newAttempts.toString());

    // Lock app if too many failed attempts
    if (newAttempts >= Config.maxFailedAttempts) {
      await _secureStorage.write(key: _appLockedKey, value: 'true');
    }
  }

  static Future<void> _resetFailedAttempts() async {
    await _secureStorage.write(key: _failedAttemptsKey, value: '0');
  }

  static Future<void> _unlockApp() async {
    await _secureStorage.write(key: _appLockedKey, value: 'false');
  }

  /// Get available biometric types as string
  static Future<List<String>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.map((type) {
        switch (type) {
          case BiometricType.face:
            return 'Face ID';
          case BiometricType.fingerprint:
            return 'Fingerprint';
          case BiometricType.iris:
            return 'Iris';
          case BiometricType.weak:
            return 'Pattern/PIN';
          case BiometricType.strong:
            return 'Strong Biometric';
          default:
            return 'Biometric';
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check authentication status summary
  static Future<AuthStatus> getAuthStatus() async {
    final isPinSetup = await AuthService.isPinSetup();
    final isBiometricEnabled = await AuthService.isBiometricEnabled();
    final isBiometricAvailable = await AuthService.isBiometricAvailable();
    final isLocked = await AuthService.isAppLocked();
    final shouldLock = await AuthService.shouldLockApp();
    final failedAttempts = await AuthService.getFailedAttempts();

    return AuthStatus(
      isPinSetup: isPinSetup,
      isBiometricEnabled: isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable,
      isAppLocked: isLocked,
      shouldAutoLock: shouldLock,
      failedAttempts: failedAttempts,
    );
  }
}

class AuthStatus {
  final bool isPinSetup;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;
  final bool isAppLocked;
  final bool shouldAutoLock;
  final int failedAttempts;

  const AuthStatus({
    required this.isPinSetup,
    required this.isBiometricEnabled,
    required this.isBiometricAvailable,
    required this.isAppLocked,
    required this.shouldAutoLock,
    required this.failedAttempts,
  });

  bool get needsAuthentication => !isPinSetup || isAppLocked || shouldAutoLock;
  bool get canUseBiometric => isBiometricAvailable && isBiometricEnabled;
  bool get isSecure => isPinSetup && failedAttempts == 0;

  @override
  String toString() {
    return 'AuthStatus(isPinSetup: $isPinSetup, isBiometricEnabled: $isBiometricEnabled, isAppLocked: $isAppLocked)';
  }
}
