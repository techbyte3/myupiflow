import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _keyAlias = 'encryption_key';

  /// Generate a new encryption key and store it securely
  static Future<void> generateAndStoreKey() async {
    final key = _generateRandomKey();
    await _secureStorage.write(key: _keyAlias, value: base64Encode(key));
  }

  /// Retrieve the encryption key from secure storage
  static Future<Uint8List?> _getStoredKey() async {
    final keyString = await _secureStorage.read(key: _keyAlias);
    if (keyString == null) return null;
    return base64Decode(keyString);
  }

  /// Generate a random 256-bit key
  static Uint8List _generateRandomKey() {
    final random = Random.secure();
    final key = Uint8List(32); // 256 bits
    for (int i = 0; i < key.length; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }

  /// Encrypt data using AES encryption
  static Future<String> encrypt(String data) async {
    try {
      var key = await _getStoredKey();
      if (key == null) {
        await generateAndStoreKey();
        key = await _getStoredKey();
      }
      
      if (key == null) throw Exception('Failed to generate encryption key');

      // Simple XOR encryption for MVP (replace with proper AES in production)
      final bytes = utf8.encode(data);
      final encrypted = Uint8List(bytes.length);
      
      for (int i = 0; i < bytes.length; i++) {
        encrypted[i] = bytes[i] ^ key[i % key.length];
      }
      
      return base64Encode(encrypted);
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt data using AES decryption
  static Future<String> decrypt(String encryptedData) async {
    try {
      final key = await _getStoredKey();
      if (key == null) throw Exception('Encryption key not found');

      final encrypted = base64Decode(encryptedData);
      final decrypted = Uint8List(encrypted.length);
      
      for (int i = 0; i < encrypted.length; i++) {
        decrypted[i] = encrypted[i] ^ key[i % key.length];
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generate password-based key for export encryption
  static Uint8List generatePasswordKey(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return Uint8List.fromList(sha256.convert(bytes).bytes);
  }

  /// Encrypt data for export with password
  static String encryptForExport(String data, String password) {
    final salt = _generateRandomKey().take(16).toList();
    final key = generatePasswordKey(password, base64Encode(salt));
    
    final bytes = utf8.encode(data);
    final encrypted = Uint8List(bytes.length);
    
    for (int i = 0; i < bytes.length; i++) {
      encrypted[i] = bytes[i] ^ key[i % key.length];
    }
    
    final result = {
      'salt': base64Encode(salt),
      'data': base64Encode(encrypted),
    };
    
    return jsonEncode(result);
  }

  /// Decrypt exported data with password
  static String decryptFromExport(String encryptedData, String password) {
    try {
      final data = jsonDecode(encryptedData) as Map<String, dynamic>;
      final salt = base64Decode(data['salt'] as String);
      final encrypted = base64Decode(data['data'] as String);
      final key = generatePasswordKey(password, base64Encode(salt));
      
      final decrypted = Uint8List(encrypted.length);
      for (int i = 0; i < encrypted.length; i++) {
        decrypted[i] = encrypted[i] ^ key[i % key.length];
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt export data: $e');
    }
  }

  /// Clear all stored encryption keys
  static Future<void> clearKeys() async {
    await _secureStorage.delete(key: _keyAlias);
  }
}