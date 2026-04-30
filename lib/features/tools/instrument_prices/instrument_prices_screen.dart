import 'package:flutter/material.dart';
import '../../../services/exchange_rate_service.dart';
import '../../../services/practice_progress_service.dart';

class InstrumentPricesScreen extends StatefulWidget {
  const InstrumentPricesScreen({super.key});

  @override
  State<InstrumentPricesScreen> createState() => _InstrumentPricesScreenState();
}

class _InstrumentPricesScreenState extends State<InstrumentPricesScreen> {
  static const Color _bg = Color(0xFF0B0D22);
  static const Color _surface = Color(0xFF17182C);
  static const Color _surfaceSoft = Color(0xFF232542);
  static const Color _border = Color(0xFF2D3050);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFFB8BCD7);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _pink = Color(0xFFF472B6);
  static const Color _green = Color(0xFF34D399);

  String selectedCurrency = 'USD';
  bool isLoadingRates = true;
  bool isUsingFallbackRates = false;
  String rateStatusText = 'Menyiapkan estimasi biaya...';

  int selectedInstrumentIndex = 0;
  List<Map<String, dynamic>> savedInterests = [];

  final TextEditingController manualPriceController = TextEditingController(
    text: '1.500.000',
  );

  bool isFormattingManualPrice = false;

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
      'description': 'Instrumen low-end untuk groove dan rhythm section.',
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
      'description': 'Praktis untuk belajar iringan dan aransemen sederhana.',
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
      'description': 'Ringan, mudah dibawa, dan cocok untuk pengiring lagu.',
      'practice': 'Latihan chord sederhana, strumming ringan, dan tempo.',
    },
    {
      'name': 'Drum Elektrik',
      'category': 'Drum',
      'price': 4500000.0,
      'icon': Icons.adjust_rounded,
      'description': 'Alternatif drum hemat ruang untuk latihan rhythm.',
      'practice': 'Latihan beat dasar, fill-in, tempo, dan koordinasi.',
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
      'description': 'Perangkat penting untuk rekaman vokal atau instrumen.',
      'practice': 'Latihan rekaman take vokal/gitar dan evaluasi hasil.',
    },
    {
      'name': 'Headphone Monitoring',
      'category': 'Audio',
      'price': 850000.0,
      'icon': Icons.headphones_rounded,
      'description': 'Membantu latihan rekaman, editing, dan fokus nada.',
      'practice': 'Latihan ear training, preview musik, dan monitoring vokal.',
    },
    {
      'name': 'Kalimba',
      'category': 'Melodi',
      'price': 250000.0,
      'icon': Icons.auto_awesome_rounded,
      'description': 'Instrumen kecil dengan suara lembut untuk melodi ringan.',
      'practice': 'Latihan melodi sederhana dan pendengaran interval.',
    },
  ];

  Map<String, dynamic> get selectedInstrument =>
      instruments[selectedInstrumentIndex];

  @override
  void initState() {
    super.initState();
    _loadExchangeRates();
    _loadSavedInterests();

    manualPriceController.addListener(_formatManualPriceInput);
  }

  void _formatManualPriceInput() {
    if (isFormattingManualPrice) return;

    final digits = manualPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');

    final formatted = digits.isEmpty
        ? ''
        : _formatWithSeparators(digits, separator: '.');

    if (manualPriceController.text == formatted) {
      if (mounted) setState(() {});
      return;
    }

    isFormattingManualPrice = true;

    manualPriceController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    isFormattingManualPrice = false;

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    manualPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadExchangeRates() async {
    setState(() {
      isLoadingRates = true;
      rateStatusText = 'Menyiapkan estimasi biaya...';
    });

    try {
      final latestRates = await ExchangeRateService.getIdrRates();

      if (!mounted) return;

      setState(() {
        exchangeRates = latestRates;
        selectedCurrency = exchangeRates.containsKey(selectedCurrency)
            ? selectedCurrency
            : 'USD';
        isLoadingRates = false;
        isUsingFallbackRates = false;
        rateStatusText = 'Kurs berhasil diperbarui.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingRates = false;
        isUsingFallbackRates = true;
        rateStatusText =
            'Kurs cadangan digunakan agar konversi tetap berjalan.';
      });
    }
  }

  Future<void> _loadSavedInterests() async {
    final interests = await PracticeProgressService.getInstrumentInterests();

    if (!mounted) return;

    setState(() {
      savedInterests = interests;
    });
  }

  Future<void> _persistSavedInterests() async {
    await PracticeProgressService.saveInstrumentInterests(savedInterests);
  }

  void _useSelectedInstrumentPrice() {
    final price = selectedInstrument['price'] as double;
    final digits = price.round().toString();

    manualPriceController.text = _formatWithSeparators(digits, separator: '.');
  }

  BigInt _manualIdrAmount() {
    final onlyDigits = manualPriceController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (onlyDigits.isEmpty) return BigInt.zero;
    return BigInt.tryParse(onlyDigits) ?? BigInt.zero;
  }

  int _decimalsForCurrency(String currency) {
    if (currency == 'IDR' || currency == 'JPY' || currency == 'KRW') return 0;
    return 2;
  }

  String _formatWithSeparators(
    String integerPart, {
    required String separator,
  }) {
    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      final positionFromEnd = integerPart.length - i;
      buffer.write(integerPart[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(separator);
      }
    }

    return buffer.toString();
  }

  String _formatMoneyValue(
    double value,
    String currency, {
    bool withCode = true,
  }) {
    final decimals = _decimalsForCurrency(currency);
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final integerPart = parts.first;
    final decimalPart = parts.length > 1 ? parts.last : '';

    final useIndonesianSeparator =
        currency == 'IDR' || currency == 'JPY' || currency == 'KRW';

    final thousandsSeparator = useIndonesianSeparator ? '.' : ',';
    final decimalSeparator = useIndonesianSeparator ? ',' : '.';

    final formattedInteger = _formatWithSeparators(
      integerPart,
      separator: thousandsSeparator,
    );

    final formatted = decimals == 0
        ? formattedInteger
        : '$formattedInteger$decimalSeparator$decimalPart';

    return withCode ? '$currency $formatted' : formatted;
  }

  String _formatBigIntIdr(BigInt value) {
    return 'IDR ${_formatWithSeparators(value.toString(), separator: '.')}';
  }

  String _convertManualAmount(String currency) {
    final amount = _manualIdrAmount();

    if (currency == 'IDR') {
      return _formatBigIntIdr(amount);
    }

    final rate = exchangeRates[currency];
    if (rate == null) return '$currency -';

    final converted = amount.toDouble() * rate;
    return _formatMoneyValue(converted, currency);
  }

  bool _isInterestSaved(String name) {
    return savedInterests.any((item) => item['name'] == name);
  }

  Future<void> _saveSelectedInterest() async {
    final item = selectedInstrument;
    final name = item['name'] as String;
    final category = item['category'] as String;
    final description = item['description'] as String;
    final practice = item['practice'] as String;
    final price = _manualIdrAmount();

    if (price <= BigInt.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan estimasi biaya terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final convertedPrice = _convertManualAmount(selectedCurrency);

    final savedItem = {
      'name': name,
      'category': category,
      'price': price.toString(),
      'converted_price': convertedPrice,
      'currency': selectedCurrency,
      'description': description,
      'practice': practice,
      'saved_at': DateTime.now().toIso8601String(),
      'storage': 'Hive',
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
        'estimated_price_idr': price.toString(),
        'converted_price': convertedPrice,
        'currency': selectedCurrency,
        'description': description,
        'practice': practice,
        'rate_source': isUsingFallbackRates ? 'Kurs cadangan' : 'Kurs online',
        'storage': 'Hive',
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name tersimpan.'),
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
        content: Text('$name dihapus.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _darkCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRateStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUsingFallbackRates
            ? const Color(0xFF2A1F16)
            : const Color(0xFF12251F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUsingFallbackRates
              ? const Color(0xFF5B3A16)
              : const Color(0xFF245C46),
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
              color: isUsingFallbackRates ? const Color(0xFFFBBF24) : _green,
              size: 22,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rateStatusText,
              style: TextStyle(
                color: isUsingFallbackRates
                    ? const Color(0xFFFFE7A8)
                    : const Color(0xFFC4F1E2),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: isLoadingRates ? null : _loadExchangeRates,
            icon: const Icon(Icons.refresh_rounded),
            color: _cyan,
            tooltip: 'Perbarui kurs',
          ),
        ],
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
              _useSelectedInstrumentPrice();
            },
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 154,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [_purple, _cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : _surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: selected ? _cyan : _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: Colors.white,
                        size: 25,
                      ),
                      const Spacer(),
                      if (saved)
                        const Icon(
                          Icons.bookmark_rounded,
                          color: _green,
                          size: 20,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    item['name'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category'].toString(),
                    style: const TextStyle(
                      color: _muted,
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

    return _darkCard(
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
                    colors: [_purple, _cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                        color: _text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['category'].toString(),
                      style: const TextStyle(
                        color: _muted,
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
              color: _muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Harga rekomendasi: ${_formatMoneyValue(price, 'IDR')}',
            style: const TextStyle(
              color: _green,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Text(
              'Arah latihan: ${item['practice']}',
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualConverterCard() {
    final amount = _manualIdrAmount();

    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimasi Biaya',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Masukkan nominal dalam IDR. Hasil konversi langsung muncul di bawah.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: manualPriceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              labelText: 'Nominal IDR',
              hintText: 'Contoh: 1500000',
              prefixIcon: const Icon(Icons.payments_rounded),
              suffixIcon: IconButton(
                onPressed: _useSelectedInstrumentPrice,
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'Pakai harga rekomendasi',
              ),
              filled: true,
              fillColor: _surfaceSoft,
              labelStyle: const TextStyle(color: _muted),
              hintStyle: const TextStyle(color: Color(0xFF7E84A8)),
              prefixIconColor: _cyan,
              suffixIconColor: _cyan,
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
              color: _surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Text(
              'Dasar konversi: ${_formatBigIntIdr(amount)}',
              style: const TextStyle(
                color: _green,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
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
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: DropdownButton<String>(
        value: currencies.contains(selectedCurrency) ? selectedCurrency : 'USD',
        isExpanded: true,
        dropdownColor: _surfaceSoft,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(16),
        iconEnabledColor: _cyan,
        style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
        items: currencies
            .where((currency) => currency != 'IDR')
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

  Widget _buildConversionResultCard() {
    final amount = _manualIdrAmount();
    final currencies = ExchangeRateService.supportedCurrencies
        .where((currency) => exchangeRates.containsKey(currency))
        .where((currency) => currency != 'IDR')
        .take(12)
        .toList();

    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Konversi',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            amount == BigInt.zero
                ? 'Isi nominal IDR untuk melihat hasil konversi.'
                : '${_formatBigIntIdr(amount)} dikonversi ke beberapa mata uang.',
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Konversi utama',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 126, child: _buildCurrencyDropdown()),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_purple, _cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'IDR → $selectedCurrency  •  ${_convertManualAmount(selectedCurrency)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...currencies.map((currency) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: currency == selectedCurrency ? _cyan : _border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: currency == selectedCurrency
                          ? _cyan.withValues(alpha: 0.18)
                          : _bg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'IDR → $currency',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: currency == selectedCurrency ? _cyan : _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _convertManualAmount(currency),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSavedInterestsSection() {
    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Minat Tersimpan',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Alat musik yang kamu simpan akan tersimpan di database lokal Hive.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (savedInterests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: const Text(
                'Belum ada alat tersimpan.',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
              ),
            )
          else
            ...savedInterests.map((item) {
              final name = item['name']?.toString() ?? 'Alat musik';
              final converted = item['converted_price']?.toString() ?? '-';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surfaceSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_rounded, color: _green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            converted,
                            style: const TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeInterest(name),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: _pink,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
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
        title: const Text(
          'Rencana Alat Musik',
          style: TextStyle(color: _text, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: _text),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            const Text(
              'Pilih alat, isi estimasi biaya, lalu lihat konversi dengan format angka yang mudah dibaca.',
              style: TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _buildRateStatusCard(),
            const SizedBox(height: 18),
            _buildInstrumentSelector(),
            const SizedBox(height: 18),
            _buildSelectedInstrumentDetail(),
            const SizedBox(height: 18),
            _buildManualConverterCard(),
            const SizedBox(height: 18),
            _buildConversionResultCard(),
            const SizedBox(height: 18),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveSelectedInterest,
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('Simpan ke Minat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildSavedInterestsSection(),
          ],
        ),
      ),
    );
  }
}
