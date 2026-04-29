import 'dart:convert';
import 'package:http/http.dart' as http;

class MusicReferenceService {
  static const String _musicBrainzBaseUrl = 'https://musicbrainz.org/ws/2';
  static const String _itunesBaseUrl = 'https://itunes.apple.com/search';

  static Future<List<Map<String, dynamic>>> searchMusicBrainz(
    String query,
  ) async {
    final uri = Uri.parse(
      '$_musicBrainzBaseUrl/recording?query=${Uri.encodeQueryComponent(query)}&fmt=json&limit=8',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'PitchPerfectFlutter/1.0 (student-project)',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('MusicBrainz gagal memuat data.');
    }

    final decoded = jsonDecode(response.body);
    final recordings = decoded['recordings'];

    if (recordings is! List) {
      return [];
    }

    return recordings.map<Map<String, dynamic>>((item) {
      final artistCredit = item['artist-credit'];
      String artist = 'Artis tidak diketahui';

      if (artistCredit is List && artistCredit.isNotEmpty) {
        final firstArtist = artistCredit.first;
        if (firstArtist is Map && firstArtist['name'] != null) {
          artist = firstArtist['name'].toString();
        }
      }

      return {
        'source': 'MusicBrainz',
        'title': (item['title'] ?? 'Judul tidak diketahui').toString(),
        'artist': artist,
        'subtitle': 'Data lagu dari MusicBrainz',
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> searchITunes(String query) async {
    final uri = Uri.parse(
      '$_itunesBaseUrl?term=${Uri.encodeQueryComponent(query)}&media=music&entity=song&limit=8',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('iTunes gagal memuat data.');
    }

    final decoded = jsonDecode(response.body);
    final results = decoded['results'];

    if (results is! List) {
      return [];
    }

    return results.map<Map<String, dynamic>>((item) {
      return {
        'source': 'iTunes',
        'title': (item['trackName'] ?? 'Judul tidak diketahui').toString(),
        'artist': (item['artistName'] ?? 'Artis tidak diketahui').toString(),
        'subtitle': (item['collectionName'] ?? 'Data lagu dari iTunes')
            .toString(),
        'artwork': item['artworkUrl100']?.toString(),
        'previewUrl': item['previewUrl']?.toString(),
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> searchAll(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final results = await Future.wait([
      searchMusicBrainz(query),
      searchITunes(query),
    ]);

    return [
      ...results[0],
      ...results[1],
    ];
  }
}
