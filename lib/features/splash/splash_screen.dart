import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../../widgets/main_bottom_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 550));

    final loggedIn = await SessionService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainBottomNav()),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D22),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 138,
                  height: 138,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
                        blurRadius: 38,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.14),
                        blurRadius: 46,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/pitch_perfect_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Pitch Perfect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Train smart. Tune better. Perform confidently.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB8BCD7),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 34),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF8B5CF6),
                    backgroundColor: Color(0xFF232542),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
