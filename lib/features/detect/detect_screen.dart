import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../services/practice_progress_service.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  bool isGuitarMode = false;
  bool isDetecting = false;
  bool silentRoomCheckEnabled = true;
  bool isCheckingRoomNoise = false;
  double? roomNoiseDb;
  String roomNoiseStatus =
      'Cek ruangan aktif. Aplikasi akan mengecek kebisingan sebelum mulai.';

  final FlutterPitchDetection pitchDetector = FlutterPitchDetection();
  StreamSubscription<Map<String, dynamic>>? pitchSubscription;
  StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;

  DateTime lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime lastGyroSwitchTime = DateTime.fromMillisecondsSinceEpoch(0);

  String detectedNote = '-';
  String detectedFrequencyText = '-';
  double detectedFrequency = 0;
  double detectedAccuracy = 0;
  bool isSignalStable = false;
  final List<double> frequencyBuffer = [];

  int selectedStringIndex = 0;

  final List<Map<String, dynamic>> guitarStrings = [
    {
      'label': 'Senar 6',
      'note': 'E2',
      'shortNote': 'E',
      'frequency': 82.41,
      'description': 'Senar paling tebal',
    },
    {
      'label': 'Senar 5',
      'note': 'A2',
      'shortNote': 'A',
      'frequency': 110.00,
      'description': 'Senar bass A',
    },
    {
      'label': 'Senar 4',
      'note': 'D3',
      'shortNote': 'D',
      'frequency': 146.83,
      'description': 'Senar tengah D',
    },
    {
      'label': 'Senar 3',
      'note': 'G3',
      'shortNote': 'G',
      'frequency': 196.00,
      'description': 'Senar tengah G',
    },
    {
      'label': 'Senar 2',
      'note': 'B3',
      'shortNote': 'B',
      'frequency': 246.94,
      'description': 'Senar tinggi B',
    },
    {
      'label': 'Senar 1',
      'note': 'E4',
      'shortNote': 'E',
      'frequency': 329.63,
      'description': 'Senar paling tipis',
    },
  ];

  Map<String, dynamic> get selectedString => guitarStrings[selectedStringIndex];

  double get targetFrequency => selectedString['frequency'] as double;

  double get centsDifference {
    if (detectedFrequency <= 0) return 0;
    return 1200 * (log(detectedFrequency / targetFrequency) / ln2);
  }

  String get solfegeText {
    final cleanNote = detectedNote
        .replaceAll(RegExp(r'[0-9]'), '')
        .replaceAll('♯', '#')
        .trim()
        .toUpperCase();

    final solfegeMap = {
      'C': 'Do',
      'C#': 'Di / Do#',
      'DB': 'Ra / Re♭',
      'D': 'Re',
      'D#': 'Ri / Re#',
      'EB': 'Me / Mi♭',
      'E': 'Mi',
      'F': 'Fa',
      'F#': 'Fi / Fa#',
      'GB': 'Se / Sol♭',
      'G': 'Sol',
      'G#': 'Si / Sol#',
      'AB': 'Le / La♭',
      'A': 'La',
      'A#': 'Li / La#',
      'BB': 'Te / Si♭',
      'B': 'Si',
    };

    return solfegeMap[cleanNote] ?? '-';
  }

  String get tuningStatus {
    if (!isDetecting) {
      return 'Pilih senar, lalu mulai stem gitar.';
    }

    if (detectedFrequency <= 0) {
      return 'Petik senar dekat mikrofon HP.';
    }

    if (!isSignalStable) {
      return 'Membaca nada... petik senar dengan jelas.';
    }

    final cents = centsDifference;

    if (cents.abs() <= 10) {
      return 'Pas! Nada senar sudah cocok.';
    }

    if (cents < 0) {
      return 'Terlalu rendah. Kencangkan senar sedikit.';
    }

    return 'Terlalu tinggi. Kendurkan senar sedikit.';
  }

  String get vocalStatus {
    if (!isDetecting) {
      return 'Mulai tes, lalu nyanyikan satu nada.';
    }

    if (detectedFrequency <= 0) {
      return 'Dekatkan suara ke mikrofon HP.';
    }

    if (!isSignalStable) {
      return 'Membaca suara... nyanyikan satu nada dengan jelas.';
    }

    return 'Nada suara terbaca sebagai $detectedNote / $solfegeText.';
  }

  Color get primaryColor =>
      isGuitarMode ? const Color(0xFF7C4DFF) : const Color(0xFF00C6FF);

  Color get secondaryColor =>
      isGuitarMode ? const Color(0xFF5E35B1) : const Color(0xFF0072FF);

  @override
  void initState() {
    super.initState();
    _startShakeListener();
    _startGyroscopeListener();
  }

  void _startShakeListener() {
    accelerometerSubscription?.cancel();

    accelerometerSubscription = accelerometerEventStream().listen((event) {
      final force = event.x.abs() + event.y.abs() + event.z.abs();
      final now = DateTime.now();
      final cooldownDone = now.difference(lastShakeTime).inMilliseconds > 1300;

      if (force > 24 && cooldownDone && !isDetecting) {
        lastShakeTime = now;
        _toggleMode();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mode diganti lewat shake HP.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _startGyroscopeListener() {
    gyroscopeSubscription?.cancel();

    gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      final rotationForce = event.x.abs() + event.y.abs() + event.z.abs();
      final now = DateTime.now();
      final cooldownDone =
          now.difference(lastGyroSwitchTime).inMilliseconds > 1600;

      if (rotationForce > 7.5 && cooldownDone && !isDetecting) {
        lastGyroSwitchTime = now;
        _toggleMode();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mode diganti lewat rotasi HP.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _toggleMode() {
    if (isDetecting) return;

    setState(() {
      isGuitarMode = !isGuitarMode;
      _resetDetectionValue();
    });
  }

  void _resetDetectionValue() {
    detectedNote = '-';
    detectedFrequencyText = '-';
    detectedFrequency = 0;
    detectedAccuracy = 0;
    isSignalStable = false;
    frequencyBuffer.clear();
  }

  double _frequencyToMidi(double frequency) {
    return 69 + 12 * (log(frequency / 440.0) / ln2);
  }

  String _noteNameFromFrequency(double frequency) {
    if (frequency <= 0) return '-';

    const noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];

    final midi = _frequencyToMidi(frequency).round();
    final noteIndex = ((midi % 12) + 12) % 12;
    final octave = (midi ~/ 12) - 1;

    return '${noteNames[noteIndex]}$octave';
  }

  bool _isFrequencyInUsefulRange(double frequency) {
    if (isGuitarMode) {
      return frequency >= 65 && frequency <= 420;
    }

    return frequency >= 80 && frequency <= 1000;
  }

  void _applyDetectedFrequency(double rawFrequency, double rawAccuracy) {
    if (!_isFrequencyInUsefulRange(rawFrequency)) {
      return;
    }

    final minimumAccuracy = isGuitarMode ? 5 : 5;

    if (rawAccuracy > 0 && rawAccuracy < minimumAccuracy) {
      return;
    }

    final calculatedNote = _noteNameFromFrequency(rawFrequency);

    setState(() {
      detectedFrequency = rawFrequency;
      detectedFrequencyText = '${rawFrequency.toStringAsFixed(1)} Hz';
      detectedNote = calculatedNote;
      detectedAccuracy = rawAccuracy;
      isSignalStable = true;
    });
  }

  Future<void> _runSilentRoomCheck() async {
    if (isCheckingRoomNoise) return;

    setState(() {
      isCheckingRoomNoise = true;
      roomNoiseDb = null;
      roomNoiseStatus = 'Mengecek kebisingan ruangan lewat mikrofon...';
    });

    final readings = <double>[];
    StreamSubscription<NoiseReading>? noiseSubscription;

    try {
      final noiseMeter = NoiseMeter();

      noiseSubscription = noiseMeter.noise.listen((reading) {
        final double db = reading.meanDecibel.toDouble();

        if (db.isFinite) {
          readings.add(db);

          if (mounted) {
            setState(() {
              roomNoiseDb = db;
            });
          }
        }
      });

      await Future.delayed(const Duration(seconds: 2));
      await noiseSubscription.cancel();

      final double averageDb = readings.isEmpty
          ? 0.0
          : readings.reduce((a, b) => a + b) / readings.length;

      final isQuietEnough = readings.isEmpty || averageDb <= 68;

      if (!mounted) return;

      setState(() {
        isCheckingRoomNoise = false;
        roomNoiseDb = averageDb;
        roomNoiseStatus = isQuietEnough
            ? 'Ruangan aman untuk test vokal.'
            : 'Ruangan cukup bising untuk test vokal.';
      });

      _showRoomCheckDialog(isQuietEnough: isQuietEnough, averageDb: averageDb);
    } catch (_) {
      await noiseSubscription?.cancel();

      if (!mounted) return;

      setState(() {
        isCheckingRoomNoise = false;
        roomNoiseStatus =
            'Cek ruangan belum bisa membaca mikrofon. Coba izinkan akses mikrofon.';
      });

      _showRoomCheckErrorDialog();
    }
  }

  void _showRoomCheckDialog({
    required bool isQuietEnough,
    required double averageDb,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF17182C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                isQuietEnough
                    ? Icons.check_circle_rounded
                    : Icons.volume_up_rounded,
                color: isQuietEnough
                    ? const Color(0xFF34D399)
                    : const Color(0xFFFBBF24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isQuietEnough ? 'Ruangan Aman' : 'Ruangan Cukup Bising',
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isQuietEnough
                ? 'Ruangan aman untuk test vokal. Kebisingan sekitar ${averageDb.toStringAsFixed(0)} dB.'
                : 'Ruangan cukup bising, coba pindah ke tempat lebih sepi agar pembacaan nada lebih jelas. Kebisingan sekitar ${averageDb.toStringAsFixed(0)} dB.',
            style: const TextStyle(
              color: Color(0xFFB8BCD7),
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

  void _showRoomCheckErrorDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF17182C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.mic_off_rounded, color: Color(0xFFF472B6)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cek Ruangan Gagal',
                  style: TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Aplikasi belum bisa membaca mikrofon untuk cek kebisingan. Pastikan izin mikrofon aktif.',
            style: TextStyle(
              color: Color(0xFFB8BCD7),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startDetection() async {
    try {
      await pitchDetector.startDetection();

      await pitchSubscription?.cancel();
      pitchSubscription = pitchDetector.onPitchDetected.listen((data) {
        if (!mounted) return;

        final frequency = data['frequency'];
        final accuracy = data['accuracy'];

        if (frequency is! num) return;

        final rawFrequency = frequency.toDouble();
        final rawAccuracy = accuracy is num ? accuracy.toDouble() : 0.0;

        _applyDetectedFrequency(rawFrequency, rawAccuracy);
      });

      if (!mounted) return;

      setState(() {
        isDetecting = true;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mikrofon belum bisa membaca nada: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int? _calculateSessionScore() {
    if (detectedFrequency <= 0 || !isSignalStable) return null;

    if (isGuitarMode) {
      final cents = centsDifference.abs();
      return (100 - (cents * 2)).clamp(40, 100).round();
    }

    if (detectedAccuracy > 0) {
      return detectedAccuracy.clamp(40, 100).round();
    }

    return 75;
  }

  Future<void> _saveDetectionSession() async {
    if (detectedFrequency <= 0) return;

    final mode = isGuitarMode ? 'Tuner Gitar' : 'Deteksi Suara';
    final targetNote = isGuitarMode ? selectedString['note'].toString() : null;
    final targetString = isGuitarMode
        ? selectedString['label'].toString()
        : null;
    final status = isGuitarMode ? tuningStatus : vocalStatus;
    final sessionScore = _calculateSessionScore();

    await PracticeProgressService.addPracticeSession(
      title: isGuitarMode
          ? 'Cek tuning $targetString $targetNote'
          : 'Deteksi suara $detectedNote / $solfegeText',
      type: 'Detect',
      score: sessionScore,
      level: null,
      combo: null,
      passed: isSignalStable,
      metadata: {
        'mode': mode,
        'target_string': targetString,
        'target_note': targetNote,
        'detected_note': detectedNote,
        'solfege': solfegeText,
        'frequency': detectedFrequencyText,
        'accuracy': detectedAccuracy <= 0
            ? '-'
            : '${detectedAccuracy.toStringAsFixed(0)}%',
        'status': status,
        'is_stable': isSignalStable,
      },
    );
  }

  Future<void> _stopDetection() async {
    await pitchSubscription?.cancel();
    pitchSubscription = null;
    await pitchDetector.stopDetection();

    await _saveDetectionSession();

    if (!mounted) return;

    setState(() {
      isDetecting = false;
    });
  }

  Future<void> _handleMainButton() async {
    if (isDetecting) {
      await _stopDetection();
    } else {
      await _startDetection();
    }
  }

  Widget _buildSilentRoomCheckCard() {
    final noiseText = roomNoiseDb == null
        ? 'Belum dicek'
        : '${roomNoiseDb!.toStringAsFixed(0)} dB';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCheckingRoomNoise
                  ? Icons.hearing_rounded
                  : Icons.graphic_eq_rounded,
              color: const Color(0xFF22D3EE),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Silent Room Check',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$roomNoiseStatus • $noiseText',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8BCD7),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: isCheckingRoomNoise ? null : _runSilentRoomCheck,
                    icon: Icon(
                      isCheckingRoomNoise
                          ? Icons.hourglass_top_rounded
                          : Icons.mic_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isCheckingRoomNoise ? 'Mengecek...' : 'Mulai Cek Ruangan',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22D3EE),
                      foregroundColor: const Color(0xFF0B0D22),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              title: 'Test Vokal',
              icon: Icons.mic_rounded,
              selected: !isGuitarMode,
              onTap: () {
                if (!isDetecting && isGuitarMode) _toggleMode();
              },
            ),
          ),
          Expanded(
            child: _buildModeTab(
              title: 'Stem Gitar',
              icon: Icons.music_note_rounded,
              selected: isGuitarMode,
              onTap: () {
                if (!isDetecting && !isGuitarMode) _toggleMode();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isDetecting ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? secondaryColor : Colors.white70,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? secondaryColor : Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuitarStringSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih senar yang mau distem',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Petik satu senar saja, jangan genjreng chord penuh.',
            style: TextStyle(
              color: Color(0xFFB8BBCC),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(guitarStrings.length, (index) {
              final item = guitarStrings[index];
              final selected = selectedStringIndex == index;

              return InkWell(
                onTap: isDetecting
                    ? null
                    : () {
                        setState(() {
                          selectedStringIndex = index;
                          _resetDetectionValue();
                        });
                      },
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 92,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? primaryColor
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.26)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item['shortNote'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'].toString(),
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
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedleTuner() {
    final cents = centsDifference;
    final clamped = cents.clamp(-50, 50).toDouble();
    final alignmentX = clamped / 50;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            tuningStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 32,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF8A65),
                          Color(0xFF21C67A),
                          Color(0xFFFF8A65),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 22,
                  child: Text(
                    'PAS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  alignment: Alignment(alignmentX, 0.2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      Container(
                        width: 6,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Rendah',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                detectedFrequency <= 0
                    ? 'Menunggu suara'
                    : '${cents.toStringAsFixed(1)} cents',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Expanded(
                child: Text(
                  'Tinggi',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVocalDetector() {
    final bool hasSound = detectedFrequency > 0;
    final String noteText = hasSound ? detectedNote : '-';
    final String solfege = hasSound ? solfegeText : '-';
    final String frequencyText = hasSound ? detectedFrequencyText : '-';
    final String accuracyText = detectedAccuracy <= 0
        ? '-'
        : '${detectedAccuracy.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Vokal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      vocalStatus,
                      style: const TextStyle(
                        color: Color(0xFFD7DAE8),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.26),
                  secondaryColor.withValues(alpha: 0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                const Text(
                  'SOLFEGE',
                  style: TextStyle(
                    color: Color(0xFFB8BBCC),
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  solfege,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasSound
                      ? 'Nada musik: $noteText'
                      : 'Nyanyikan satu nada dengan jelas.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildVocalMiniInfo(
                title: 'Nada',
                value: noteText,
                icon: Icons.music_note_rounded,
              ),
              const SizedBox(width: 10),
              _buildVocalMiniInfo(
                title: 'Frekuensi',
                value: frequencyText,
                icon: Icons.graphic_eq_rounded,
              ),
              const SizedBox(width: 10),
              _buildVocalMiniInfo(
                title: 'Akurasi',
                value: accuracyText,
                icon: Icons.verified_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: const Text(
              'Cara pakai: mulai tes, nyanyikan satu nada, lalu lihat nada dan solfege yang terbaca.',
              style: TextStyle(
                color: Color(0xFFD7DAE8),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocalMiniInfo({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9DA3BC),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCircle() {
    final displayNote = detectedFrequency <= 0 ? '-' : detectedNote;
    final displayFrequency = detectedFrequency <= 0
        ? '-'
        : detectedFrequencyText;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              primaryColor.withValues(alpha: 0.96),
              secondaryColor,
              const Color(0xFF1A1733),
            ],
            radius: 0.85,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDetecting ? 0.48 : 0.25),
              blurRadius: isDetecting ? 42 : 28,
              spreadRadius: isDetecting ? 8 : 4,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayNote,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 68,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayFrequency,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isDetecting ? 'Mikrofon Aktif' : 'Mikrofon Mati',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToUseCard() {
    final text = isGuitarMode
        ? '1. Pilih senar\n2. Mulai deteksi\n3. Petik satu senar dekat mikrofon\n4. Ikuti indikator tuning'
        : '1. Mulai test vokal\n2. Nyanyikan satu nada\n3. Lihat nada dan solfege yang terbaca';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFD7DAE8),
                fontSize: 13,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pitchSubscription?.cancel();
    pitchDetector.stopDetection();
    accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetNote = selectedString['note'].toString();
    final targetFrequencyText =
        '${(selectedString['frequency'] as double).toStringAsFixed(1)} Hz';
    final accuracyText = detectedAccuracy <= 0
        ? '-'
        : '${detectedAccuracy.toStringAsFixed(0)}%';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1020),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            const Text(
              'Detect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tes nada vokal atau stem gitar dengan mikrofon HP.',
              style: TextStyle(
                color: Color(0xFFB8BBCC),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            _buildModeSwitcher(),
            const SizedBox(height: 14),
            _buildSilentRoomCheckCard(),
            const SizedBox(height: 22),
            if (isGuitarMode) _buildGuitarStringSelector(),
            if (isGuitarMode) const SizedBox(height: 22),
            _buildResultCircle(),
            const SizedBox(height: 22),
            Row(
              children: [
                _buildSmallInfo(
                  title: isGuitarMode ? 'Target Senar' : 'Nada',
                  value: isGuitarMode ? targetNote : detectedNote,
                  subtitle: isGuitarMode ? targetFrequencyText : solfegeText,
                ),
                const SizedBox(width: 12),
                _buildSmallInfo(
                  title: 'Akurasi',
                  value: accuracyText,
                  subtitle: detectedFrequencyText,
                ),
              ],
            ),
            const SizedBox(height: 22),
            isGuitarMode ? _buildNeedleTuner() : _buildVocalDetector(),
            const SizedBox(height: 22),
            _buildHowToUseCard(),
            const SizedBox(height: 22),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _handleMainButton,
                icon: Icon(
                  isDetecting
                      ? Icons.stop_circle_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(isDetecting ? 'Berhenti Deteksi' : 'Mulai Deteksi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDetecting
                      ? const Color(0xFFFF8A65)
                      : primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfo({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF9DA3BC),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
