import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/notification_service.dart';
import '../../../services/practice_progress_service.dart';

class ClassSchedulerScreen extends StatefulWidget {
  const ClassSchedulerScreen({super.key});

  @override
  State<ClassSchedulerScreen> createState() => _ClassSchedulerScreenState();
}

class _ClassSchedulerScreenState extends State<ClassSchedulerScreen> {
  static const String _savedSchedulesKey = 'smart_practice_schedules';

  String selectedPractice = 'Gitar';
  String selectedTarget = 'Tuning Gitar';
  String selectedZone = 'WIB';
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  DateTime manualConvertDate = DateTime.now();
  TimeOfDay manualConvertTime = TimeOfDay.now();
  String manualFromZone = 'WIB';
  String manualToZone = 'WITA';

  bool isSaving = false;

  final List<Map<String, dynamic>> savedSchedules = [];
  final Map<int, String> scheduleDisplayZones = {};

  final Map<String, int> zoneOffsets = {
    'London': 0,
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
  };

  final Map<String, Map<String, dynamic>> practiceCatalog = {
    'Vokal': {
      'icon': Icons.mic_rounded,
      'color': Color(0xFF7C4DFF),
      'targets': [
        'Pemanasan Vokal',
        'Pernapasan Diafragma',
        'Intonasi',
        'Nada Tinggi',
        'Artikulasi',
        'Vibrato Dasar',
      ],
      'focus':
          'Kontrol napas, stabilitas nada, artikulasi, dan ekspresi suara.',
    },
    'Gitar': {
      'icon': Icons.music_note_rounded,
      'color': Color(0xFFFF8A65),
      'targets': [
        'Tuning Gitar',
        'Chord Dasar',
        'Strumming',
        'Fingerstyle',
        'Picking',
        'Rhythm',
        'Perpindahan Chord',
      ],
      'focus':
          'Tuning, chord, petikan, strumming, tempo, dan koordinasi tangan.',
    },
    'Piano': {
      'icon': Icons.piano_rounded,
      'color': Color(0xFF00A6FB),
      'targets': [
        'Chord Progression',
        'Melodi Dasar',
        'Koordinasi Tangan',
        'Sight Reading',
        'Ritme Piano',
        'Aransemen Sederhana',
      ],
      'focus': 'Chord, melodi, koordinasi tangan kanan-kiri, dan ritme.',
    },
    'Biola': {
      'icon': Icons.library_music_rounded,
      'color': Color(0xFF21C67A),
      'targets': [
        'Bowing Dasar',
        'Intonasi',
        'Tangga Nada',
        'Posisi Jari',
        'Vibrato Awal',
        'Kontrol Gesekan',
      ],
      'focus': 'Intonasi, bowing, posisi jari, dan kestabilan nada.',
    },
    'Ear Training': {
      'icon': Icons.hearing_rounded,
      'color': Color(0xFF9C27B0),
      'targets': [
        'Do Re Mi',
        'Tebak Nada',
        'Interval Dasar',
        'Repeat Pitch',
        'Akurasi Nada',
        'Memori Melodi',
      ],
      'focus': 'Pendengaran nada, interval, memori melodi, dan akurasi pitch.',
    },
    'Recording': {
      'icon': Icons.mic_external_on_rounded,
      'color': Color(0xFF0072FF),
      'targets': [
        'Take Vokal',
        'Mic Control',
        'Monitoring',
        'Evaluasi Rekaman',
        'Layering Suara',
        'Kebersihan Audio',
      ],
      'focus':
          'Kualitas rekaman, jarak mikrofon, monitoring, dan evaluasi audio.',
    },
  };

  Map<String, dynamic> get _practicePlan => practiceCatalog[selectedPractice]!;

  List<String> get _currentTargets {
    final targets = _practicePlan['targets'] as List;
    return targets.map((item) => item.toString()).toList();
  }

  int get _deviceOffset => DateTime.now().timeZoneOffset.inHours;

  String get _deviceZoneLabel {
    for (final entry in zoneOffsets.entries) {
      if (entry.value == _deviceOffset) return entry.key;
    }

    final sign = _deviceOffset >= 0 ? '+' : '';
    return 'UTC$sign$_deviceOffset';
  }

  @override
  void initState() {
    super.initState();
    _normalizeInitialTime();
    _loadSavedSchedules();
  }

  void _normalizeInitialTime() {
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    final next = now.add(const Duration(minutes: 3));
    selectedTime = TimeOfDay(hour: next.hour, minute: next.minute);
    manualConvertDate = DateTime(now.year, now.month, now.day);
    manualConvertTime = TimeOfDay(hour: next.hour, minute: next.minute);
  }

