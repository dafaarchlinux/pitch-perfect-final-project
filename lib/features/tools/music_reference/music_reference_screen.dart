import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../services/deezer_music_service.dart';
import '../../../../services/practice_progress_service.dart';

const Color _bg = Color(0xFF0B0D22);
const Color _surface = Color(0xFF17182C);
const Color _surfaceSoft = Color(0xFF232542);
const Color _border = Color(0xFF2D3050);
const Color _text = Color(0xFFF8FAFC);
const Color _muted = Color(0xFFB8BCD7);
const Color _purple = Color(0xFF8B5CF6);
const Color _cyan = Color(0xFF22D3EE);
const Color _pink = Color(0xFFF472B6);
const Color _green = Color(0xFF34D399);

class MusicReferenceScreen extends StatefulWidget {
  const MusicReferenceScreen({super.key});

  @override
  State<MusicReferenceScreen> createState() => _MusicReferenceScreenState();
}

class _MusicReferenceScreenState extends State<MusicReferenceScreen> {
  final TextEditingController searchController = TextEditingController();
  final AudioPlayer audioPlayer = AudioPlayer();

  String selectedFocus = 'Vokal';
  String? playingPreviewUrl;
  bool isLoading = false;
  bool hasHandledRouteArguments = false;
  String? errorMessage;
  List<Map<String, dynamic>> tracks = [];
  List<Map<String, dynamic>> savedReferences = [];

  final Map<String, String> focusQueries = const {
    'Vokal': 'vocal pop acoustic',
    'Pemanasan Vokal': 'vocal warm up singing',
    'Gitar Akustik': 'acoustic guitar fingerstyle',
    'Gitar Elektrik': 'electric guitar rock solo',
    'Piano': 'piano ballad chord progression',
    'Ear Training': 'jazz instrumental melody',
    'Recording': 'studio vocal recording',
    'Pop': 'pop hits vocal practice',
    'Rock': 'rock guitar vocal',
    'Jazz': 'jazz standards vocal',
    'Classical': 'classical piano violin',
    'R&B': 'rnb vocal runs',
    'Indie': 'indie acoustic',
    'K-Pop': 'kpop vocal dance',
    'Dangdut': 'dangdut indonesia',
    'Lo-fi': 'lofi study music',
    'Instrumental': 'instrumental practice',
    'Beginner': 'easy songs beginner music',
    'Focus Practice': 'calm focus practice music',
  };

