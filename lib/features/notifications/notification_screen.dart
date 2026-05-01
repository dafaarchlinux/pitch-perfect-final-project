import 'package:flutter/material.dart';

import '../../services/practice_progress_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color _bg = Color(0xFF0B0D22);
  static const Color _surface = Color(0xFF17182C);
  static const Color _surfaceSoft = Color(0xFF232542);
  static const Color _border = Color(0xFF2D3050);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _pink = Color(0xFFF472B6);
  static const Color _green = Color(0xFF34D399);
  static const Color _orange = Color(0xFFF59E0B);

  bool isLoading = true;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);

    try {
      final history = await PracticeProgressService.getHistory();
      final items = <Map<String, dynamic>>[];

      for (final item in history) {
        final mapped = _mapHistoryToNotification(item);
        if (mapped != null) items.add(mapped);
      }

      items.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;
      setState(() {
        notifications = items;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        notifications = [];
        isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _mapHistoryToNotification(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? '';
    final title = item['title']?.toString() ?? 'Notifikasi';
    final createdAt = item['created_at']?.toString() ??
        item['createdAt']?.toString() ??
        item['date']?.toString() ??
        DateTime.now().toIso8601String();

    final rawMetadata = item['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};

    final notificationTitle = metadata['notification_title']?.toString();
    final notificationBody = metadata['notification_body']?.toString();
    final source = metadata['source']?.toString() ?? '';

    final lowerType = type.toLowerCase();
    final lowerTitle = title.toLowerCase();
    final isNotificationFromCenter = notificationTitle != null ||
        notificationBody != null ||
        source.toLowerCase().contains('notification');
    final isScheduleNotification = lowerType.contains('scheduler') ||
        lowerTitle.contains('jadwal latihan') ||
        lowerTitle.contains('reminder');
    final isNotificationType = lowerType.contains('notifikasi') ||
        lowerType.contains('notification');

    if (!isNotificationFromCenter && !isScheduleNotification && !isNotificationType) {
      return null;
    }

    return {
      'title': notificationTitle ?? title,
      'body': notificationBody ?? _fallbackBody(item, metadata),
      'type': type.isEmpty ? 'Notifikasi Aplikasi' : type,
      'created_at': createdAt,
      'source': source.isEmpty ? 'Pitch Perfect' : source,
      'color': _notificationColor(type, title),
    };
  }

  String _fallbackBody(Map<String, dynamic> item, Map<String, dynamic> metadata) {
    final body = metadata['body']?.toString();
    if (body != null && body.trim().isNotEmpty) return body;

    final target = metadata['target']?.toString();
    final practice = metadata['practice']?.toString();
    final date = metadata['date']?.toString();
    final time = metadata['time']?.toString();
    final timezone = metadata['timezone']?.toString();

    if (practice != null || target != null || date != null || time != null) {
      final practiceText = practice == null ? 'Latihan musik' : practice;
      final targetText = target == null ? '' : ' • Target: $target';
      final timeText = time == null ? '' : ' • $time ${timezone ?? ''}'.trimRight();
      final dateText = date == null ? '' : ' • $date';
      return '$practiceText$targetText$timeText$dateText';
    }

    return 'Notifikasi dari aplikasi Pitch Perfect.';
  }

  Color _notificationColor(String type, String title) {
    final text = '${type.toLowerCase()} ${title.toLowerCase()}';

    if (text.contains('jadwal') || text.contains('scheduler') || text.contains('reminder')) {
      return _cyan;
    }
    if (text.contains('target')) return _orange;
    if (text.contains('latihan') || text.contains('practice')) return _purple;
    if (text.contains('game')) return _pink;
    return _green;
  }

  String _formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate);
    if (date == null) return 'Waktu tidak diketahui';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} • $hour:$minute';
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: _purple,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${notifications.length} Notifikasi',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Daftar notifikasi yang sudah pernah dikirim oleh aplikasi.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
            color: _cyan,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(Map<String, dynamic> item) {
    final color = item['color'] is Color ? item['color'] as Color : _purple;
    final title = item['title']?.toString() ?? 'Notifikasi';
    final body = item['body']?.toString() ?? 'Notifikasi dari Pitch Perfect.';
    final type = item['type']?.toString() ?? 'Notifikasi Aplikasi';
    final createdAt = item['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    color: Color(0xFF6F7EA7),
                    fontSize: 11,
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

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: const [
          Icon(Icons.notifications_none_rounded, color: _muted, size: 42),
          SizedBox(height: 12),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              color: _text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Notifikasi yang dikirim oleh aplikasi akan muncul di halaman ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: _muted,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
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
        iconTheme: const IconThemeData(color: _text),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: _text,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          color: _purple,
          backgroundColor: _surface,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              if (isLoading)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: const Center(
                    child: CircularProgressIndicator(color: _purple),
                  ),
                )
              else ...[
                _sectionTitle('Riwayat Notifikasi'),
                const SizedBox(height: 14),
                if (notifications.isEmpty)
                  _emptyState()
                else
                  ...notifications.map(_notificationTile),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
