import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../services/audio_db_service.dart';
import '../../services/deezer_music_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/location_service.dart';
import '../../services/music_reference_service.dart';
import '../../services/nearby_music_store_service.dart';
import '../../services/practice_progress_service.dart';
import '../../services/session_service.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  String userName = 'Music Enthusiast';
  String? profileImagePath;
  bool isLoading = true;
  bool isLoadingMusic = true;
  bool isLoadingNearestStore = false;

  int totalSessions = 0;
  int weeklySessions = 0;
  int? averageScore;

  Map<String, int> gameRecords = {
    'best_score': 0,
    'best_level': 0,
    'best_combo': 0,
  };

  List<Map<String, dynamic>> musicRecommendations = [];
  List<Map<String, dynamic>> instrumentPlans = [];
  List<Map<String, dynamic>> practiceSchedules = [];
  List<Map<String, dynamic>> historyItems = [];
  Map<String, dynamic>? nearestMusicStore;
  Map<String, dynamic>? artistSpotlight;
  Map<String, double> currencyRates = {};

  final AudioPlayer audioPlayer = AudioPlayer();
  String? playingPreviewUrl;

  final List<String> recommendationQueries = const [
    'vocal acoustic pop',
    'acoustic guitar practice',
    'piano ballad',
    'jazz instrumental',
    'indie acoustic',
    'rnb vocal',
    'lofi focus music',
    'rock guitar',
  ];

  final List<String> spotlightArtists = const [
    'Coldplay',
    'Adele',
    'Bruno Mars',
    'Ed Sheeran',
    'Queen',
    'Linkin Park',
    'Ariana Grande',
    'Taylor Swift',
    'Maroon 5',
    'Imagine Dragons',
  ];

  @override
  void initState() {
    super.initState();
    _loadHome();
    _loadNearestMusicStore();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadHome() async {
    setState(() => isLoading = true);

    final name = await SessionService.getUserName();
    final imagePath = await SessionService.getProfileImagePath();

    Map<String, dynamic> summary = {};
    List<Map<String, dynamic>> instruments = [];
    List<Map<String, dynamic>> schedules = [];
    List<Map<String, dynamic>> history = [];
    Map<String, int> records = {
      'best_score': 0,
      'best_level': 0,
      'best_combo': 0,
    };

    try {
      summary = await PracticeProgressService.getSummary();
    } catch (_) {}

    try {
      instruments = await PracticeProgressService.getInstrumentInterests();
    } catch (_) {}

    try {
      schedules = await PracticeProgressService.getPracticeSchedules();
    } catch (_) {}

    try {
      records = await PracticeProgressService.getGameRecords();
    } catch (_) {}

    try {
      history = await PracticeProgressService.getHistory();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      userName = name.trim().isEmpty ? 'Music Enthusiast' : name.trim();
      profileImagePath = imagePath;
      totalSessions = summary['total_sessions'] ?? 0;
      weeklySessions = summary['weekly_sessions'] ?? 0;
      averageScore = summary['average_score'];
      instrumentPlans = instruments;
      practiceSchedules = schedules;
      gameRecords = records;
      historyItems = history;
      isLoading = false;
    });

    await Future.wait([
      _loadMusicRecommendations(),
      _loadArtistSpotlight(),
      _loadCurrencyRates(),
    ]);
  }

  Future<void> _loadMusicRecommendations() async {
    if (!mounted) return;
    setState(() => isLoadingMusic = true);

    final startIndex = DateTime.now().minute % recommendationQueries.length;
    final orderedQueries = [
      ...recommendationQueries.skip(startIndex),
      ...recommendationQueries.take(startIndex),
    ];

    for (final query in orderedQueries) {
      try {
        final result = await DeezerMusicService.searchTracks(
          query: query,
          limit: 8,
        );

        if (!mounted) return;

        if (result.isNotEmpty) {
          setState(() {
            musicRecommendations = result.take(8).toList();
            isLoadingMusic = false;
          });
          return;
        }
      } catch (_) {
        continue;
      }
    }

    try {
      final fallback = await MusicReferenceService.searchITunes('acoustic guitar');
      if (!mounted) return;

      if (fallback.isNotEmpty) {
        setState(() {
          musicRecommendations = fallback.take(8).toList();
          isLoadingMusic = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      musicRecommendations = [];
      isLoadingMusic = false;
    });
  }

  Future<void> _loadArtistSpotlight() async {
    final startIndex = DateTime.now().second % spotlightArtists.length;
    final orderedArtists = [
      ...spotlightArtists.skip(startIndex),
      ...spotlightArtists.take(startIndex),
    ];

    for (final artistName in orderedArtists) {
      try {
        final artist = await AudioDbService.searchArtist(artistName);
        if (!mounted) return;
        if (artist != null) {
          setState(() => artistSpotlight = artist);
          return;
        }
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> _loadCurrencyRates() async {
    try {
      final rates = await ExchangeRateService.getIdrRates();
      if (!mounted) return;
      setState(() => currencyRates = rates);
    } catch (_) {}
  }

  Future<void> _loadNearestMusicStore() async {
    if (!mounted) return;
    setState(() => isLoadingNearestStore = true);

    try {
      final location = await LocationService.getCurrentLocation();
      if (location['success'] != true) {
        if (!mounted) return;
        setState(() {
          nearestMusicStore = null;
          isLoadingNearestStore = false;
        });
        return;
      }

      final latitude = location['latitude'];
      final longitude = location['longitude'];

      if (latitude is! double || longitude is! double) {
        if (!mounted) return;
        setState(() {
          nearestMusicStore = null;
          isLoadingNearestStore = false;
        });
        return;
      }

      final result = await NearbyMusicStoreService.getNearbyStores(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final stores = List<Map<String, dynamic>>.from(result['stores'] ?? []);
        setState(() {
          nearestMusicStore = stores.isEmpty ? null : stores.first;
          isLoadingNearestStore = false;
        });
      } else {
        setState(() {
          nearestMusicStore = null;
          isLoadingNearestStore = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        nearestMusicStore = null;
        isLoadingNearestStore = false;
      });
    }
  }

  Future<void> _togglePreview(Map<String, dynamic> track) async {
    final preview =
        track['preview']?.toString() ?? track['previewUrl']?.toString() ?? '';

    if (preview.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview lagu belum tersedia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (playingPreviewUrl == preview && audioPlayer.playing) {
        await audioPlayer.pause();
        if (!mounted) return;
        setState(() => playingPreviewUrl = null);
        return;
      }

      await audioPlayer.stop();
      await audioPlayer.setUrl(preview);
      if (!mounted) return;
      setState(() => playingPreviewUrl = preview);
      await audioPlayer.play();
      if (!mounted) return;
      setState(() => playingPreviewUrl = null);
    } catch (_) {
      if (!mounted) return;
      setState(() => playingPreviewUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview lagu belum bisa diputar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openMusicReference(Map<String, dynamic> track) {
    final title = track['title']?.toString().isNotEmpty == true
        ? track['title'].toString()
        : track['trackName']?.toString() ?? '';

    final artist = track['artist']?.toString().isNotEmpty == true
        ? track['artist'].toString()
        : track['artistName']?.toString() ?? '';

    final query = [title, artist]
        .where((item) => item.trim().isNotEmpty)
        .join(' ')
        .trim();

    Navigator.pushNamed(
      context,
      '/music-reference',
      arguments: {
        'query': query.isEmpty ? 'acoustic vocal practice' : query,
        'track': track,
      },
    );
  }

  void _goToTab(int index) {
    widget.onNavigate?.call(index);
  }

  String _firstName() {
    final parts = userName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Music Enthusiast' : parts.first;
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

  String _formatSchedule(Map<String, dynamic> item) {
    final practice = item['practice']?.toString() ??
        item['practice_type']?.toString() ??
        item['title']?.toString() ??
        'Latihan';
    final target = item['target']?.toString() ?? 'Target latihan';
    final date = item['date']?.toString() ?? '-';
    final time = item['time']?.toString() ??
        '${(item['hour'] ?? 0).toString().padLeft(2, '0')}:${(item['minute'] ?? 0).toString().padLeft(2, '0')}';
    final zone = item['timezone']?.toString() ?? item['zone']?.toString() ?? 'WIB';

    return '$practice • $target\n$time $zone • $date';
  }

  String _moneyInsight() {
    final usd = currencyRates['USD'];
    final eur = currencyRates['EUR'];

    if (usd == null || eur == null || usd <= 0 || eur <= 0) {
      return 'Cek estimasi alat musik dan konversi biaya.';
    }

    final usdValue = 1000000 * usd;
    final eurValue = 1000000 * eur;
    return 'IDR 1.000.000 ≈ USD ${usdValue.toStringAsFixed(2)} • EUR ${eurValue.toStringAsFixed(2)}';
  }

  String _trackAlbumImage(Map<String, dynamic> track) {
    final candidates = [
      track['album_cover_big'],
      track['album_cover_medium'],
      track['album_cover'],
      track['cover_big'],
      track['cover_medium'],
      track['cover'],
      track['album'] is Map ? track['album']['cover_big'] : null,
      track['album'] is Map ? track['album']['cover_medium'] : null,
      track['album'] is Map ? track['album']['cover'] : null,
      track['artworkUrl100'],
      track['artworkUrl60'],
      track['image'],
    ];

    for (final candidate in candidates) {
      final url = candidate?.toString() ?? '';
      if (url.trim().isNotEmpty && url.startsWith('http')) {
        return url;
      }
    }

    return '';
  }

  Widget _card({required Widget child, EdgeInsets? padding, Color? color}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _homeAvatar() {
    final path = profileImagePath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();

    return InkWell(
      onTap: () => _goToTab(4),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _border),
          color: _surface,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: _surfaceSoft,
            shape: BoxShape.circle,
          ),
          child: hasImage
              ? Image.file(File(path), fit: BoxFit.cover)
              : const Icon(Icons.person_outline_rounded, color: _purple, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Datang,',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_firstName()} 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _homeAvatar(),
      ],
    );
  }

  Widget _sectionTitle(String title, {String? actionText, VoidCallback? onAction}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                color: _pink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final accuracy = averageScore ?? 0;
    final bestScore = gameRecords['best_score'] ?? 0;

    return _card(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_purple, _pink]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$accuracy%',
                      style: const TextStyle(
                        color: _text,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Akurasi rata-rata latihan',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.emoji_events_outlined,
                color: _muted.withOpacity(0.20),
                size: 72,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryMiniCard(
                  title: 'AKTIVITAS',
                  value: '$totalSessions',
                  subtitle: 'Total tersimpan',
                  color: _cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMiniCard(
                  title: 'MINGGU INI',
                  value: '$weeklySessions',
                  subtitle: 'Latihan baru',
                  color: _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryMiniCard(
                  title: 'AKURASI',
                  value: '$accuracy%',
                  subtitle: 'Rata-rata skor',
                  color: _pink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMiniCard(
                  title: 'GAMES',
                  value: '$bestScore',
                  subtitle: 'Skor terbaik',
                  color: _purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMiniCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: _quickCircleAction(
              icon: Icons.piano_rounded,
              title: 'Rencana',
              color: _purple,
              onTap: () => Navigator.pushNamed(context, '/instrument-prices'),
            ),
          ),
          Expanded(
            child: _quickCircleAction(
              icon: Icons.calendar_month_rounded,
              title: 'Jadwal',
              color: _cyan,
              onTap: () => Navigator.pushNamed(context, '/scheduler'),
            ),
          ),
          Expanded(
            child: _quickCircleAction(
              icon: Icons.psychology_rounded,
              title: 'AI Coach',
              color: _pink,
              onTap: () => Navigator.pushNamed(context, '/ai-coach'),
            ),
          ),
          Expanded(
            child: _quickCircleAction(
              icon: Icons.storefront_rounded,
              title: 'Terdekat',
              color: _green,
              onTap: () => Navigator.pushNamed(context, '/nearby'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCircleAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 27),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicRecommendations() {
    if (isLoadingMusic) {
      return SizedBox(
        height: 210,
        child: Center(
          child: CircularProgressIndicator(color: _cyan.withOpacity(0.9)),
        ),
      );
    }

    if (musicRecommendations.isEmpty) {
      return _card(
        child: const Text(
          'Rekomendasi lagu belum tersedia. Coba refresh halaman ini.',
          style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: musicRecommendations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _musicCard(musicRecommendations[index]);
        },
      ),
    );
  }

  Widget _musicCard(Map<String, dynamic> track) {
    final title = track['title']?.toString().isNotEmpty == true
        ? track['title'].toString()
        : track['trackName']?.toString() ?? 'Lagu';
    final artist = track['artist']?.toString().isNotEmpty == true
        ? track['artist'].toString()
        : track['artistName']?.toString() ?? 'Artis';
    final image = _trackAlbumImage(track);
    final preview =
        track['preview']?.toString() ?? track['previewUrl']?.toString() ?? '';
    final isPlaying = preview.isNotEmpty && playingPreviewUrl == preview;

    return SizedBox(
      width: 158,
      child: InkWell(
        onTap: () => _openMusicReference(track),
        borderRadius: BorderRadius.circular(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 158,
                  height: 158,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B1D55), Color(0xFF0F3B4F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _border),
                  ),
                  child: image.isEmpty
                      ? const Center(
                          child: Icon(Icons.music_note_rounded, color: _pink, size: 44),
                        )
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.music_note_rounded, color: _pink, size: 44),
                            );
                          },
                        ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: InkWell(
                    onTap: () => _togglePreview(track),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _bg.withOpacity(0.78),
                        shape: BoxShape.circle,
                        border: Border.all(color: _border),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueSection() {
    final latestSchedule = practiceSchedules.isEmpty ? null : practiceSchedules.first;
    final latestPlan = instrumentPlans.isEmpty ? null : instrumentPlans.first;
    final lastActivity = historyItems.isEmpty ? null : historyItems.first;

    return Column(
      children: [
        _buildArtistSpotlight(),
        const SizedBox(height: 12),
        _continueCard(
          icon: Icons.calendar_month_rounded,
          title: latestSchedule == null
              ? 'Smart Practice Scheduler'
              : latestSchedule['practice']?.toString() ??
                  latestSchedule['practice_type']?.toString() ??
                  'Smart Practice Scheduler',
          subtitle: latestSchedule == null
              ? 'Atur jadwal latihan dan reminder harianmu.'
              : _formatSchedule(latestSchedule).replaceAll('\n', ' • '),
          color: _cyan,
          onTap: () => Navigator.pushNamed(context, '/scheduler'),
        ),
        const SizedBox(height: 12),
        _continueCard(
          icon: Icons.piano_rounded,
          title: latestPlan == null
              ? 'Rencana Beli Alat Musik'
              : latestPlan['name']?.toString() ?? 'Rencana Beli Alat Musik',
          subtitle: latestPlan == null
              ? _moneyInsight()
              : latestPlan['converted_price']?.toString() ?? _moneyInsight(),
          color: _purple,
          onTap: () => Navigator.pushNamed(context, '/instrument-prices'),
        ),
        const SizedBox(height: 12),
        _continueCard(
          icon: Icons.history_rounded,
          title: lastActivity == null
              ? 'Riwayat Aktivitas'
              : lastActivity['title']?.toString() ?? 'Aktivitas Terakhir',
          subtitle: lastActivity == null
              ? 'Lihat kembali aktivitas dan progress latihanmu.'
              : '${lastActivity['type'] ?? 'Aktivitas'} • ${_formatActivityTime(lastActivity['created_at']?.toString())}',
          color: _green,
          onTap: () => Navigator.pushNamed(context, '/history'),
        ),
      ],
    );
  }

  Widget _continueCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistSpotlight() {
    final artist = artistSpotlight;
    if (artist == null) {
      return _continueCard(
        icon: Icons.person_rounded,
        title: 'Artist Spotlight',
        subtitle: 'Cari referensi artis dan lagu untuk latihan musikmu.',
        color: _pink,
        onTap: () => Navigator.pushNamed(context, '/music-reference'),
      );
    }

    final name = artist['strArtist']?.toString() ?? 'Artis Musik';
    final genre = artist['strGenre']?.toString() ?? 'Referensi musik';
    final image = artist['strArtistThumb']?.toString() ?? '';

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/music-reference'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _pink.withOpacity(0.16),
              ),
              child: image.isEmpty
                  ? const Icon(Icons.person_rounded, color: _pink)
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person_rounded, color: _pink);
                      },
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ARTIST SPOTLIGHT',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    genre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreCards() {
    final storeName = nearestMusicStore?['name']?.toString();

    return Column(
      children: [
        _smallDashboardCard(
          icon: Icons.storefront_rounded,
          title: storeName == null ? 'Tempat Musik Terdekat' : storeName,
          subtitle: isLoadingNearestStore
              ? 'Mencari toko musik terdekat...'
              : storeName == null
                  ? 'Cari toko musik, studio, dan tempat latihan di sekitar kamu.'
                  : '${nearestMusicStore?['type'] ?? 'Tempat Musik'} • ${nearestMusicStore?['distance_text'] ?? 'jarak tersedia'}',
          color: _green,
          onTap: () => Navigator.pushNamed(context, '/nearby'),
        ),
      ],
    );
  }

  Widget _smallDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHome,
          color: _purple,
          backgroundColor: _surface,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _sectionTitle('Ringkasan Progres'),
              const SizedBox(height: 14),
              _buildSummaryCard(),
              const SizedBox(height: 30),
              _sectionTitle('Akses Cepat'),
              const SizedBox(height: 14),
              _buildQuickActions(),
              const SizedBox(height: 30),
              _sectionTitle(
                'Rekomendasi Lagu',
                actionText: 'Lihat Semua',
                onAction: () => Navigator.pushNamed(context, '/music-reference'),
              ),
              const SizedBox(height: 14),
              _buildMusicRecommendations(),
              const SizedBox(height: 30),
              _sectionTitle('Lanjutkan'),
              const SizedBox(height: 14),
              _buildContinueSection(),
              const SizedBox(height: 16),
              _buildMoreCards(),
            ],
          ),
        ),
      ),
    );
  }
}
