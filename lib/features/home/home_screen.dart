import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../services/audio_db_service.dart';
import '../../services/deezer_music_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/music_reference_service.dart';
import '../../services/practice_progress_service.dart';
import '../../services/location_service.dart';
import '../../services/nearby_music_store_service.dart';
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

  String userName = 'Pengguna';
  String? profileImagePath;
  bool isLoading = true;
  bool isLoadingMusic = true;
  final AudioPlayer audioPlayer = AudioPlayer();
  String? playingPreviewUrl;

  int totalSessions = 0;
  int weeklySessions = 0;
  int? averageScore;

  List<Map<String, dynamic>> musicRecommendations = [];
  List<Map<String, dynamic>> instrumentPlans = [];
  List<Map<String, dynamic>> practiceSchedules = [];
  Map<String, dynamic>? artistSpotlight;
  Map<String, double> currencyRates = {};
  Map<String, int> gameRecords = {
    'best_score': 0,
    'best_level': 0,
    'best_combo': 0,
  };

  List<Map<String, dynamic>> latestSchedules = [];
  List<Map<String, dynamic>> latestInstrumentPlans = [];
  Map<String, dynamic>? nearestMusicStore;
  bool isLoadingNearestStore = false;

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
    final name = await SessionService.getUserName();
    final imagePath = await SessionService.getProfileImagePath();
    final summary = await PracticeProgressService.getSummary();
    final instruments = await PracticeProgressService.getInstrumentInterests();
    final schedules = await PracticeProgressService.getPracticeSchedules();
    final records = await PracticeProgressService.getGameRecords();

    if (!mounted) return;

    setState(() {
      userName = name.trim().isEmpty ? 'Pengguna' : name.trim();
      profileImagePath = imagePath;
      totalSessions = summary['total_sessions'] ?? 0;
      weeklySessions = summary['weekly_sessions'] ?? 0;
      averageScore = summary['average_score'];
      instrumentPlans = instruments;
      practiceSchedules = schedules;
      gameRecords = records;
      latestSchedules = schedules.take(3).toList();
      latestInstrumentPlans = instrumentPlans.take(3).toList();
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

    setState(() {
      isLoadingMusic = true;
    });

    final startIndex = DateTime.now().minute % recommendationQueries.length;
    final orderedQueries = [
      ...recommendationQueries.skip(startIndex),
      ...recommendationQueries.take(startIndex),
    ];

    for (final query in orderedQueries) {
      try {
        final result = await DeezerMusicService.searchTracks(
          query: query,
          limit: 6,
        );

        if (!mounted) return;

        if (result.isNotEmpty) {
          setState(() {
            musicRecommendations = result.take(4).toList();
            isLoadingMusic = false;
          });
          return;
        }
      } catch (_) {
        continue;
      }
    }

    try {
      final fallback = await MusicReferenceService.searchITunes(
        'acoustic guitar',
      );

      if (!mounted) return;

      if (fallback.isNotEmpty) {
        setState(() {
          musicRecommendations = fallback.take(4).toList();
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
          setState(() {
            artistSpotlight = artist;
          });
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

      setState(() {
        currencyRates = rates;
      });
    } catch (_) {}
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

        setState(() {
          playingPreviewUrl = null;
        });

        return;
      }

      await audioPlayer.stop();
      await audioPlayer.setUrl(preview);

      if (!mounted) return;

      setState(() {
        playingPreviewUrl = preview;
      });

      await audioPlayer.play();

      if (!mounted) return;

      setState(() {
        playingPreviewUrl = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        playingPreviewUrl = null;
      });

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

    final query = [
      title,
      artist,
    ].where((item) => item.trim().isNotEmpty).join(' ').trim();

    Navigator.pushNamed(
      context,
      '/music-reference',
      arguments: {
        'query': query.isEmpty ? 'acoustic vocal practice' : query,
        'track': track,
      },
    );
  }

  Future<void> _loadNearestMusicStore() async {
    if (!mounted) return;

    setState(() {
      isLoadingNearestStore = true;
    });

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

  void _openFilteredHistory(String query) {
    Navigator.pushNamed(context, '/history', arguments: {'query': query});
  }

  void _goToTab(int index) {
    widget.onNavigate?.call(index);
  }

  String _firstName() {
    final parts = userName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Pengguna' : parts.first;
  }

  String _formatSchedule(Map<String, dynamic> item) {
    final now = DateTime.now();
    final month = item['month'] is int ? item['month'] as int : now.month;
    final date = item['date'] is int ? item['date'] as int : now.day;
    final hour = item['hour'] is int ? item['hour'] as int : 0;
    final minute = item['minute'] is int ? item['minute'] as int : 0;
    final zone = item['zone']?.toString() ?? 'WIB';

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

    return '$date ${months[month - 1]} • ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $zone';
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
            color: Colors.black.withValues(alpha: 0.24),
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
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [_cyan, _purple, _pink]),
          boxShadow: [
            BoxShadow(
              color: _cyan.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: _surfaceSoft,
            shape: BoxShape.circle,
          ),
          child: hasImage
              ? Image.file(File(path), fit: BoxFit.cover)
              : const Icon(Icons.person_rounded, color: _muted, size: 24),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color: _purple.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/pitch_perfect_logo.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pitch Perfect',
                style: TextStyle(
                  color: _text,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Halo, ${_firstName()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _homeAvatar(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _quickAction(
          icon: Icons.graphic_eq_rounded,
          title: 'Tes Nada',
          color: _purple,
          onTap: () => _goToTab(1),
        ),
        _quickAction(
          icon: Icons.build_rounded,
          title: 'Tools',
          color: _cyan,
          onTap: () => _goToTab(2),
        ),
        _quickAction(
          icon: Icons.psychology_rounded,
          title: 'AI Coach',
          color: _pink,
          onTap: () => Navigator.pushNamed(context, '/ai-coach'),
        ),
        _quickAction(
          icon: Icons.library_music_rounded,
          title: 'Referensi Musik',
          color: _green,
          onTap: () => Navigator.pushNamed(context, '/music-reference'),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _text,
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: _text,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMusicRecommendation() {
    if (isLoadingMusic) {
      return _card(
        child: const Row(
          children: [
            CircularProgressIndicator(color: _purple),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Menyiapkan rekomendasi musik...',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    if (musicRecommendations.isEmpty) {
      return _card(
        child: Row(
          children: [
            const Icon(Icons.music_note_rounded, color: _purple, size: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Rekomendasi belum muncul. Buka Referensi Musik untuk mencari lagu latihan.',
                style: TextStyle(
                  color: _muted,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: _loadMusicRecommendations,
              icon: const Icon(Icons.refresh_rounded),
              color: _cyan,
              tooltip: 'Muat ulang rekomendasi',
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Untuk latihan hari ini',
            style: TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...musicRecommendations.take(3).map((track) {
            final cover = track['cover']?.toString().isNotEmpty == true
                ? track['cover'].toString()
                : track['artwork']?.toString().isNotEmpty == true
                ? track['artwork'].toString()
                : track['image']?.toString() ?? '';
            final title = track['title']?.toString().isNotEmpty == true
                ? track['title'].toString()
                : track['trackName']?.toString() ?? 'Lagu';
            final artist = track['artist']?.toString().isNotEmpty == true
                ? track['artist'].toString()
                : track['artistName']?.toString().isNotEmpty == true
                ? track['artistName'].toString()
                : track['subtitle']?.toString() ?? 'Artist';

            final preview =
                track['preview']?.toString() ??
                track['previewUrl']?.toString() ??
                '';
            final isPlaying =
                preview.isNotEmpty && playingPreviewUrl == preview;

            return InkWell(
              onTap: () => _openMusicReference(track),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _surfaceSoft.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: cover.isEmpty
                          ? Container(
                              width: 52,
                              height: 52,
                              color: _surfaceSoft,
                              child: const Icon(
                                Icons.album_rounded,
                                color: _cyan,
                              ),
                            )
                          : Image.network(
                              cover,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 52,
                                  height: 52,
                                  color: _surfaceSoft,
                                  child: const Icon(
                                    Icons.album_rounded,
                                    color: _cyan,
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(width: 12),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 4),
                          const Text(
                            'Ketuk lagu untuk lihat detail',
                            style: TextStyle(
                              color: Color(0xFF7E84A8),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _togglePreview(track),
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                      ),
                      color: _cyan,
                      tooltip: isPlaying ? 'Pause' : 'Play',
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/music-reference'),
              icon: const Icon(Icons.library_music_rounded),
              label: const Text('Lihat Referensi Musik'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _cyan,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistAndMoney() {
    final artistName =
        artistSpotlight?['strArtist']?.toString() ?? 'Inspirasi artis';
    final artistGenre =
        artistSpotlight?['strGenre']?.toString() ?? 'Cari inspirasi musik';
    final image = artistSpotlight?['strArtistThumb']?.toString() ?? '';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _compactCard(
                icon: Icons.album_rounded,
                title: artistName,
                subtitle: artistGenre,
                imageUrl: image,
                color: _purple,
                onTap: () => Navigator.pushNamed(context, '/music-reference'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _compactCard(
                icon: Icons.currency_exchange_rounded,
                title: 'Estimasi Biaya',
                subtitle: _moneyInsight(),
                color: _green,
                onTap: () => Navigator.pushNamed(context, '/instrument-prices'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await Future.wait([
                _loadMusicRecommendations(),
                _loadArtistSpotlight(),
                _loadCurrencyRates(),
              ]);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Muat Ulang Rekomendasi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cyan,
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String imageUrl = '',
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: 178,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageUrl.isEmpty
                ? Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imageUrl,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 42,
                          height: 42,
                          color: color.withValues(alpha: 0.13),
                          child: Icon(icon, color: color, size: 22),
                        );
                      },
                    ),
                  ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedSnapshot() {
    final schedule = latestSchedules.isNotEmpty ? latestSchedules.first : null;
    final plan = latestInstrumentPlans.isNotEmpty
        ? latestInstrumentPlans.first
        : null;

    final scheduleTitle = schedule == null
        ? 'Belum ada jadwal latihan'
        : '${schedule['practice_type'] ?? schedule['title'] ?? 'Jadwal latihan'}';

    final scheduleSubtitle = schedule == null
        ? 'Buat jadwal latihan agar muncul di sini.'
        : '${schedule['day'] ?? 'Jadwal'} • ${schedule['local_time'] ?? schedule['time'] ?? '-'} ${schedule['zone'] ?? 'WIB'}';

    final planTitle = plan == null
        ? 'Belum ada rencana alat'
        : '${plan['name'] ?? 'Rencana alat musik'}';

    final planSubtitle = plan == null
        ? 'Simpan rencana beli alat musik agar muncul di sini.'
        : '${plan['category'] ?? 'Alat musik'} • ${plan['converted_price'] ?? plan['price'] ?? '-'}';

    return Column(
      children: [
        _savedSnapshotCard(
          icon: Icons.location_on_rounded,
          title: nearestMusicStore == null
              ? 'Tempat Musik Terdekat'
              : '${nearestMusicStore!['name'] ?? 'Tempat Musik Terdekat'}',
          subtitle: isLoadingNearestStore
              ? 'Mencari tempat musik terdekat...'
              : nearestMusicStore == null
              ? 'Buka peta untuk melihat toko/tempat musik di sekitarmu.'
              : '${nearestMusicStore!['type'] ?? 'Tempat Musik'} • ${nearestMusicStore!['distance_text'] ?? 'Jarak belum tersedia'}',
          color: _cyan,
          onTap: () => Navigator.pushNamed(context, '/nearby'),
        ),
        const SizedBox(height: 12),
        _savedSnapshotCard(
          icon: Icons.calendar_month_rounded,
          title: scheduleTitle,
          subtitle: scheduleSubtitle,
          color: _purple,
          onTap: () => _openFilteredHistory('Smart Practice Scheduler'),
        ),
        const SizedBox(height: 12),
        _savedSnapshotCard(
          icon: Icons.piano_rounded,
          title: planTitle,
          subtitle: planSubtitle,
          color: _green,
          onTap: () => _openFilteredHistory('Rencana Beli Alat'),
        ),
      ],
    );
  }

  Widget _savedSnapshotCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: color, size: 24),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF7E84A8),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    final accuracy = averageScore == null ? '-' : '$averageScore%';
    final bestScore = gameRecords['best_score'] ?? 0;

    return _card(
      child: Row(
        children: [
          _summaryItem('Aktivitas', '$totalSessions', Icons.history_rounded),
          _divider(),
          _summaryItem('Minggu Ini', '$weeklySessions', Icons.bolt_rounded),
          _divider(),
          _summaryItem('Akurasi', accuracy, Icons.insights_rounded),
          _divider(),
          _summaryItem('Game', '$bestScore', Icons.videogame_asset_rounded),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _purple, size: 22),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
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

  Widget _divider() {
    return Container(width: 1, height: 48, color: _border);
  }

  Widget _buildNextSteps() {
    final latestSchedule = practiceSchedules.isEmpty
        ? null
        : practiceSchedules.first;
    final latestInstrument = instrumentPlans.isEmpty
        ? null
        : instrumentPlans.first;

    return Column(
      children: [
        _smallFeature(
          icon: Icons.notifications_active_rounded,
          title: latestSchedule == null
              ? 'Buat jadwal latihan'
              : '${latestSchedule['practice_type'] ?? 'Latihan'} • ${latestSchedule['target'] ?? 'Target'}',
          subtitle: latestSchedule == null
              ? 'Atur waktu latihan dan reminder.'
              : _formatSchedule(latestSchedule),
          color: _green,
          onTap: () => Navigator.pushNamed(context, '/scheduler'),
        ),
        const SizedBox(height: 12),
        _smallFeature(
          icon: Icons.piano_rounded,
          title: latestInstrument == null
              ? 'Rencana alat musik'
              : latestInstrument['name']?.toString() ?? 'Alat tersimpan',
          subtitle: latestInstrument == null
              ? 'Simpan alat incaran dan estimasi biaya.'
              : latestInstrument['converted_price']?.toString() ??
                    'Estimasi tersimpan',
          color: _cyan,
          onTap: () => Navigator.pushNamed(context, '/instrument-prices'),
        ),
        const SizedBox(height: 12),
        _smallFeature(
          icon: Icons.location_on_rounded,
          title: 'Tempat Musik',
          subtitle: 'Cari toko, studio, atau kursus musik terdekat.',
          color: _pink,
          onTap: () => Navigator.pushNamed(context, '/nearby'),
        ),
      ],
    );
  }

  Widget _smallFeature({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(width: 12),
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
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF7E84A8),
              size: 15,
            ),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _sectionTitle('Akses Cepat'),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _sectionTitle('Rekomendasi'),
              _buildMusicRecommendation(),
              const SizedBox(height: 16),
              _buildArtistAndMoney(),
              const SizedBox(height: 24),
              _sectionTitle('Tersimpan'),
              _buildSavedSnapshot(),
              const SizedBox(height: 24),
              _sectionTitle('Ringkasan'),
              _buildProgressSummary(),
              const SizedBox(height: 24),
              _sectionTitle('Lanjutkan'),
              _buildNextSteps(),
            ],
          ),
        ),
      ),
    );
  }
}
