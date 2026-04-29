import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _usersKey = 'registered_users';

  static Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await _getUsers();

    final existingUser = users.any(
      (user) => (user['email'] as String).toLowerCase() == email.toLowerCase(),
    );

    if (existingUser) {
      return {
        'success': false,
        'message': 'Email sudah terdaftar',
      };
    }

    users.add({
      'name': name.trim(),
      'email': email.trim(),
      'password': _hashPassword(password),
    });

    await _saveUsers(users);

    return {
      'success': true,
      'message': 'Registrasi berhasil',
    };
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final users = await _getUsers();
    final hashedPassword = _hashPassword(password);

    try {
      final user = users.firstWhere(
        (user) =>
            (user['email'] as String).toLowerCase() == email.toLowerCase() &&
            user['password'] == hashedPassword,
      );

      return {
        'success': true,
        'message': 'Login berhasil',
        'user': user,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Email atau password salah',
      };
    }
  }
}
