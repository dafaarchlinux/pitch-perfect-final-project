import 'package:flutter/material.dart';

import '../../../services/practice_progress_service.dart';

const Color _bg = Color(0xFF0B0D22);
const Color _surface = Color(0xFF17182C);
const Color _surfaceSoft = Color(0xFF232542);
const Color _border = Color(0xFF2D3050);
const Color _text = Color(0xFFF8FAFC);
const Color _muted = Color(0xFF9EA6C9);
const Color _purple = Color(0xFF8B5CF6);
const Color _cyan = Color(0xFF22D3EE);
const Color _pink = Color(0xFFF472B6);
const Color _green = Color(0xFF34D399);

class ClassSchedulerScreen extends StatefulWidget {
  const ClassSchedulerScreen({super.key});

  @override
  State<ClassSchedulerScreen> createState() => _ClassSchedulerScreenState();
}

class _ClassSchedulerScreenState extends State<ClassSchedulerScreen> {
  String selectedPractice = 'Gitar';
  String selectedTarget = 'Teknik Chord';
  String selectedZone = 'WIB';
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool isSaving = false;

  String? editingScheduleId;

  final List<Map<String, dynamic>> savedSchedules = [];

  final Map<String, int> zoneOffsets = {
    'London': 0,
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
  };

  final Map<String, Map<String, dynamic>> practiceCatalog = {
    'Vokal': {
      'icon': Icons.mic_rounded,
      'color': Color(0xFF8B5CF6),
      'targets': [
        'Pemanasan Vokal',
        'Pernapasan Diafragma',
        'Intonasi',
        'Nada Tinggi',
        'Artikulasi',
        'Vibrato Dasar',
      ],
      'focus': 'Kontrol napas, stabilitas nada, artikulasi, dan ekspresi suara.',
    },
    'Gitar': {
      'icon': Icons.music_note_rounded,
      'color': Color(0xFFF472B6),
      'targets': [
        'Tuning Gitar',
        'Teknik Chord',
        'Strumming',
        'Fingerstyle',
        'Picking',
        'Rhythm',
        'Perpindahan Chord',
      ],
      'focus': 'Tuning, chord, petikan, strumming, tempo, dan koordinasi tangan.',
    },
    'Piano': {
      'icon': Icons.piano_rounded,
      'color': Color(0xFF22D3EE),
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
      'color': Color(0xFF34D399),
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
      'color': Color(0xFFFBBF24),
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
      'color': Color(0xFF22D3EE),
      'targets': [
        'Take Vokal',
        'Mic Control',
        'Monitoring',
        'Evaluasi Rekaman',
        'Layering Suara',
        'Kebersihan Audio',
      ],
      'focus': 'Kualitas rekaman, jarak mikrofon, monitoring, dan evaluasi audio.',
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
  }

  Future<void> _loadSavedSchedules() async {
    final schedules = await PracticeProgressService.getPracticeSchedules();

    if (!mounted) return;

    setState(() {
      savedSchedules
        ..clear()
        ..addAll(schedules);
    });
  }

  Future<void> _persistSavedSchedules() async {
    await PracticeProgressService.savePracticeSchedules(savedSchedules);
  }

  String _formatTimeFromParts(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return _formatTimeFromParts(time.hour, time.minute);
  }

  String _formatCompactDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _selectedDateTime() {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  DateTime _toUtcBasedOnZone(DateTime localInput, String zone) {
    final offset = zoneOffsets[zone] ?? 7;
    return localInput.subtract(Duration(hours: offset));
  }

  DateTime _fromUtcToZone(DateTime utc, String zone) {
    final offset = zoneOffsets[zone] ?? 7;
    return utc.add(Duration(hours: offset));
  }

  Map<String, String> _convertedTimesForSelection() {
    final input = _selectedDateTime();
    final utc = _toUtcBasedOnZone(input, selectedZone);

    final result = <String, String>{};
    for (final zone in ['WIB', 'WITA', 'WIT', 'London']) {
      final converted = _fromUtcToZone(utc, zone);
      result[zone] = '${_formatTimeFromParts(converted.hour, converted.minute)} • ${_formatCompactDate(converted)}';
    }
    return result;
  }

  Map<String, String> _convertedTimesFromSchedule(Map<String, dynamic> schedule) {
    final rawDate = schedule['date']?.toString() ?? _formatCompactDate(DateTime.now());
    final rawTime = schedule['time']?.toString() ?? '00:00';
    final rawZone = schedule['timezone']?.toString() ?? 'WIB';

    final dateParts = rawDate.split('-');
    final timeParts = rawTime.split(':');

    final date = DateTime(
      int.tryParse(dateParts.elementAt(0)) ?? DateTime.now().year,
      int.tryParse(dateParts.elementAt(1)) ?? DateTime.now().month,
      int.tryParse(dateParts.elementAt(2)) ?? DateTime.now().day,
      int.tryParse(timeParts.elementAt(0)) ?? 0,
      int.tryParse(timeParts.elementAt(1)) ?? 0,
    );

    final utc = _toUtcBasedOnZone(date, rawZone);
    final result = <String, String>{};

    for (final zone in ['WIB', 'WITA', 'WIT', 'London']) {
      final converted = _fromUtcToZone(utc, zone);
      result[zone] = '${_formatTimeFromParts(converted.hour, converted.minute)} • ${_formatCompactDate(converted)}';
    }

    return result;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(now) ? now : selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _purple,
              surface: _surface,
              onSurface: _text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _purple,
              surface: _surface,
              onSurface: _text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setState(() => selectedTime = picked);
  }

  Map<String, dynamic> _buildScheduleData({String? id}) {
    final plan = _practicePlan;
    return {
      'id': id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      'practice': selectedPractice,
      'target': selectedTarget,
      'date': _formatCompactDate(selectedDate),
      'time': _formatTime(selectedTime),
      'timezone': selectedZone,
      'device_timezone': _deviceZoneLabel,
      'converted_times': _convertedTimesForSelection(),
      'focus': plan['focus'].toString(),
      'created_at': DateTime.now().toIso8601String(),
      'storage': 'Hive',
    };
  }

  Future<void> _saveSchedule() async {
    final scheduledDateTime = _selectedDateTime();

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jadwal yang belum lewat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final scheduleData = _buildScheduleData(id: editingScheduleId);

      if (editingScheduleId == null) {
        savedSchedules.insert(0, scheduleData);
      } else {
        final index = savedSchedules.indexWhere((item) => item['id'] == editingScheduleId);
        if (index == -1) {
          savedSchedules.insert(0, scheduleData);
        } else {
          savedSchedules[index] = scheduleData;
        }
      }

      await _persistSavedSchedules();

      await PracticeProgressService.addPracticeSession(
        title: editingScheduleId == null
            ? 'Jadwal latihan: $selectedPractice'
            : 'Edit jadwal latihan: $selectedPractice',
        type: 'Smart Practice Scheduler',
        passed: true,
        metadata: scheduleData,
      );

      if (!mounted) return;
      setState(() {
        isSaving = false;
        editingScheduleId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editingScheduleId == null
                ? 'Jadwal latihan berhasil disimpan.'
                : 'Jadwal latihan berhasil diperbarui.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan jadwal.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteSchedule(String id) async {
    setState(() {
      savedSchedules.removeWhere((item) => item['id'] == id);
      if (editingScheduleId == id) editingScheduleId = null;
    });
    await _persistSavedSchedules();
  }

  void _startEditSchedule(
    Map<String, dynamic> schedule, {
    bool closeDialog = false,
  }) {
    final practice = schedule['practice']?.toString() ?? 'Gitar';
    final target = schedule['target']?.toString() ?? 'Teknik Chord';
    final rawDate = schedule['date']?.toString() ?? _formatCompactDate(DateTime.now());
    final rawTime = schedule['time']?.toString() ?? _formatTime(TimeOfDay.now());
    final timezone = schedule['timezone']?.toString() ?? 'WIB';

    final dateParts = rawDate.split('-');
    final timeParts = rawTime.split(':');

    final parsedDate = DateTime(
      int.tryParse(dateParts.elementAt(0)) ?? DateTime.now().year,
      int.tryParse(dateParts.elementAt(1)) ?? DateTime.now().month,
      int.tryParse(dateParts.elementAt(2)) ?? DateTime.now().day,
    );

    final parsedTime = TimeOfDay(
      hour: int.tryParse(timeParts.elementAt(0)) ?? TimeOfDay.now().hour,
      minute: int.tryParse(timeParts.elementAt(1)) ?? TimeOfDay.now().minute,
    );

    final validPractice = practiceCatalog.containsKey(practice) ? practice : 'Gitar';
    final targets = (practiceCatalog[validPractice]!['targets'] as List)
        .map((item) => item.toString())
        .toList();

    setState(() {
      editingScheduleId = schedule['id']?.toString();
      selectedPractice = validPractice;
      selectedTarget = targets.contains(target) ? target : targets.first;
      selectedDate = parsedDate;
      selectedTime = parsedTime;
      selectedZone = zoneOffsets.containsKey(timezone) ? timezone : 'WIB';
    });

    if (closeDialog) {
      Navigator.pop(context);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mode edit aktif. Ubah data lalu tekan Simpan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      editingScheduleId = null;
      _normalizeInitialTime();
      selectedPractice = 'Gitar';
      selectedTarget = 'Teknik Chord';
      selectedZone = 'WIB';
    });
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _muted,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _inputShell({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return _inputShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: _surfaceSoft,
          iconEnabledColor: _muted,
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(
            color: _text,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSchedulerForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          if (editingScheduleId != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _purple.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mode edit jadwal aktif',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: _pink, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('JENIS LATIHAN'),
                    const SizedBox(height: 9),
                    _dropdownField(
                      value: selectedPractice,
                      items: practiceCatalog.keys.toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final targets = (practiceCatalog[value]!['targets'] as List)
                            .map((item) => item.toString())
                            .toList();
                        setState(() {
                          selectedPractice = value;
                          selectedTarget = targets.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('TARGET'),
                    const SizedBox(height: 9),
                    _dropdownField(
                      value: _currentTargets.contains(selectedTarget)
                          ? selectedTarget
                          : _currentTargets.first,
                      items: _currentTargets,
                      onChanged: (value) {
                        if (value != null) setState(() => selectedTarget = value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('TANGGAL'),
                    const SizedBox(height: 9),
                    _inputShell(
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatCompactDate(selectedDate),
                              style: const TextStyle(
                                color: _text,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_month_rounded, color: _muted, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('JAM'),
                    const SizedBox(height: 9),
                    _inputShell(
                      onTap: _pickTime,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatTime(selectedTime),
                              style: const TextStyle(
                                color: _text,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(Icons.schedule_rounded, color: _muted, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSelectedDataAndTimezone(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                isSaving
                    ? 'Menyimpan...'
                    : editingScheduleId == null
                        ? 'Simpan Jadwal & Reminder'
                        : 'Simpan Perubahan Jadwal',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDataAndTimezone() {
    final plan = _practicePlan;
    final icon = plan['icon'] as IconData;
    final color = plan['color'] as Color;
    final converted = _convertedTimesForSelection();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPractice,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: $selectedTarget',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _pink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _smallInfoBox(
                  icon: Icons.calendar_today_rounded,
                  label: 'TANGGAL',
                  value: _formatCompactDate(selectedDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _smallInfoBox(
                  icon: Icons.access_time_rounded,
                  label: 'JAM',
                  value: '${_formatTime(selectedTime)} $selectedZone',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lihat konversi zona waktu',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: _dropdownField(
                  value: selectedZone,
                  items: zoneOffsets.keys.toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedZone = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: converted.entries.map((entry) {
              final isSelected = entry.key == selectedZone;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? _purple.withOpacity(0.22) : _bg.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? _purple : _border),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    color: isSelected ? _text : _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _smallInfoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
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

  Widget _buildSavedSchedulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JADWAL MENDATANG',
          style: TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 14),
        if (savedSchedules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: const Text(
              'Belum ada jadwal tersimpan.',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          )
        else
          ...savedSchedules.map((schedule) => _buildSchedulePreview(schedule)),
      ],
    );
  }

  Widget _buildSchedulePreview(Map<String, dynamic> schedule) {
    final practice = schedule['practice']?.toString() ?? 'Latihan';
    final target = schedule['target']?.toString() ?? '-';
    final date = schedule['date']?.toString() ?? '-';
    final time = schedule['time']?.toString() ?? '-';
    final timezone = schedule['timezone']?.toString() ?? 'WIB';
    final plan = practiceCatalog[practice] ?? practiceCatalog['Gitar']!;
    final icon = plan['icon'] as IconData;
    final color = plan['color'] as Color;

    return InkWell(
      onTap: () => _showScheduleDetail(schedule),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    practice,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    target,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: _muted, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '$time $timezone',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today_rounded, color: _muted, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _startEditSchedule(schedule),
              icon: const Icon(Icons.edit_outlined),
              color: _cyan,
              tooltip: 'Edit jadwal',
            ),
            IconButton(
              onPressed: () => _deleteSchedule(schedule['id']?.toString() ?? ''),
              icon: const Icon(Icons.delete_outline_rounded),
              color: _muted,
              tooltip: 'Hapus jadwal',
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDetail(Map<String, dynamic> schedule) {
    final practice = schedule['practice']?.toString() ?? 'Latihan';
    final target = schedule['target']?.toString() ?? '-';
    final date = schedule['date']?.toString() ?? '-';
    final time = schedule['time']?.toString() ?? '-';
    final timezone = schedule['timezone']?.toString() ?? 'WIB';
    final focus = schedule['focus']?.toString() ?? '-';
    final plan = practiceCatalog[practice] ?? practiceCatalog['Gitar']!;
    final icon = plan['icon'] as IconData;
    final color = plan['color'] as Color;
    final converted = _convertedTimesFromSchedule(schedule);
    String detailZone = converted.containsKey(timezone) ? timezone : 'WIB';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.84,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: _border),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _surfaceSoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: _text,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(icon, color: color, size: 40),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          practice,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Target: $target',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _pink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _smallInfoBox(
                                icon: Icons.calendar_today_rounded,
                                label: 'TANGGAL',
                                value: date,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _smallInfoBox(
                                icon: Icons.access_time_rounded,
                                label: 'JAM',
                                value: '$time $timezone',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _surfaceSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _border),
                          ),
                          child: Text(
                            'Fokus latihan: $focus',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _surfaceSoft,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Konversi Zona Waktu',
                                style: TextStyle(
                                  color: _cyan.withOpacity(0.95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _bg.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: detailZone,
                                    isExpanded: true,
                                    dropdownColor: _surfaceSoft,
                                    iconEnabledColor: _cyan,
                                    borderRadius: BorderRadius.circular(14),
                                    style: const TextStyle(
                                      color: _text,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    items: converted.keys
                                        .map(
                                          (zone) => DropdownMenuItem(
                                            value: zone,
                                            child: Text(zone),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setDialogState(() {
                                        detailZone = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _purple.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _purple.withOpacity(0.55),
                                  ),
                                ),
                                child: Text(
                                  '$detailZone: ${converted[detailZone] ?? '-'}',
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _startEditSchedule(
                              schedule,
                              closeDialog: true,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _cyan,
                              side: const BorderSide(color: _cyan),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Edit Jadwal',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _surfaceSoft,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Tutup Detail',
                              style: TextStyle(
                                color: _text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _text),
        title: const Text(
          'Smart Practice Scheduler',
          style: TextStyle(color: _text, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            const Text(
              'Music Practice Scheduler',
              style: TextStyle(
                color: _cyan,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Atur waktu latihanmu dengan lebih terstruktur',
              style: TextStyle(
                color: Color(0xFFB9C7FF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            _buildSchedulerForm(),
            const SizedBox(height: 32),
            _buildSavedSchedulesSection(),
          ],
        ),
      ),
    );
  }
}
