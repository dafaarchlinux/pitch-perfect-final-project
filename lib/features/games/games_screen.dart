import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
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

  static const String _pianoBestScoreKey = 'repeat_pitch_best_score';
  static const String _pianoBestLevelKey = 'repeat_pitch_best_level';
  static const String _pianoBestComboKey = 'repeat_pitch_best_combo';
  static const String _voiceBestScoreKey = 'voice_match_best_score';
  static const String _voiceBestLevelKey = 'voice_match_best_level';
  static const String _voiceBestComboKey = 'voice_match_best_combo';

  static const int _pianoSequenceStepMs = 1000;
  static const int _pianoNoteHoldMs = 600;
  static const int _pianoTapHoldMs = 300;
  static const int _voiceTargetHoldMs = 650;
  static const int _voiceStepGapMs = 250;
  static const int _voiceStableHitNeed = 2;
  static const int _voiceProcessEveryMs = 70;
  static const double _voiceMatchToleranceCents = 55;

  final AudioPlayer audioPlayer = AudioPlayer();
  final FlutterPitchDetection voicePitchDetector = FlutterPitchDetection();
  StreamSubscription<dynamic>? voicePitchSubscription;
  Timer? voiceTargetTimer;
  final Random random = Random();

  final List<Map<String, dynamic>> pianoNotes = const [
    {
      'label': 'Do',
      'tone': 'C4',
      'asset': 'assets/audio/notes/do.wav',
      'frequency': 261.63,
      'color': Color(0xFFE95778),
    },
    {
      'label': 'Re',
      'tone': 'D4',
      'asset': 'assets/audio/notes/re.wav',
      'frequency': 293.66,
      'color': Color(0xFFFF7E5F),
    },
    {
      'label': 'Mi',
      'tone': 'E4',
      'asset': 'assets/audio/notes/mi.wav',
      'frequency': 329.63,
      'color': Color(0xFFFFD34E),
    },
    {
      'label': 'Fa',
      'tone': 'F4',
      'asset': 'assets/audio/notes/fa.wav',
      'frequency': 349.23,
      'color': Color(0xFF81C784),
    },
    {
      'label': 'Sol',
      'tone': 'G4',
      'asset': 'assets/audio/notes/sol.wav',
      'frequency': 392.00,
      'color': Color(0xFF4FC3F7),
    },
    {
      'label': 'La',
      'tone': 'A4',
      'asset': 'assets/audio/notes/la.wav',
      'frequency': 440.00,
      'color': Color(0xFF7986CB),
    },
    {
      'label': 'Si',
      'tone': 'B4',
      'asset': 'assets/audio/notes/si.wav',
      'frequency': 493.88,
      'color': Color(0xFFBA68C8),
    },
    {
      'label': 'Do+',
      'tone': 'C5',
      'asset': 'assets/audio/notes/doo.wav',
      'frequency': 523.25,
      'color': Color(0xFFEC5B93),
    },
  ];

  String selectedGame = 'piano'; // piano, voice
  String gameState = 'idle';
  String statusMessage = 'Pilih mode game untuk memulai latihan nada.';

  int score = 0;
  int level = 1;
  int combo = 0;

  int pianoBestScore = 0;
  int pianoBestLevel = 0;
  int pianoBestCombo = 0;
  int voiceBestScore = 0;
  int voiceBestLevel = 0;
  int voiceBestCombo = 0;

  List<int> pianoSequence = [];
  int pianoUserStep = 0;
  int? activePianoNoteIndex;
  bool isBusy = false;

  List<_VoiceTargetNote> voiceSequence = [];
  int voiceUserStep = 0;
  String detectedVoiceNote = '-';
  double detectedVoiceFrequency = 0;
  double voiceCentsDiff = 0;
  int voiceStableHits = 0;
  bool voiceProcessingCorrect = false;
  final List<double> voiceFrequencyBuffer = [];
  DateTime lastVoiceProcessTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isPianoMode => selectedGame == 'piano';
  bool get isVoiceMode => selectedGame == 'voice';

  bool get isGameRunning {
    return gameState == 'pianoShowing' ||
        gameState == 'pianoListening' ||
        gameState == 'voiceShowing' ||
        gameState == 'voiceListening';
  }

  bool get _canPressPianoKeys {
    return isPianoMode && !isBusy && gameState == 'pianoListening';
  }

  int get activeBestScore => isVoiceMode ? voiceBestScore : pianoBestScore;
  int get activeBestLevel => isVoiceMode ? voiceBestLevel : pianoBestLevel;

  _VoiceTargetNote? get activeVoiceTarget {
    if (voiceSequence.isEmpty || voiceUserStep >= voiceSequence.length) return null;
    return voiceSequence[voiceUserStep];
  }

  @override
  void initState() {
    super.initState();
    _loadBestRecords();
  }

  @override
  void dispose() {
    voiceTargetTimer?.cancel();
    voicePitchSubscription?.cancel();
    voicePitchDetector.stopDetection();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadBestRecords() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      pianoBestScore = prefs.getInt(_pianoBestScoreKey) ?? 0;
      pianoBestLevel = prefs.getInt(_pianoBestLevelKey) ?? 0;
      pianoBestCombo = prefs.getInt(_pianoBestComboKey) ?? 0;
      voiceBestScore = prefs.getInt(_voiceBestScoreKey) ?? 0;
      voiceBestLevel = prefs.getInt(_voiceBestLevelKey) ?? 0;
      voiceBestCombo = prefs.getInt(_voiceBestComboKey) ?? 0;
    });
  }

  Future<void> _saveBestRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_pianoBestScoreKey, pianoBestScore),
      prefs.setInt(_pianoBestLevelKey, pianoBestLevel),
      prefs.setInt(_pianoBestComboKey, pianoBestCombo),
      prefs.setInt(_voiceBestScoreKey, voiceBestScore),
      prefs.setInt(_voiceBestLevelKey, voiceBestLevel),
      prefs.setInt(_voiceBestComboKey, voiceBestCombo),
    ]);
  }

  Future<bool> _confirmEndGame() async {
    if (!isGameRunning) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Akhiri Permainan?',
            style: TextStyle(color: _text, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Yakin ingin mengakhiri permainan? Hasil sementara akan disimpan ke riwayat.',
            style: TextStyle(
              color: _muted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
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
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Akhiri',
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

    return result ?? false;
  }

  Future<void> _selectGame(String mode) async {
    if (selectedGame == mode) return;

    final allowed = await _confirmEndGame();
    if (!allowed) return;

    if (isGameRunning) {
      await _endCurrentGame(endedByUser: true);
    }

    setState(() {
      selectedGame = mode;
      _resetCurrentGameState();
      statusMessage = mode == 'piano'
          ? 'Game Piano siap. Dengarkan urutan nada lalu ulangi dengan tuts.'
          : 'Voice Match siap. Tirukan nada target menggunakan suaramu.';
    });
  }

  void _resetCurrentGameState() {
    score = 0;
    level = 1;
    combo = 0;
    gameState = 'idle';
    pianoSequence = [];
    pianoUserStep = 0;
    activePianoNoteIndex = null;
    voiceSequence = [];
    voiceUserStep = 0;
    detectedVoiceNote = '-';
    detectedVoiceFrequency = 0;
    voiceCentsDiff = 0;
    voiceStableHits = 0;
    voiceProcessingCorrect = false;
    voiceFrequencyBuffer.clear();
    lastVoiceProcessTime = DateTime.fromMillisecondsSinceEpoch(0);
    isBusy = false;
  }

  Future<void> _endCurrentGame({bool endedByUser = false}) async {
    if (isVoiceMode) {
      await _stopVoiceDetection();
    }

    if (isPianoMode) {
      await _savePianoResult(endedByUser: endedByUser);
    } else {
      await _saveVoiceResult(endedByUser: endedByUser, reason: 'Diakhiri user');
    }

    if (!mounted) return;

    setState(() {
      gameState = 'gameOver';
      statusMessage = endedByUser
          ? 'Permainan diakhiri dan hasilnya sudah disimpan.'
          : 'Permainan selesai.';
    });
  }

  Future<void> _playPianoNote(int index, {int milliseconds = _pianoNoteHoldMs}) async {
    if (index < 0 || index >= pianoNotes.length) return;

    setState(() => activePianoNoteIndex = index);

    try {
      await audioPlayer.stop();
      await audioPlayer.setVolume(1.0);
      await audioPlayer.setSpeed(1.0);
      await audioPlayer.setAsset(pianoNotes[index]['asset'].toString());
      await audioPlayer.play();
      await Future.delayed(Duration(milliseconds: milliseconds));
    } catch (_) {
      await _playToneFrequency(
        (pianoNotes[index]['frequency'] as num).toDouble(),
        milliseconds: milliseconds,
      );
    }

    if (!mounted) return;
    setState(() => activePianoNoteIndex = null);
  }

  Future<void> _startPianoGame() async {
    final allowed = await _confirmEndGame();
    if (!allowed) return;

    if (isGameRunning) await _endCurrentGame(endedByUser: true);

    await _stopVoiceDetection();
    await audioPlayer.stop();

    setState(() {
      selectedGame = 'piano';
      score = 0;
      level = 1;
      combo = 0;
      pianoUserStep = 0;
      pianoSequence = [random.nextInt(pianoNotes.length)];
      gameState = 'pianoShowing';
      statusMessage = 'Bersiap mendengarkan nada pertama...';
    });

    await _playPianoSequence();
  }

  Future<void> _playPianoSequence() async {
    if (pianoSequence.isEmpty || isBusy) return;

    setState(() {
      isBusy = true;
      gameState = 'pianoShowing';
      pianoUserStep = 0;
      statusMessage = 'Dengarkan urutan nadanya...';
    });

    await Future.delayed(const Duration(milliseconds: 450));

    for (final noteIndex in pianoSequence) {
      if (!mounted) return;
      final stepStart = DateTime.now();
      await _playPianoNote(noteIndex, milliseconds: _pianoNoteHoldMs);
      final elapsedMs = DateTime.now().difference(stepStart).inMilliseconds;
      final remainingMs = max(0, _pianoSequenceStepMs - elapsedMs);
      await Future.delayed(Duration(milliseconds: remainingMs));
    }

    if (!mounted) return;

    setState(() {
      pianoUserStep = 0;
      isBusy = false;
      gameState = 'pianoListening';
      statusMessage = 'Giliranmu! Tekan tuts sesuai urutan.';
    });
  }

  Future<void> _handlePianoKeyTap(int index) async {
    if (!_canPressPianoKeys) return;

    await _playPianoNote(index, milliseconds: _pianoTapHoldMs);

    final expected = pianoSequence[pianoUserStep];
    if (index == expected) {
      final isLast = pianoUserStep == pianoSequence.length - 1;

      setState(() {
        pianoUserStep++;
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
          pianoSequence.add(random.nextInt(pianoNotes.length));
          pianoUserStep = 0;
        });

        await _playPianoSequence();
      }
    } else {
      await _pianoGameOver();
    }
  }

  Future<void> _pianoGameOver() async {
    final finalScore = score;
    final finalLevel = level;
    final finalCombo = combo;

    setState(() {
      gameState = 'gameOver';
      statusMessage = finalScore > pianoBestScore
          ? 'Game Piano selesai. Skor terbaik baru!'
          : 'Game Piano selesai. Coba ulangi lagi ya.';
      pianoBestScore = max(pianoBestScore, finalScore);
      pianoBestLevel = max(pianoBestLevel, finalLevel);
      pianoBestCombo = max(pianoBestCombo, finalCombo);
      pianoSequence = [];
      pianoUserStep = 0;
    });

    await _saveBestRecords();
    await _savePianoResult();
  }

  Future<void> _savePianoResult({bool endedByUser = false}) async {
    if (score <= 0 && level <= 1 && !endedByUser) return;

    final accuracy = ((score / max(1, level * 20)) * 100).clamp(35, 95).round();

    pianoBestScore = max(pianoBestScore, score);
    pianoBestLevel = max(pianoBestLevel, level);
    pianoBestCombo = max(pianoBestCombo, combo);
    await _saveBestRecords();

    try {
      await PracticeProgressService.addPracticeSession(
        title: endedByUser
            ? 'Game Piano diakhiri pada level $level'
            : 'Latihan Game Piano sampai level $level',
        type: 'Mini Game',
        score: accuracy,
        level: level,
        combo: combo,
        passed: false,
        metadata: {
          'game_name': 'Piano Repeat Pitch',
          'raw_score': score,
          'accuracy': accuracy,
          'level_reached': level,
          'best_combo': combo,
          'sequence_length': pianoSequence.length,
          'ended_by_user': endedByUser,
          'result': endedByUser ? 'Diakhiri user' : 'Perlu latihan lagi',
          'storage': 'Hive',
        },
      );
    } catch (_) {}
  }

  Future<void> _repeatPianoSequence() async {
    if (pianoSequence.isEmpty || isBusy || gameState != 'pianoListening') return;
    await _playPianoSequence();
  }

  Future<void> _startVoiceGame() async {
    final allowed = await _confirmEndGame();
    if (!allowed) return;

    if (isGameRunning) await _endCurrentGame(endedByUser: true);

    await audioPlayer.stop();
    await _stopVoiceDetection();

    setState(() {
      selectedGame = 'voice';
      score = 0;
      level = 1;
      combo = 0;
      voiceUserStep = 0;
      detectedVoiceNote = '-';
      detectedVoiceFrequency = 0;
      voiceCentsDiff = 0;
      voiceStableHits = 0;
      voiceProcessingCorrect = false;
      voiceSequence = [_randomVoiceTarget(level)];
      gameState = 'voiceShowing';
      statusMessage = 'Dengarkan nada target, lalu tirukan dengan suaramu.';
    });

    await _playVoiceSequenceThenListen();
  }

  Future<void> _playVoiceSequenceThenListen() async {
    if (voiceSequence.isEmpty || isBusy) return;

    await _stopVoiceDetection();

    setState(() {
      isBusy = true;
      gameState = 'voiceShowing';
      voiceUserStep = 0;
      detectedVoiceNote = '-';
      detectedVoiceFrequency = 0;
      voiceCentsDiff = 0;
      voiceStableHits = 0;
      statusMessage = 'Dengarkan nada target...';
    });

    await Future.delayed(const Duration(milliseconds: 450));

    for (final target in voiceSequence) {
      if (!mounted) return;
      setState(() {
        statusMessage = 'Target: ${target.label}. Dengarkan baik-baik.';
      });
      await _playVoiceTarget(target, milliseconds: _voiceTargetHoldMs);
      await Future.delayed(const Duration(milliseconds: _voiceStepGapMs));
    }

    if (!mounted) return;

    setState(() {
      voiceUserStep = 0;
      isBusy = false;
      gameState = 'voiceListening';
      statusMessage = 'Tirukan nada pertama: ${voiceSequence.first.label}';
    });

    await _startVoiceDetection();
    _startVoiceTargetTimeout();
  }

  Future<void> _startVoiceDetection() async {
    await _stopVoiceDetection();

    try {
      voiceFrequencyBuffer.clear();
      voiceStableHits = 0;
      lastVoiceProcessTime = DateTime.fromMillisecondsSinceEpoch(0);

      voicePitchSubscription = voicePitchDetector.onPitchDetected.listen((data) {
        if (!mounted || gameState != 'voiceListening') return;

        double? rawFrequency;
        double rawAccuracy = 0;

        if (data is Map) {
          final frequency = data['frequency'] ?? data['pitch'];
          final accuracy = data['accuracy'];
          if (frequency is num) rawFrequency = frequency.toDouble();
          if (accuracy is num) rawAccuracy = accuracy.toDouble();
        } else {
          try {
            final dynamic dynamicData = data;
            final pitch = dynamicData.pitch;
            if (pitch is num) rawFrequency = pitch.toDouble();
          } catch (_) {}
        }

        if (rawFrequency == null || rawFrequency! <= 0) return;
        _handleVoiceFrequency(rawFrequency!, rawAccuracy);
      });

      await voicePitchDetector.startDetection();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        gameState = 'gameOver';
        statusMessage = 'Microphone belum bisa digunakan. Pastikan izin microphone aktif.';
      });
    }
  }

  Future<void> _stopVoiceDetection() async {
    voiceTargetTimer?.cancel();
    voiceTargetTimer = null;
    await voicePitchSubscription?.cancel();
    voicePitchSubscription = null;
    try {
      await voicePitchDetector.stopDetection();
    } catch (_) {}
  }

  void _startVoiceTargetTimeout() {
    voiceTargetTimer?.cancel();
    voiceTargetTimer = Timer(const Duration(seconds: 14), () async {
      if (!mounted || gameState != 'voiceListening') return;
      await _voiceGameOver(reason: 'Waktu habis. Nada belum sesuai target.');
    });
  }

  void _handleVoiceFrequency(double frequency, double accuracy) {
    final target = activeVoiceTarget;
    if (target == null || voiceProcessingCorrect) return;

    final now = DateTime.now();
    if (now.difference(lastVoiceProcessTime).inMilliseconds < _voiceProcessEveryMs) {
      return;
    }
    lastVoiceProcessTime = now;

    if (frequency < 70 || frequency > 1300) return;

    voiceFrequencyBuffer.add(frequency);
    if (voiceFrequencyBuffer.length > 3) {
      voiceFrequencyBuffer.removeAt(0);
    }

    final sorted = List<double>.from(voiceFrequencyBuffer)..sort();
    final stableFrequency = sorted[sorted.length ~/ 2];
    final cents = 1200 * (log(stableFrequency / target.frequency) / ln2);
    final detectedMidi = _frequencyToMidi(stableFrequency).round();
    final detectedLabel = _midiToNoteLabel(detectedMidi);
    final isMatch = cents.abs() <= _voiceMatchToleranceCents;

    setState(() {
      detectedVoiceFrequency = stableFrequency;
      detectedVoiceNote = detectedLabel;
      voiceCentsDiff = cents.clamp(-120, 120).toDouble();

      if (isMatch) {
        voiceStableHits++;
        statusMessage = voiceStableHits >= _voiceStableHitNeed
            ? 'Pas! Nada ${target.label} berhasil ditiru.'
            : 'Hampir pas! Tahan nada ${target.label} sebentar...';
      } else {
        voiceStableHits = 0;
        statusMessage = cents < 0
            ? 'Nada terlalu rendah. Naikkan sedikit menuju ${target.label}.'
            : 'Nada terlalu tinggi. Turunkan sedikit menuju ${target.label}.';
      }
    });

    if (isMatch && voiceStableHits >= _voiceStableHitNeed) {
      voiceProcessingCorrect = true;
      Future.microtask(_advanceVoiceTarget);
    }
  }

  Future<void> _advanceVoiceTarget() async {
    voiceTargetTimer?.cancel();
    await _stopVoiceDetection();

    final isLast = voiceUserStep == voiceSequence.length - 1;

    if (!mounted) return;

    setState(() {
      combo++;
      score += 30 + (level * 5) + (combo * 3);
      voiceStableHits = 0;
      voiceProcessingCorrect = false;
      statusMessage = isLast
          ? 'Mantap! Semua nada level ini berhasil.'
          : 'Benar! Lanjut ke nada berikutnya.';
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    if (isLast) {
      setState(() {
        level++;
        final nextLength = min(level, 8);
        while (voiceSequence.length < nextLength) {
          voiceSequence.add(_randomVoiceTarget(level));
        }
      });

      await _playVoiceSequenceThenListen();
    } else {
      setState(() {
        voiceUserStep++;
        final target = activeVoiceTarget;
        statusMessage = target == null
            ? 'Tirukan nada berikutnya.'
            : 'Tirukan nada berikutnya: ${target.label}';
      });

      await _startVoiceDetection();
      _startVoiceTargetTimeout();
    }
  }

  Future<void> _voiceGameOver({required String reason}) async {
    await _stopVoiceDetection();

    if (!mounted) return;

    setState(() {
      gameState = 'gameOver';
      statusMessage = reason;
      voiceBestScore = max(voiceBestScore, score);
      voiceBestLevel = max(voiceBestLevel, level);
      voiceBestCombo = max(voiceBestCombo, combo);
      voiceStableHits = 0;
      voiceProcessingCorrect = false;
    });

    await _saveBestRecords();
    await _saveVoiceResult(reason: reason);
  }

  Future<void> _saveVoiceResult({bool endedByUser = false, String reason = 'Perlu latihan lagi'}) async {
    if (score <= 0 && level <= 1 && !endedByUser) return;

    final accuracy = ((score / max(1, level * 45)) * 100).clamp(35, 98).round();

    voiceBestScore = max(voiceBestScore, score);
    voiceBestLevel = max(voiceBestLevel, level);
    voiceBestCombo = max(voiceBestCombo, combo);
    await _saveBestRecords();

    try {
      await PracticeProgressService.addPracticeSession(
        title: endedByUser
            ? 'Voice Match diakhiri pada level $level'
            : 'Latihan Voice Match sampai level $level',
        type: 'Mini Game',
        score: accuracy,
        level: level,
        combo: combo,
        passed: false,
        metadata: {
          'game_name': 'Voice Match',
          'raw_score': score,
          'accuracy': accuracy,
          'level_reached': level,
          'best_combo': combo,
          'target_sequence': voiceSequence.map((item) => item.label).toList(),
          'ended_by_user': endedByUser,
          'result': endedByUser ? 'Diakhiri user' : reason,
          'storage': 'Hive',
        },
      );
    } catch (_) {}
  }

  _VoiceTargetNote _randomVoiceTarget(int currentLevel) {
    late List<int> pool;

    if (currentLevel <= 3) {
      pool = [60, 62, 64, 65, 67, 69, 71, 72]; // C4-C5 natural notes.
    } else if (currentLevel <= 6) {
      pool = [48, 50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67, 69, 71, 72, 74, 76];
    } else {
      pool = List<int>.generate(37, (index) => 48 + index); // C3-C6 chromatic.
    }

    final midi = pool[random.nextInt(pool.length)];
    return _VoiceTargetNote(
      midi: midi,
      label: _midiToNoteLabel(midi),
      frequency: _midiToFrequency(midi),
    );
  }

  double _frequencyToMidi(double frequency) {
    return 69 + 12 * (log(frequency / 440.0) / ln2);
  }

  double _midiToFrequency(int midi) {
    return 440.0 * pow(2, (midi - 69) / 12).toDouble();
  }

  String _midiToNoteLabel(int midi) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final note = names[((midi % 12) + 12) % 12];
    final octave = (midi ~/ 12) - 1;
    return '$note$octave';
  }

  Future<void> _playVoiceTarget(_VoiceTargetNote target, {int milliseconds = _voiceTargetHoldMs}) async {
    final assetRef = _voiceAssetForMidi(target.midi);

    if (assetRef != null) {
      try {
        await audioPlayer.stop();
        await audioPlayer.setVolume(1.0);
        await audioPlayer.setSpeed(1.0);
        await audioPlayer.setAsset(assetRef.asset);
        await audioPlayer.setSpeed((target.frequency / assetRef.baseFrequency).clamp(0.5, 2.0).toDouble());
        await audioPlayer.play();
        await Future.delayed(Duration(milliseconds: milliseconds));
        await audioPlayer.stop();
        await audioPlayer.setSpeed(1.0);
        return;
      } catch (_) {
        try {
          await audioPlayer.setSpeed(1.0);
        } catch (_) {}
      }
    }

    await _playToneFrequency(target.frequency, milliseconds: milliseconds);
  }

  _VoiceAssetRef? _voiceAssetForMidi(int midi) {
    final noteIndex = ((midi % 12) + 12) % 12;
    final octave = (midi ~/ 12) - 1;

    switch (noteIndex) {
      case 0:
        if (octave >= 5) {
          return const _VoiceAssetRef('assets/audio/notes/doo.wav', 523.25);
        }
        return const _VoiceAssetRef('assets/audio/notes/do.wav', 261.63);
      case 2:
        return const _VoiceAssetRef('assets/audio/notes/re.wav', 293.66);
      case 4:
        return const _VoiceAssetRef('assets/audio/notes/mi.wav', 329.63);
      case 5:
        return const _VoiceAssetRef('assets/audio/notes/fa.wav', 349.23);
      case 7:
        return const _VoiceAssetRef('assets/audio/notes/sol.wav', 392.00);
      case 9:
        return const _VoiceAssetRef('assets/audio/notes/la.wav', 440.00);
      case 11:
        return const _VoiceAssetRef('assets/audio/notes/si.wav', 493.88);
      default:
        return null;
    }
  }

  Future<void> _playToneFrequency(double frequency, {int milliseconds = 520}) async {
    try {
      final file = await _createToneWavFile(frequency, milliseconds);
      await audioPlayer.stop();
      await audioPlayer.setVolume(1.0);
      await audioPlayer.setFilePath(file.path);
      await audioPlayer.play();
      await Future.delayed(Duration(milliseconds: milliseconds + 80));
      await audioPlayer.stop();
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
      await Future.delayed(Duration(milliseconds: milliseconds));
    }
  }

  Future<File> _createToneWavFile(double frequency, int milliseconds) async {
    final dir = await getTemporaryDirectory();
    final safeFrequency = frequency.toStringAsFixed(2).replaceAll('.', '_');
    final file = File('${dir.path}/tone_${safeFrequency}_${milliseconds}ms_loud.wav');

    if (await file.exists()) return file;

    final bytes = _buildSineWaveWav(
      frequency: frequency,
      milliseconds: milliseconds,
    );
    return file.writeAsBytes(bytes, flush: true);
  }

  Uint8List _buildSineWaveWav({required double frequency, required int milliseconds}) {
    const sampleRate = 44100;
    const channels = 1;
    const bitsPerSample = 16;
    final sampleCount = (sampleRate * milliseconds / 1000).round();
    final dataSize = sampleCount * channels * bitsPerSample ~/ 8;
    final totalSize = 44 + dataSize;
    final bytes = Uint8List(totalSize);
    final data = ByteData.view(bytes.buffer);

    void writeString(int offset, String value) {
      final codes = value.codeUnits;
      for (var i = 0; i < codes.length; i++) {
        bytes[offset + i] = codes[i];
      }
    }

    writeString(0, 'RIFF');
    data.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * channels * bitsPerSample ~/ 8, Endian.little);
    data.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    writeString(36, 'data');
    data.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final envelope = min(1.0, i / 800) * min(1.0, (sampleCount - i) / 800);
      final sample = sin(2 * pi * frequency * i / sampleRate) * 0.82 * envelope;
      data.setInt16(44 + i * 2, (sample * 32767).round(), Endian.little);
    }

    return bytes;
  }

  Widget _gameTitle() {
    return Column(
      children: [
        Text(
          isVoiceMode ? 'VOICE MATCH' : 'REPEAT PITCH',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _text,
            fontSize: 27,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isVoiceMode
              ? 'Tirulah nada yang muncul dengan suaramu.'
              : 'Dengarkan urutan nada, lalu ulangi dengan tuts piano.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _modeCards() {
    return Row(
      children: [
        Expanded(
          child: _modeCard(
            title: 'Piano Game',
            emoji: '🎹',
            selected: isPianoMode,
            onTap: () => _selectGame('piano'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _modeCard(
            title: 'Voice Game',
            emoji: '🎤',
            selected: isVoiceMode,
            onTap: () => _selectGame('voice'),
          ),
        ),
      ],
    );
  }

  Widget _modeCard({
    required String title,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _cyan.withOpacity(0.18) : _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? _cyan : _border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _cyan.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(child: _scoreItem('SKOR', '$score', _cyan)),
          Container(width: 1, height: 44, color: _border),
          Expanded(child: _scoreItem('LEVEL', '$level', _purple)),
          Container(width: 1, height: 44, color: _border),
          Expanded(child: _scoreItem('TERBAIK', '$activeBestScore', _yellow)),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, String value, Color color) {
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
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _statusCard() {
    final color = gameState == 'gameOver'
        ? _pink
        : isVoiceMode
            ? _cyan
            : _green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.48)),
      ),
      child: Row(
        children: [
          Text(
            isVoiceMode ? '♬' : '●',
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gamePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
      ),
      child: isVoiceMode ? _voicePanel() : _pianoPanel(),
    );
  }

  Widget _pianoPanel() {
    final showKeys = gameState == 'pianoShowing' ||
        gameState == 'pianoListening' ||
        gameState == 'gameOver';

    return Column(
      children: [
        const Text(
          'GAME PIANO',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        if (!showKeys) ...[
          _waveDecoration(),
          const SizedBox(height: 22),
          _mainButton(
            label: 'MULAI GAME PIANO',
            onTap: _startPianoGame,
          ),
        ] else ...[
          _pianoKeys(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _smallButton(
                  label: 'Dengar Lagi',
                  onTap: gameState == 'pianoListening' ? _repeatPianoSequence : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _smallButton(
                  label: 'Ulang Game',
                  onTap: _startPianoGame,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _voicePanel() {
    final target = activeVoiceTarget;
    final listening = gameState == 'voiceListening';
    final playing = gameState == 'voiceShowing';
    final idle = gameState == 'idle' || gameState == 'gameOver';

    return Column(
      children: [
        const Text(
          'ANALISIS NADA VOKAL',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        if (idle) ...[
          _waveDecoration(),
          const SizedBox(height: 22),
          _mainButton(
            label: 'MULAI LATIHAN VOICE',
            onTap: _startVoiceGame,
          ),
        ] else ...[
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _cyan.withOpacity(0.7), width: 3),
              boxShadow: [
                BoxShadow(
                  color: _cyan.withOpacity(0.15),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    target?.label ?? '-',
                    style: const TextStyle(
                      color: _text,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'TARGET',
                    style: TextStyle(
                      color: _cyan.withOpacity(0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _voiceMeter(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _voiceMetric('TERDETEKSI', detectedVoiceNote),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _voiceMetric(
                  'FREKUENSI',
                  detectedVoiceFrequency <= 0
                      ? '-'
                      : '${detectedVoiceFrequency.toStringAsFixed(1)} Hz',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _smallButton(
                  label: playing ? 'Memainkan...' : 'Ulang Nada',
                  onTap: listening ? _playVoiceSequenceThenListen : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _smallButton(
                  label: 'Akhiri',
                  onTap: () async => _voiceGameOver(reason: 'Permainan dihentikan.'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _waveDecoration() {
    final heights = [24.0, 40.0, 58.0, 74.0, 54.0, 88.0, 46.0, 68.0, 34.0];
    return SizedBox(
      height: 104,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: heights.map((height) {
          return Container(
            width: 8,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: _cyan,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _voiceMeter() {
    final pos = ((voiceCentsDiff.clamp(-120, 120) + 120) / 240).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final left = (width * pos - 5).clamp(0.0, width - 10);
        return SizedBox(
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
              ),
              Center(
                child: Container(width: 3, height: 20, color: _muted.withOpacity(0.5)),
              ),
              Positioned(
                left: left,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: voiceCentsDiff.abs() <= 45 ? _green : _pink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _voiceMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pianoKeys() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(pianoNotes.length, (index) {
        final note = pianoNotes[index];
        final color = note['color'] as Color;
        final active = activePianoNoteIndex == index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == pianoNotes.length - 1 ? 0 : 5),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: active ? 0.94 : 1,
              child: InkWell(
                onTap: _canPressPianoKeys ? () => _handlePianoKeyTap(index) : null,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: active ? 112 : 124,
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
                          note['label'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          note['tone'].toString(),
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
            ),
          ),
        );
      }),
    );
  }

  Widget _mainButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isBusy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _cyan,
          foregroundColor: _bg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
      ),
    );
  }

  Widget _smallButton({required String label, required FutureOr<void> Function()? onTap}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap == null || isBusy ? null : () async => await onTap(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _surfaceSoft,
          foregroundColor: _text,
          disabledBackgroundColor: _surfaceSoft.withOpacity(0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    );
  }

  Widget _bestInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _bestMini('BEST SCORE', activeBestScore == 0 ? '-' : '$activeBestScore'),
          ),
          Expanded(
            child: _bestMini('BEST LEVEL', activeBestLevel == 0 ? '-' : '$activeBestLevel'),
          ),
          Expanded(
            child: _bestMini(
              'MODE',
              isVoiceMode ? 'Voice' : 'Piano',
            ),
          ),
        ],
      ),
    );
  }

  Widget _bestMini(String label, String value) {
    return Column(
      children: [
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
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final allowed = await _confirmEndGame();
        if (allowed && isGameRunning) {
          await _endCurrentGame(endedByUser: true);
        }
        return allowed;
      },
      child: Scaffold(
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
              const SizedBox(height: 24),
              _modeCards(),
              const SizedBox(height: 18),
              _scoreBoard(),
              const SizedBox(height: 18),
              _statusCard(),
              const SizedBox(height: 18),
              _gamePanel(),
              const SizedBox(height: 18),
              _bestInfoCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceTargetNote {
  final int midi;
  final String label;
  final double frequency;

  const _VoiceTargetNote({
    required this.midi,
    required this.label,
    required this.frequency,
  });
}

class _VoiceAssetRef {
  final String asset;
  final double baseFrequency;

  const _VoiceAssetRef(this.asset, this.baseFrequency);
}
