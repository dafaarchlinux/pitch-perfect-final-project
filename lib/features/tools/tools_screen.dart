import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const Color _bgColor = Color(0xFFFCFCFE);
  static const Color _textDark = Color(0xFF20243A);
  static const Color _textSoft = Color(0xFF7C7E8A);

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required List<Color> gradientColors,
    required String routeName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, routeName),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSoft,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: _textSoft,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tools Musik',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: _textDark),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFE9E9F3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF7C4DFF),
                    size: 26,
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'Pusat fitur pendukung musik untuk mencari tempat latihan, merencanakan pembelian alat, dan membuat jadwal latihan dengan reminder otomatis.',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSoft,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildSectionHeader(
              'Fitur Utama',
              'Pilih tools yang kamu butuhkan untuk mendukung latihan musik harian.',
            ),
            _buildToolCard(
              context: context,
              title: 'Tempat Musik Terdekat',
              subtitle:
                  'Cari toko alat musik, studio musik, karaoke, kursus musik, dan layanan audio terdekat berdasarkan lokasimu.',
              badge: 'Maps & Lokasi',
              icon: Icons.location_on_rounded,
              gradientColors: const [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
              routeName: '/nearby',
            ),
            _buildToolCard(
              context: context,
              title: 'Rencana Beli Alat Musik',
              subtitle:
                  'Pilih alat musik yang diminati, lihat estimasi biaya dengan kurs live, lalu simpan minat untuk rekomendasi latihan.',
              badge: 'Kurs Live & Minat',
              icon: Icons.piano_rounded,
              gradientColors: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
              routeName: '/instrument-prices',
            ),
            _buildToolCard(
              context: context,
              title: 'Smart Practice Scheduler',
              subtitle:
                  'Buat jadwal latihan pribadi, pilih target belajar, atur zona waktu, dan aktifkan reminder otomatis.',
              badge: 'Jadwal & Reminder',
              icon: Icons.schedule_rounded,
              gradientColors: const [Color(0xFF00A86B), Color(0xFF007A5A)],
              routeName: '/scheduler',
            ),
            _buildSectionHeader(
              'Ringkasan',
              'Tools ini membantu kebutuhan utama aplikasi: lokasi musik, estimasi biaya alat, dan jadwal latihan.',
            ),
            _buildMiniInfo(
              icon: Icons.currency_exchange_rounded,
              title: 'Estimasi Biaya',
              subtitle:
                  'Bandingkan estimasi harga alat musik dalam banyak mata uang.',
              color: const Color(0xFF7C4DFF),
            ),
            const SizedBox(height: 12),
            _buildMiniInfo(
              icon: Icons.schedule_rounded,
              title: 'Reminder Latihan',
              subtitle:
                  'Buat jadwal latihan dengan tanggal, zona waktu, dan notifikasi.',
              color: const Color(0xFF00A86B),
            ),
          ],
        ),
      ),
    );
  }
}