  @override
  void initState() {
    super.initState();
    searchController.text = focusQueries[selectedFocus]!;
    _loadSavedReferences();
    _searchTracks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (hasHandledRouteArguments) return;
    hasHandledRouteArguments = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      final query = args['query']?.toString().trim() ?? '';
      final track = args['track'];

      if (query.isNotEmpty) {
        searchController.text = query;

        if (track is Map) {
          final selectedTrack = Map<String, dynamic>.from(track);

          setState(() {
            tracks = [selectedTrack, ...tracks];
          });
        }

        Future.microtask(_searchTracks);
      }
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedReferences() async {
    final history = await PracticeProgressService.getHistory();

    final references = history
        .where((item) {
          return item['type']?.toString() == 'Referensi Musik';
        })
        .take(10)
        .toList();

    if (!mounted) return;

    setState(() {
      savedReferences = references;
    });
  }

  Future<void> _searchTracks() async {
    final query = searchController.text.trim();

    if (query.isEmpty) {
      _showMessage('Masukkan kata kunci lagu terlebih dahulu.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await DeezerMusicService.searchTracks(query: query);

      if (!mounted) return;

      setState(() {
        tracks = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        tracks = [];
        isLoading = false;
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _togglePreview(Map<String, dynamic> track) async {
    final preview = track['preview']?.toString() ?? '';

    if (preview.isEmpty) {
      _showMessage('Preview audio tidak tersedia untuk lagu ini.');
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

      _showMessage('Preview audio belum bisa diputar.');
    }
  }

  Future<void> _deleteSavedReference(Map<String, dynamic> item) async {
    final createdAt = item['created_at']?.toString();

    if (createdAt == null || createdAt.isEmpty) {
      _showMessage('Referensi belum bisa dihapus.');
      return;
    }

    await PracticeProgressService.deleteHistoryItem(createdAt);
    await _loadSavedReferences();

    if (!mounted) return;

    _showMessage('Referensi lagu dihapus.');
  }

  Future<void> _saveTrack(Map<String, dynamic> track) async {
    await PracticeProgressService.addPracticeSession(
      title: 'Referensi lagu: ${track['title']}',
      type: 'Referensi Musik',
      score: null,
      level: null,
      combo: null,
      passed: true,
      metadata: {
        ...track,
        'focus': selectedFocus,
        'query': searchController.text.trim(),
        'storage': 'Hive',
      },
    );

    if (!mounted) return;

    await _loadSavedReferences();

    _showMessage('Referensi lagu disimpan ke riwayat latihan.');
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '-';
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '$minutes:${remain.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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

  Widget _buildSearchCard() {
    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Referensi Musik',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Temukan lagu dan artis sebagai bahan latihan vokal, gitar, piano, atau ear training.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              labelText: 'Cari lagu atau artis',
              hintText: 'Contoh: acoustic guitar',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: _searchTracks,
                icon: const Icon(Icons.arrow_forward_rounded),
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
            onSubmitted: (_) => _searchTracks(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _searchTracks,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.library_music_rounded),
              label: Text(isLoading ? 'Mencari...' : 'Cari Referensi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _surfaceSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12251F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF245C46)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_done_rounded, color: _green),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Referensi musik siap digunakan untuk mencari lagu, cover album, dan preview audio.',
              style: TextStyle(
                color: Color(0xFFC4F1E2),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track) {
    final title = track['title']?.toString() ?? 'Unknown Track';
    final artist = track['artist']?.toString() ?? 'Unknown Artist';
    final album = track['album']?.toString() ?? 'Unknown Album';
    final cover = track['cover_big']?.toString() ?? '';
    final duration = track['duration'] is int ? track['duration'] as int : 0;
    final preview = track['preview']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: cover.isNotEmpty
                ? Image.network(
                    cover,
                    width: 86,
                    height: 86,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _coverFallback(),
                  )
                : _coverFallback(),
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
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$album • ${_formatDuration(duration)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _togglePreview(track),
                      icon: Icon(
                        playingPreviewUrl == preview
                            ? Icons.pause_circle_rounded
                            : Icons.play_circle_rounded,
                        size: 16,
                      ),
                      label: Text(
                        playingPreviewUrl == preview ? 'Pause' : 'Play',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cyan,
                        side: const BorderSide(color: _border),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed: () => _saveTrack(track),
                      icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                      label: const Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
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

  Widget _coverFallback() {
    return Container(
      width: 86,
      height: 86,
      color: _surfaceSoft,
      child: const Icon(Icons.album_rounded, color: _cyan, size: 36),
    );
  }

  Widget _buildSavedReferencesSection() {
    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Referensi Tersimpan',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Lagu yang kamu simpan bisa dipakai sebagai bahan latihan dan tetap tersedia di riwayat.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (savedReferences.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: const Text(
                'Belum ada referensi tersimpan.',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
              ),
            )
          else
            ...savedReferences.map((item) {
              final metadata = item['metadata'] is Map
                  ? Map<String, dynamic>.from(item['metadata'])
                  : <String, dynamic>{};

              final title =
                  metadata['title']?.toString() ??
                  item['title']?.toString().replaceFirst(
                    'Referensi lagu: ',
                    '',
                  ) ??
                  'Lagu tersimpan';
              final artist = metadata['artist']?.toString() ?? 'Unknown Artist';
              final album = metadata['album']?.toString() ?? 'Unknown Album';
              final cover = metadata['cover']?.toString() ?? '';
              final source = metadata['source']?.toString() ?? 'Music Preview';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: cover.isNotEmpty
                          ? Image.network(
                              cover,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _smallCoverFallback();
                              },
                            )
                          : _smallCoverFallback(),
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
                            '$artist • $album',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            source,
                            style: const TextStyle(
                              color: _cyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteSavedReference(item),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: _pink,
                      tooltip: 'Hapus referensi',
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _smallCoverFallback() {
    return Container(
      width: 52,
      height: 52,
      color: _surface,
      child: const Icon(Icons.album_rounded, color: _cyan, size: 24),
    );
  }

  Widget _buildResults() {
    if (isLoading) {
      return _darkCard(
        child: const Row(
          children: [
            CircularProgressIndicator(color: _purple),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Mengambil referensi lagu...',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return _darkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: _pink, size: 34),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: _muted,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _searchTracks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _cyan,
                side: const BorderSide(color: _border),
              ),
            ),
          ],
        ),
      );
    }

    if (tracks.isEmpty) {
      return _darkCard(
        child: const Text(
          'Belum ada referensi. Pilih fokus latihan atau gunakan pencarian.',
          style: TextStyle(
            color: _muted,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(children: tracks.map(_buildTrackCard).toList());
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
          'Referensi Musik',
          style: TextStyle(color: _text, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: _text),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            const Text(
              'Temukan referensi musik untuk latihan dan simpan lagu pilihanmu ke riwayat.',
              style: TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _buildApiStatus(),
            const SizedBox(height: 18),
            _buildSearchCard(),
            const SizedBox(height: 18),
            _buildResults(),
            const SizedBox(height: 18),
            _buildSavedReferencesSection(),
          ],
        ),
      ),
    );
  }
}
