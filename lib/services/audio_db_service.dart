import 'dart:convert';

import 'package:http/http.dart' as http;

class AudioDbService {
  static const String _baseUrl = 'https://www.theaudiodb.com/api/v1/json/123';

  static Future<Map<String, dynamic>?> searchArtist(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    final uri = Uri.parse(
      '$_baseUrl/search.php',
    ).replace(queryParameters: {'s': cleanQuery});

    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Detail artis belum tersedia.');
    }

    final decoded = jsonDecode(response.body);
    final artists = decoded['artists'];

    if (artists is! List || artists.isEmpty) {
      return null;
    }

    final first = artists.first;
    if (first is! Map) return null;

    return Map<String, dynamic>.from(first);
  }
}
