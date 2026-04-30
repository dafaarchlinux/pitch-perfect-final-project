import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  Future<void> _handleRegister() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Semua field wajib diisi.');
      return;
    }

    if (!AuthService.isValidUsername(username)) {
      _showMessage(
        'Username harus 4-20 karakter dan hanya boleh huruf kecil, angka, titik, atau underscore.',
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Format email belum valid.');
      return;
    }

    if (password.length < 8) {
      _showMessage('Password minimal 8 karakter.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Konfirmasi password tidak sama.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await AuthService.register(
      name: name,
      username: username,
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    _showMessage(result['message']?.toString() ?? 'Terjadi kesalahan.');

    if (result['success'] == true) {
      Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 116,
            height: 116,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF472B6).withValues(alpha: 0.24),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/pitch_perfect_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Create Your Account',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF8FAFC),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Buat akun untuk menyimpan progres dan latihan musikmu.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFFB8BCD7),
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _HeroChip(icon: Icons.history_rounded, label: 'Progress'),
            _HeroChip(icon: Icons.emoji_events_rounded, label: 'Achievement'),
            _HeroChip(
              icon: Icons.notifications_active_rounded,
              label: 'Reminder',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textCapitalization: TextCapitalization.none,
      style: const TextStyle(
        color: Color(0xFFF8FAFC),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: onToggle == null
            ? null
            : IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
        filled: true,
        fillColor: const Color(0xFF232542),
        labelStyle: const TextStyle(color: Color(0xFFB8BCD7)),
        hintStyle: const TextStyle(color: Color(0xFF8C91B1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF17182C),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF2D3050)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildField(
            controller: nameController,
            label: 'Nama',
            hint: 'Nama lengkap',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: usernameController,
            label: 'Username',
            hint: 'contoh: dafa_music',
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Username harus unik.',
              style: TextStyle(
                color: Color(0xFF8C91B1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: emailController,
            label: 'Email',
            hint: 'nama@email.com',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: passwordController,
            label: 'Password',
            hint: 'Minimal 8 karakter',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            onToggle: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: confirmPasswordController,
            label: 'Konfirmasi Password',
            hint: 'Ulangi password',
            icon: Icons.lock_reset_rounded,
            obscureText: obscureConfirmPassword,
            onToggle: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 58,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
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
                      'Buat Akun',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D22),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildAuthCard(),
              const SizedBox(height: 18),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text(
                  'Sudah punya akun? Masuk',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF17182C),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2D3050)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFF472B6)),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD8DDF3),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
