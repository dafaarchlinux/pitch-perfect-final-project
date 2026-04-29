import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/location_service.dart';
import '../../../services/nearby_music_store_service.dart';
import 'package:maps_launcher/maps_launcher.dart';

class NearbyStoreScreen extends StatefulWidget {
  const NearbyStoreScreen({super.key});

  @override
  State<NearbyStoreScreen> createState() => _NearbyStoreScreenState();
}

class _NearbyStoreScreenState extends State<NearbyStoreScreen> {
  bool isLoadingLocation = true;
  bool isLoadingStores = false;

  String locationText = 'Mendeteksi lokasi kamu...';
  String errorText = '';

  double? latitude;
  double? longitude;

  List<Map<String, dynamic>> stores = [];

  @override
  void initState() {
    super.initState();
    _loadLocationFast();
  }

  Future<void> _loadLocationFast() async {
    setState(() {
      isLoadingLocation = true;
      errorText = '';
    });

    final locationResult = await LocationService.getCurrentLocation();

    if (!mounted) return;

    if (locationResult['success'] != true) {
      setState(() {
        locationText =
            locationResult['message'] ?? 'Lokasi belum berhasil dibaca';
        isLoadingLocation = false;
      });
      return;
    }

    setState(() {
      latitude = locationResult['latitude'];
      longitude = locationResult['longitude'];
      locationText =
          locationResult['location_name'] ?? 'Lokasi berhasil didapat';
      isLoadingLocation = false;
    });

    _loadNearbyStores();
  }

  Future<void> _loadNearbyStores() async {
    if (latitude == null || longitude == null) return;

    setState(() {
      isLoadingStores = true;
      errorText = '';
    });

    final nearbyResult = await NearbyMusicStoreService.getNearbyStores(
      latitude: latitude!,
      longitude: longitude!,
    );

    if (!mounted) return;

    if (nearbyResult['success'] == true) {
      final rawStores = List<Map<String, dynamic>>.from(
        nearbyResult['stores'] ?? [],
      );

      setState(() {
        stores = rawStores;
        isLoadingStores = false;
      });
    } else {
      setState(() {
        errorText =
            nearbyResult['message'] ??
            'Belum berhasil mengambil tempat musik terdekat';
        isLoadingStores = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadLocationFast();
  }

  Future<void> _openStoreInMaps(Map<String, dynamic> store) async {
    final lat = store['lat'];
    final lon = store['lon'];
    final name = (store['name'] ?? 'Tempat Musik').toString();

    if (lat is double && lon is double) {
      await MapsLauncher.launchCoordinates(lat, lon, name);
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (latitude != null && longitude != null) {
      markers.add(
        Marker(
          point: LatLng(latitude!, longitude!),
          width: 54,
          height: 54,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 22),
          ),
        ),
      );
    }

    for (final store in stores) {
      final lat = store['lat'];
      final lon = store['lon'];

      if (lat is double && lon is double) {
        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 40,
            height: 40,
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFFF4D6D),
              size: 34,
            ),
          ),
        );
      }
    }

    return markers;
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final name = (store['name'] ?? 'Tempat Musik').toString();
    final type = (store['type'] ?? 'Music Place').toString();
    final address = ((store['address'] ?? '').toString().trim().isEmpty)
        ? locationText
        : store['address'].toString();
    final distanceText = (store['distance_text'] ?? '').toString();

    return InkWell(
      onTap: () => _openStoreInMaps(store),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FB),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.store_mall_directory_rounded,
                color: Color(0xFF7C4DFF),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF23263A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7C7E8A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5E35B1),
                          ),
                        ),
                      ),
                      if (distanceText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            distanceText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0072FF),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Color _bgColor = Color(0xFFFCFCFE);

  @override
  Widget build(BuildContext context) {
    final canShowMap = latitude != null && longitude != null;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tempat Musik Terdekat',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
            children: [
              const Text(
                'Temukan toko alat musik, studio musik, karaoke, kursus musik, dan layanan audio yang relevan di sekitar lokasimu.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7C7E8A),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        locationText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF23263A),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                    if (isLoadingLocation)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 280,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: canShowMap
                    ? FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(latitude!, longitude!),
                          initialZoom: 11.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.pitch_perfect',
                          ),
                          MarkerLayer(markers: _buildMarkers()),
                        ],
                      )
                    : Container(
                        color: const Color(0xFFEDE9FE),
                        alignment: Alignment.center,
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Map akan tampil setelah lokasi berhasil dibaca.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5E35B1),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Toko & Layanan Musik Terdekat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF23263A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isLoadingStores
                    ? 'Mencari toko alat musik, studio, dan kursus musik terdekat...'
                    : 'Menampilkan hasil dari data lokasi nyata yang paling relevan dengan kebutuhan musik.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7C7E8A),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              if (isLoadingStores)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mencari toko dan layanan musik terdekat...',
                          style: TextStyle(
                            color: Color(0xFF23263A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (errorText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (!isLoadingStores && stores.isEmpty && errorText.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Belum ditemukan toko alat musik atau layanan musik yang tercatat di area ini. Coba refresh atau buka Google Maps untuk pencarian langsung.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              ...stores.map(_buildStoreCard),
            ],
          ),
        ),
      ),
    );
  }
}
