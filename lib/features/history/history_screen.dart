import 'package:flutter/material.dart';
import '../../services/practice_progress_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
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

  String _formatDate(String? rawDate) {
    if (rawDate == null) return 'Waktu belum tersedia';

    final date = DateTime.tryParse(rawDate);
    if (date == null) return 'Waktu belum tersedia';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  IconData _iconForType(String type) {
    final lower = type.toLowerCase();

    if (lower.contains('vokal') || lower.contains('voice')) {
      return Icons.mic_rounded;
    }

    if (lower.contains('gitar') || lower.contains('tuner')) {
      return Icons.music_note_rounded;
    }

    if (lower.contains('game')) {
      return Icons.sports_esports_rounded;
    }

    return Icons.history_rounded;
  }

  Widget _buildMetadataChip(IconData icon, String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      constraints: const BoxConstraints(maxWidth: 230),
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
          Flexible(
            child: Text(
              cleanText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4B4E63),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetadataChips(Map<String, dynamic> item) {
    final metadataRaw = item['metadata'];
    final metadata = metadataRaw is Map
        ? Map<String, dynamic>.from(metadataRaw)
        : <String, dynamic>{};

    final type = (item['type'] ?? '').toString().toLowerCase();

    if (type.contains('planner kelas')) {
      return [
        _buildMetadataChip(
          Icons.person_rounded,
          (metadata['coach'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.timer_rounded,
          (metadata['duration'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.flag_rounded,
          (metadata['focus'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.schedule_rounded,
          '${metadata['student_time'] ?? ''} WIB',
        ),
        _buildMetadataChip(
          Icons.public_rounded,
          '${metadata['teacher_time'] ?? ''} ${metadata['teacher_zone'] ?? ''}',
        ),
      ];
    }

    if (type.contains('rencana beli alat')) {
      return [
        _buildMetadataChip(
          Icons.music_note_rounded,
          (metadata['instrument_name'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.payments_rounded,
          (metadata['converted_price'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.cloud_done_rounded,
          (metadata['rate_source'] ?? '').toString(),
        ),
      ];
    }

    if (type.contains('smart practice scheduler')) {
      return [
        _buildMetadataChip(
          Icons.music_note_rounded,
          (metadata['practice_type'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.flag_rounded,
          (metadata['target'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.calendar_month_rounded,
          (metadata['day'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.schedule_rounded,
          '${metadata['local_time'] ?? ''} ${metadata['zone'] ?? ''}',
        ),
        _buildMetadataChip(
          Icons.public_rounded,
          (metadata['london_time'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.timer_rounded,
          (metadata['duration'] ?? '').toString(),
        ),
      ];
    }

    if (type.contains('game')) {
      return [
        _buildMetadataChip(
          Icons.videogame_asset_rounded,
          (metadata['game_name'] ?? 'Repeat Pitch').toString(),
        ),
        _buildMetadataChip(
          Icons.leaderboard_rounded,
          'Raw ${metadata['raw_score'] ?? '-'}',
        ),
        _buildMetadataChip(
          Icons.format_list_numbered_rounded,
          'Urutan ${metadata['sequence_length'] ?? '-'} nada',
        ),
        _buildMetadataChip(
          Icons.flag_rounded,
          (metadata['result'] ?? '').toString(),
        ),
      ];
    }

    if (type.contains('detect')) {
      return [
        _buildMetadataChip(
          Icons.graphic_eq_rounded,
          (metadata['mode'] ?? 'Detect').toString(),
        ),
        _buildMetadataChip(
          Icons.music_note_rounded,
          (metadata['detected_note'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.record_voice_over_rounded,
          (metadata['solfege'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.speed_rounded,
          (metadata['frequency'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.info_rounded,
          (metadata['status'] ?? '').toString(),
        ),
      ];
    }

    if (type.contains('music assistant')) {
      return [
        _buildMetadataChip(
          Icons.search_rounded,
          (metadata['query'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.library_music_rounded,
          '${metadata['result_count'] ?? 0} referensi',
        ),
        _buildMetadataChip(
          Icons.cloud_done_rounded,
          (metadata['source'] ?? '').toString(),
        ),
      ];
    }

    if (type.contains('preview lagu')) {
      return [
        _buildMetadataChip(
          Icons.play_circle_fill_rounded,
          (metadata['title'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.person_rounded,
          (metadata['artist'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.cloud_done_rounded,
          (metadata['source'] ?? '').toString(),
        ),
      ];
    }

    if (type.contains('referensi musik')) {
      return [
        _buildMetadataChip(
          Icons.person_rounded,
          (metadata['artist'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.category_rounded,
          (metadata['genre'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.public_rounded,
          (metadata['country'] ?? '').toString(),
        ),
        _buildMetadataChip(
          Icons.cloud_done_rounded,
          (metadata['source'] ?? '').toString(),
        ),
      ];
    }

    return [];
  }

  Future<void> _confirmDeleteHistoryItem(Map<String, dynamic> item) async {
    final createdAt = item['created_at']?.toString();
    final title = (item['title'] ?? 'Riwayat ini').toString();

    if (createdAt == null || createdAt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riwayat ini belum bisa dihapus.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Hapus Riwayat?'),
          content: Text('Riwayat "$title" akan dihapus dari daftar aktivitas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Hapus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D75),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await PracticeProgressService.deleteHistoryItem(createdAt);

    if (!mounted) return;

    setState(() {
      historyItems.removeWhere(
        (historyItem) => historyItem['created_at']?.toString() == createdAt,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Riwayat berhasil dihapus.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Aktivitas latihan').toString();
    final type = (item['type'] ?? 'Latihan').toString();
    final score = item['score'];
    final level = item['level'];
    final combo = item['combo'];
    final createdAt = item['created_at']?.toString();
    final metadataChips = _buildMetadataChips(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEDF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _iconForType(type),
              color: const Color(0xFF7C4DFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF20243A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C7E8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A9AA5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (score is int || level is int || combo is int) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    children: [
                      if (score is int)
                        _buildMetadataChip(Icons.star_rounded, 'Skor $score%'),
                      if (level is int)
                        _buildMetadataChip(
                          Icons.trending_up_rounded,
                          'Level $level',
                        ),
                      if (combo is int)
                        _buildMetadataChip(
                          Icons.local_fire_department_rounded,
                          'Combo $combo',
                        ),
                    ],
                  ),
                ],
                if (metadataChips.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(children: metadataChips),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _confirmDeleteHistoryItem(item),
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFFE85D75),
            tooltip: 'Hapus riwayat ini',
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
          'Riwayat Aktivitas',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
            children: [
              const Text(
                'Catatan latihan, game, dan aktivitas musik yang tersimpan akan muncul di sini.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF7C7E8A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (historyItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FB),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEDEDF5)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: Color(0xFF7C4DFF),
                        size: 34,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat latihan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF20243A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mulai latihan dari menu Detect atau mainkan game musik. Setelah aktivitas tersimpan, riwayatnya akan tampil di sini.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...historyItems.map(_buildHistoryCard),
            ],
          ),
        ),
      ),
    );
  }
}
