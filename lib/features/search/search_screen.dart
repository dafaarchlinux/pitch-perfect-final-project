import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/music_reference_service.dart';
import '../../services/music_ai_service.dart';
import '../../services/practice_progress_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController chatController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final AudioPlayer audioPlayer = AudioPlayer();

  bool isLoading = false;
  String? playingPreviewUrl;

  final List<Map<String, dynamic>> messages = [
    {
      'role': 'assistant',
      'text':
          'Halo! Aku Music Assistant. Kamu bisa tanya rekomendasi lagu, referensi artis, latihan vokal, atau ide lagu untuk latihan gitar.',
    },
  ];

  Future<void> _saveAssistantActivity({
    required String query,
    required bool foundResults,
    int resultCount = 0,
  }) async {
    await PracticeProgressService.addPracticeSession(
      title: 'Music Assistant: $query',
      type: 'Music Assistant',
      score: null,
      level: null,
      combo: null,
      passed: foundResults,
      metadata: {
        'query': query,
        'found_results': foundResults,
        'result_count': resultCount,
        'source': 'MusicBrainz + iTunes + TheAudioDB + Music Assistant',
      },
    );
  }

  Future<void> _savePreviewActivity(Map<String, dynamic> item) async {
    await PracticeProgressService.addPracticeSession(
      title: 'Preview lagu: ${item['title'] ?? 'Musik'}',
      type: 'Preview Lagu',
      score: null,
      level: null,
      combo: null,
      passed: true,
      metadata: {
        'title': item['title'],
        'artist': item['artist'],
        'subtitle': item['subtitle'],
        'source': item['source'],
        'has_preview': true,
      },
    );
  }

  Future<void> _sendMessage() async {
    final question = chatController.text.trim();

    if (question.isEmpty || isLoading) return;

    setState(() {
      messages.add({'role': 'user', 'text': question});
      isLoading = true;
    });

    chatController.clear();
    _scrollToBottom();

    final answer = await _buildAssistantAnswer(question);

    if (!mounted) return;

    final results = answer['results'];
    await _saveAssistantActivity(
      query: question,
      foundResults: results is List && results.isNotEmpty,
      resultCount: results is List ? results.length : 0,
    );

    if (!mounted) return;

    setState(() {
      messages.add(answer);
      isLoading = false;
    });

    _scrollToBottom();
  }

  Future<Map<String, dynamic>> _buildAssistantAnswer(String question) async {
    final lower = question.toLowerCase();

    List<Map<String, dynamic>> musicResults = [];

    if (_shouldSearchMusicApi(lower)) {
      final musicQuery = _extractMusicQuery(question);

      try {
        final results = await MusicReferenceService.searchAll(musicQuery);

        final playableResults = results
            .where((item) {
              final previewUrl = item['previewUrl']?.toString();
              return previewUrl != null && previewUrl.isNotEmpty;
            })
            .take(5)
            .toList();

        musicResults = playableResults.isNotEmpty
            ? playableResults
            : results.take(5).toList();
      } catch (_) {
        musicResults = [];
      }
    }

    try {
      final aiAnswer = await MusicAiService.askMusicAssistant(
        question: question,
        history: messages,
      );

      return {
        'role': 'assistant',
        'text': musicResults.isEmpty
            ? aiAnswer
            : '$aiAnswer\n\nAku juga menemukan beberapa referensi musik dari API yang bisa kamu cek:',
        if (musicResults.isNotEmpty) 'results': musicResults,
      };
    } catch (_) {
      final localFallback = _localMusicFallback(question);
      if (localFallback != null) {
        return localFallback;
      }

      if (_isTrainingQuestion(lower)) {
        return {'role': 'assistant', 'text': _trainingAnswer(lower)};
      }

      if (musicResults.isNotEmpty) {
        return {
          'role': 'assistant',
          'text':
              'Aku menemukan referensi musik dari database musik yang bisa kamu cek:',
          'results': musicResults,
        };
      }

      return {
        'role': 'assistant',
        'text':
            'AI belum berhasil tersambung ke OpenRouter. Pastikan API key benar, akun OpenRouter aktif, model openrouter/free tersedia, dan HP punya koneksi internet.',
      };
    }
  }

  bool _shouldSearchMusicApi(String lower) {
    final keywords = [
      'lagu',
      'musik',
      'artis',
      'album',
      'band',
      'penyanyi',
      'song',
      'artist',
      'aftershine',
      'noah',
      'taylor',
      'jawa',
      'pop',
      'akustik',
      'gitar',
    ];

    return keywords.any(lower.contains);
  }

  String _extractMusicQuery(String question) {
    var query = question.toLowerCase().trim();

    final removablePhrases = [
      'carikan',
      'cari',
      'rekomendasi',
      'rekomendasikan',
      'lagu',
      'musik',
      'dong',
      'apa',
      'yang',
      'paling',
      'favorit',
      'buat',
      'untuk',
      'latihan',
      'enak',
      'bagus',
      'tolong',
      'saya',
      'aku',
    ];

    for (final phrase in removablePhrases) {
      query = query.replaceAll(RegExp('\\b$phrase\\b'), ' ');
    }

    query = query.replaceAll(RegExp(r'\s+'), ' ').trim();

    return query.isEmpty ? question.trim() : query;
  }

  Map<String, dynamic>? _localMusicFallback(String question) {
    final lower = question.toLowerCase();

    if (lower.contains('aftershine')) {
      return {
        'role': 'assistant',
        'text':
            'Aftershine cocok untuk referensi lagu pop Jawa dan koplo modern. Coba juga artis sejenis seperti Guyon Waton, Denny Caknan, NDX AKA, Happy Asmara, dan Yeni Inka. Untuk latihan vokal, pilih lagu bertempo sedang, latih bagian reff pelan-pelan, lalu cek nadanya memakai mode Deteksi Suara.',
      };
    }

    if (lower.contains('jawa') ||
        lower.contains('koplo') ||
        lower.contains('dangdut')) {
      return {
        'role': 'assistant',
        'text':
            'Untuk referensi lagu Jawa atau koplo, kamu bisa coba Aftershine, Guyon Waton, Denny Caknan, NDX AKA, Happy Asmara, Yeni Inka, atau Gilga Sahid. Untuk latihan vokal, mulai dari lagu tempo sedang, nyanyikan reff satu bait, lalu cek nada memakai mode Deteksi Suara.',
      };
    }

    return null;
  }

  bool _isTrainingQuestion(String lower) {
    final keywords = [
      'latih',
      'latihan',
      'vokal',
      'suara',
      'napas',
      'pernapasan',
      'warming',
      'pemanasan',
      'gitar',
      'tuning',
      'stem',
      'nada',
      'do re mi',
      'fals',
    ];

    return keywords.any(lower.contains);
  }

  String _trainingAnswer(String lower) {
    if (lower.contains('vokal') ||
        lower.contains('suara') ||
        lower.contains('napas') ||
        lower.contains('warming') ||
        lower.contains('pemanasan')) {
      return 'Untuk melatih vokal, mulai dari pemanasan ringan 5–10 menit. Coba humming, lip trill, latihan napas diafragma, lalu nyanyikan Do Re Mi perlahan. Jangan langsung memaksa nada tinggi. Gunakan menu Detect untuk melihat nada suara yang kamu nyanyikan.';
    }

    if (lower.contains('gitar') ||
        lower.contains('tuning') ||
        lower.contains('stem')) {
      return 'Untuk stem gitar, buka menu Detect lalu pilih mode Tuner Gitar. Pilih senar target E, A, D, G, B, atau E, lalu petik satu senar saja. Kalau indikator terlalu rendah, kencangkan senar. Kalau terlalu tinggi, kendurkan senar. Kalau sudah PAS, senar sudah cocok.';
    }

    if (lower.contains('do re mi') || lower.contains('nada')) {
      return 'Untuk latihan Do Re Mi, gunakan tangga nada C mayor: Do = C, Re = D, Mi = E, Fa = F, Sol = G, La = A, Si = B. Buka Detect mode Deteksi Suara, nyanyikan satu nada, lalu lihat hasil Do/Re/Mi yang terbaca.';
    }

    return 'Latihan musik yang aman dimulai dari pemanasan, latihan nada pelan, lalu tingkatkan kesulitan secara bertahap. Gunakan Detect untuk cek nada, dan nanti gunakan Games untuk latihan skor.';
  }

  Future<void> _togglePreview(Map<String, dynamic> item) async {
    final previewUrl = item['previewUrl']?.toString();
    if (previewUrl == null || previewUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview audio tidak tersedia untuk lagu ini.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (playingPreviewUrl == previewUrl) {
        await audioPlayer.stop();

        if (!mounted) return;

        setState(() {
          playingPreviewUrl = null;
        });
        return;
      }

      await audioPlayer.stop();
      await audioPlayer.setUrl(previewUrl);
      await audioPlayer.play();

      await _savePreviewActivity(item);

      if (!mounted) return;

      setState(() {
        playingPreviewUrl = previewUrl;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        playingPreviewUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview audio gagal diputar. Coba lagu lain.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 180,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  void _askSuggestion(String text) {
    chatController.text = text;
    _sendMessage();
  }

  Widget _buildBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final results = message['results'];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
                )
              : null,
          color: isUser ? null : const Color(0xFFF7F7FB),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 8),
            bottomRight: Radius.circular(isUser ? 8 : 22),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFEDEDF5)),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message['text']?.toString() ?? '',
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF20243A),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (results is List && results.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...results.map((item) {
                if (item is Map<String, dynamic>) {
                  return _buildMusicResultCard(item);
                }

                return const SizedBox.shrink();
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMusicResultCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'Judul tidak diketahui';
    final artist = item['artist']?.toString() ?? 'Artis tidak diketahui';
    final subtitle = item['subtitle']?.toString() ?? 'Referensi musik';
    final source = item['source']?.toString() ?? 'API';
    final artwork = item['artwork']?.toString();
    final previewUrl = item['previewUrl']?.toString();
    final hasPreview = previewUrl != null && previewUrl.isNotEmpty;
    final isPlaying = playingPreviewUrl == previewUrl;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: artwork == null || artwork.isEmpty
                ? const Icon(Icons.music_note_rounded, color: Color(0xFF7C4DFF))
                : Image.network(
                    artwork,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.music_note_rounded,
                        color: Color(0xFF7C4DFF),
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
                  source.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF7C4DFF),
                    fontSize: 9,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF20243A),
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
                    color: Color(0xFF4B5563),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8A8D99),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (hasPreview) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              height: 42,
              child: ElevatedButton(
                onPressed: () => _togglePreview(item),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isPlaying
                      ? const Color(0xFFFF7043)
                      : const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: isLoading ? null : () => _askSuggestion(text),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        color: Color(0xFF5E35B1),
      ),
      backgroundColor: const Color(0xFFF1EDFF),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    chatController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  static const Color _bgColor = Color(0xFFFCFCFE);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
        title: const Text(
          'Music Assistant',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.library_music_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Tanya lagu, artis, referensi latihan, atau tips vokal dan gitar.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildSuggestionChip('lagu jawa favorit'),
                const SizedBox(width: 8),
                _buildSuggestionChip('cara melatih vokal'),
                const SizedBox(width: 8),
                _buildSuggestionChip('lagu gitar akustik mudah'),
                const SizedBox(width: 8),
                _buildSuggestionChip('lagu untuk latihan nada tinggi'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              children: [
                ...messages.map(_buildBubble),
                if (isLoading)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6, bottom: 14),
                      child: Text(
                        'Music Assistant sedang mencari jawaban...',
                        style: TextStyle(
                          color: Color(0xFF7C7E8A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                bottomInset > 0 ? 12 : 10,
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller: chatController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: 'Tanya musik atau latihan...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFF7C4DFF),
                          disabledBackgroundColor: const Color(0xFFB7A8FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
