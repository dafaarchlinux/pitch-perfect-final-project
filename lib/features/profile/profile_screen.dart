import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/session_service.dart';
import '../../services/practice_progress_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = 'Guest User';
  String userEmail = 'guest@email.com';
  String? profileImagePath;

  int totalSessions = 0;
  int weeklySessions = 0;
  int? averageScore;
  List<Map<String, dynamic>> historyItems = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
    });

    final name = await SessionService.getUserName();
    final email = await SessionService.getUserEmail();
    final summary = await PracticeProgressService.getSummary();
    final history = await PracticeProgressService.getHistory();
    final savedImagePath = await SessionService.getProfileImagePath();

    if (!mounted) return;

    setState(() {
      userName = name;
      userEmail = email;
      totalSessions = summary['total_sessions'] ?? 0;
      weeklySessions = summary['weekly_sessions'] ?? 0;
      averageScore = summary['average_score'];
      historyItems = history;
      profileImagePath = savedImagePath;
      isLoading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 800,
    );

    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'pitch_perfect_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');

    await SessionService.saveProfileImagePath(savedFile.path);

    if (!mounted) return;

    setState(() {
      profileImagePath = savedFile.path;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto profil berhasil diperbarui'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await SessionService.clearSession();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun'),
        content: const Text(
          'Yakin ingin keluar dari akun Pitch Perfect di perangkat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _handleLogout(context);
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEDEDF5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF20243A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF23263A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: Color(0xFF7C7E8A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF8B5CF6),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEDF5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF23263A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0xFF7C7E8A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 17,
          color: Color(0xFFB1B3BE),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildWeeklyProgressCard() {
    final hasProgress = totalSessions > 0;
    final weeklyTarget = 5;
    final progressText = hasProgress
        ? '$weeklySessions/$weeklyTarget sesi minggu ini'
        : 'Mulai latihan pertamamu';
    final description = hasProgress
        ? 'Lanjutkan aktivitas musik agar progres mingguanmu tetap konsisten.'
        : 'Buka Detect, Games, atau Planner Kelas untuk mulai mencatat progres.';

    final progressValue = (weeklySessions / weeklyTarget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8F1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD3F0E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'PROGRES MINGGU INI',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.9,
                    color: Color(0xFF3FA37B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFF21C67A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasProgress ? Icons.trending_up_rounded : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            progressText,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF3F6B57),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 9,
              backgroundColor: Colors.white,
              color: const Color(0xFF21C67A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool unlocked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked
            ? color.withValues(alpha: 0.09)
            : const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked
              ? color.withValues(alpha: 0.16)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: unlocked
                  ? color.withValues(alpha: 0.13)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              unlocked ? icon : Icons.lock_rounded,
              color: unlocked ? color : const Color(0xFF9CA3AF),
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: unlocked
                        ? const Color(0xFF20243A)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? const Color(0xFF6B7280)
                        : const Color(0xFFA1A1AA),
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF21C67A),
              size: 22,
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementSection() {
    bool hasType(String keyword) {
      return historyItems.any((item) {
        final type = (item['type'] ?? '').toString().toLowerCase();
        return type.contains(keyword.toLowerCase());
      });
    }

    final hasAnyActivity = totalSessions > 0;
    final hasScheduler = hasType('smart practice scheduler');
    final hasPlanner = hasType('planner kelas');
    final hasInstrumentPlan = hasType('rencana beli alat');
    final hasGame = hasType('game');
    final hasNotification = hasType('notifikasi');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievement Musik',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF20243A),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Badge terbuka otomatis dari aktivitas asli yang kamu lakukan di Pitch Perfect.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Color(0xFF7C7E8A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        _buildAchievementBadge(
          icon: Icons.play_circle_fill_rounded,
          title: 'Langkah Pertama',
          subtitle: 'Terbuka setelah ada aktivitas pertama di aplikasi.',
          color: const Color(0xFF7C4DFF),
          unlocked: hasAnyActivity,
        ),
        _buildAchievementBadge(
          icon: Icons.event_available_rounded,
          title: 'Planner Aktif',
          subtitle: 'Terbuka setelah membuat jadwal latihan otomatis.',
          color: const Color(0xFF00A86B),
          unlocked: hasScheduler,
        ),
        _buildAchievementBadge(
          icon: Icons.school_rounded,
          title: 'Siap Kelas Privat',
          subtitle: 'Terbuka setelah menyimpan rencana kelas privat.',
          color: const Color(0xFFFF8A65),
          unlocked: hasPlanner,
        ),
        _buildAchievementBadge(
          icon: Icons.piano_rounded,
          title: 'Pemburu Alat Musik',
          subtitle: 'Terbuka setelah menyimpan minat alat musik.',
          color: const Color(0xFF0072FF),
          unlocked: hasInstrumentPlan,
        ),
        _buildAchievementBadge(
          icon: Icons.videogame_asset_rounded,
          title: 'Gamer Nada',
          subtitle: 'Terbuka setelah menyelesaikan latihan lewat Games.',
          color: const Color(0xFF9C27B0),
          unlocked: hasGame,
        ),
        _buildAchievementBadge(
          icon: Icons.notifications_active_rounded,
          title: 'Reminder Siap',
          subtitle: 'Terbuka setelah memakai fitur notifikasi latihan.',
          color: const Color(0xFF21C67A),
          unlocked: hasNotification,
        ),
      ],
    );
  }

  static const Color _bgColor = Color(0xFFFCFCFE);

  @override
  Widget build(BuildContext context) {
    final accuracyText = averageScore == null ? '-' : '$averageScore%';
    final accuracySubtitle = averageScore == null
        ? 'Belum ada nilai latihan'
        : 'Rata-rata dari sesi tersimpan';

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
            children: [
              const Center(
                child: Text(
                  'Profil Saya',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF20243A),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD9D8FF),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFF1F2F8),
                        backgroundImage:
                            profileImagePath != null &&
                                profileImagePath!.isNotEmpty
                            ? FileImage(File(profileImagePath!))
                            : null,
                        child:
                            profileImagePath == null ||
                                profileImagePath!.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                size: 58,
                                color: Color(0xFF6B7280),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 2,
                      child: InkWell(
                        onTap: _pickProfileImage,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  userName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF20243A),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  userEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9093A3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _loadProfileData,
                  icon: isLoading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh Data Profil'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _buildStatCard(
                    title: 'Total Aktivitas',
                    value: '$totalSessions',
                    subtitle: 'Aktivitas tersimpan',
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFF7C4DFF),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Akurasi Nada',
                    value: accuracyText,
                    subtitle: accuracySubtitle,
                    icon: Icons.graphic_eq_rounded,
                    color: const Color(0xFF00A86B),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWeeklyProgressCard(),
              const SizedBox(height: 24),
              _buildAchievementSection(),
              const SizedBox(height: 24),
              _buildMenuTile(
                icon: Icons.settings_rounded,
                title: 'Pengaturan Aplikasi',
                subtitle: 'Atur tampilan, keamanan, dan preferensi aplikasi.',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              _buildMenuTile(
                icon: Icons.history_rounded,
                title: 'Riwayat Aktivitas',
                subtitle:
                    'Lihat catatan latihan, aktivitas, dan progres musikmu.',
                onTap: () => Navigator.pushNamed(context, '/history'),
              ),
              _buildMenuTile(
                icon: Icons.notifications_active_rounded,
                title: 'Notifikasi',
                subtitle:
                    'Cek pengingat latihan dan informasi penting dari aplikasi.',
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
              _buildMenuTile(
                icon: Icons.rate_review_rounded,
                title: 'Saran & Kesan',
                subtitle:
                    'Kirim masukan agar Pitch Perfect bisa terus ditingkatkan.',
                onTap: () => Navigator.pushNamed(context, '/feedback'),
              ),
              _buildMenuTile(
                icon: Icons.logout_rounded,
                title: 'Keluar Akun',
                subtitle: 'Akhiri sesi login dari perangkat ini dengan aman.',
                iconColor: Colors.redAccent,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
