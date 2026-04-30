import 'dart:convert';

import 'package:http/http.dart' as http;

class DeezerMusicService {
  static const String _searchEndpoint = 'https://api.deezer.com/search';

  static Future<List<Map<String, dynamic>>> searchTracks({
    required String query,
    int limit = 12,
  }) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      _searchEndpoint,
    ).replace(queryParameters: {'q': cleanQuery, 'limit': limit.toString()});

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Deezer API gagal memuat referensi lagu.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];

    if (data is! List) {
      return [];
    }

    return data.whereType<Map>().map((item) {
      final artist = item['artist'];
      final album = item['album'];

      return {
        'id': item['id']?.toString() ?? '',
        'title': item['title']?.toString() ?? 'Unknown Track',
        'artist': artist is Map
            ? artist['name']?.toString() ?? 'Unknown Artist'
            : 'Unknown Artist',
        'album': album is Map
            ? album['title']?.toString() ?? 'Unknown Album'
            : 'Unknown Album',
        'cover': album is Map ? album['cover_medium']?.toString() ?? '' : '',
        'cover_big': album is Map ? album['cover_big']?.toString() ?? '' : '',
        'preview': item['preview']?.toString() ?? '',
        'link': item['link']?.toString() ?? '',
        'duration': item['duration'] is int ? item['duration'] as int : 0,
        'source': 'Deezer API',
      };
    }).toList();
  }
}
