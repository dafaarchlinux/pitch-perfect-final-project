import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/exchange_rate_service.dart';
import '../../../services/practice_progress_service.dart';

class InstrumentPricesScreen extends StatefulWidget {
  const InstrumentPricesScreen({super.key});

  @override
  State<InstrumentPricesScreen> createState() => _InstrumentPricesScreenState();
}

class _InstrumentPricesScreenState extends State<InstrumentPricesScreen> {
  static const String _savedInterestKey = 'saved_instrument_interests';

  String selectedCurrency = 'IDR';
  bool isLoadingRates = true;
  bool isUsingFallbackRates = false;
  String rateStatusText = 'Menyiapkan estimasi biaya alat musik...';

  int selectedInstrumentIndex = 0;
  List<Map<String, dynamic>> savedInterests = [];

  final TextEditingController manualPriceController = TextEditingController(
    text: '1500000',
  );

  Map<String, double> exchangeRates = {
    'IDR': 1,
    'USD': 0.000061,
    'EUR': 0.000057,
    'JPY': 0.0095,
    'GBP': 0.000048,
    'AUD': 0.000093,
    'CAD': 0.000084,
    'SGD': 0.000082,
    'CHF': 0.000054,
    'CNY': 0.00044,
    'KRW': 0.083,
    'MYR': 0.00029,
    'THB': 0.0022,
    'PHP': 0.0035,
    'INR': 0.0051,
    'HKD': 0.00048,
    'NZD': 0.00010,
    'SEK': 0.00067,
    'NOK': 0.00068,
    'DKK': 0.00043,
    'PLN': 0.00025,
    'CZK': 0.0014,
    'HUF': 0.023,
    'TRY': 0.0020,
    'ZAR': 0.0011,
    'BRL': 0.00034,
    'MXN': 0.0011,
    'ILS': 0.00023,
    'RON': 0.00029,
    'BGN': 0.00011,
    'ISK': 0.0085,
  };

  final List<Map<String, dynamic>> instruments = [
    {
      'name': 'Gitar Akustik',
      'category': 'Gitar',
      'price': 1500000.0,
      'icon': Icons.music_note_rounded,
      'description': 'Cocok untuk pemula, chord dasar, dan tampil akustik.',
      'practice': 'Latihan chord dasar, strumming, dan tuning gitar.',
    },
    {
      'name': 'Gitar Elektrik',
      'category': 'Gitar',
      'price': 2800000.0,
      'icon': Icons.graphic_eq_rounded,
      'description': 'Untuk rock, lead, rhythm, dan eksplorasi efek suara.',
      'practice': 'Latihan picking, power chord, bending, dan timing.',
    },
    {
      'name': 'Gitar Bass',
      'category': 'Bass',
      'price': 2600000.0,
      'icon': Icons.album_rounded,
      'description':
          'Instrumen low-end untuk groove, band, dan rhythm section.',
      'practice': 'Latihan tempo, root note, groove, dan sinkron dengan drum.',
    },
    {
      'name': 'Piano Digital',
      'category': 'Piano',
      'price': 3250000.0,
      'icon': Icons.piano_rounded,
      'description': 'Pilihan kuat untuk belajar chord, melodi, dan aransemen.',
      'practice': 'Latihan chord progression, melodi, dan koordinasi tangan.',
    },
    {
      'name': 'Keyboard Portable',
      'category': 'Keyboard',
      'price': 2200000.0,
      'icon': Icons.queue_music_rounded,
      'description':
          'Praktis untuk belajar iringan, aransemen, dan produksi musik.',
      'practice': 'Latihan rhythm style, chord, dan lagu sederhana.',
    },
    {
      'name': 'Biola',
      'category': 'String',
      'price': 1850000.0,
      'icon': Icons.library_music_rounded,
      'description':
          'Instrumen klasik untuk intonasi, bowing, dan feeling nada.',
      'practice': 'Latihan intonasi, bowing stabil, dan tangga nada.',
    },
    {
      'name': 'Ukulele',
      'category': 'String',
      'price': 650000.0,
      'icon': Icons.music_note_rounded,
      'description':
          'Ringan, mudah dibawa, dan cocok untuk pengiring lagu santai.',
      'practice': 'Latihan chord sederhana, strumming ringan, dan tempo.',
    },
    {
      'name': 'Drum Elektrik',
      'category': 'Drum',
      'price': 4500000.0,
      'icon': Icons.adjust_rounded,
      'description':
          'Alternatif drum hemat ruang untuk latihan rhythm di rumah.',
      'practice':
          'Latihan beat dasar, fill-in, tempo, dan koordinasi tangan kaki.',
    },
    {
      'name': 'Cajon',
      'category': 'Perkusi',
      'price': 750000.0,
      'icon': Icons.grid_view_rounded,
      'description':
          'Perkusi akustik ringkas untuk latihan rhythm dan perform live.',
      'practice':
          'Latihan pola kick-snare, groove akustik, dan dinamika pukulan.',
    },
    {
      'name': 'Mic Condenser',
      'category': 'Recording',
      'price': 950000.0,
      'icon': Icons.mic_rounded,
      'description':
          'Untuk rekaman vokal, podcast, dan latihan kualitas suara.',
      'practice': 'Latihan vokal, artikulasi, dan kontrol jarak mikrofon.',
    },
    {
      'name': 'Audio Interface',
      'category': 'Recording',
      'price': 1450000.0,
      'icon': Icons.settings_input_component_rounded,
      'description':
          'Perangkat penting untuk rekaman vokal atau instrumen ke laptop.',
      'practice': 'Latihan rekaman take vokal/gitar dan evaluasi hasil suara.',
    },
    {
      'name': 'Studio Monitor',
      'category': 'Audio',
      'price': 3000000.0,
      'icon': Icons.speaker_rounded,
      'description':
          'Speaker referensi untuk mixing, produksi, dan evaluasi audio.',
      'practice': 'Latihan mendengar detail frekuensi dan balancing suara.',
    },
    {
      'name': 'Headphone Monitoring',
      'category': 'Audio',
      'price': 850000.0,
      'icon': Icons.headphones_rounded,
      'description':
          'Membantu latihan rekaman, editing audio, dan fokus mendengar nada.',
      'practice': 'Latihan ear training, preview musik, dan monitoring vokal.',
    },
    {
      'name': 'Kalimba',
      'category': 'Melodi',
      'price': 250000.0,
      'icon': Icons.auto_awesome_rounded,
      'description':
          'Instrumen kecil dengan suara lembut untuk latihan melodi ringan.',
      'practice': 'Latihan melodi sederhana dan pendengaran interval.',
    },
    {
      'name': 'Harmonika',
      'category': 'Tiup',
      'price': 180000.0,
      'icon': Icons.air_rounded,
      'description': 'Instrumen tiup kecil untuk latihan napas dan melodi.',
      'practice': 'Latihan napas, melodi pendek, dan kontrol nada.',
    },
  ];

