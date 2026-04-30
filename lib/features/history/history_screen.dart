import 'package:flutter/material.dart';

import '../../services/practice_progress_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color _bg = Color(0xFF0B0D22);
  static const Color _surface = Color(0xFF17182C);
  static const Color _surfaceSoft = Color(0xFF232542);
  static const Color _border = Color(0xFF2D3050);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFFB8BCD7);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _pink = Color(0xFFF472B6);

  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  bool hasHandledRouteArguments = false;
  String searchQuery = '';
  List<Map<String, dynamic>> historyItems = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (hasHandledRouteArguments) return;
    hasHandledRouteArguments = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      final query = args['query']?.toString().trim() ?? '';

      if (query.isNotEmpty) {
        searchController.text = query;
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
    });

    final data = await PracticeProgressService.getHistory();

    if (!mounted) return;

    setState(() {
      historyItems = data;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredHistoryItems {
    if (searchQuery.isEmpty) return historyItems;

    return historyItems.where((item) {
      final metadata = item['metadata'] is Map
          ? Map<String, dynamic>.from(item['metadata'])
          : <String, dynamic>{};

      final searchableText = [
        item['title'],
        item['type'],
        item['score'],
        item['level'],
        item['combo'],
        item['created_at'],
        ...metadata.values,
      ].where((value) => value != null).join(' ').toLowerCase();

      return searchableText.contains(searchQuery);
    }).toList();
  }

  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: _text, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          icon: const Icon(Icons.search_rounded, color: _cyan),
          hintText: 'Cari riwayat latihan, lagu, game, atau saran...',
          hintStyle: const TextStyle(
            color: Color(0xFF7E84A8),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () => searchController.clear(),
                  icon: const Icon(Icons.close_rounded),
                  color: _muted,
                ),
        ),
      ),
    );
  }

  String _formatDate(String? rawDate) {
    final date = DateTime.tryParse(rawDate ?? '');
    if (date == null) return 'Waktu belum tersedia';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _iconForType(String type) {
    final lower = type.toLowerCase();

    if (lower.contains('saran')) {
      return Icons.rate_review_rounded;
    }

    if (lower.contains('detect') || lower.contains('vokal')) {
      return Icons.mic_rounded;
    }

    if (lower.contains('game')) {
      return Icons.sports_esports_rounded;
    }

    if (lower.contains('rencana')) {
      return Icons.piano_rounded;
    }

    if (lower.contains('scheduler') || lower.contains('jadwal')) {
      return Icons.calendar_month_rounded;
    }

    if (lower.contains('referensi')) {
      return Icons.library_music_rounded;
    }

    if (lower.contains('assistant') || lower.contains('coach')) {
      return Icons.psychology_rounded;
    }

    return Icons.history_rounded;
  }

  Widget _chip(IconData icon, String text) {
    final clean = text.trim();
    if (clean.isEmpty || clean == '-') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8, top: 8),
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _cyan),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              clean,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _metadataChips(Map<String, dynamic> item) {
    final metadata = item['metadata'] is Map
        ? Map<String, dynamic>.from(item['metadata'])
        : <String, dynamic>{};

    return [
      _chip(
        Icons.music_note_rounded,
        (metadata['detected_note'] ??
                metadata['title'] ??
                metadata['instrument_name'] ??
                '')
            .toString(),
      ),
      _chip(
        Icons.person_rounded,
        (metadata['artist'] ?? metadata['coach'] ?? '').toString(),
      ),
      _chip(Icons.speed_rounded, (metadata['frequency'] ?? '').toString()),
      _chip(Icons.insights_rounded, (metadata['accuracy'] ?? '').toString()),
      _chip(
        Icons.info_rounded,
        (metadata['status'] ?? metadata['source'] ?? '').toString(),
      ),
    ];
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final createdAt = item['created_at']?.toString();
    if (createdAt == null || createdAt.isEmpty) return;

    await PracticeProgressService.deleteHistoryItem(createdAt);
    await _loadHistory();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Hapus Semua Riwayat?',
            style: TextStyle(color: _text),
          ),
          content: const Text(
            'Semua riwayat akun ini akan dihapus.',
            style: TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _pink),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await PracticeProgressService.clearHistory();
    await _loadHistory();
  }

  Widget _historyCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'Aktivitas';
    final type = item['type']?.toString() ?? 'Riwayat';
    final score = item['score'];
    final level = item['level'];
    final combo = item['combo'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(_iconForType(type), color: _cyan),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$type • ${_formatDate(item['created_at']?.toString())}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  children: [
                    if (score is int) _chip(Icons.star_rounded, 'Skor $score%'),
                    if (level is int)
                      _chip(Icons.trending_up_rounded, 'Level $level'),
                    if (combo is int)
                      _chip(
                        Icons.local_fire_department_rounded,
                        'Combo $combo',
                      ),
                    ..._metadataChips(item),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteItem(item),
            icon: const Icon(Icons.delete_outline_rounded),
            color: _pink,
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_rounded, color: _cyan, size: 34),
          SizedBox(height: 12),
          Text(
            'Belum ada riwayat',
            style: TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Aktivitas akun ini akan muncul di sini setelah kamu latihan, menyimpan referensi, atau mengisi saran dan kesan.',
            style: TextStyle(
              color: _muted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        foregroundColor: _text,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Riwayat',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (historyItems.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_rounded),
              color: _pink,
              tooltip: 'Hapus semua',
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
            children: [
              const Text(
                'Riwayat aktivitas akun aktif.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _searchBox(),
              const SizedBox(height: 18),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: _purple),
                  ),
                )
              else if (historyItems.isEmpty)
                _emptyState()
              else if (filteredHistoryItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _border),
                  ),
                  child: const Text(
                    'Tidak ada riwayat yang cocok dengan pencarian.',
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ...filteredHistoryItems.map(_historyCard),
            ],
          ),
        ),
      ),
    );
  }
}
