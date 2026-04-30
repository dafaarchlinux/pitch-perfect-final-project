import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const Color _bgColor = Color(0xFF0F1020);
  static const Color _surface = Color(0xFF1A1B2E);
  static const Color _surfaceSoft = Color(0xFF232542);
  static const Color _border = Color(0xFF2D3050);
  static const Color _textLight = Color(0xFFF8FAFC);
  static const Color _textSoft = Color(0xFFB8BCD7);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _pink = Color(0xFFF472B6);
  static const Color _green = Color(0xFF34D399);

  List<BoxShadow> _softGlow(
    Color color, {
    double opacity = 0.16,
    double blur = 24,
    double y = 10,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.30),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ];
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required List<Color> gradientColors,
    required String routeName,
  }) {
    final glowColor = gradientColors.last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, routeName),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withValues(alpha: 0.72))
                  .toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: _softGlow(glowColor, opacity: 0.16, blur: 24, y: 10),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _surface.withValues(alpha: 0.96),
                  _surfaceSoft.withValues(alpha: 0.90),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _softGlow(glowColor, opacity: 0.18, blur: 18),
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
                          color: glowColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: glowColor.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: glowColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textLight,
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
                        style: const TextStyle(
                          color: _textSoft,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
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
                    color: glowColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: glowColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: glowColor,
                    size: 16,
                  ),
                ),
              ],
            ),
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
        color: _surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: _softGlow(color, opacity: 0.07, blur: 16, y: 7),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.16)),
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
                    color: _textLight,
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
                    fontWeight: FontWeight.w600,
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
              color: _textLight,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: _textSoft,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17182C), Color(0xFF251640), Color(0xFF122637)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
        boxShadow: _softGlow(_cyan, opacity: 0.10, blur: 22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_purple, _cyan, _pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Text(
              'Kelola kebutuhan latihan musikmu dalam satu tempat: lokasi, rencana alat, dan jadwal latihan.',
              style: TextStyle(
                fontSize: 14,
                color: _textSoft,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
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
            color: _textLight,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: _textLight),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
          children: [
            _buildIntroCard(),
            const SizedBox(height: 18),
            _buildSectionHeader(
              'Tools',
              'Pilih fitur yang ingin kamu gunakan.',
            ),
            _buildToolCard(
              context: context,
              title: 'Tempat Musik',
              subtitle:
                  'Temukan toko musik, studio, kursus, dan layanan audio di sekitar kamu.',
              badge: 'Lokasi',
              icon: Icons.location_on_rounded,
              gradientColors: const [_purple, _pink],
              routeName: '/nearby',
            ),
            _buildToolCard(
              context: context,
              title: 'Rencana Alat Musik',
              subtitle:
                  'Simpan alat musik incaran dan lihat estimasi biayanya dalam berbagai mata uang.',
              badge: 'Biaya Alat',
              icon: Icons.piano_rounded,
              gradientColors: const [_cyan, _purple],
              routeName: '/instrument-prices',
            ),
            _buildToolCard(
              context: context,
              title: 'Jadwal Latihan',
              subtitle:
                  'Atur jadwal latihan, target belajar, zona waktu, dan reminder.',
              badge: 'Reminder',
              icon: Icons.schedule_rounded,
              gradientColors: const [_green, _cyan],
              routeName: '/scheduler',
            ),
            _buildToolCard(
              context: context,
              title: 'Referensi Musik',
              subtitle:
                  'Cari lagu sebagai bahan latihan vokal, gitar, piano, dan ear training.',
              badge: 'Referensi Musik',
              icon: Icons.library_music_rounded,
              gradientColors: const [_pink, _purple],
              routeName: '/music-reference',
            ),
            _buildSectionHeader(
              'Pendukung',
              'Fitur tambahan untuk membuat latihan lebih terarah.',
            ),
            _buildMiniInfo(
              icon: Icons.currency_exchange_rounded,
              title: 'Biaya Alat',
              subtitle:
                  'Lihat estimasi harga alat musik dengan konversi mata uang.',
              color: _purple,
            ),
            const SizedBox(height: 12),
            _buildMiniInfo(
              icon: Icons.schedule_rounded,
              title: 'Pengingat Latihan',
              subtitle:
                  'Simpan jadwal latihan dan aktifkan notifikasi pengingat.',
              color: _green,
            ),
          ],
        ),
      ),
    );
  }
}
