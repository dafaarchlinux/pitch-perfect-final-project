import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await NotificationService.init();
  runApp(const PitchPerfectApp());
}

class PitchPerfectApp extends StatelessWidget {
  const PitchPerfectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pitch Perfect',
      theme: AppTheme.lightTheme,
      routes: AppRoutes.routes,
      home: const SplashScreen(),
    );
  }
}
