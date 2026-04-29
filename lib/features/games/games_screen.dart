import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/practice_progress_service.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final Random random = Random();

  String gameState = 'idle';
  int level = 1;
  int score = 0;
  int combo = 0;
  int bestCombo = 0;
  int userIndex = 0;
  int? activeNoteIndex;
  bool isSaving = false;

  int bestScoreSaved = 0;
  int bestLevelSaved = 0;
  int bestComboSaved = 0;

  final List<int> sequence = [];

  final List<Map<String, dynamic>> notes = [
    {
      'label': 'Do',
      'asset': 'assets/audio/notes/do.wav',
      'emoji': '🍎',
      'color': Color(0xFFE85D75),
    },
    {
      'label': 'Re',
      'asset': 'assets/audio/notes/re.wav',
      'emoji': '🍊',
      'color': Color(0xFFFF8A65),
    },
    {
      'label': 'Mi',
      'asset': 'assets/audio/notes/mi.wav',
      'emoji': '🍋',
      'color': Color(0xFFFFC857),
    },
    {
      'label': 'Fa',
      'asset': 'assets/audio/notes/fa.wav',
      'emoji': '🍃',
      'color': Color(0xFF21C67A),
    },
    {
      'label': 'Sol',
      'asset': 'assets/audio/notes/sol.wav',
      'emoji': '💧',
      'color': Color(0xFF00A6FB),
    },
    {
      'label': 'La',
      'asset': 'assets/audio/notes/la.wav',
      'emoji': '🌌',
      'color': Color(0xFF5E60CE),
    },
    {
      'label': 'Si',
      'asset': 'assets/audio/notes/si.wav',
      'emoji': '🍇',
      'color': Color(0xFF9C27B0),
    },
  ];

  String get feedbackText {
    switch (gameState) {
      case 'playing':
        return 'Dengarkan urutan nadanya...';
      case 'user_turn':
        return 'Sekarang tekan urutan nada yang sama!';
      case 'success':
        return 'Keren! Level berikutnya dimulai.';
      case 'game_over':
        return 'Ups, urutannya belum tepat. Coba lagi!';
      case 'finished':
        return 'Lolos! Pendengaran nadamu makin tajam.';
      default:
        return 'Dengarkan nada, lalu ulangi dengan menekan tombol.';
    }
  }

  String get mascot {
    switch (gameState) {
      case 'playing':
        return '🐦';
      case 'user_turn':
        return '🐤';
      case 'success':
        return '🥳';
      case 'game_over':
        return '🥺';
      case 'finished':
        return '🏆';
      default:
        return '🎵';
    }
  }

  Future<void> _playNote(int index) async {
    setState(() => activeNoteIndex = index);

    await audioPlayer.stop();
    await audioPlayer.setAsset(notes[index]['asset'].toString());
    await audioPlayer.play();

    await Future.delayed(const Duration(milliseconds: 420));

    if (!mounted) return;
    setState(() => activeNoteIndex = null);
  }

  Future<void> _playSequence() async {
    setState(() {
      gameState = 'playing';
      userIndex = 0;
    });

    await Future.delayed(const Duration(milliseconds: 450));

    for (final noteIndex in sequence) {
      if (!mounted) return;
      await _playNote(noteIndex);
      await Future.delayed(const Duration(milliseconds: 280));
    }

    if (!mounted) return;

    setState(() {
      gameState = 'user_turn';
    });
  }

  Future<void> _startGame() async {
    await audioPlayer.stop();

    setState(() {
      level = 1;
      score = 0;
      combo = 0;
      bestCombo = 0;
      userIndex = 0;
      sequence
        ..clear()
        ..add(random.nextInt(notes.length));
      gameState = 'playing';
    });

    await _playSequence();
  }

  Future<void> _nextLevel() async {
    if (level >= 100) {
      await _finishGame();
      return;
    }

    setState(() {
      level++;
      sequence.add(random.nextInt(notes.length));
      gameState = 'success';
    });

    await Future.delayed(const Duration(milliseconds: 850));
    await _playSequence();
  }

  Future<void> _handleNoteTap(int index) async {
    if (gameState != 'user_turn') return;

    await _playNote(index);

    final expected = sequence[userIndex];

    if (index == expected) {
      setState(() {
        userIndex++;
        combo++;
        if (combo > bestCombo) bestCombo = combo;
        score += 10 + (combo * 2);
      });

      await _updateBestRecords();

      if (userIndex >= sequence.length) {
        await _nextLevel();
      }
    } else {
      setState(() {
        combo = 0;
        gameState = 'game_over';
      });

      await _saveResult(passed: false);
    }
  }

  Future<void> _finishGame() async {
    setState(() {
      gameState = 'finished';
    });

    await _saveResult(passed: true);
  }

  Future<void> _saveResult({required bool passed}) async {
    if (isSaving) return;

    setState(() => isSaving = true);

    final accuracy = passed
        ? 100
        : ((score / max(1, level * 20)) * 100).clamp(35, 95).round();

    await PracticeProgressService.addPracticeSession(
      title: passed
          ? 'Lolos Repeat Pitch level $level'
          : 'Latihan Repeat Pitch sampai level $level',
      type: 'Mini Game',
      score: accuracy,
      level: level,
      combo: bestCombo,
      passed: passed,
      metadata: {
        'game_name': 'Repeat Pitch',
        'raw_score': score,
        'accuracy': accuracy,
        'level_reached': level,
        'best_combo': bestCombo,
        'sequence_length': sequence.length,
        'max_level': 100,
        'result': passed ? 'Selesai' : 'Perlu latihan lagi',
      },
    );

    await _loadLeaderboard();

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          passed
              ? 'Mantap! Kamu berhasil menyelesaikan challenge.'
              : 'Game selesai. Skor terbaik akan tersimpan otomatis.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _replaySequence() async {
    if (gameState == 'playing') return;
    await _playSequence();
  }

  Widget _buildStatusCard() {
    final progress = sequence.isEmpty ? 0.0 : userIndex / sequence.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E35B1).withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Text(mascot, style: const TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gameState == 'finished'
                          ? 'Challenge Lolos!'
                          : 'Repeat Pitch',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      feedbackText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildHeroMiniInfo('Level', '$level'),
              const SizedBox(width: 10),
              _buildHeroMiniInfo('Skor', '$score'),
              const SizedBox(width: 10),
              _buildHeroMiniInfo('Combo', '${combo}x'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              color: const Color(0xFFFFC857),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sequence.isEmpty
                ? 'Belum mulai'
                : 'Progress jawaban: $userIndex / ${sequence.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMiniInfo(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteButton(int index) {
    final note = notes[index];
    final color = note['color'] as Color;
    final isActive = activeNoteIndex == index;
    final canTap = gameState == 'user_turn';

    return SizedBox(
      width: 76,
      height: 86,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: isActive ? 1.08 : 1.0,
        child: ElevatedButton(
          onPressed: canTap ? () => _handleNoteTap(index) : null,
          style: ElevatedButton.styleFrom(
            elevation: isActive ? 8 : 0,
            backgroundColor: canTap || isActive
                ? color
                : const Color(0xFFF0F0F6),
            disabledBackgroundColor: isActive ? color : const Color(0xFFF0F0F6),
            foregroundColor: Colors.white,
            disabledForegroundColor: isActive
                ? Colors.white
                : const Color(0xFFB1B3BE),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                note['label'].toString(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                note['emoji'].toString(),
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEDEDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Papan Nada',
            style: TextStyle(
              color: Color(0xFF20243A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            gameState == 'user_turn'
                ? 'Tekan nada sesuai urutan yang kamu dengar.'
                : 'Tombol nada akan aktif saat giliranmu menjawab.',
            style: const TextStyle(
              color: Color(0xFF7C7E8A),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                notes.length,
                (index) => _buildNoteButton(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (gameState == 'idle') {
      return _buildPrimaryButton(
        label: 'Mulai Main',
        icon: Icons.play_arrow_rounded,
        onPressed: _startGame,
      );
    }

    if (gameState == 'game_over') {
      return _buildPrimaryButton(
        label: 'Coba Lagi',
        icon: Icons.refresh_rounded,
        onPressed: _startGame,
      );
    }

    if (gameState == 'finished') {
      return _buildPrimaryButton(
        label: 'Main Lagi',
        icon: Icons.emoji_events_rounded,
        onPressed: _startGame,
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: gameState == 'playing' ? null : _replaySequence,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Dengar Lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5E35B1),
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPrimaryButton(
            label: 'Ulang Game',
            icon: Icons.restart_alt_rounded,
            onPressed: _startGame,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE85D75),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildHowToPlay() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE2C7)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: Color(0xFFFF8A65), size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Cara main: dengarkan urutan nada random, lalu tekan tombol Do Re Mi sesuai urutan. Setiap level menambah satu nada baru. Target tertinggi: level 100.',
              style: TextStyle(
                color: Color(0xFF8A4B22),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBestRecords() async {
    final prefs = await SharedPreferences.getInstance();

    final oldBestScore = prefs.getInt('game_best_score') ?? 0;
    final oldBestLevel = prefs.getInt('game_best_level') ?? 0;
    final oldBestCombo = prefs.getInt('game_best_combo') ?? 0;

    if (score > oldBestScore) {
      await prefs.setInt('game_best_score', score);
    }

    if (level > oldBestLevel) {
      await prefs.setInt('game_best_level', level);
    }

    if (bestCombo > oldBestCombo) {
      await prefs.setInt('game_best_combo', bestCombo);
    }

    await _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      bestScoreSaved = prefs.getInt('game_best_score') ?? 0;
      bestLevelSaved = prefs.getInt('game_best_level') ?? 0;
      bestComboSaved = prefs.getInt('game_best_combo') ?? 0;
    });
  }

  Widget _buildLeaderboardCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEDEDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFB703),
                size: 27,
              ),
              SizedBox(width: 10),
              Text(
                'Papan Skor',
                style: TextStyle(
                  color: Color(0xFF20243A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildLeaderboardMini(
                'Skor',
                bestScoreSaved == 0 ? '-' : '$bestScoreSaved',
              ),
              const SizedBox(width: 10),
              _buildLeaderboardMini(
                'Level',
                bestLevelSaved == 0 ? '-' : '$bestLevelSaved',
              ),
              const SizedBox(width: 10),
              _buildLeaderboardMini(
                'Combo',
                bestComboSaved == 0 ? '-' : '${bestComboSaved}x',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bestScoreSaved == 0
                ? 'Belum ada rekor. Tekan Mulai Main untuk membuat skor pertamamu.'
                : 'Rekor terbaikmu tersimpan otomatis saat skor, level, atau combo meningkat.',
            style: const TextStyle(
              color: Color(0xFF7C7E8A),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardMini(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF20243A),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF8A8D99),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  static const Color _bgColor = Color(0xFFFCFCFE);

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mini Games',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 170),
        children: [
          const Text(
            'Latih telinga musikmu dengan game tangga nada yang cepat dan seru.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF7C7E8A),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatusCard(),
          const SizedBox(height: 18),
          _buildLeaderboardCard(),
          const SizedBox(height: 18),
          _buildControls(),
          const SizedBox(height: 18),
          _buildNoteBoard(),
          const SizedBox(height: 18),
          _buildHowToPlay(),
        ],
      ),
    );
  }
}
