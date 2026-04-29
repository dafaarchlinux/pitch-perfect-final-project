import 'package:flutter/material.dart';
import '../../../services/practice_progress_service.dart';

class PrivateClassScreen extends StatefulWidget {
  const PrivateClassScreen({super.key});

  @override
  State<PrivateClassScreen> createState() => _PrivateClassScreenState();
}

class _PrivateClassScreenState extends State<PrivateClassScreen> {
  TimeOfDay selectedStudyTime = const TimeOfDay(hour: 19, minute: 0);
  String selectedTeacherZone = 'London';
  String selectedClassType = 'Vokal';
  bool isSaving = false;

  final Map<String, int> timezoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 1,
  };

  final Map<String, Map<String, String>> classPlans = {
    'Vokal': {
      'coach': 'Coach Amelia',
      'duration': '60 menit',
      'focus': 'napas, intonasi, Do Re Mi, dan kontrol nada',
      'icon': '🎤',
    },
    'Gitar': {
      'coach': 'Coach Daniel',
      'duration': '45 menit',
      'focus': 'chord dasar, strumming, tuning, dan tempo',
      'icon': '🎸',
    },
    'Piano': {
      'coach': 'Coach Olivia',
      'duration': '60 menit',
      'focus': 'chord, melodi, koordinasi tangan, dan ritme',
      'icon': '🎹',
    },
    'Biola': {
      'coach': 'Coach Ken',
      'duration': '50 menit',
      'focus': 'intonasi, bowing, tangga nada, dan feeling nada',
      'icon': '🎻',
    },
  };

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _convertFromWibToTeacherZone() {
    final baseDate = DateTime(
      2025,
      1,
      1,
      selectedStudyTime.hour,
      selectedStudyTime.minute,
    );

    final teacherOffset = timezoneOffsets[selectedTeacherZone] ?? 7;
    final hourDifference = teacherOffset - 7;
    final converted = baseDate.add(Duration(hours: hourDifference));

    final hour = converted.hour.toString().padLeft(2, '0');
    final minute = converted.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _pickStudyTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedStudyTime,
    );

    if (picked != null) {
      setState(() {
        selectedStudyTime = picked;
      });
    }
  }

  Future<void> _savePlan() async {
    if (isSaving) return;

    setState(() => isSaving = true);

    final studentTime = _formatTime(selectedStudyTime);
    final teacherTime = _convertFromWibToTeacherZone();
    final plan = classPlans[selectedClassType]!;

    await PracticeProgressService.addPracticeSession(
      title: 'Rencana kelas privat $selectedClassType',
      type: 'Planner Kelas',
      score: null,
      level: null,
      combo: null,
      passed: true,
      metadata: {
        'class_type': selectedClassType,
        'coach': plan['coach'],
        'duration': plan['duration'],
        'focus': plan['focus'],
        'student_time': studentTime,
        'teacher_time': teacherTime,
        'teacher_zone': selectedTeacherZone,
      },
    );

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rencana tersimpan: $selectedClassType dengan ${plan['coach']} • $studentTime WIB / $teacherTime $selectedTeacherZone',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildTeacherZoneDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButton<String>(
        value: selectedTeacherZone,
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(16),
        items: const ['WIB', 'WITA', 'WIT', 'London']
            .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedTeacherZone = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildClassTypeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: classPlans.entries.map((entry) {
        final selected = selectedClassType == entry.key;
        final icon = entry.value['icon'] ?? '🎵';

        return InkWell(
          onTap: () {
            setState(() {
              selectedClassType = entry.key;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 96,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF7C4DFF)
                  : const Color(0xFFF7F7FB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? const Color(0xFF7C4DFF)
                    : const Color(0xFFEDEDF5),
              ),
            ),
            child: Column(
              children: [
                Text(icon, style: const TextStyle(fontSize: 25)),
                const SizedBox(height: 7),
                Text(
                  entry.key,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF20243A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    final studentTime = _formatTime(selectedStudyTime);
    final teacherTime = _convertFromWibToTeacherZone();
    final plan = classPlans[selectedClassType]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Rencana',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF20243A),
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            Icons.school_rounded,
            'Jenis kelas',
            selectedClassType,
          ),
          _buildSummaryRow(
            Icons.person_rounded,
            'Rekomendasi coach',
            plan['coach']!,
          ),
          _buildSummaryRow(Icons.timer_rounded, 'Durasi', plan['duration']!),
          _buildSummaryRow(Icons.flag_rounded, 'Fokus latihan', plan['focus']!),
          _buildSummaryRow(
            Icons.access_time_rounded,
            'Jam kamu',
            '$studentTime WIB',
          ),
          _buildSummaryRow(
            Icons.public_rounded,
            'Jam guru',
            '$teacherTime $selectedTeacherZone',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7C4DFF), size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8A8D99),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF20243A),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const Color _bgColor = Color(0xFFFCFCFE);

  @override
  Widget build(BuildContext context) {
    final studentTime = _formatTime(selectedStudyTime);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Kelas Privat',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            const Text(
              'Rencanakan kelas privat musik yang cocok dengan jam belajarmu dan zona waktu guru.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF7C7E8A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Planner Kelas Privat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih jenis kelas, jam belajar, dan zona waktu guru.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Jenis kelas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF20243A),
              ),
            ),
            const SizedBox(height: 10),
            _buildClassTypeSelector(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickStudyTime,
                icon: const Icon(Icons.access_time_rounded),
                label: Text('Pilih jam belajar: $studentTime WIB'),
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
            const SizedBox(height: 14),
            const Text(
              'Zona waktu guru',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF20243A),
              ),
            ),
            const SizedBox(height: 8),
            _buildTeacherZoneDropdown(),
            const SizedBox(height: 18),
            _buildSummaryCard(),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _savePlan,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(isSaving ? 'Menyimpan...' : 'Simpan Rencana'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB7A8FF),
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
}
