import 'package:flutter/material.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/feedback/feedback_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/notifications/notification_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/ai_coach/ai_coach_screen.dart';
import '../../features/tools/nearby_store/nearby_store_screen.dart';
import '../../features/tools/class_scheduler/class_scheduler_screen.dart';
import '../../features/tools/instrument_prices/instrument_prices_screen.dart';
import '../../features/tools/music_reference/music_reference_screen.dart';
import '../../widgets/main_bottom_nav.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/home': (context) => const MainBottomNav(),
    '/feedback': (context) => const FeedbackScreen(),
    '/history': (context) => const HistoryScreen(),
    '/notifications': (context) => const NotificationScreen(),
    '/search': (context) => const SearchScreen(),
    '/ai-coach': (context) => const AICoachScreen(),
    '/nearby': (context) => const NearbyStoreScreen(),
    '/instrument-prices': (context) => const InstrumentPricesScreen(),
    '/scheduler': (context) => const ClassSchedulerScreen(),
    '/music-reference': (context) => const MusicReferenceScreen(),
  };
}
