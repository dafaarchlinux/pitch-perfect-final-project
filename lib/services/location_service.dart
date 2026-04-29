import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<Map<String, dynamic>> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return {
        'success': false,
        'message': 'GPS belum aktif. Aktifkan layanan lokasi terlebih dahulu.',
      };
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return {
          'success': false,
          'message': 'Izin lokasi ditolak.',
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return {
        'success': false,
        'message': 'Izin lokasi ditolak permanen. Ubah lewat pengaturan perangkat.',
      };
    }

    Position? position;

    try {
      position = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    position ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );

    String locationName =
        'Koordinat aktif: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[
          if ((place.subLocality ?? '').isNotEmpty) place.subLocality!,
          if ((place.locality ?? '').isNotEmpty) place.locality!,
          if ((place.administrativeArea ?? '').isNotEmpty)
            place.administrativeArea!,
          if ((place.country ?? '').isNotEmpty) place.country!,
        ];

        if (parts.isNotEmpty) {
          locationName = parts.join(', ');
        }
      }
    } catch (_) {
      // fallback tetap pakai koordinat
    }

    return {
      'success': true,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'location_name': locationName,
    };
  }
}
