import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _profileImagePathKey = 'profile_image_path';

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUserNameKey = 'biometric_user_name';
  static const String _biometricUserEmailKey = 'biometric_user_email';

  static Future<void> saveLoginSession({
    required String name,
    required String email,
  }) async {
    await _storage.write(key: _isLoggedInKey, value: 'true');
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userEmailKey, value: email);
  }

  static Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: _isLoggedInKey);
    return value == 'true';
  }

  static Future<String> getUserName() async {
    return await _storage.read(key: _userNameKey) ?? 'Guest User';
  }

  static Future<String> getUserEmail() async {
    return await _storage.read(key: _userEmailKey) ?? 'guest@email.com';
  }

  static Future<void> saveProfileImagePath(String path) async {
    await _storage.write(key: _profileImagePathKey, value: path);
  }

  static Future<String?> getProfileImagePath() async {
    return await _storage.read(key: _profileImagePathKey);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _isLoggedInKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
  }

  static Future<void> enableBiometricForUser({
    required String name,
    required String email,
  }) async {
    await _storage.write(key: _biometricEnabledKey, value: 'true');
    await _storage.write(key: _biometricUserNameKey, value: name);
    await _storage.write(key: _biometricUserEmailKey, value: email);
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  static Future<String> getBiometricUserName() async {
    return await _storage.read(key: _biometricUserNameKey) ?? 'Guest User';
  }

  static Future<String> getBiometricUserEmail() async {
    return await _storage.read(key: _biometricUserEmailKey) ??
        'guest@email.com';
  }

  static Future<void> disableBiometric() async {
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _biometricUserNameKey);
    await _storage.delete(key: _biometricUserEmailKey);
  }
}
