import 'package:flutter/material.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  static const Color _bgColor = Color(0xFF0F1020);
  static const Color _textLight = Color(0xFFF8FAFC);
  static const Color _textSoft = Color(0xFFB8BCD7);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _pink = Color(0xFFF472B6);
  static const Color _green = Color(0xFF34D399);

  final PageController _pageController = PageController(viewportFraction: 0.82);
  int _currentIndex = 0;

  final List<_ToolFlashCardData> _tools = const [
    _ToolFlashCardData(
      title: 'Tempat\nMusik',
      subtitle: 'Cari toko musik, studio, kursus, dan layanan audio terdekat.',
      badge: 'Lokasi',
      icon: Icons.location_on_rounded,
      backgroundIcon: Icons.location_on_rounded,
      gradientColors: [_purple, _pink],
      iconColor: _purple,
      routeName: '/nearby',
    ),
    _ToolFlashCardData(
      title: 'Rencana\nAlat',
      subtitle: 'Simpan wishlist alat musik dan cek estimasi biayanya.',
      badge: 'Biaya Alat',
      icon: Icons.piano_rounded,
      backgroundIcon: Icons.piano_rounded,
      gradientColors: [_cyan, _purple],
      iconColor: _cyan,
      routeName: '/instrument-prices',
    ),
    _ToolFlashCardData(
      title: 'Jadwal\nLatihan',
      subtitle: 'Atur jadwal belajar, target latihan, zona waktu, dan reminder.',
      badge: 'Reminder',
      icon: Icons.calendar_month_rounded,
      backgroundIcon: Icons.calendar_month_rounded,
      gradientColors: [_green, _cyan],
      iconColor: _green,
      routeName: '/scheduler',
    ),
    _ToolFlashCardData(
      title: 'Referensi\nMusik',
      subtitle: 'Cari lagu untuk bahan latihan vokal dan instrumen.',
      badge: 'Referensi',
      icon: Icons.music_note_rounded,
      backgroundIcon: Icons.music_note_rounded,
      gradientColors: [_pink, _purple],
      iconColor: _pink,
      routeName: '/music-reference',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<BoxShadow> _softGlow(Color color) {
    return [
      BoxShadow(
        color: color.withOpacity(0.28),
        blurRadius: 34,
        offset: const Offset(0, 18),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.38),
        blurRadius: 24,
        offset: const Offset(0, 14),
      ),
    ];
  }

  void _openTool(_ToolFlashCardData item) {
    Navigator.pushNamed(context, item.routeName);
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(top: 18),
      child: Column(
        children: [
          Text(
            'Tools Musik',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textLight,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Geser untuk memilih fitur.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSoft,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_ToolFlashCardData item, int index) {
    final isActive = index == _currentIndex;

    return AnimatedScale(
      scale: isActive ? 1.0 : 0.92,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: () => _openTool(item),
        borderRadius: BorderRadius.circular(42),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(42),
            boxShadow: isActive ? _softGlow(item.gradientColors.last) : [],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -42,
                top: -42,
                child: Transform.rotate(
                  angle: -0.18,
                  child: Icon(
                    item.backgroundIcon,
                    size: 220,
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 22,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      item.icon,
                      color: item.iconColor,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Text(
                        'KETUK UNTUK BUKA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: _tools.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 26),
            child: _buildCard(_tools[index], index),
          );
        },
      ),
    );
  }

  Widget _buildIndicators() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_tools.length, (index) {
          final active = _currentIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? _cyan : const Color(0xFF2D3050),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCarousel(),
            _buildIndicators(),
          ],
        ),
      ),
    );
  }
}

class _ToolFlashCardData {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final IconData backgroundIcon;
  final List<Color> gradientColors;
  final Color iconColor;
  final String routeName;

  const _ToolFlashCardData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.backgroundIcon,
    required this.gradientColors,
    required this.iconColor,
    required this.routeName,
  });
}
