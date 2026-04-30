import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = const [
    {
      'title': 'Latihan Musik Lebih Terarah',
      'subtitle':
          'Tes vokal, stem gitar, dan pantau progres latihanmu dalam satu aplikasi.',
      'icon': Icons.graphic_eq_rounded,
      'color': Color(0xFF22D3EE),
    },
    {
      'title': 'Tools untuk Musisi',
      'subtitle':
          'Temukan tempat musik, rencanakan alat incaran, dan buat jadwal latihan.',
      'icon': Icons.piano_rounded,
      'color': Color(0xFFF472B6),
    },
    {
      'title': 'AI Coach & Game',
      'subtitle':
          'Dapatkan arahan latihan, pelajari teori musik, dan tingkatkan akurasi nada.',
      'icon': Icons.psychology_rounded,
      'color': Color(0xFF8B5CF6),
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildLogoBadge() {
    return Container(
      width: 132,
      height: 132,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.28),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/pitch_perfect_logo.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFeatureIcon(Map<String, dynamic> page) {
    final color = page['color'] as Color;

    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(page['icon'] as IconData, color: color, size: 34),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF8B5CF6)
                : const Color(0xFF3A3D5F),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D22),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
              child: Row(
                children: [
                  const Text(
                    'Pitch Perfect',
                    style: TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(26, 16, 26, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogoBadge(),
                        const SizedBox(height: 34),
                        _buildFeatureIcon(page),
                        const SizedBox(height: 26),
                        Text(
                          page['title'].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 31,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page['subtitle'].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB8BCD7),
                            fontSize: 15,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildDots(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastPage ? 'Mulai Sekarang' : 'Lanjut',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