  Map<String, dynamic> get selectedInstrument =>
      instruments[selectedInstrumentIndex];

  @override
  void initState() {
    super.initState();
    _loadExchangeRates();
    _loadSavedInterests();
  }

  @override
  void dispose() {
    manualPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadExchangeRates() async {
    setState(() {
      isLoadingRates = true;
      rateStatusText = 'Menyiapkan estimasi biaya alat musik...';
    });

    try {
      final latestRates = await ExchangeRateService.getIdrRates();

      if (!mounted) return;

      setState(() {
        exchangeRates = latestRates;
        if (!exchangeRates.containsKey(selectedCurrency)) {
          selectedCurrency = 'IDR';
        }
        isLoadingRates = false;
        isUsingFallbackRates = false;
        rateStatusText =
            'Estimasi biaya global siap digunakan untuk rencana pembelian alat musik.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingRates = false;
        isUsingFallbackRates = true;
        rateStatusText =
            'Mode estimasi aktif. Kurs cadangan dipakai agar perhitungan tetap berjalan.';
      });
    }
  }

  Future<void> _loadSavedInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedInterestKey);

    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      if (!mounted) return;

      setState(() {
        savedInterests = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (_) {
      return;
    }
  }

  Future<void> _persistSavedInterests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedInterestKey, jsonEncode(savedInterests));
  }

  String _formatNumber(double value, {int decimals = 0}) {
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final number = parts.first;
    final buffer = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      final positionFromEnd = number.length - i;
      buffer.write(number[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    if (decimals > 0 && parts.length > 1) {
      return '${buffer.toString()}.${parts.last}';
    }

    return buffer.toString();
  }

  int _decimalsForCurrency(String currency) {
    if (currency == 'IDR' || currency == 'JPY' || currency == 'KRW') return 0;
    return 2;
  }

  String _convertPrice(double idrPrice, {String? currency}) {
    final targetCurrency = currency ?? selectedCurrency;

    if (targetCurrency == 'IDR') {
      return 'IDR ${_formatNumber(idrPrice)}';
    }

    final rate = exchangeRates[targetCurrency];
    if (rate == null) return '$targetCurrency -';

    final converted = idrPrice * rate;
    final decimals = _decimalsForCurrency(targetCurrency);

    return '$targetCurrency ${_formatNumber(converted, decimals: decimals)}';
  }

  bool _isInterestSaved(String name) {
    return savedInterests.any((item) => item['name'] == name);
  }

  Future<void> _saveSelectedInterest() async {
    final item = selectedInstrument;
    final name = item['name'] as String;
    final price = item['price'] as double;
    final description = item['description'] as String;
    final practice = item['practice'] as String;
    final category = item['category'] as String;
    final convertedPrice = _convertPrice(price);

    final savedItem = {
      'name': name,
      'category': category,
      'price': price,
      'converted_price': convertedPrice,
      'currency': selectedCurrency,
      'description': description,
      'practice': practice,
      'saved_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      savedInterests.removeWhere((oldItem) => oldItem['name'] == name);
      savedInterests.insert(0, savedItem);
    });

    await _persistSavedInterests();

    await PracticeProgressService.addPracticeSession(
      title: 'Minat alat musik: $name',
      type: 'Rencana Beli Alat',
      score: null,
      level: null,
      combo: null,
      passed: true,
      metadata: {
        'instrument_name': name,
        'category': category,
        'estimated_price_idr': price,
        'converted_price': convertedPrice,
        'currency': selectedCurrency,
        'description': description,
        'practice': practice,
        'rate_source': isUsingFallbackRates
            ? 'Mode estimasi cadangan'
            : 'Estimasi kurs global',
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name tersimpan di Minat Tersimpan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeInterest(String name) async {
    setState(() {
      savedInterests.removeWhere((item) => item['name'] == name);
    });

    await _persistSavedInterests();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name dihapus dari Minat Tersimpan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  BigInt _manualIdrAmount() {
    final onlyDigits = manualPriceController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (onlyDigits.isEmpty) return BigInt.zero;

    return BigInt.tryParse(onlyDigits) ?? BigInt.zero;
  }

  String _formatBigInt(BigInt value) {
    final raw = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final positionFromEnd = raw.length - i;
      buffer.write(raw[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  String _convertBigIntPrice(BigInt idrAmount, {String? currency}) {
    final targetCurrency = currency ?? selectedCurrency;

    if (targetCurrency == 'IDR') {
      return 'IDR ${_formatBigInt(idrAmount)}';
    }

    final rate = exchangeRates[targetCurrency];
    if (rate == null) return '$targetCurrency -';

    const scaleInt = 100000000;
    final scale = BigInt.from(scaleInt);
    final scaledRate = BigInt.from((rate * scaleInt).round());

    final convertedScaled = idrAmount * scaledRate;
    final whole = convertedScaled ~/ scale;
    final remainder = convertedScaled % scale;

    final decimals = _decimalsForCurrency(targetCurrency);
    if (decimals == 0) {
      return '$targetCurrency ${_formatBigInt(whole)}';
    }

    final decimalDivider = BigInt.from(10).pow(8 - decimals);
    final fraction = (remainder ~/ decimalDivider).toString().padLeft(
      decimals,
      '0',
    );

    return '$targetCurrency ${_formatBigInt(whole)}.$fraction';
  }

  Widget _buildManualConverterCard() {
    final amount = _manualIdrAmount();

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
            'Estimasi Biaya Custom',
            style: TextStyle(
              color: Color(0xFF20243A),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Masukkan perkiraan harga alat musik dalam rupiah, lalu lihat estimasi nilainya dalam mata uang pilihan.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: manualPriceController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Perkiraan harga IDR',
              hintText: 'Contoh: 1500000',
              prefixIcon: const Icon(Icons.payments_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Estimasi dalam mata uang pilihan: ${_convertBigIntPrice(amount)}',
              style: const TextStyle(
                color: Color(0xFF20243A),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUsingFallbackRates
            ? const Color(0xFFFFF4E8)
            : const Color(0xFFEFFAF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUsingFallbackRates
              ? const Color(0xFFFFD6A5)
              : const Color(0xFFCDEEDB),
        ),
      ),
      child: Row(
        children: [
          if (isLoadingRates)
            const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              isUsingFallbackRates
                  ? Icons.info_outline_rounded
                  : Icons.public_rounded,
              color: isUsingFallbackRates
                  ? const Color(0xFFB45309)
                  : const Color(0xFF00A86B),
              size: 22,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rateStatusText,
              style: TextStyle(
                color: isUsingFallbackRates
                    ? const Color(0xFF92400E)
                    : const Color(0xFF166534),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: isLoadingRates ? null : _loadExchangeRates,
            icon: const Icon(Icons.refresh_rounded),
            color: const Color(0xFF5E35B1),
            tooltip: 'Perbarui estimasi kurs',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    final currencies = ExchangeRateService.supportedCurrencies
        .where((currency) => exchangeRates.containsKey(currency))
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButton<String>(
        value: currencies.contains(selectedCurrency) ? selectedCurrency : 'IDR',
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(16),
        items: currencies
            .map(
              (currency) =>
                  DropdownMenuItem(value: currency, child: Text(currency)),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedCurrency = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildInstrumentSelector() {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: instruments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = instruments[index];
          final selected = index == selectedInstrumentIndex;
          final saved = _isInterestSaved(item['name'].toString());

          return InkWell(
            onTap: () {
              setState(() {
                selectedInstrumentIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 150,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF7C4DFF)
                    : const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF7C4DFF)
                      : const Color(0xFFEDEDF5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF7C4DFF),
                        size: 25,
                      ),
                      const Spacer(),
                      if (saved)
                        Icon(
                          Icons.bookmark_rounded,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF00A86B),
                          size: 20,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    item['name'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF20243A),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category'].toString(),
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.75)
                          : const Color(0xFF7C7E8A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedInstrumentDetail() {
    final item = selectedInstrument;
    final name = item['name'] as String;
    final price = item['price'] as double;
    final saved = _isInterestSaved(name);

    final previewCurrencies = ExchangeRateService.supportedCurrencies
        .where((currency) => exchangeRates.containsKey(currency))
        .toList();

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
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF20243A),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['category'].toString(),
                      style: const TextStyle(
                        color: Color(0xFF7C7E8A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item['description'].toString(),
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Estimasi utama: ${_convertPrice(price)}',
            style: const TextStyle(
              color: Color(0xFF00A86B),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Arah latihan: ${item['practice']}',
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Konversi semua mata uang',
            style: TextStyle(
              color: Color(0xFF20243A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: previewCurrencies.map((currency) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: currency == selectedCurrency
                      ? const Color(0xFF7C4DFF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE6E2FF)),
                ),
                child: Text(
                  _convertPrice(price, currency: currency),
                  style: TextStyle(
                    color: currency == selectedCurrency
                        ? Colors.white
                        : const Color(0xFF4B4E63),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: saved
                ? OutlinedButton.icon(
                    onPressed: () => _removeInterest(name),
                    icon: const Icon(Icons.bookmark_remove_rounded),
                    label: const Text('Hapus dari Minat Tersimpan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE85D75),
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _saveSelectedInterest,
                    icon: const Icon(Icons.bookmark_add_rounded),
                    label: const Text('Simpan ke Minat Tersimpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedInterestsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F7), Color(0xFFF3E8FF)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Minat Tersimpan',
            style: TextStyle(
              color: Color(0xFF20243A),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Alat yang kamu simpan akan tampil di sini dan tetap tercatat di History sebagai rencana pembelian.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (savedInterests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Belum ada alat tersimpan. Pilih salah satu alat, lalu tekan Simpan ke Minat Tersimpan.',
                style: TextStyle(
                  color: Color(0xFF7C7E8A),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...savedInterests.map((item) {
              final name = item['name']?.toString() ?? 'Alat musik';
              final convertedPrice =
                  item['converted_price']?.toString() ?? 'Estimasi tersedia';
              final practice = item['practice']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.bookmark_rounded,
                      color: Color(0xFF7C4DFF),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Color(0xFF20243A),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            convertedPrice,
                            style: const TextStyle(
                              color: Color(0xFF00A86B),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (practice.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              practice,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
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
                      onPressed: () => _removeInterest(name),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: const Color(0xFFE85D75),
                      tooltip: 'Hapus minat',
                    ),
                  ],
                ),
              );
            }),
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
          'Rencana Beli Alat Musik',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          children: [
            const Text(
              'Pilih alat musik yang kamu incar, bandingkan estimasi biayanya dalam banyak mata uang, lalu simpan ke daftar minat.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF7C7E8A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _buildCurrencyDropdown(),
            const SizedBox(height: 12),
            _buildRateStatusCard(),
            const SizedBox(height: 18),
            _buildManualConverterCard(),
            const SizedBox(height: 18),
            const Text(
              'Pilih Alat Musik',
              style: TextStyle(
                color: Color(0xFF20243A),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _buildInstrumentSelector(),
            const SizedBox(height: 18),
            _buildSelectedInstrumentDetail(),
            const SizedBox(height: 18),
            _buildSavedInterestsSection(),
          ],
        ),
      ),
    );
  }
}
