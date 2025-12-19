import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static late FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _biometricKey = 'biometric_enabled';

  static Future<void> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  // Token management
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // User data
  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userKey, value: userData);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userKey);
  }

  // Biometric settings
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricKey);
    return value == 'true';
  }

  // Clear all data (logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
