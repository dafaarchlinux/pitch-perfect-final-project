import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeProgressService {
  static const String _boxName = 'pitch_perfect_database';
  static const String _historyKey = 'practice_history';
  static const String _migrationKey = 'practice_history_migrated_to_hive';

  static Future<Box> _openBox() async {
    return Hive.openBox(_boxName);
  }

  static Future<void> _migrateOldSharedPreferencesHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_migrationKey) ?? false;

    if (migrated) return;

    final oldRaw = prefs.getString(_historyKey);
    if (oldRaw == null || oldRaw.trim().isEmpty) {
      await prefs.setBool(_migrationKey, true);
      return;
    }

    try {
      final decoded = jsonDecode(oldRaw);
      if (decoded is! List) {
        await prefs.setBool(_migrationKey, true);
        return;
      }

      final oldHistory = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final box = await _openBox();
      final existingRaw = box.get(_historyKey);

      final existingHistory = existingRaw is List
          ? existingRaw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (existingHistory.isEmpty && oldHistory.isNotEmpty) {
        await box.put(_historyKey, oldHistory);
      }

      await prefs.setBool(_migrationKey, true);
    } catch (_) {
      await prefs.setBool(_migrationKey, true);
    }
  }

  static Future<void> addPracticeSession({
    required String title,
    required String type,
    int? score,
    int? level,
    int? combo,
    bool? passed,
    Map<String, dynamic>? metadata,
  }) async {
    await _migrateOldSharedPreferencesHistory();

    final box = await _openBox();
    final history = await getHistory();

    history.insert(0, {
      'title': title,
      'type': type,
      'score': score,
      'level': level,
      'combo': combo,
      'passed': passed,
      'metadata': metadata ?? {},
      'created_at': DateTime.now().toIso8601String(),
      'storage': 'Hive',
    });

    await box.put(_historyKey, history);
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    await _migrateOldSharedPreferencesHistory();

    final box = await _openBox();
    final raw = box.get(_historyKey);

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> getSummary() async {
    final history = await getHistory();

    final scoredSessions = history
        .where((item) => item['score'] is int)
        .map((item) => item['score'] as int)
        .toList();

    final averageScore = scoredSessions.isEmpty
        ? null
        : (scoredSessions.reduce((a, b) => a + b) / scoredSessions.length)
              .round();

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final weeklySessions = history.where((item) {
      final rawDate = item['created_at']?.toString();
      if (rawDate == null) return false;

      final date = DateTime.tryParse(rawDate);
      if (date == null) return false;

      return date.isAfter(sevenDaysAgo);
    }).length;

    return {
      'total_sessions': history.length,
      'average_score': averageScore,
      'weekly_sessions': weeklySessions,
      'storage': 'Hive',
    };
  }

  static Future<void> deleteHistoryItem(String createdAt) async {
    final box = await _openBox();
    final history = await getHistory();

    history.removeWhere((item) => item['created_at']?.toString() == createdAt);

    await box.put(_historyKey, history);
  }

  static Future<void> clearHistory() async {
    final box = await _openBox();
    await box.delete(_historyKey);
  }
}
