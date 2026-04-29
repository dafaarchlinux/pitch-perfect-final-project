import 'package:flutter/material.dart';

class TrendingInstrumentsScreen extends StatefulWidget {
  const TrendingInstrumentsScreen({super.key});

  @override
  State<TrendingInstrumentsScreen> createState() =>
      _TrendingInstrumentsScreenState();
}

class _TrendingInstrumentsScreenState extends State<TrendingInstrumentsScreen> {
  String selectedCurrency = 'IDR';
  String selectedTimezone = 'WIB';
  String selectedTeacherTimezone = 'London';

  final TextEditingController priceInputController = TextEditingController(
    text: '1500000',
  );

  TimeOfDay selectedPrivateTime = const TimeOfDay(hour: 19, minute: 0);

  final Map<String, double> exchangeRates = {
    'IDR': 1,
    'USD': 0.000061,
    'EUR': 0.000057,
    'JPY': 0.0095,
  };

  final Map<String, int> timezoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 1,
  };

  final List<Map<String, dynamic>> instruments = [
    {
      'name': 'Gitar Akustik',
      'price': 1500000.0,
      'icon': Icons.music_note,
      'tag': 'Cocok untuk pemula',
    },
    {
      'name': 'Piano Digital',
      'price': 3250000.0,
      'icon': Icons.piano,
      'tag': 'Suara lebih lengkap',
    },
    {
      'name': 'Biola',
      'price': 1850000.0,
      'icon': Icons.library_music,
      'tag': 'Pilihan klasik',
    },
  ];

  final List<Map<String, String>> classes = [
    {'title': 'Kelas Vokal Online', 'time': '19:00', 'day': 'Monday'},
    {'title': 'Kelas Gitar Fingerstyle', 'time': '20:00', 'day': 'Wednesday'},
    {'title': 'Kelas Piano Online', 'time': '18:30', 'day': 'Friday'},
  ];

  @override
  void dispose() {
    priceInputController.dispose();
    super.dispose();
  }

  String convertPrice(double idrPrice) {
    if (selectedCurrency == 'IDR') {
      return 'IDR ${idrPrice.toStringAsFixed(0)}';
    }
    final converted = idrPrice * exchangeRates[selectedCurrency]!;
    return '$selectedCurrency ${converted.toStringAsFixed(2)}';
  }

  String convertManualPrice() {
    final raw = double.tryParse(priceInputController.text.trim()) ?? 0;
    return convertPrice(raw);
  }

  String convertTimeFromWib(String baseTime, String targetZone) {
    final parts = baseTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final wibDate = DateTime(2025, 1, 1, hour, minute);
    final targetOffset = timezoneOffsets[targetZone] ?? 7;
    final difference = targetOffset - 7;

    final converted = wibDate.add(Duration(hours: difference));
    final hh = converted.hour.toString().padLeft(2, '0');
    final mm = converted.minute.toString().padLeft(2, '0');

    return '$hh:$mm';
  }

  String convertTime(String baseTime) {
    return convertTimeFromWib(baseTime, selectedTimezone);
  }

  String getPrivateTeacherTime() {
    final hh = selectedPrivateTime.hour.toString().padLeft(2, '0');
    final mm = selectedPrivateTime.minute.toString().padLeft(2, '0');
    return convertTimeFromWib('$hh:$mm', selectedTeacherTimezone);
  }

  Future<void> _pickPrivateTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedPrivateTime,
    );

    if (picked != null) {
      setState(() {
        selectedPrivateTime = picked;
      });
    }
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20243A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7C7E8A),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInstrumentCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF23263A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['tag'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C7E8A),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      convertPrice(item['price'] as double),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00A86B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedCurrency,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5E35B1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, String> item) {
    final convertedTime = convertTime(item['time']!);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7E8FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0072FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item['day']} • $convertedTime ($selectedTimezone)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF54708B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jadwal awal WIB: ${item['time']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConverterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F7), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konversi Harga & Jadwal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF23263A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ubah harga alat musik ke mata uang lain dan cek jam kelas online sesuai zona waktu.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              if (isNarrow) {
                return Column(
                  children: [
                    _buildDropdownBox(
                      value: selectedCurrency,
                      items: const ['IDR', 'USD', 'EUR', 'JPY'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCurrency = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownBox(
                      value: selectedTimezone,
                      items: const ['WIB', 'WITA', 'WIT', 'London'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedTimezone = value;
                          });
                        }
                      },
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildDropdownBox(
                      value: selectedCurrency,
                      items: const ['IDR', 'USD', 'EUR', 'JPY'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCurrency = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownBox(
                      value: selectedTimezone,
                      items: const ['WIB', 'WITA', 'WIT', 'London'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedTimezone = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: priceInputController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Harga alat musik dalam rupiah',
              hintText: 'Contoh: 1500000',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Harga setelah dikonversi: ${convertManualPrice()}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF23263A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateClassPlanner() {
    final localHour = selectedPrivateTime.hour.toString().padLeft(2, '0');
    final localMinute = selectedPrivateTime.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(26),
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
          const Text(
            'Planner Kelas Privat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20243A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih jam belajar kamu, lalu lihat jam yang sesuai untuk guru di zona waktu lain.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              if (isNarrow) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickPrivateTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          'Pilih jam belajar: $localHour:$localMinute',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownBox(
                      value: selectedTeacherTimezone,
                      items: const ['WIB', 'WITA', 'WIT', 'London'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedTeacherTimezone = value;
                          });
                        }
                      },
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickPrivateTime,
                      icon: const Icon(Icons.access_time),
                      label: Text('Jam belajar: $localHour:$localMinute'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownBox(
                      value: selectedTeacherTimezone,
                      items: const ['WIB', 'WITA', 'WIT', 'London'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedTeacherTimezone = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Jam guru di $selectedTeacherTimezone: ${getPrivateTeacherTime()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownBox({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(16),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
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
          'Alat Musik & Kelas',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            _buildConverterCard(),
            const SizedBox(height: 24),
            _buildSectionTitle(
              'Harga Alat Musik',
              'Lihat contoh alat musik populer dan ubah harganya ke mata uang lain.',
            ),
            const SizedBox(height: 16),
            ...instruments.map(_buildInstrumentCard),
            const SizedBox(height: 10),
            _buildSectionTitle(
              'Jadwal Kelas Online',
              'Cek jadwal kelas musik dari luar negeri dalam zona waktu pilihanmu.',
            ),
            const SizedBox(height: 16),
            ...classes.map(_buildClassCard),
            const SizedBox(height: 10),
            _buildSectionTitle(
              'Kelas Privat',
              'Atur jam belajar sendiri dan cocokkan dengan zona waktu guru musik.',
            ),
            const SizedBox(height: 16),
            _buildPrivateClassPlanner(),
          ],
        ),
      ),
    );
  }
}
