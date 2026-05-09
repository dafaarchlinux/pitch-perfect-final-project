import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/practice_progress_service.dart';
import '../../services/session_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bg = Color(0xFF0B0D22);
  static const Color _surface = Color(0xFF17182C);
  static const Color _surfaceSoft = Color(0xFF232542);
  static const Color _border = Color(0xFF2D3050);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFFB8BCD7);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _pink = Color(0xFFF472B6);
  static const Color _green = Color(0xFF34D399);

  // Piano Game / Repeat Pitch
  static const String _bestScoreKey = 'repeat_pitch_best_score';
  static const String _bestLevelKey = 'repeat_pitch_best_level';
  static const String _bestComboKey = 'repeat_pitch_best_combo';

  // Voice Game / Voice Match
  static const String _voiceBestScoreKey = 'voice_match_best_score';
  static const String _voiceBestLevelKey = 'voice_match_best_level';
  static const String _voiceBestComboKey = 'voice_match_best_combo';

  // Overall best game, disimpan dari halaman Games.
  static const String _overallBestScoreKey = 'music_game_best_score';
  static const String _overallBestLevelKey = 'music_game_best_level';
  static const String _overallBestComboKey = 'music_game_best_combo';
  static const String _overallBestSourceKey = 'music_game_best_source';

  static const String _lastScoreKey = 'repeat_pitch_last_score';
  static const String _lastLevelKey = 'repeat_pitch_last_level';
  static const String _lastComboKey = 'repeat_pitch_last_combo';
  static const String _lastAccuracyKey = 'repeat_pitch_last_accuracy';
  static const String _lastPlayedAtKey = 'repeat_pitch_last_played_at';

  Timer? _gameScoreRefreshTimer;

  String userName = 'Pengguna';
  String userEmail = 'guest@email.com';
  String? profileImagePath;

  int totalSessions = 0;
  int weeklySessions = 0;
  int? averageScore;
  Map<String, int> gameRecords = {
    'best_score': 0,
    'best_level': 0,
    'best_combo': 0,
  };
  Map<String, dynamic>? latestGameResult;
  String bestGameSource = 'Skor';

  bool biometricEnabled = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _startGameScoreAutoRefresh();
  }

  @override
  void dispose() {
    _gameScoreRefreshTimer?.cancel();
    super.dispose();
  }

  void _startGameScoreAutoRefresh() {
    _gameScoreRefreshTimer?.cancel();
    _gameScoreRefreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshGameScoreOnly(),
    );
  }

  int _biggerInt(int a, int b) => a > b ? a : b;

  bool _sameGameRecords(Map<String, int> a, Map<String, int> b) {
    return (a['best_score'] ?? 0) == (b['best_score'] ?? 0) &&
        (a['best_level'] ?? 0) == (b['best_level'] ?? 0) &&
        (a['best_combo'] ?? 0) == (b['best_combo'] ?? 0);
  }

  Future<Map<String, int>> _readGameRecords() async {
    Map<String, int> records = {
      'best_score': 0,
      'best_level': 0,
      'best_combo': 0,
    };

    try {
      records = await PracticeProgressService.getGameRecords();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();

      final legacyScore = records['best_score'] ?? 0;
      final legacyLevel = records['best_level'] ?? 0;
      final legacyCombo = records['best_combo'] ?? 0;

      final pianoScore = _biggerInt(
        legacyScore,
        prefs.getInt(_bestScoreKey) ?? 0,
      );
      final pianoLevel = _biggerInt(
        legacyLevel,
        prefs.getInt(_bestLevelKey) ?? 0,
      );
      final pianoCombo = _biggerInt(
        legacyCombo,
        prefs.getInt(_bestComboKey) ?? 0,
      );

      final voiceScore = prefs.getInt(_voiceBestScoreKey) ?? 0;
      final voiceLevel = prefs.getInt(_voiceBestLevelKey) ?? 0;
      final voiceCombo = prefs.getInt(_voiceBestComboKey) ?? 0;

      final overallScore = prefs.getInt(_overallBestScoreKey) ?? 0;
      final overallLevel = prefs.getInt(_overallBestLevelKey) ?? 0;
      final overallCombo = prefs.getInt(_overallBestComboKey) ?? 0;

      if (overallScore >= pianoScore && overallScore >= voiceScore) {
        records = {
          'best_score': overallScore,
          'best_level': overallLevel,
          'best_combo': overallCombo,
        };
      } else if (voiceScore > pianoScore) {
        records = {
          'best_score': voiceScore,
          'best_level': voiceLevel,
          'best_combo': voiceCombo,
        };
      } else {
        records = {
          'best_score': pianoScore,
          'best_level': pianoLevel,
          'best_combo': pianoCombo,
        };
      }
    } catch (_) {}

    return records;
  }

  Future<String> _readBestGameSource(Map<String, int> records) async {
    final bestScore = records['best_score'] ?? 0;
    if (bestScore <= 0) return 'Skor';

    try {
      final prefs = await SharedPreferences.getInstance();
      final pianoScore = prefs.getInt(_bestScoreKey) ?? 0;
      final voiceScore = prefs.getInt(_voiceBestScoreKey) ?? 0;
      final overallScore = prefs.getInt(_overallBestScoreKey) ?? 0;
      final overallSource = prefs.getString(_overallBestSourceKey);

      if (overallScore == bestScore &&
          overallSource != null &&
          overallSource.trim().isNotEmpty &&
          overallSource != 'Belum ada game') {
        return overallSource;
      }

      if (voiceScore == bestScore && voiceScore >= pianoScore) {
        return 'Voice Game';
      }

      if (pianoScore == bestScore) {
        return 'Piano Game';
      }
    } catch (_) {}

    return 'Piano Game';
  }

  Future<Map<String, dynamic>?> _readLatestGameResult() async {
    Map<String, dynamic>? latestGame;

    try {
      latestGame = await PracticeProgressService.getLatestGameResult();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastScore = prefs.getInt(_lastScoreKey);
      final lastPlayedAt = prefs.getString(_lastPlayedAtKey);

      if (lastScore != null) {
        final fallbackLatestGame = {
          'game_name': 'Repeat Pitch',
          'raw_score': lastScore,
          'score': prefs.getInt(_lastAccuracyKey) ?? 0,
          'level': prefs.getInt(_lastLevelKey) ?? 0,
          'combo': prefs.getInt(_lastComboKey) ?? 0,
          'played_at': lastPlayedAt,
        };

        latestGame = fallbackLatestGame;
      }
    } catch (_) {}

    return latestGame;
  }

  Future<void> _refreshGameScoreOnly() async {
    final records = await _readGameRecords();
    final source = await _readBestGameSource(records);
    final latestGame = await _readLatestGameResult();

    if (!mounted) return;

    if (!_sameGameRecords(gameRecords, records) ||
        latestGameResult.toString() != latestGame.toString() ||
        bestGameSource != source) {
      setState(() {
        gameRecords = records;
        latestGameResult = latestGame;
        bestGameSource = source;
      });
    }
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    String nextName = 'Pengguna';
    String nextEmail = 'guest@email.com';
    String? nextImagePath;
    int nextTotalSessions = 0;
    int nextWeeklySessions = 0;
    int? nextAverageScore;
    Map<String, int> nextGameRecords = {
      'best_score': 0,
      'best_level': 0,
      'best_combo': 0,
    };
    Map<String, dynamic>? nextLatestGameResult;
    String nextBestGameSource = 'Skor';
    bool nextBiometricEnabled = false;

    try {
      nextName = await SessionService.getUserName();
      nextEmail = await SessionService.getUserEmail();
      nextImagePath = await SessionService.getProfileImagePath();
    } catch (_) {}

    try {
      final summary = await PracticeProgressService.getSummary();

      nextTotalSessions = summary['total_sessions'] ?? 0;
      nextWeeklySessions = summary['weekly_sessions'] ?? 0;
      nextAverageScore = summary['average_score'];
    } catch (_) {}

    nextGameRecords = await _readGameRecords();
    nextBestGameSource = await _readBestGameSource(nextGameRecords);
    nextLatestGameResult = await _readLatestGameResult();

    try {
      nextBiometricEnabled =
          await SessionService.isCurrentUserBiometricEnabled();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      userName = nextName.trim().isEmpty ? 'Pengguna' : nextName.trim();
      userEmail = nextEmail.trim().isEmpty
          ? 'guest@email.com'
          : nextEmail.trim();
      profileImagePath = nextImagePath;
      totalSessions = nextTotalSessions;
      weeklySessions = nextWeeklySessions;
      averageScore = nextAverageScore;
      gameRecords = nextGameRecords;
      latestGameResult = nextLatestGameResult;
      bestGameSource = nextBestGameSource;
      biometricEnabled = nextBiometricEnabled;
      isLoading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 900,
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

    _showMessage('Foto profil berhasil diperbarui.');
  }

  Future<void> _toggleBiometric() async {
    if (biometricEnabled) {
      await SessionService.disableBiometric();

      if (!mounted) return;

      setState(() {
        biometricEnabled = false;
      });

      _showMessage('Login biometrik dinonaktifkan.');
      return;
    }

    await SessionService.enableBiometricForUser(
      name: userName,
      email: userEmail,
    );

    if (!mounted) return;

    setState(() {
      biometricEnabled = true;
    });

    _showMessage('Login biometrik diaktifkan.');
  }

  Future<void> _logout() async {
    await SessionService.clearSession();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(color: _text, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Yakin ingin keluar dari akun ini? Kamu akan tetap bisa masuk kembali dengan email dan password yang sama.',
            style: TextStyle(
              color: _muted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: _muted,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Batal',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Keluar',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
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

  Widget _avatar() {
    final path = profileImagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    return Stack(
      children: [
        Container(
          width: 108,
          height: 108,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_purple, _cyan, _pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _cyan.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: _surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: hasImage
                ? Image.file(File(path), fit: BoxFit.cover)
                : const Icon(Icons.person_rounded, color: _muted, size: 58),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: InkWell(
            onTap: _pickProfileImage,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_cyan, _purple]),
                shape: BoxShape.circle,
                border: Border.all(color: _bg, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17182C), Color(0xFF251640), Color(0xFF122637)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _avatar(),
          const SizedBox(height: 16),
          Text(
            userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _text,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            userEmail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _statusChip(
                icon: Icons.verified_user_rounded,
                text: 'Session aktif',
                color: _green,
              ),
              _statusChip(
                icon: biometricEnabled
                    ? Icons.fingerprint_rounded
                    : Icons.fingerprint_outlined,
                text: biometricEnabled
                    ? 'Biometrik aktif'
                    : 'Biometrik nonaktif',
                color: biometricEnabled ? _cyan : _muted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final accuracy = averageScore == null ? '-' : '$averageScore%';
    final bestScore = gameRecords['best_score'] ?? 0;

    return Row(
      children: [
        _statItem(
          title: 'Aktivitas',
          value: '$totalSessions',
          icon: Icons.history_rounded,
          color: _purple,
        ),
        const SizedBox(width: 10),
        _statItem(
          title: 'Minggu Ini',
          value: '$weeklySessions',
          icon: Icons.bolt_rounded,
          color: _green,
        ),
        const SizedBox(width: 10),
        _statItem(
          title: 'Akurasi',
          value: accuracy,
          icon: Icons.insights_rounded,
          color: _cyan,
        ),
        const SizedBox(width: 10),
        _statItem(
          title: bestScore <= 0 ? 'Skor' : bestGameSource,
          value: '$bestScore',
          icon: Icons.videogame_asset_rounded,
          color: _pink,
        ),
      ],
    );
  }

  Widget _gameMiniInfo({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF7E84A8),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: _text,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

Widget _buildMenus() {
  return Column(
    children: [
      _menuTile(
        icon: biometricEnabled
            ? Icons.fingerprint_rounded
            : Icons.fingerprint_outlined,
        title: biometricEnabled ? 'Biometrik Aktif' : 'Aktifkan Biometrik',
        subtitle: biometricEnabled
            ? 'Login cepat dengan fingerprint sudah aktif.'
            : 'Gunakan fingerprint untuk masuk lebih cepat.',
        color: biometricEnabled ? _green : _cyan,
        onTap: _toggleBiometric,
      ),
      const SizedBox(height: 14),
      _menuTile(
        icon: Icons.notifications_rounded,
        title: 'Notifikasi',
        subtitle: 'Lihat daftar pemberitahuan yang telah diterima.',
        color: _cyan,
        onTap: () => Navigator.pushNamed(context, '/notifications'),
      ),
      const SizedBox(height: 14),
      _menuTile(
        icon: Icons.history_rounded,
        title: 'Riwayat Latihan',
        subtitle: 'Lihat aktivitas, referensi musik, dan progres.',
        color: _green,
        onTap: () => Navigator.pushNamed(context, '/history'),
      ),
      const SizedBox(height: 14),
      _menuTile(
        icon: Icons.chat_bubble_rounded,
        title: 'Saran & Kesan TPM',
        subtitle: 'Tulis kesan dan saran untuk mata kuliah TPM.',
        color: _cyan,
        onTap: () => Navigator.pushNamed(context, '/feedback'),
      ),
      const SizedBox(height: 14),
      _menuTile(
        icon: Icons.logout_rounded,
        title: 'Logout',
        subtitle: 'Keluar dari akun di perangkat ini.',
        color: _pink,
        onTap: _showLogoutDialog,
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil',
          style: TextStyle(color: _text, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: _text),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 118),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _sectionTitle('Ringkasan'),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(color: _purple),
                  ),
                )
              else ...[
                _buildStats(),
              ],
              const SizedBox(height: 24),
              _sectionTitle('Menu'),
              _buildMenus(),
            ],
          ),
        ),
      ),
    );
  }
}
