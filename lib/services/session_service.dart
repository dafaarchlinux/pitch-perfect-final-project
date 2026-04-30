import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userNameKey = 'user_name';
  static const String _userUsernameKey = 'user_username';
  static const String _userEmailKey = 'user_email';
  static const String _profileImagePathKey = 'profile_image_path';

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUserNameKey = 'biometric_user_name';
  static const String _biometricUserEmailKey = 'biometric_user_email';
  static const String _biometricAccountsKey = 'biometric_accounts';

  static String _sanitizeAccountKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static Future<String> _currentUserScopedKey(String baseKey) async {
    final email = await getUserEmail();
    final username = await getUserUsername();

    final rawIdentity = email.trim().isNotEmpty && email != 'guest@email.com'
        ? email
        : username;

    final identity = _sanitizeAccountKey(rawIdentity);
    return identity.isEmpty ? baseKey : '${baseKey}_$identity';
  }

  static Future<void> saveLoginSession({
    required String name,
    required String email,
    String? username,
  }) async {
    await _storage.write(key: _isLoggedInKey, value: 'true');
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userEmailKey, value: email);

    if (username != null && username.trim().isNotEmpty) {
      await _storage.write(key: _userUsernameKey, value: username);
    }
  }

  static Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: _isLoggedInKey);
    return value == 'true';
  }

  static Future<String> getUserName() async {
    return await _storage.read(key: _userNameKey) ?? 'Guest User';
  }

  static Future<String> getUserUsername() async {
    return await _storage.read(key: _userUsernameKey) ?? 'guest';
  }

  static Future<String> getUserEmail() async {
    return await _storage.read(key: _userEmailKey) ?? 'guest@email.com';
  }

  static Future<void> saveProfileImagePath(String path) async {
    final key = await _currentUserScopedKey(_profileImagePathKey);
    await _storage.write(key: key, value: path);
  }

  static Future<String?> getProfileImagePath() async {
    final key = await _currentUserScopedKey(_profileImagePathKey);
    return await _storage.read(key: key);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _isLoggedInKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userUsernameKey);
    await _storage.delete(key: _userEmailKey);
  }

  static Future<List<Map<String, String>>> getBiometricAccounts() async {
    final raw = await _storage.read(key: _biometricAccountsKey);

    final accounts = <Map<String, String>>[];

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final name = item['name']?.toString() ?? '';
              final email = item['email']?.toString() ?? '';
              final username = item['username']?.toString() ?? '';

              if (email.trim().isNotEmpty) {
                accounts.add({
                  'name': name,
                  'email': email,
                  'username': username,
                });
              }
            }
          }
        }
      } catch (_) {}
    }

    // Migrasi data biometric lama agar tidak hilang.
    final oldEnabledValue = await _storage.read(key: _biometricEnabledKey);
    final oldEnabled = oldEnabledValue == 'true';
    final oldEmail = await _storage.read(key: _biometricUserEmailKey);
    final oldName = await _storage.read(key: _biometricUserNameKey);

    if (oldEnabled == true &&
        oldEmail != null &&
        oldEmail.trim().isNotEmpty &&
        !accounts.any((item) => item['email'] == oldEmail)) {
      accounts.add({
        'name': oldName ?? 'Pengguna',
        'email': oldEmail,
        'username': '',
      });

      await _saveBiometricAccounts(accounts);
    }

    return accounts;
  }

  static Future<void> _saveBiometricAccounts(
    List<Map<String, String>> accounts,
  ) async {
    await _storage.write(
      key: _biometricAccountsKey,
      value: jsonEncode(accounts),
    );
  }

  static Future<void> saveLoginSessionFromBiometric({
    required String name,
    required String email,
    String? username,
  }) async {
    await saveLoginSession(name: name, email: email, username: username);
  }

  static Future<bool> isCurrentUserBiometricEnabled() async {
    final currentEmail = await getUserEmail();
    final accounts = await getBiometricAccounts();

    return accounts.any((item) {
      return item['email']?.toLowerCase() == currentEmail.toLowerCase();
    });
  }

  static Future<void> enableBiometricForUser({
    required String name,
    required String email,
  }) async {
    final username = await getUserUsername();
    final accounts = await getBiometricAccounts();

    final normalizedEmail = email.trim().toLowerCase();
    accounts.removeWhere((item) {
      return item['email']?.trim().toLowerCase() == normalizedEmail;
    });

    accounts.add({'name': name, 'email': email, 'username': username});

    await _saveBiometricAccounts(accounts);

    // Tetap tulis key lama sebagai fallback kompatibilitas.
    await _storage.write(key: _biometricEnabledKey, value: 'true');
    await _storage.write(key: _biometricUserNameKey, value: name);
    await _storage.write(key: _biometricUserEmailKey, value: email);
  }

  static Future<bool> isBiometricEnabled() async {
    final accounts = await getBiometricAccounts();
    if (accounts.isNotEmpty) return true;

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
    final currentEmail = await getUserEmail();
    final accounts = await getBiometricAccounts();

    accounts.removeWhere((item) {
      return item['email']?.trim().toLowerCase() == currentEmail.toLowerCase();
    });

    await _saveBiometricAccounts(accounts);

    if (accounts.isEmpty) {
      await _storage.delete(key: _biometricEnabledKey);
      await _storage.delete(key: _biometricUserNameKey);
      await _storage.delete(key: _biometricUserEmailKey);
    }
  }
}
