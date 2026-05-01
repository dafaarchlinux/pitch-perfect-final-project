import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../services/practice_progress_service.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  static const Color _bg = Color(0xFF0B0D22);
  static const Color _surface = Color(0xFF17182C);
  static const Color _surfaceSoft = Color(0xFF232542);
  static const Color _border = Color(0xFF2D3050);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF8EA0C8);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _pink = Color(0xFFFF4D73);
  static const Color _green = Color(0xFF22C55E);
  static const Color _yellow = Color(0xFFFACC15);
  static const Color _orange = Color(0xFFF59E0B);

  bool isGuitarMode = true;
  bool isDetecting = false;
  bool isCheckingRoom = false;

  final FlutterPitchDetection pitchDetector = FlutterPitchDetection();
  StreamSubscription<Map<String, dynamic>>? pitchSubscription;
  StreamSubscription<AccelerometerEvent>? accelerometerSubscription;

  DateTime lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);

  String detectedNote = '-';
  String detectedFrequencyText = '-';
  String roomStatus = 'Belum dicek';
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
      return 'Pilih senar, lalu tekan Mulai Deteksi.';
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
      return 'Tekan Mulai Deteksi, lalu nyanyikan satu nada.';
    }

    if (detectedFrequency <= 0) {
      return 'Dekatkan suara ke mikrofon HP.';
    }

    if (!isSignalStable) {
      return 'Membaca suara... nyanyikan satu nada dengan jelas.';
    }

    return 'Nada suara terbaca sebagai $detectedNote / $solfegeText.';
  }

  Color get primaryColor => isGuitarMode ? _purple : _cyan;

  Color get secondaryColor => isGuitarMode
      ? const Color(0xFF5E35B1)
      : const Color(0xFF0072FF);

  @override
  void initState() {
    super.initState();
    _startShakeListener();
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
            content: Text('Mode diganti lewat gerakan HP.'),
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

    const minimumAccuracy = 5;

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

  Future<void> _checkRoomNoise() async {
    if (isDetecting || isCheckingRoom) return;

    setState(() {
      isCheckingRoom = true;
      roomStatus = 'Mengecek...';
      _resetDetectionValue();
    });

    try {
      await pitchDetector.startDetection();

      int sampleCount = 0;
      int detectedCount = 0;
      double totalAccuracy = 0;

      await pitchSubscription?.cancel();
      pitchSubscription = pitchDetector.onPitchDetected.listen((data) {
        final frequency = data['frequency'];
        final accuracy = data['accuracy'];

        sampleCount++;

        if (frequency is num && frequency.toDouble() > 0) {
          detectedCount++;
        }

        if (accuracy is num) {
          totalAccuracy += accuracy.toDouble();
        }
      });

      await Future.delayed(const Duration(seconds: 2));

      await pitchSubscription?.cancel();
      pitchSubscription = null;
      await pitchDetector.stopDetection();

      final averageAccuracy = sampleCount == 0 ? 0 : totalAccuracy / sampleCount;
      final signalRatio = sampleCount == 0 ? 0 : detectedCount / sampleCount;

      String result;
      if (detectedCount == 0 || signalRatio < 0.2) {
        result = 'Tenang (Optimal)';
      } else if (signalRatio < 0.5 || averageAccuracy < 25) {
        result = 'Cukup tenang';
      } else {
        result = 'Terlalu bising';
      }

      if (!mounted) return;

      setState(() {
        roomStatus = result;
        isCheckingRoom = false;
        _resetDetectionValue();
      });
    } catch (_) {
      try {
        await pitchSubscription?.cancel();
        pitchSubscription = null;
        await pitchDetector.stopDetection();
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        roomStatus = 'Tidak bisa dicek';
        isCheckingRoom = false;
        _resetDetectionValue();
      });
    }
  }

  Future<void> _saveDetectionSession() async {
    if (detectedFrequency <= 0) return;

    final mode = isGuitarMode ? 'Tuner Gitar' : 'Deteksi Suara';
    final targetNote = isGuitarMode ? selectedString['note'].toString() : null;
    final targetString = isGuitarMode ? selectedString['label'].toString() : null;
    final status = isGuitarMode ? tuningStatus : vocalStatus;

    await PracticeProgressService.addPracticeSession(
      title: isGuitarMode
          ? 'Cek tuning $targetString $targetNote'
          : 'Deteksi suara $detectedNote / $solfegeText',
      type: 'Detect',
      score: null,
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
        'room_status': roomStatus,
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

  double get _displayAccuracy {
    if (detectedFrequency <= 0) return 0;
    if (isGuitarMode) {
      return (100 - (centsDifference.abs() * 2)).clamp(0, 100).toDouble();
    }
    if (detectedAccuracy > 0) return detectedAccuracy.clamp(0, 100).toDouble();
    return isSignalStable ? 75 : 0;
  }

  String get _mainStatusLabel {
    if (!isDetecting) return 'SIAP';
    if (detectedFrequency <= 0) return 'MENUNGGU';
    if (!isSignalStable) return 'MEMBACA';
    if (!isGuitarMode) return 'TERDETEKSI';
    final cents = centsDifference;
    if (cents.abs() <= 10) return 'PAS';
    return cents < 0 ? 'TERLALU RENDAH' : 'TERLALU TINGGI';
  }

  Color get _statusColor {
    if (!isDetecting) return _cyan;
    if (detectedFrequency <= 0 || !isSignalStable) return _yellow;
    if (!isGuitarMode) return _cyan;
    final cents = centsDifference;
    if (cents.abs() <= 10) return _green;
    return cents < 0 ? _orange : _pink;
  }

  double get _needlePosition {
    if (!isGuitarMode || detectedFrequency <= 0) return 0.5;
    return ((centsDifference.clamp(-50, 50) + 50) / 100).clamp(0.0, 1.0);
  }

  String get _centerNoteText {
    if (detectedFrequency > 0) return detectedNote.replaceAll(RegExp(r'[0-9]'), '');
    if (isGuitarMode) return selectedString['shortNote'].toString();
    return '-';
  }

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              title: 'Tuner Gitar',
              icon: Icons.music_note_rounded,
              selected: isGuitarMode,
              onTap: () {
                if (!isDetecting && !isGuitarMode) _toggleMode();
              },
            ),
          ),
          Expanded(
            child: _buildModeTab(
              title: 'Deteksi Suara',
              icon: Icons.mic_rounded,
              selected: !isGuitarMode,
              onTap: () {
                if (!isDetecting && isGuitarMode) _toggleMode();
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
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : _muted),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _muted,
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

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [_cyan, Color(0xFF93C5FD), Color(0xFFC084FC)],
                  ).createShader(bounds);
                },
                child: const Text(
                  'Smart Tuner & Detector',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                isGuitarMode ? 'MODE GITAR AKUSTIK' : 'MODE DETEKSI BEBAS',
                style: const TextStyle(
                  color: Color(0xFFB9C7FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.55)),
          ),
          child: Icon(
            isGuitarMode ? Icons.music_note_rounded : Icons.mic_rounded,
            color: const Color(0xFFD8B4FE),
          ),
        ),
      ],
    );
  }

  Widget _buildMainTunerCard() {
    final color = _statusColor;
    final statusText = isGuitarMode ? tuningStatus : vocalStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _tuningLabel(Icons.arrow_downward_rounded, 'RENDAH', _orange),
              const Spacer(),
              _tuningLabel(Icons.check_circle_outline_rounded, 'PAS', _green),
              const Spacer(),
              _tuningLabel(Icons.arrow_upward_rounded, 'TINGGI', _pink),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.75), width: 4),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.16),
                  blurRadius: 35,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _centerNoteText,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 58,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mainStatusLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _buildNeedleBar(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleMainButton,
              icon: Icon(
                isDetecting ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: isDetecting ? _pink : Colors.white,
              ),
              label: Text(
                isDetecting ? 'Berhentikan Deteksi' : 'Mulai Deteksi',
                style: TextStyle(
                  color: isDetecting ? _pink : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDetecting ? _pink.withOpacity(0.14) : primaryColor,
                side: BorderSide(color: isDetecting ? _pink : primaryColor),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDetecting || isCheckingRoom ? null : _checkRoomNoise,
              icon: Icon(
                Icons.air_rounded,
                color: isDetecting || isCheckingRoom ? _muted : _cyan,
              ),
              label: Text(
                isCheckingRoom ? 'Mengecek Ruangan...' : 'Mulai Cek Ruangan',
                style: TextStyle(
                  color: isDetecting || isCheckingRoom ? _muted : _cyan,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _surfaceSoft,
                disabledBackgroundColor: _surfaceSoft.withOpacity(0.65),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _metricCard('SOLFEGE', solfegeText, _text)),
              const SizedBox(width: 10),
              Expanded(child: _metricCard('NADA', detectedNote, _text)),
              const SizedBox(width: 10),
              Expanded(child: _metricCard('FREKUENSI', detectedFrequencyText, _cyan)),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'AKURASI',
                  _displayAccuracy <= 0 ? '-' : '${_displayAccuracy.round()}%',
                  _text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tuningLabel(IconData icon, String label, Color color) {
    final status = _mainStatusLabel;
    final active = status.contains(label) || (label == 'PAS' && status == 'PAS');
    return Opacity(
      opacity: active ? 1 : 0.35,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedleBar() {
    final position = _needlePosition;
    final color = _statusColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final markerLeft = (width * position - 4).clamp(0.0, width - 8);
        return SizedBox(
          height: 18,
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
                child: Container(
                  width: 3,
                  height: 18,
                  color: _muted.withOpacity(0.55),
                ),
              ),
              Positioned(
                left: markerLeft,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.55), blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCard(String title, String value, Color color) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF78A0D4),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuitarStringSelector() {
    if (!isGuitarMode) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIH SENAR TARGET',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: guitarStrings.length,
            separatorBuilder: (context, index) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
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
                borderRadius: BorderRadius.circular(17),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 105,
                  decoration: BoxDecoration(
                    color: selected ? _cyan.withOpacity(0.85) : _surface,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: selected ? _cyan : _border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['shortNote'].toString(),
                        style: TextStyle(
                          color: selected ? Colors.white : _text,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item['label'].toString(),
                        style: TextStyle(
                          color: selected ? Colors.white70 : _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _orange.withOpacity(0.45)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _yellow, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Peringatan: Pastikan sensor mikrofon diizinkan. Dekatkan sumber suara ke mikrofon agar hasil deteksi lebih stabil.',
              style: TextStyle(
                color: Color(0xFFFFD166),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detect',
          style: TextStyle(
            color: _text,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            _buildModeSwitcher(),
            const SizedBox(height: 18),
            _buildMainTunerCard(),
            const SizedBox(height: 24),
            _buildGuitarStringSelector(),
            if (isGuitarMode) const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    icon: Icons.sensors_rounded,
                    title: 'STATUS RUANG',
                    value: roomStatus,
                    color: roomStatus == 'Tenang (Optimal)' ? _green : _cyan,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _infoTile(
                    icon: Icons.verified_user_rounded,
                    title: 'KALIBRASI',
                    value: 'Otomatis',
                    color: _purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _warningBox(),
          ],
        ),
      ),
    );
  }
}
