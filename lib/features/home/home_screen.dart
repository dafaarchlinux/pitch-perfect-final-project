import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/session_service.dart';
import '../../services/practice_progress_service.dart';
import '../../services/audio_db_service.dart';
import '../../services/location_service.dart';
import '../../services/nearby_music_store_service.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'Pengguna';
  int totalSessions = 0;
  int weeklySessions = 0;
  int? averageScore;
  List<Map<String, dynamic>> historyItems = [];
  Map<String, dynamic>? musicDiscoveryArtist;
  bool isLoadingDiscovery = true;

  String dashboardLocationText = 'Mendeteksi lokasi musik terdekat...';
  bool isLoadingNearbyPlaces = true;
  List<Map<String, dynamic>> nearbyMusicPlaces = [];

  List<Map<String, dynamic>> savedInstrumentPlans = [];
  List<Map<String, dynamic>> savedPracticeSchedules = [];

  bool isLoading = true;

  static const Color _bgColor = Color(0xFFFCFCFE);

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<Map<String, dynamic>?> _loadMusicDiscoveryArtist() async {
    final artists = [
      'Coldplay',
      'Taylor Swift',
      'Adele',
      'Bruno Mars',
      'Ed Sheeran',
      'Maroon 5',
      'Ariana Grande',
      'Imagine Dragons',
      'Linkin Park',
      'Queen',
    ];

    final index = DateTime.now().day % artists.length;

    try {
      return await AudioDbService.searchArtist(artists[index]);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadDashboardLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final rawInstruments = prefs.getString('saved_instrument_interests');
    final rawSchedules = prefs.getString('smart_practice_schedules');

    final instruments = <Map<String, dynamic>>[];
    final schedules = <Map<String, dynamic>>[];

    try {
      final decoded = rawInstruments == null
          ? null
          : jsonDecode(rawInstruments);
      if (decoded is List) {
        instruments.addAll(
          decoded.whereType<Map>().map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
      }
    } catch (_) {}

    try {
      final decoded = rawSchedules == null ? null : jsonDecode(rawSchedules);
      if (decoded is List) {
        schedules.addAll(
          decoded.whereType<Map>().map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
      }
    } catch (_) {}

    schedules.sort((a, b) {
      DateTime parseSchedule(Map<String, dynamic> item) {
        final now = DateTime.now();
        final year = item['year'] is int ? item['year'] as int : now.year;
        final month = item['month'] is int ? item['month'] as int : now.month;
        final date = item['date'] is int ? item['date'] as int : now.day;
        final hour = item['hour'] is int ? item['hour'] as int : 0;
        final minute = item['minute'] is int ? item['minute'] as int : 0;
        return DateTime(year, month, date, hour, minute);
      }

      return parseSchedule(a).compareTo(parseSchedule(b));
    });

    if (!mounted) return;

    setState(() {
      savedInstrumentPlans = instruments;
      savedPracticeSchedules = schedules;
    });
  }

  Future<void> _loadNearbyMusicDashboard() async {
    setState(() {
      isLoadingNearbyPlaces = true;
    });

    final locationResult = await LocationService.getCurrentLocation();

    if (!mounted) return;

    if (locationResult['success'] != true) {
      setState(() {
        dashboardLocationText =
            locationResult['message'] ?? 'Lokasi belum berhasil dibaca.';
        nearbyMusicPlaces = [];
        isLoadingNearbyPlaces = false;
      });
      return;
    }

    final latitude = locationResult['latitude'];
    final longitude = locationResult['longitude'];
    final locationName =
        locationResult['location_name']?.toString() ?? 'Lokasi kamu';

    setState(() {
      dashboardLocationText = locationName;
    });

    if (latitude is! double || longitude is! double) {
      setState(() {
        isLoadingNearbyPlaces = false;
      });
      return;
    }

    final nearbyResult = await NearbyMusicStoreService.getNearbyStores(
      latitude: latitude,
      longitude: longitude,
    );

    if (!mounted) return;

    if (nearbyResult['success'] == true) {
      final stores = List<Map<String, dynamic>>.from(
        nearbyResult['stores'] ?? [],
      );

      setState(() {
        nearbyMusicPlaces = stores.take(3).toList();
        isLoadingNearbyPlaces = false;
      });
    } else {
      setState(() {
        nearbyMusicPlaces = [];
        isLoadingNearbyPlaces = false;
      });
    }
  }

  Future<void> _loadHomeData() async {
    final name = await SessionService.getUserName();
    final summary = await PracticeProgressService.getSummary();
    final history = await PracticeProgressService.getHistory();
    final discoveryArtist = await _loadMusicDiscoveryArtist();

    await _loadDashboardLocalData();
    _loadNearbyMusicDashboard();

    if (!mounted) return;

    setState(() {
      userName = name.trim().isEmpty ? 'Pengguna' : name;
      totalSessions = summary['total_sessions'] ?? 0;
      weeklySessions = summary['weekly_sessions'] ?? 0;
      averageScore = summary['average_score'];
      historyItems = history;
      musicDiscoveryArtist = discoveryArtist;
      isLoadingDiscovery = false;
      isLoading = false;
    });
  }

  void _goToTab(int index) {
    widget.onNavigate?.call(index);
  }

  Widget _buildHeroCard() {
    final hasProgress = totalSessions > 0;
    final title = hasProgress
        ? 'Lanjutkan progres musikmu'
        : 'Mulai cek nada pertamamu';
    final subtitle = hasProgress
        ? 'Gunakan Detect untuk mengecek nada gitar atau suara, lalu lanjutkan latihan di Games.'
        : 'Mulai dari Detect untuk cek nada gitar/suara, lalu gunakan Tools untuk kebutuhan pendukung musik.';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E35B1).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PITCH PERFECT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _goToTab(1),
                  icon: const Icon(Icons.graphic_eq_rounded),
                  label: const Text('Buka Detect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5E35B1),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goToTab(3),
                  icon: const Icon(Icons.videogame_asset_rounded),
                  label: const Text('Latihan Game'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final weeklyTarget = 5;
    final progressValue = (weeklySessions / weeklyTarget).clamp(0.0, 1.0);
    final accuracyText = averageScore == null ? '-' : '$averageScore%';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8F1),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD3F0E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'RINGKASAN PROGRES',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.9,
                    color: Color(0xFF3FA37B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.insights_rounded,
                  size: 34,
                  color: Color(0xFF21C67A),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildProgressMini(
                title: 'Total Aktivitas',
                value: '$totalSessions',
                subtitle: 'tersimpan',
              ),
              const SizedBox(width: 12),
              _buildProgressMini(
                title: 'Akurasi Rata-rata',
                value: accuracyText,
                subtitle: averageScore == null
                    ? 'belum ada nilai'
                    : 'dari latihan',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            totalSessions == 0
                ? 'Belum ada aktivitas. Mulai dari Detect atau Games agar progres muncul di sini.'
                : '$weeklySessions/$weeklyTarget aktivitas minggu ini. Jaga konsistensi latihanmu.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B6B5C),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 9,
              backgroundColor: Colors.white,
              color: const Color(0xFF21C67A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMini({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B4332),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF3F6B57),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B8A7A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7FB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEDEDF5)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF20243A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFB1B3BE),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatActivityTime(String? rawDate) {
    if (rawDate == null) return 'Baru saja';

    final date = DateTime.tryParse(rawDate);
    if (date == null) return 'Baru saja';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes} menit lalu';
    if (difference.inDays < 1) return '${difference.inHours} jam lalu';
    return '${difference.inDays} hari lalu';
  }

  Map<String, dynamic> _recommendationFromLastActivity() {
    if (historyItems.isEmpty) {
      return {
        'title': 'Mulai bangun progres musik',
        'subtitle':
            'Coba Detect untuk cek nada atau Games untuk latihan pendengaran nada.',
        'button': 'Mulai Detect',
        'icon': Icons.graphic_eq_rounded,
        'color': const Color(0xFF7C4DFF),
        'action': () => _goToTab(1),
      };
    }

    final last = historyItems.first;
    final type = (last['type'] ?? '').toString().toLowerCase();
    final metadataRaw = last['metadata'];
    final metadata = metadataRaw is Map
        ? Map<String, dynamic>.from(metadataRaw)
        : <String, dynamic>{};

    if (type.contains('rencana beli alat')) {
      final instrument = (metadata['instrument_name'] ?? 'alat musik')
          .toString();

      return {
        'title': 'Latihan sesuai minat alatmu',
        'subtitle':
            'Kamu menyimpan minat $instrument. Lanjutkan dengan Detect, Games, atau kelas privat yang sesuai.',
        'button': 'Buka Tools',
        'icon': Icons.piano_rounded,
        'color': const Color(0xFF0072FF),
        'action': () => _goToTab(2),
      };
    }

    if (type.contains('smart practice scheduler')) {
      final practice = (metadata['practice_type'] ?? 'musik').toString();
      final time = '${metadata['local_time'] ?? ''} ${metadata['zone'] ?? ''}'
          .trim();

      return {
        'title': 'Jadwal latihan sudah dibuat',
        'subtitle':
            'Latihan $practice kamu tersimpan untuk $time. Reminder Android akan membantu mengingatkan.',
        'button': 'Lihat History',
        'icon': Icons.notifications_active_rounded,
        'color': const Color(0xFF00A86B),
        'action': () => _goToTab(4),
      };
    }

    if (type.contains('planner kelas')) {
      final coach = (metadata['coach'] ?? 'coach pilihan').toString();
      final focus = (metadata['focus'] ?? 'fokus latihan').toString();

      return {
        'title': 'Rencana kelas privat siap',
        'subtitle': 'Kamu punya rencana dengan $coach. Fokus latihan: $focus.',
        'button': 'Buka Profile',
        'icon': Icons.school_rounded,
        'color': const Color(0xFFFF8A65),
        'action': () => _goToTab(4),
      };
    }

    if (type.contains('game')) {
      return {
        'title': 'Pertahankan skor latihan',
        'subtitle':
            'Lanjutkan Repeat Pitch untuk meningkatkan level, combo, dan akurasi nada.',
        'button': 'Buka Games',
        'icon': Icons.videogame_asset_rounded,
        'color': const Color(0xFFFF8A65),
        'action': () => _goToTab(3),
      };
    }

    if (type.contains('notifikasi')) {
      return {
        'title': 'Pengingat latihan aktif',
        'subtitle':
            'Gunakan scheduler agar reminder latihan muncul otomatis di Android.',
        'button': 'Atur Jadwal',
        'icon': Icons.schedule_rounded,
        'color': const Color(0xFF00A86B),
        'action': () => _goToTab(2),
      };
    }

    return {
      'title': 'Lanjutkan ekosistem latihan',
      'subtitle':
          'Aktivitas terakhir sudah tersimpan. Pilih latihan berikutnya agar progres makin lengkap.',
      'button': 'Buka Tools',
      'icon': Icons.auto_awesome_rounded,
      'color': const Color(0xFF7C4DFF),
      'action': () => _goToTab(2),
    };
  }

  Widget _buildSmartRecommendationCard() {
    final recommendation = _recommendationFromLastActivity();
    final color = recommendation['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              recommendation['icon'] as IconData,
              color: color,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'].toString(),
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF20243A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  recommendation['subtitle'].toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: recommendation['action'] as VoidCallback,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(recommendation['button'].toString()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastActivityCard() {
    if (historyItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FB),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFEDEDF5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFF7C4DFF), size: 30),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'Belum ada aktivitas terakhir. Setelah kamu memakai Detect, Games, Tools, atau Scheduler, ringkasannya muncul di sini.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final last = historyItems.first;
    final title = (last['title'] ?? 'Aktivitas Pitch Perfect').toString();
    final type = (last['type'] ?? 'Aktivitas').toString();
    final createdAt = last['created_at']?.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(26),
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
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF7C4DFF),
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AKTIVITAS TERAKHIR',
                  style: TextStyle(
                    color: Color(0xFF7C4DFF),
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF20243A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$type • ${_formatActivityTime(createdAt)}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMusicDiscoveryReference() async {
    final artist = musicDiscoveryArtist;
    if (artist == null) return;

    final name = artist['strArtist']?.toString() ?? 'Artis musik';
    final genre = artist['strGenre']?.toString() ?? '';
    final country = artist['strCountry']?.toString() ?? '';
    final formedYear = artist['intFormedYear']?.toString() ?? '';
    final image = artist['strArtistThumb']?.toString() ?? '';

    await PracticeProgressService.addPracticeSession(
      title: 'Referensi musik: $name',
      type: 'Referensi Musik',
      score: null,
      level: null,
      combo: null,
      passed: true,
      metadata: {
        'artist': name,
        'genre': genre,
        'country': country,
        'formed_year': formedYear,
        'image': image,
        'source': 'TheAudioDB API',
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name tersimpan sebagai referensi musik.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await _loadHomeData();
  }

  Widget _buildMusicDiscoveryCard() {
    final artist = musicDiscoveryArtist;

    if (isLoadingDiscovery) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FB),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFEDEDF5)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'Mengambil referensi musik dari API...',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (artist == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFFFD6A5)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFB45309),
              size: 28,
            ),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'Referensi musik API belum tersedia. Coba refresh beranda saat koneksi internet stabil.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final name = artist['strArtist']?.toString() ?? 'Artis musik';
    final genre = artist['strGenre']?.toString().trim() ?? '';
    final country = artist['strCountry']?.toString().trim() ?? '';
    final formedYear = artist['intFormedYear']?.toString().trim() ?? '';
    final image = artist['strArtistThumb']?.toString() ?? '';
    final description =
        artist['strBiographyID']?.toString().trim().isNotEmpty == true
        ? artist['strBiographyID'].toString()
        : artist['strBiographyEN']?.toString() ?? '';

    final infoParts = [genre, country, formedYear].where((value) {
      final lower = value.toLowerCase();
      return value.isNotEmpty &&
          lower != 'null' &&
          value != '0' &&
          value != '-';
    }).toList();

    final infoText = infoParts.isEmpty
        ? 'Referensi artis dari TheAudioDB'
        : infoParts.join(' • ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6E2FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MUSIC DISCOVERY API',
            style: TextStyle(
              color: Color(0xFF7C4DFF),
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: image.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF7C4DFF),
                        size: 36,
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF7C4DFF),
                            size: 36,
                          );
                        },
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF20243A),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      infoText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 13),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveMusicDiscoveryReference,
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: const Text('Simpan Referensi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _loadHomeData,
                icon: const Icon(Icons.refresh_rounded),
                color: const Color(0xFF7C4DFF),
                tooltip: 'Muat ulang referensi',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDashboardDateTime(Map<String, dynamic> item) {
    final now = DateTime.now();
    final year = item['year'] is int ? item['year'] as int : now.year;
    final month = item['month'] is int ? item['month'] as int : now.month;
    final date = item['date'] is int ? item['date'] as int : now.day;
    final hour = item['hour'] is int ? item['hour'] as int : 0;
    final minute = item['minute'] is int ? item['minute'] as int : 0;
    final zone = item['zone']?.toString() ?? 'WIB';

    final dt = DateTime(year, month, date, hour, minute);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $zone';
  }

  Widget _buildHomeDashboardCard({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? footer,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 27),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF20243A),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFB1B3BE),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (footer != null) ...[const SizedBox(height: 12), footer],
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyDashboardCard() {
    final topPlace = nearbyMusicPlaces.isEmpty ? null : nearbyMusicPlaces.first;

    final title = isLoadingNearbyPlaces
        ? 'Mencari tempat musik terdekat...'
        : topPlace == null
        ? 'Tempat musik terdekat'
        : topPlace['name']?.toString() ?? 'Tempat musik terdekat';

    final subtitle = isLoadingNearbyPlaces
        ? 'Lokasi kamu sedang dibaca untuk mencari toko musik, studio, karaoke, kursus musik, dan layanan audio.'
        : topPlace == null
        ? 'Lokasi kamu: $dashboardLocationText. Ketuk untuk melihat pencarian tempat musik di sekitar kamu.'
        : 'Lokasi kamu: $dashboardLocationText. Terdekat: ${topPlace['type'] ?? 'Tempat Musik'} • ${topPlace['distance_text'] ?? 'jarak tersedia'}';

    return _buildHomeDashboardCard(
      icon: Icons.location_on_rounded,
      label: 'Lokasi Musik',
      title: title,
      subtitle: subtitle,
      color: const Color(0xFFE85D75),
      onTap: () => Navigator.pushNamed(context, '/nearby'),
      footer: nearbyMusicPlaces.isEmpty
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: nearbyMusicPlaces.map((place) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFD7DF)),
                  ),
                  child: Text(
                    '${place['name'] ?? 'Tempat Musik'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE85D75),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildInstrumentPlanDashboardCard() {
    final latest = savedInstrumentPlans.isEmpty
        ? null
        : savedInstrumentPlans.first;

    final title = latest == null
        ? 'Belum ada rencana beli alat'
        : latest['name']?.toString() ?? 'Rencana beli alat musik';

    final subtitle = latest == null
        ? 'Simpan alat musik yang kamu minati, lalu lihat ringkasannya langsung di beranda.'
        : '${savedInstrumentPlans.length} alat tersimpan. Estimasi terakhir: ${latest['converted_price'] ?? 'harga tersedia'}.';

    return _buildHomeDashboardCard(
      icon: Icons.piano_rounded,
      label: 'Rencana Beli',
      title: title,
      subtitle: subtitle,
      color: const Color(0xFF0072FF),
      onTap: () => Navigator.pushNamed(context, '/instrument-prices'),
    );
  }

  Widget _buildScheduleDashboardCard() {
    final upcoming = savedPracticeSchedules.isEmpty
        ? null
        : savedPracticeSchedules.first;

    final title = upcoming == null
        ? 'Belum ada jadwal latihan'
        : '${upcoming['practice_type'] ?? 'Latihan'} • ${upcoming['target'] ?? 'Target'}';

    final subtitle = upcoming == null
        ? 'Buat jadwal latihan dengan tanggal, zona waktu, dan reminder Android.'
        : 'Jadwal terdekat: ${_formatDashboardDateTime(upcoming)}. Reminder HP: ${upcoming['device_reminder_time'] ?? 'aktif'}.';

    return _buildHomeDashboardCard(
      icon: Icons.notifications_active_rounded,
      label: 'Jadwal Terdekat',
      title: title,
      subtitle: subtitle,
      color: const Color(0xFF00A86B),
      onTap: () => Navigator.pushNamed(context, '/scheduler'),
    );
  }

  Widget _buildAiCoachDashboardCard() {
    return _buildHomeDashboardCard(
      icon: Icons.psychology_rounded,
      label: 'AI Music Coach',
      title: 'Asisten AI untuk latihan musik',
      subtitle:
          'Tanya teori musik, tips vokal, latihan gitar, ear training, atau minta rencana latihan yang lebih terarah.',
      color: const Color(0xFF9C27B0),
      onTap: () => Navigator.pushNamed(context, '/ai-coach'),
    );
  }

  Widget _buildDashboardGrid() {
    return Column(
      children: [
        _buildNearbyDashboardCard(),
        const SizedBox(height: 14),
        _buildInstrumentPlanDashboardCard(),
        const SizedBox(height: 14),
        _buildScheduleDashboardCard(),
        const SizedBox(height: 14),
        _buildAiCoachDashboardCard(),
      ],
    );
  }

  Widget _buildApiInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F7), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_sync_rounded,
            color: Color(0xFF7C4DFF),
            size: 30,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitur Berbasis API',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF20243A),
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Pitch Perfect memakai API untuk data musik, toko musik terdekat, dan konversi mata uang.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        userName.split(' ').where((part) => part.isNotEmpty).isEmpty
        ? 'Pengguna'
        : userName.split(' ').first;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Halo, $firstName 👋',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF20243A),
                      ),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pantau progres, lanjutkan aktivitas terakhir, dan dapatkan rekomendasi latihan berikutnya.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7C7E8A),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              _buildHeroCard(),
              const SizedBox(height: 18),
              _buildProgressCard(),
              const SizedBox(height: 18),
              _buildSmartRecommendationCard(),
              const SizedBox(height: 14),
              _buildLastActivityCard(),
              const SizedBox(height: 18),
              _buildMusicDiscoveryCard(),
              const SizedBox(height: 24),
              _buildSectionTitle(
                'Dashboard Musikmu',
                'Pantau lokasi, rencana beli alat, jadwal latihan, dan AI Coach dari satu beranda.',
              ),
              const SizedBox(height: 14),
              _buildDashboardGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle(
                'Mulai dari mana?',
                'Pilih fitur sesuai kebutuhanmu saat ini.',
              ),
              const SizedBox(height: 14),
              _buildFeatureCard(
                icon: Icons.tune_rounded,
                title: 'Cek Nada Gitar atau Suara',
                subtitle:
                    'Gunakan tuner gitar dan deteksi Do Re Mi dari mikrofon HP.',
                badge: 'Detect',
                color: const Color(0xFF7C4DFF),
                onTap: () => _goToTab(1),
              ),
              _buildFeatureCard(
                icon: Icons.library_music_rounded,
                title: 'Music Assistant',
                subtitle:
                    'Cari referensi lagu dan preview musik dari MusicBrainz serta iTunes API.',
                badge: 'API Musik',
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.pushNamed(context, '/search'),
              ),
              _buildFeatureCard(
                icon: Icons.build_rounded,
                title: 'Tools Musik',
                subtitle:
                    'Cari tempat musik, simpan minat alat, buat jadwal latihan, dan aktifkan reminder.',
                badge: 'Tools',
                color: const Color(0xFF0072FF),
                onTap: () => _goToTab(2),
              ),
              _buildFeatureCard(
                icon: Icons.videogame_asset_rounded,
                title: 'Latihan Lewat Game',
                subtitle:
                    'Gunakan mini game untuk latihan nada, skor, dan progres.',
                badge: 'Games',
                color: const Color(0xFFFF8A65),
                onTap: () => _goToTab(3),
              ),
              _buildFeatureCard(
                icon: Icons.person_rounded,
                title: 'Lihat Profil & Riwayat',
                subtitle:
                    'Cek aktivitas tersimpan, progres, dan pengaturan akun.',
                badge: 'Profile',
                color: const Color(0xFF00A86B),
                onTap: () => _goToTab(4),
              ),
              const SizedBox(height: 10),
              _buildApiInfoCard(),
            ],
          ),
        ),
      ),
    );
  }
}
