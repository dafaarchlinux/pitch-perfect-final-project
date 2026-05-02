import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/practice_progress_service.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  static const Color _bg = Color(0xFF0B0D22);
  static const Color _surface = Color(0xFF17182C);
  static const Color _surfaceSoft = Color(0xFF232542);
  static const Color _border = Color(0xFF2D3050);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _pink = Color(0xFFF472B6);
  static const Color _green = Color(0xFF34D399);
  static const Color _yellow = Color(0xFFFACC15);

  static const String _bestScoreKey = 'repeat_pitch_best_score';
  static const String _bestLevelKey = 'repeat_pitch_best_level';
  static const String _bestComboKey = 'repeat_pitch_best_combo';
  static const String _lastScoreKey = 'repeat_pitch_last_score';
  static const String _lastLevelKey = 'repeat_pitch_last_level';
  static const String _lastComboKey = 'repeat_pitch_last_combo';
  static const String _lastAccuracyKey = 'repeat_pitch_last_accuracy';
  static const String _lastPlayedAtKey = 'repeat_pitch_last_played_at';

  final AudioPlayer audioPlayer = AudioPlayer();
  final Random random = Random();

  final List<Map<String, dynamic>> notes = const [
    {
      'label': 'Do',
      'tone': 'C4',
      'asset': 'assets/audio/notes/do.wav',
      'color': Color(0xFFE95778),
    },
    {
      'label': 'Re',
      'tone': 'D4',
      'asset': 'assets/audio/notes/re.wav',
      'color': Color(0xFFFF7E5F),
    },
    {
      'label': 'Mi',
      'tone': 'E4',
      'asset': 'assets/audio/notes/mi.wav',
      'color': Color(0xFFFFD34E),
    },
    {
      'label': 'Fa',
      'tone': 'F4',
      'asset': 'assets/audio/notes/fa.wav',
      'color': Color(0xFF81C784),
    },
    {
      'label': 'Sol',
      'tone': 'G4',
      'asset': 'assets/audio/notes/sol.wav',
      'color': Color(0xFF4FC3F7),
    },
    {
      'label': 'La',
      'tone': 'A4',
      'asset': 'assets/audio/notes/la.wav',
      'color': Color(0xFF7986CB),
    },
    {
      'label': 'Si',
      'tone': 'B4',
      'asset': 'assets/audio/notes/si.wav',
      'color': Color(0xFFBA68C8),
    },
    {
      'label': 'Do+',
      'tone': 'C5',
      'asset': 'assets/audio/notes/doo.wav',
      'color': Color(0xFFEC5B93),
    },
  ];

  List<int> sequence = [];
  int userStep = 0;
  int score = 0;
  int level = 1;
  int combo = 0;
  int bestScore = 0;
  int bestLevel = 0;
  int bestCombo = 0;

  String gameMode = 'idle'; // idle, playing, practice, showing, listening, gameOver
  String statusMessage = 'Tekan Mulai Main untuk memulai tantangan nada.';
  int? activeNoteIndex;
  bool isBusy = false;

  bool get _canPressKeys {
    if (isBusy) return false;
    return gameMode == 'practice' ||
        gameMode == 'listening' ||
        gameMode == 'idle' ||
        gameMode == 'gameOver';
  }

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      bestScore = prefs.getInt(_bestScoreKey) ?? 0;
      bestLevel = prefs.getInt(_bestLevelKey) ?? 0;
      bestCombo = prefs.getInt(_bestComboKey) ?? 0;
    });
  }

  Future<void> _saveBestScore({
    required int lastScore,
    required int lastLevel,
    required int lastCombo,
    required int lastAccuracy,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Data ini dibaca juga oleh HomeScreen dan ProfileScreen.
    // Jadi begitu game selesai, ringkasan skor di halaman lain bisa ikut update.
    await Future.wait([
      prefs.setInt(_bestScoreKey, bestScore),
      prefs.setInt(_bestLevelKey, bestLevel),
      prefs.setInt(_bestComboKey, bestCombo),
      prefs.setInt(_lastScoreKey, lastScore),
      prefs.setInt(_lastLevelKey, lastLevel),
      prefs.setInt(_lastComboKey, lastCombo),
      prefs.setInt(_lastAccuracyKey, lastAccuracy),
      prefs.setString(_lastPlayedAtKey, DateTime.now().toIso8601String()),
    ]);
  }

  Future<void> _playNote(int index) async {
    if (index < 0 || index >= notes.length) return;

    setState(() => activeNoteIndex = index);

    try {
      await audioPlayer.stop();
      await audioPlayer.setSpeed(1.0);
      await audioPlayer.setAsset(notes[index]['asset'].toString());
      await audioPlayer.play();
      await Future.delayed(const Duration(milliseconds: 420));
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 240));
    }

    try {
      await audioPlayer.setSpeed(1.0);
    } catch (_) {}

    if (!mounted) return;
    setState(() => activeNoteIndex = null);
  }

  Future<void> _playSequence() async {
    if (sequence.isEmpty || isBusy) return;

    setState(() {
      isBusy = true;
      gameMode = 'showing';
      userStep = 0;
      statusMessage = 'Dengarkan urutan nadanya...';
    });

    await Future.delayed(const Duration(milliseconds: 450));

    for (final noteIndex in sequence) {
      if (!mounted) return;
      await _playNote(noteIndex);
      await Future.delayed(const Duration(milliseconds: 280));
    }

    if (!mounted) return;

    setState(() {
      userStep = 0;
      isBusy = false;
      gameMode = 'listening';
      statusMessage = 'Giliranmu! Ulangi nadanya.';
    });
  }

  Future<void> _startGame() async {
    if (isBusy) return;

    await audioPlayer.stop();

    setState(() {
      score = 0;
      level = 1;
      combo = 0;
      userStep = 0;
      sequence = [random.nextInt(notes.length)];
      gameMode = 'playing';
      statusMessage = 'Bersiap mendengarkan nada pertama...';
    });

    await _playSequence();
  }

  void _startPracticeMode() {
    if (isBusy) return;

    setState(() {
      gameMode = 'practice';
      statusMessage = 'Mode latihan aktif. Tekan tuts secara bebas.';
      sequence = [];
      userStep = 0;
      combo = 0;
    });
  }

  Future<void> _handleNoteTap(int index) async {
    if (!_canPressKeys) return;

    if (gameMode == 'idle' || gameMode == 'gameOver') {
      await _playNote(index);
      setState(() {
        statusMessage = 'Tekan Mulai Main untuk bermain, atau Latihan untuk bebas menekan tuts.';
      });
      return;
    }

    if (gameMode == 'practice') {
      await _playNote(index);
      setState(() {
        statusMessage = 'Mode latihan aktif. Anda dapat melanjutkan permainan kapan saja.';
      });
      return;
    }

    if (gameMode != 'listening') return;

    await _playNote(index);

    final expected = sequence[userStep];
    if (index == expected) {
      final isLast = userStep == sequence.length - 1;

      setState(() {
        userStep++;
        combo++;
        score += 10 + (combo * 2);
        statusMessage = isLast
            ? 'Benar! Level berikutnya dimulai.'
            : 'Benar! Lanjutkan urutannya.';
      });

      if (isLast) {
        await Future.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;

        setState(() {
          level++;
          sequence.add(random.nextInt(notes.length));
          userStep = 0;
        });

        await _playSequence();
      }
    } else {
      await _gameOver();
    }
  }

  Future<void> _gameOver() async {
    final finalScore = score;
    final finalLevel = level;
    final finalCombo = combo;
    final accuracy = ((finalScore / max(1, finalLevel * 20)) * 100)
        .clamp(35, 95)
        .round();

    final isNewBest = finalScore > bestScore;

    setState(() {
      gameMode = 'gameOver';
      statusMessage = isNewBest
          ? 'Game selesai. Skor terbaik baru!'
          : 'Game selesai. Coba ulangi lagi ya.';
      bestScore = max(bestScore, finalScore);
      bestLevel = max(bestLevel, finalLevel);
      bestCombo = max(bestCombo, finalCombo);
      userStep = 0;
      sequence = [];
    });

    await _saveBestScore(
      lastScore: finalScore,
      lastLevel: finalLevel,
      lastCombo: finalCombo,
      lastAccuracy: accuracy,
    );

    try {
      await PracticeProgressService.addPracticeSession(
        title: 'Latihan Repeat Pitch sampai level $finalLevel',
        type: 'Mini Game',
        score: accuracy,
        level: finalLevel,
        combo: finalCombo,
        passed: false,
        metadata: {
          'game_name': 'Repeat Pitch',
          'raw_score': finalScore,
          'accuracy': accuracy,
          'level_reached': finalLevel,
          'best_combo': finalCombo,
          'sequence_length': finalLevel,
          'result': 'Perlu latihan lagi',
          'storage': 'Hive',
        },
      );
    } catch (_) {}
  }

  Future<void> _repeatSequence() async {
    if (sequence.isEmpty || isBusy || gameMode == 'practice') return;
    await _playSequence();
  }

  Widget _pageTitle() {
    return const Text(
      'Mini Games',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _text,
        fontSize: 28,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _gameTitle() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Text(
            'REPEAT PITCH',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _text,
              fontSize: 30,
              height: 1.18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Dengarkan urutan nada, lalu ulangi!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _scoreItem(
              label: 'SKOR SEKARANG',
              value: '$score',
              color: _cyan,
              icon: null,
            ),
          ),
          Container(width: 1, height: 44, color: _border),
          Expanded(
            child: _scoreItem(
              label: 'TERBAIK',
              value: '$bestScore',
              color: _yellow,
              icon: Icons.emoji_events_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreItem({
    required String label,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                color: icon == null ? color : _text,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: _bigActionButton(
            title: gameMode == 'idle' || gameMode == 'gameOver'
                ? 'Mulai Main'
                : 'Ulangi Game',
            icon: Icons.play_arrow_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFF6D4DF2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: _startGame,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _bigActionButton(
            title: 'Latihan',
            icon: Icons.keyboard_alt_rounded,
            gradient: null,
            onTap: _startPracticeMode,
          ),
        ),
      ],
    );
  }

  Widget _bigActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? _surfaceSoft : null,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: gradient == null ? _border : Colors.transparent,
          ),
          boxShadow: gradient == null
              ? []
              : [
                  BoxShadow(
                    color: _purple.withOpacity(0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    final bool practice = gameMode == 'practice';
    final bool gameOver = gameMode == 'gameOver';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: practice
              ? _green.withOpacity(0.65)
              : gameOver
                  ? _pink.withOpacity(0.65)
                  : _cyan.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: practice
                  ? _green
                  : gameOver
                      ? _pink
                      : _green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: sequence.isEmpty || isBusy || gameMode == 'practice'
                ? null
                : _repeatSequence,
            icon: const Icon(Icons.replay_rounded),
            color: _text,
            style: IconButton.styleFrom(backgroundColor: _surfaceSoft),
            tooltip: 'Ulangi nada',
          ),
        ],
      ),
    );
  }

  Widget _scoreInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _miniInfo(
              label: 'LEVEL',
              value: '$level',
              icon: Icons.layers_rounded,
              color: _purple,
            ),
          ),
          Expanded(
            child: _miniInfo(
              label: 'COMBO',
              value: '$combo',
              icon: Icons.flash_on_rounded,
              color: _yellow,
            ),
          ),
          Expanded(
            child: _miniInfo(
              label: 'BEST LEVEL',
              value: '$bestLevel',
              icon: Icons.workspace_premium_rounded,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _text,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _pianoKeys() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 5.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(notes.length, (index) {
            final note = notes[index];
            final color = note['color'] as Color;
            final active = activeNoteIndex == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == notes.length - 1 ? 0 : spacing,
                ),
                child: _pianoKey(
                  height: active ? 118 : 128,
                  color: color,
                  label: note['label'].toString(),
                  tone: note['tone'].toString(),
                  active: active,
                  onTap: () => _handleNoteTap(index),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _pianoKey({
    required double height,
    required Color color,
    required String label,
    required String tone,
    required bool active,
    required VoidCallback onTap,
  }) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: active ? 0.94 : 1,
      child: InkWell(
        onTap: _canPressKeys ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(active ? 1 : 0.95),
                color.withOpacity(active ? 0.72 : 0.86),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(active ? 0.38 : 0.16),
                blurRadius: active ? 20 : 10,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tone,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.info_outline_rounded, color: _muted, size: 15),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            gameMode == 'practice'
                ? 'MODE LATIHAN: TEKAN TUTS SECARA BEBAS.'
                : 'TEKAN TUTS SESUAI URUTAN UNTUK MENDAPATKAN SKOR TINGGI.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
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
        iconTheme: const IconThemeData(color: _text),
        title: const Text(
          'Mini Games',
          style: TextStyle(
            color: _text,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          children: [
            _gameTitle(),
            const SizedBox(height: 22),
            _actionButtons(),
            const SizedBox(height: 16),
            _scoreBoard(),
            const SizedBox(height: 16),
            _statusCard(),
            const SizedBox(height: 16),
            _scoreInfo(),
            if (gameMode != 'idle') ...[
              const SizedBox(height: 26),
              _pianoKeys(),
              const SizedBox(height: 20),
              _hint(),
            ],
          ],
        ),
      ),
    );
  }
}
