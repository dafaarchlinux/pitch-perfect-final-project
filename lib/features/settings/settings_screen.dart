import 'package:flutter/material.dart';
import '../../services/biometric_service.dart';
import '../../services/session_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool biometricEnabled = false;
  bool soundModeEnabled = true;
  String selectedLanguage = 'Indonesia';
  String currentUserName = 'Guest User';
  String currentUserEmail = 'guest@email.com';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await SessionService.isBiometricEnabled();
    final name = await SessionService.getUserName();
    final email = await SessionService.getUserEmail();

    if (!mounted) return;

    setState(() {
      biometricEnabled = enabled;
      currentUserName = name;
      currentUserEmail = email;
    });
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (value) {
      final available = await BiometricService.isBiometricAvailable();

      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fingerprint/biometrik tidak tersedia di perangkat ini',
            ),
          ),
        );
        return;
      }

      final authenticated = await BiometricService.authenticate();

      if (!mounted) return;

      if (authenticated) {
        await SessionService.enableBiometricForUser(
          name: currentUserName,
          email: currentUserEmail,
        );

        if (!mounted) return;

        setState(() {
          biometricEnabled = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login fingerprint berhasil diaktifkan'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fingerprint dibatalkan atau gagal')),
        );
      }
    } else {
      await SessionService.disableBiometric();

      if (!mounted) return;

      setState(() {
        biometricEnabled = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login fingerprint dinonaktifkan')),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun'),
        content: const Text('Yakin ingin keluar dari akun Pitch Perfect?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF8D91A3),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color iconColor = const Color(0xFF6C63FF),
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Color(0xFF23263A),
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF8D91A3), fontSize: 13),
            ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFCFE),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
        children: [
          _buildSectionTitle('Keamanan & Preferensi'),
          _buildCard(
            children: [
              _buildTile(
                icon: Icons.fingerprint,
                title: 'Login Fingerprint',
                subtitle: 'Aktifkan sidik jari untuk akun ini',
                trailing: Switch(
                  value: biometricEnabled,
                  activeThumbColor: const Color(0xFF6C63FF),
                  onChanged: _handleBiometricToggle,
                ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              _buildTile(
                icon: Icons.volume_up_rounded,
                title: 'Mode Suara',
                subtitle: 'Aktifkan efek audio dan feedback suara',
                trailing: Switch(
                  value: soundModeEnabled,
                  activeThumbColor: const Color(0xFF6C63FF),
                  onChanged: (value) {
                    setState(() {
                      soundModeEnabled = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildSectionTitle('Bahasa'),
          _buildCard(
            children: [
              _buildTile(
                icon: Icons.language_rounded,
                title: 'Bahasa Aplikasi',
                subtitle: selectedLanguage,
                trailing: DropdownButton<String>(
                  value: selectedLanguage,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: const [
                    DropdownMenuItem(
                      value: 'Indonesia',
                      child: Text('Indonesia'),
                    ),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLanguage = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildSectionTitle('Data & Aktivitas'),
          _buildCard(
            children: [
              _buildTile(
                icon: Icons.delete_outline_rounded,
                title: 'Hapus Riwayat',
                subtitle: 'Bersihkan history latihan, tuning, dan game',
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Color(0xFFB1B3BE),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur hapus riwayat akan diproses'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildSectionTitle('Akun'),
          _buildCard(
            children: [
              _buildTile(
                icon: Icons.logout_rounded,
                title: 'Keluar Akun',
                subtitle: 'Keluar dari akun yang sedang aktif',
                iconColor: Colors.redAccent,
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Color(0xFFB1B3BE),
                ),
                onTap: _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
