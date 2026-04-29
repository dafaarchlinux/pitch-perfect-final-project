import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'pitch_perfect_alarm_v2';

  static const AndroidNotificationChannel _practiceChannel =
      AndroidNotificationChannel(
        _channelId,
        'Pitch Perfect Reminder',
        description: 'Reminder jadwal latihan musik Pitch Perfect.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final timezoneName = timezoneInfo.identifier.toString();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      // Fallback kalau timezone perangkat tidak terbaca.
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings: initializationSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_practiceChannel);
    await androidPlugin?.requestNotificationsPermission();

    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {
      // Beberapa Android tidak menampilkan dialog exact alarm dari sini.
    }
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        _channelId,
        'Pitch Perfect Reminder',
        channelDescription: 'Reminder jadwal latihan musik Pitch Perfect.',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        ticker: 'Pitch Perfect',
      );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
  );

  static Future<void> showPracticeReminder({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: _notificationDetails,
    );
  }

  static Future<void> schedulePracticeReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final now = DateTime.now();

    final safeSchedule = scheduledAt.isBefore(now)
        ? now.add(const Duration(seconds: 20))
        : scheduledAt;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(safeSchedule, tz.local),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }
}
