import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _usersKey = 'secure_registered_users';
  static const int _saltLength = 24;
  static const int _hashLength = 32;
  static const int _iterations = 210000;

  static final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: _hashLength * 8,
  );

  static Future<List<Map<String, dynamic>>> _getUsers() async {
    final raw = await _storage.read(key: _usersKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    await _storage.write(key: _usersKey, value: jsonEncode(users));
  }

  static List<int> _createSalt() {
    final random = Random.secure();
    return List<int>.generate(_saltLength, (_) => random.nextInt(256));
  }

  static Future<String> _hashPassword({
    required String password,
    required List<int> salt,
  }) async {
    final secretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final bytes = await secretKey.extractBytes();
    return base64Encode(bytes);
  }

  static bool isValidUsername(String username) {
    final value = username.trim().toLowerCase();
    final regex = RegExp(r'^[a-z0-9._]{4,20}$');
    return regex.hasMatch(value);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();

    final users = await _getUsers();

    final usernameExists = users.any(
      (user) => user['username']?.toString().toLowerCase() == cleanUsername,
    );

    if (usernameExists) {
      return {'success': false, 'message': 'Username sudah digunakan'};
    }

    final emailExists = users.any(
      (user) => user['email']?.toString().toLowerCase() == cleanEmail,
    );

    if (emailExists) {
      return {'success': false, 'message': 'Email sudah terdaftar'};
    }

    final salt = _createSalt();
    final passwordHash = await _hashPassword(password: password, salt: salt);

    users.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': cleanName,
      'username': cleanUsername,
      'email': cleanEmail,
      'password_hash': passwordHash,
      'password_salt': base64Encode(salt),
      'password_algorithm': 'PBKDF2-HMAC-SHA256',
      'password_iterations': _iterations,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _saveUsers(users);

    return {'success': true, 'message': 'Akun berhasil dibuat'};
  }

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim().toLowerCase();
    final users = await _getUsers();

    for (final user in users) {
      final userEmail = user['email']?.toString().toLowerCase();
      final userUsername = user['username']?.toString().toLowerCase();

      if (cleanIdentifier != userEmail && cleanIdentifier != userUsername) {
        continue;
      }

      final saltText = user['password_salt']?.toString();
      final savedHash = user['password_hash']?.toString();

      if (saltText == null || savedHash == null) {
        return {
          'success': false,
          'message': 'Data akun tidak valid. Silakan daftar ulang.',
        };
      }

      final salt = base64Decode(saltText);
      final inputHash = await _hashPassword(password: password, salt: salt);

      if (inputHash == savedHash) {
        return {
          'success': true,
          'message': 'Login berhasil',
          'user': {
            'id': user['id'],
            'name': user['name'],
            'username': user['username'],
            'email': user['email'],
          },
        };
      }

      return {
        'success': false,
        'message': 'Username/email atau password salah',
      };
    }

    return {'success': false, 'message': 'Username/email atau password salah'};
  }
}