  Future<void> _loadSavedSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedSchedulesKey);

    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      if (!mounted) return;

      setState(() {
        savedSchedules
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
      });
    } catch (_) {
      return;
    }
  }

  Future<void> _persistSavedSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedSchedulesKey, jsonEncode(savedSchedules));
  }

  String _formatTimeFromParts(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return _formatTimeFromParts(time.hour, time.minute);
  }

  String _dayName(DateTime date) {
    const names = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return names[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${_dayName(date)}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime _originalDateTime() {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  DateTime _convertDateTime({
    required DateTime originalDateTime,
    required String fromZone,
    required String toZone,
  }) {
    final fromOffset = zoneOffsets[fromZone] ?? 7;
    final toOffset = zoneOffsets[toZone] ?? 7;
    return originalDateTime.add(Duration(hours: toOffset - fromOffset));
  }

  DateTime _toDeviceDateTime({
    required DateTime originalDateTime,
    required String fromZone,
  }) {
    final fromOffset = zoneOffsets[fromZone] ?? 7;
    return originalDateTime.add(Duration(hours: _deviceOffset - fromOffset));
  }

  String _convertedText({
    required DateTime originalDateTime,
    required String fromZone,
    required String toZone,
  }) {
    final converted = _convertDateTime(
      originalDateTime: originalDateTime,
      fromZone: fromZone,
      toZone: toZone,
    );

    return '${_formatDate(converted)} • ${_formatTimeFromParts(converted.hour, converted.minute)} $toZone';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(DateTime(now.year, now.month, now.day))
          ? DateTime(now.year, now.month, now.day)
          : selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3, 12, 31),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked == null) return;

    setState(() {
      selectedTime = picked;
    });
  }

  void _selectPractice(String value) {
    final targets = practiceCatalog[value]!['targets'] as List;

    setState(() {
      selectedPractice = value;
      selectedTarget = targets.first.toString();
    });
  }

  Future<void> _saveSchedule() async {
    if (isSaving) return;

    final original = _originalDateTime();
    final deviceSchedule = _toDeviceDateTime(
      originalDateTime: original,
      fromZone: selectedZone,
    );

    if (deviceSchedule.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal dan jam yang belum lewat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final plan = _practicePlan;
    final deviceReminderText =
        '${_formatDate(deviceSchedule)} • ${_formatTimeFromParts(deviceSchedule.hour, deviceSchedule.minute)} $_deviceZoneLabel';

    final savedSchedule = {
      'id': notificationId,
      'practice_type': selectedPractice,
      'target': selectedTarget,
      'year': selectedDate.year,
      'month': selectedDate.month,
      'date': selectedDate.day,
      'hour': selectedTime.hour,
      'minute': selectedTime.minute,
      'zone': selectedZone,
      'focus': plan['focus'],
      'device_zone': _deviceZoneLabel,
      'device_reminder_time': deviceReminderText,
      'created_at': DateTime.now().toIso8601String(),
      'notification_enabled': true,
    };

    setState(() {
      savedSchedules.insert(0, savedSchedule);
      scheduleDisplayZones[notificationId] = selectedZone;
    });

    await _persistSavedSchedules();

    await PracticeProgressService.addPracticeSession(
      title: 'Jadwal latihan $selectedPractice',
      type: 'Smart Practice Scheduler',
      score: null,
      level: null,
      combo: null,
      passed: true,
      metadata: {
        ...savedSchedule,
        'original_time':
            '${_formatDate(selectedDate)} • ${_formatTime(selectedTime)} $selectedZone',
        'london_time': _convertedText(
          originalDateTime: original,
          fromZone: selectedZone,
          toZone: 'London',
        ),
      },
    );

    await NotificationService.schedulePracticeReminder(
      id: notificationId,
      title: 'Waktunya latihan $selectedPractice',
      body: '$selectedTarget • Reminder HP: $deviceReminderText',
      scheduledAt: deviceSchedule,
    );

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Jadwal tersimpan: ${_formatDate(selectedDate)} • ${_formatTime(selectedTime)} $selectedZone. Reminder HP: $deviceReminderText.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeSchedule(Map<String, dynamic> schedule) async {
    final id = schedule['id'];
    if (id is int) {
      await NotificationService.cancelNotification(id);
    }

    setState(() {
      savedSchedules.removeWhere((item) => item['id'] == schedule['id']);
      if (id is int) scheduleDisplayZones.remove(id);
    });

    await _persistSavedSchedules();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jadwal dihapus dan reminder dibatalkan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildChoiceChips({
    required List<String> values,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: values.map((value) {
        final selected = selectedValue == value;

        return ChoiceChip(
          label: Text(value),
          selected: selected,
          onSelected: (_) => onSelected(value),
          selectedColor: const Color(0xFF7C4DFF),
          backgroundColor: const Color(0xFFF1F3F9),
          labelStyle: TextStyle(
            color: selected ? Colors.white : const Color(0xFF4B5563),
            fontWeight: FontWeight.w800,
          ),
          side: BorderSide(
            color: selected ? const Color(0xFF7C4DFF) : const Color(0xFFE5E7EB),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF20243A),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7C7E8A),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6E2FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF7C4DFF)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4B4E63),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTimeCard() {
    final now = DateTime.now();
    final nowText =
        '${_formatDate(now)} • ${_formatTimeFromParts(now.hour, now.minute)} $_deviceZoneLabel';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCDEEDB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.phone_android_rounded,
            color: Color(0xFF00A86B),
            size: 28,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              'Jam perangkat HP kamu: $nowText. Reminder otomatis mengikuti jam perangkat ini.',
              style: const TextStyle(
                color: Color(0xFF166534),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickManualConvertDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate:
          manualConvertDate.isBefore(DateTime(now.year, now.month, now.day))
          ? DateTime(now.year, now.month, now.day)
          : manualConvertDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3, 12, 31),
    );

    if (picked == null) return;

    setState(() {
      manualConvertDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickManualConvertTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: manualConvertTime,
    );

    if (picked == null) return;

    setState(() {
      manualConvertTime = picked;
    });
  }

  Widget _buildZoneDropdown({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(16),
        items: zoneOffsets.keys
            .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }

  Widget _buildManualTimeConverterCard() {
    final original = DateTime(
      manualConvertDate.year,
      manualConvertDate.month,
      manualConvertDate.day,
      manualConvertTime.hour,
      manualConvertTime.minute,
    );

    final converted = _convertedText(
      originalDateTime: original,
      fromZone: manualFromZone,
      toZone: manualToZone,
    );

    final originalText =
        '${_formatDate(manualConvertDate)} • ${_formatTime(manualConvertTime)} $manualFromZone';

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
          const Text(
            'Konversi Manual Jadwal',
            style: TextStyle(
              color: Color(0xFF20243A),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Gunakan ini sebagai patokan sebelum menyimpan jadwal. Pilih waktu asal, lalu lihat hasilnya di zona tujuan.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickManualConvertDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(_formatDate(manualConvertDate)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5E35B1),
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickManualConvertTime,
            icon: const Icon(Icons.schedule_rounded),
            label: Text('Jam asal: ${_formatTime(manualConvertTime)}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5E35B1),
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildZoneDropdown(
                  value: manualFromZone,
                  onChanged: (value) => setState(() => manualFromZone = value),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF7C4DFF)),
              const SizedBox(width: 10),
              Expanded(
                child: _buildZoneDropdown(
                  value: manualToZone,
                  onChanged: (value) => setState(() => manualToZone = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waktu asal: $originalText',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hasil konversi: $converted',
                  style: const TextStyle(
                    color: Color(0xFF00A86B),
                    fontSize: 15,
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

  Widget _buildSummaryCard() {
    final plan = _practicePlan;
    final color = plan['color'] as Color;
    final original = _originalDateTime();
    final deviceSchedule = _toDeviceDateTime(
      originalDateTime: original,
      fromZone: selectedZone,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEDEDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(plan['icon'] as IconData, color: color, size: 28),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rencana $selectedPractice',
                      style: const TextStyle(
                        color: Color(0xFF20243A),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatDate(selectedDate)} • ${_formatTime(selectedTime)} $selectedZone',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.flag_rounded, selectedTarget),
              _buildInfoChip(
                Icons.notifications_active_rounded,
                'Reminder aktif',
              ),
              _buildInfoChip(
                Icons.phone_android_rounded,
                '${_formatDate(deviceSchedule)} • ${_formatTimeFromParts(deviceSchedule.hour, deviceSchedule.minute)} $_deviceZoneLabel',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Fokus: ${plan['focus']}',
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Konversi waktu jadwal ini',
            style: TextStyle(
              color: Color(0xFF20243A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: zoneOffsets.keys.map((zone) {
              return _buildInfoChip(
                Icons.public_rounded,
                _convertedText(
                  originalDateTime: original,
                  fromZone: selectedZone,
                  toZone: zone,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedSchedulesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF3E8FF)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwalku',
            style: TextStyle(
              color: Color(0xFF20243A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Setiap jadwal menyimpan tanggal dan zona asli. Kamu bisa mengubah tampilan konversi per jadwal tanpa mengubah reminder.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (savedSchedules.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Belum ada jadwal tersimpan. Buat jadwal latihan pertama, lalu reminder otomatis akan aktif.',
                style: TextStyle(
                  color: Color(0xFF7C7E8A),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...savedSchedules.map(_buildSavedScheduleCard),
        ],
      ),
    );
  }

  Widget _buildSavedScheduleCard(Map<String, dynamic> schedule) {
    final id = schedule['id'] is int
        ? schedule['id'] as int
        : schedule.hashCode;
    final practice = schedule['practice_type']?.toString() ?? 'Latihan';
    final target = schedule['target']?.toString() ?? 'Target';
    final zone = schedule['zone']?.toString() ?? 'WIB';
    final year = schedule['year'] is int
        ? schedule['year'] as int
        : DateTime.now().year;
    final month = schedule['month'] is int
        ? schedule['month'] as int
        : DateTime.now().month;
    final date = schedule['date'] is int
        ? schedule['date'] as int
        : DateTime.now().day;
    final hour = schedule['hour'] is int ? schedule['hour'] as int : 0;
    final minute = schedule['minute'] is int ? schedule['minute'] as int : 0;
    final focus = schedule['focus']?.toString() ?? '';
    final reminder = schedule['device_reminder_time']?.toString() ?? '-';

    final original = DateTime(year, month, date, hour, minute);
    final displayZone = scheduleDisplayZones[id] ?? zone;
    final converted = _convertedText(
      originalDateTime: original,
      fromZone: zone,
      toZone: displayZone,
    );

    final plan = practiceCatalog[practice];
    final color = plan == null
        ? const Color(0xFF7C4DFF)
        : plan['color'] as Color;
    final icon = plan == null
        ? Icons.event_note_rounded
        : plan['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$practice • $target',
                  style: const TextStyle(
                    color: Color(0xFF20243A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  converted,
                  style: const TextStyle(
                    color: Color(0xFF00A86B),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jadwal asli: ${_formatDate(original)} • ${_formatTimeFromParts(hour, minute)} $zone',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reminder HP: $reminder',
                  style: const TextStyle(
                    color: Color(0xFF5E35B1),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6E2FF)),
                  ),
                  child: DropdownButton<String>(
                    value: displayZone,
                    isExpanded: true,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(16),
                    items: zoneOffsets.keys
                        .map(
                          (itemZone) => DropdownMenuItem(
                            value: itemZone,
                            child: Text('Konversi jadwal ini ke $itemZone'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => scheduleDisplayZones[id] = value);
                    },
                  ),
                ),
                if (focus.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    focus,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7C7E8A),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeSchedule(schedule),
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFFE85D75),
            tooltip: 'Hapus jadwal',
          ),
        ],
      ),
    );
  }

  static const Color _bgColor = Color(0xFFFCFCFE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Smart Practice Scheduler',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            const Text(
              'Buat jadwal latihan berdasarkan tanggal, jam, dan zona waktu asli. Reminder otomatis akan mengikuti jam perangkat HP.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF7C7E8A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _buildDeviceTimeCard(),
            const SizedBox(height: 18),
            _buildManualTimeConverterCard(),
            const SizedBox(height: 20),
            _buildSectionTitle(
              'Jenis latihan',
              'Pilih area musik yang ingin kamu jadwalkan.',
            ),
            _buildChoiceChips(
              values: practiceCatalog.keys.toList(),
              selectedValue: selectedPractice,
              onSelected: _selectPractice,
            ),
            const SizedBox(height: 18),
            _buildSectionTitle(
              'Target belajar',
              'Target berubah mengikuti jenis latihan yang dipilih.',
            ),
            _buildChoiceChips(
              values: _currentTargets,
              selectedValue: selectedTarget,
              onSelected: (value) => setState(() => selectedTarget = value),
            ),
            const SizedBox(height: 18),
            _buildSectionTitle(
              'Zona waktu asli',
              'Zona ini menjadi acuan jadwal yang disimpan.',
            ),
            _buildChoiceChips(
              values: zoneOffsets.keys.toList(),
              selectedValue: selectedZone,
              onSelected: (value) => setState(() => selectedZone = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text('Pilih tanggal: ${_formatDate(selectedDate)}'),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  'Pilih jam latihan: ${_formatTime(selectedTime)} $selectedZone',
                ),
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
            const SizedBox(height: 18),
            _buildSummaryCard(),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveSchedule,
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
                label: Text(
                  isSaving ? 'Menyimpan...' : 'Simpan Jadwal & Reminder',
                ),
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
            const SizedBox(height: 20),
            _buildSavedSchedulesSection(),
          ],
        ),
      ),
    );
  }
}
