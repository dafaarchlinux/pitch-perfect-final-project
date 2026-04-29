import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class NearbyMusicStoreService {
  static const String _endpoint = 'https://nominatim.openstreetmap.org/search';

  static Future<Map<String, dynamic>> getNearbyStores({
    required double latitude,
    required double longitude,
  }) async {
    final keywords = [
      'toko musik',
      'alat musik',
      'musik',
      'music store',
      'music',
      'studio musik',
      'recording studio',
      'karaoke',
      'kursus musik',
      'les musik',
      'vocal course',
      'audio',
      'sound system',
      'gitar',
      'guitar',
      'piano',
      'keyboard',
      'drum',
      'yamaha music',
    ];

    final stores = <Map<String, dynamic>>[];

    for (final keyword in keywords) {
      final result = await _searchByKeyword(
        keyword: keyword,
        latitude: latitude,
        longitude: longitude,
      );

      stores.addAll(result);

      if (stores.length >= 12) {
        break;
      }
    }

    final uniqueStores = <String, Map<String, dynamic>>{};

    for (final store in stores) {
      final key = '${store['name']}-${store['lat']}-${store['lon']}'
          .toLowerCase();
      uniqueStores[key] = store;
    }

    final finalStores = uniqueStores.values.toList();

    for (final store in finalStores) {
      final lat = store['lat'];
      final lon = store['lon'];

      if (lat is double && lon is double) {
        final distance = _calculateDistanceKm(latitude, longitude, lat, lon);

        store['distance_km'] = distance;
        store['distance_text'] = '${distance.toStringAsFixed(1)} km';
      }
    }

    finalStores.sort((a, b) {
      final distanceA = a['distance_km'];
      final distanceB = b['distance_km'];

      if (distanceA is! double && distanceB is! double) return 0;
      if (distanceA is! double) return 1;
      if (distanceB is! double) return -1;

      return distanceA.compareTo(distanceB);
    });

    final limitedStores = finalStores.take(20).toList();

    if (limitedStores.isEmpty) {
      return {
        'success': false,
        'message':
            'Belum ada tempat musik yang tercatat di OpenStreetMap untuk area ini. Kamu tetap bisa memakai tombol Google Maps untuk mencari toko musik, studio, karaoke, kursus musik, atau layanan audio terdekat.',
      };
    }

    return {'success': true, 'stores': limitedStores};
  }

  static Future<List<Map<String, dynamic>>> _searchByKeyword({
    required String keyword,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final delta = 0.22;

      final left = longitude - delta;
      final right = longitude + delta;
      final top = latitude + delta;
      final bottom = latitude - delta;

      final uri = Uri.parse(_endpoint).replace(
        queryParameters: {
          'format': 'jsonv2',
          'q': keyword,
          'limit': '15',
          'addressdetails': '1',
          'bounded': '1',
          'viewbox': '$left,$top,$right,$bottom',
        },
      );

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'PitchPerfectFlutter/1.0 (student project)',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map(_parseNominatimItem)
          .whereType<Map<String, dynamic>>()
          .where(_isRelevantMusicPlace)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic>? _parseNominatimItem(dynamic item) {
    if (item is! Map) return null;

    final map = Map<String, dynamic>.from(item);

    final lat = double.tryParse((map['lat'] ?? '').toString());
    final lon = double.tryParse((map['lon'] ?? '').toString());

    if (lat == null || lon == null) return null;

    final displayName = (map['display_name'] ?? '').toString().trim();
    if (displayName.isEmpty) return null;

    final address = map['address'] is Map
        ? Map<String, dynamic>.from(map['address'])
        : <String, dynamic>{};

    final name = _pickName(map, address, displayName);

    return {
      'name': name,
      'type': _detectType(name, displayName),
      'address': displayName,
      'lat': lat,
      'lon': lon,
    };
  }

  static String _pickName(
    Map<String, dynamic> map,
    Map<String, dynamic> address,
    String displayName,
  ) {
    final namedKeys = [
      'name',
      'amenity',
      'shop',
      'tourism',
      'leisure',
      'building',
    ];

    for (final key in namedKeys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    final addressKeys = [
      'shop',
      'amenity',
      'building',
      'road',
      'neighbourhood',
      'suburb',
      'village',
      'town',
      'city',
    ];

    for (final key in addressKeys) {
      final value = address[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return displayName.split(',').first.trim();
  }

  static String _detectType(String name, String displayName) {
    final text = '$name $displayName'.toLowerCase();

    if (text.contains('gitar') ||
        text.contains('guitar') ||
        text.contains('piano') ||
        text.contains('keyboard') ||
        text.contains('drum') ||
        text.contains('yamaha')) {
      return 'Toko Alat Musik';
    }

    if (text.contains('studio') || text.contains('recording')) {
      return 'Studio Musik';
    }

    if (text.contains('kursus') ||
        text.contains('school') ||
        text.contains('vocal') ||
        text.contains('vokal') ||
        text.contains('les musik')) {
      return 'Kelas / Sekolah Musik';
    }

    if (text.contains('audio') ||
        text.contains('sound') ||
        text.contains('speaker') ||
        text.contains('ampli')) {
      return 'Audio / Sound System';
    }

    if (text.contains('karaoke')) {
      return 'Karaoke / Hiburan Musik';
    }

    return 'Tempat Musik';
  }

  static bool _isRelevantMusicPlace(Map<String, dynamic> store) {
    final text = '${store['name']} ${store['type']} ${store['address']}'
        .toLowerCase();

    final keywords = [
      'musik',
      'music',
      'gitar',
      'guitar',
      'piano',
      'keyboard',
      'drum',
      'vocal',
      'vokal',
      'audio',
      'sound',
      'studio',
      'recording',
      'karaoke',
      'organ',
      'yamaha',
      'band',
      'dj',
      'speaker',
      'ampli',
      'kursus',
      'les musik',
    ];

    return keywords.any(text.contains);
  }

  static double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreeToRadian(lat2 - lat1);
    final dLon = _degreeToRadian(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreeToRadian(lat1)) *
            cos(_degreeToRadian(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }
}
