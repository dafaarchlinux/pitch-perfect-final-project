import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/practice_progress_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool isSending = false;

  Future<void> _sendNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    if (isSending) return;

    setState(() => isSending = true);

    await NotificationService.showPracticeReminder(title: title, body: body);

    await PracticeProgressService.addPracticeSession(
      title: title,
      type: type,
      score: null,
      level: null,
      combo: null,
      passed: true,
      metadata: {
        'notification_title': title,
        'notification_body': body,
        'source': 'Notification Center',
      },
    );

    if (!mounted) return;

    setState(() => isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifikasi dikirim: $title'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildReminderCard({
    required IconData icon,
    required String title,
    required String body,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF20243A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: isSending ? null : onTap,
                    icon: const Icon(
                      Icons.notifications_active_rounded,
                      size: 18,
                    ),
                    label: Text(buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const Color _bgColor = Color(0xFFFCFCFE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notification Center',
          style: TextStyle(
            color: Color(0xFF20243A),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF20243A)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          children: [
            const Text(
              'Atur dan coba pengingat latihan Pitch Perfect. Notifikasi akan muncul di Android notification tray.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF7C7E8A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF5E35B1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Pengingat Musik',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gunakan notifikasi untuk mengingat latihan, jadwal practice, dan target mingguan.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildReminderCard(
              icon: Icons.graphic_eq_rounded,
              title: 'Pengingat Latihan Nada',
              body:
                  'Cocok untuk mengingatkan user membuka Detect atau Repeat Pitch.',
              buttonText: 'Kirim Reminder',
              color: const Color(0xFF7C4DFF),
              onTap: () => _sendNotification(
                title: 'Waktunya latihan nada',
                body:
                    'Buka Pitch Perfect dan lanjutkan latihan Detect atau Repeat Pitch hari ini.',
                type: 'Notifikasi Latihan',
              ),
            ),
            _buildReminderCard(
              icon: Icons.calendar_month_rounded,
              title: 'Pengingat Jadwal Latihan',
              body:
                  'Dipakai untuk jadwal dari Smart Practice Scheduler dan kelas privat.',
              buttonText: 'Kirim Pengingat Jadwal',
              color: const Color(0xFF00A86B),
              onTap: () => _sendNotification(
                title: 'Jadwal latihan sudah dekat',
                body:
                    'Cek Smart Practice Scheduler dan siapkan sesi latihan musikmu.',
                type: 'Notifikasi Jadwal',
              ),
            ),
            _buildReminderCard(
              icon: Icons.emoji_events_rounded,
              title: 'Target Mingguan',
              body:
                  'Mendorong user agar konsisten latihan dan progresnya tercatat.',
              buttonText: 'Kirim Target',
              color: const Color(0xFFFF8A65),
              onTap: () => _sendNotification(
                title: 'Kejar target mingguanmu',
                body:
                    'Selesaikan latihan musik minggu ini agar progress Profile makin naik.',
                type: 'Notifikasi Target',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
