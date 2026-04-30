import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../services/biometric_service.dart';
import '../../../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _bg = Color(0xFF0B0D22);
  static const Color _surface = Color(0xFF17182C);
  static const Color _surfaceSoft = Color(0xFF232542);
  static const Color _border = Color(0xFF2D3050);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFFB8BCD7);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showMessage('Username/email dan password wajib diisi.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    final result = await AuthService.login(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result['success'] == true) {
      final user = Map<String, dynamic>.from(result['user']);

      await SessionService.saveLoginSession(
        name: user['name']?.toString() ?? 'Pengguna',
        email: user['email']?.toString() ?? '',
        username: user['username']?.toString(),
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      return;
    }

    _showMessage(result['message']?.toString() ?? 'Login gagal.');
  }

  Future<void> _handleBiometricLogin() async {
    final accounts = await SessionService.getBiometricAccounts();

    if (accounts.isEmpty) {
      if (!mounted) return;
      _showFingerprintNotEnabledDialog();
      return;
    }

    final available = await BiometricService.isBiometricAvailable();

    if (!available) {
      if (!mounted) return;
      _showMessage('Biometrik tidak tersedia di perangkat ini.');
      return;
    }

    final authenticated = await BiometricService.authenticate();

    if (!mounted) return;

    if (!authenticated) {
      _showMessage('Autentikasi fingerprint dibatalkan.');
      return;
    }

    if (accounts.length == 1) {
      await _loginWithBiometricAccount(accounts.first);
      return;
    }

    _showBiometricAccountPicker(accounts);
  }

  Future<void> _loginWithBiometricAccount(Map<String, String> account) async {
    final name = account['name']?.trim();
    final email = account['email']?.trim();
    final username = account['username']?.trim();

    if (email == null || email.isEmpty) {
      _showMessage('Data akun fingerprint tidak lengkap.');
      return;
    }

    await SessionService.saveLoginSession(
      name: name == null || name.isEmpty ? 'Pengguna' : name,
      email: email,
      username: username == null || username.isEmpty ? null : username,
    );

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  void _showBiometricAccountPicker(List<Map<String, String>> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(Icons.fingerprint_rounded, color: _cyan, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pilih Akun',
                        style: TextStyle(
                          color: _text,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fingerprint berhasil. Pilih akun yang ingin digunakan.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...accounts.map((account) {
                  final name = account['name']?.trim();
                  final email = account['email']?.trim();
                  final username = account['username']?.trim();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: _surfaceSoft,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_purple, _cyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        name == null || name.isEmpty ? 'Pengguna' : name,
                        style: const TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        username == null || username.isEmpty
                            ? email ?? ''
                            : '@$username • ${email ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF7E84A8),
                        size: 16,
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _loginWithBiometricAccount(account);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFingerprintNotEnabledDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: _cyan),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fingerprint Belum Aktif',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: const Text(
            'Login terlebih dahulu, lalu aktifkan fingerprint melalui menu Profil.',
            style: TextStyle(
              color: _muted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 106,
        height: 106,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.28),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: _cyan.withValues(alpha: 0.13),
              blurRadius: 42,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/pitch_perfect_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLogo(),
        const SizedBox(height: 28),
        const Text(
          'Masuk ke Akun',
          style: TextStyle(
            color: _text,
            fontSize: 33,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kelola latihan musik, progres, referensi lagu, dan AI Coach dalam satu akun.',
          style: TextStyle(
            color: _muted,
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: _text,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _surfaceSoft,
        labelStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w700),
        hintStyle: const TextStyle(
          color: Color(0xFF7E84A8),
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: _cyan,
        suffixIconColor: _muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: _cyan, width: 1.3),
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInput(
            controller: identifierController,
            label: 'Username atau Email',
            hint: 'Masukkan username atau email',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildInput(
            controller: passwordController,
            label: 'Password',
            hint: 'Masukkan password',
            icon: Icons.lock_outline_rounded,
            obscure: obscurePassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 58,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _surfaceSoft,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : _handleBiometricLogin,
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: _cyan, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text(
                'Gunakan Fingerprint',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.pushNamed(context, '/register');
                },
          child: const Text(
            'Belum punya akun? Buat akun',
            style: TextStyle(
              color: _purple,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pitch Perfect',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6F7598),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAuthCard(),
              const SizedBox(height: 18),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
