import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_service.dart';

class PracticeProgressService {
  static const String _boxName = 'pitch_perfect_database';
  static const String _historyKey = 'practice_history';
  static const String _instrumentInterestsKey = 'instrument_interests';
  static const String _gameRecordsKey = 'game_records';
  static const String _practiceSchedulesKey = 'practice_schedules';
  static const String _migrationKey = 'practice_history_migrated_to_hive';
  static const String _instrumentMigrationKey =
      'instrument_interests_migrated_to_hive';
  static const String _legacyInstrumentInterestsKey =
      'saved_instrument_interests';
  static const String _gameRecordsMigrationKey =
      'game_records_migrated_to_hive';
  static const String _practiceSchedulesMigrationKey =
      'practice_schedules_migrated_to_hive';
  static const String _legacyPracticeSchedulesKey = 'smart_practice_schedules';

  static String _safeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_\$'), '');
  }

  static Future<Box> _openBox() async {
    final email = await SessionService.getUserEmail();
    final username = await SessionService.getUserUsername();
    final rawIdentity = email.trim().isNotEmpty && email != 'guest@email.com'
        ? email
        : username;

    final identity = _safeKey(rawIdentity);
    final scopedBoxName = identity.isEmpty ? _boxName : '${_boxName}_$identity';

    return Hive.openBox(scopedBoxName);
  }

  static Future<String> _currentOwnerId() async {
    final email = await SessionService.getUserEmail();
    final username = await SessionService.getUserUsername();

    final rawIdentity = email.trim().isNotEmpty && email != 'guest@email.com'
        ? email
        : username;

    return _safeKey(rawIdentity);
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

  static Future<void> _migrateOldPracticeSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_practiceSchedulesMigrationKey) ?? false;

    if (migrated) return;

    final oldRaw = prefs.getString(_legacyPracticeSchedulesKey);
    if (oldRaw == null || oldRaw.trim().isEmpty) {
      await prefs.setBool(_practiceSchedulesMigrationKey, true);
      return;
    }

    try {
      final decoded = jsonDecode(oldRaw);
      if (decoded is! List) {
        await prefs.setBool(_practiceSchedulesMigrationKey, true);
        return;
      }

      final oldSchedules = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final box = await _openBox();
      final existingRaw = box.get(_practiceSchedulesKey);
      final existingSchedules = existingRaw is List
          ? existingRaw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (existingSchedules.isEmpty && oldSchedules.isNotEmpty) {
        await box.put(_practiceSchedulesKey, oldSchedules);
      }

      await prefs.setBool(_practiceSchedulesMigrationKey, true);
    } catch (_) {
      await prefs.setBool(_practiceSchedulesMigrationKey, true);
    }
  }

  static Future<void> _migrateOldGameRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_gameRecordsMigrationKey) ?? false;

    if (migrated) return;

    final oldBestScore = prefs.getInt('game_best_score') ?? 0;
    final oldBestLevel = prefs.getInt('game_best_level') ?? 0;
    final oldBestCombo = prefs.getInt('game_best_combo') ?? 0;

    final box = await _openBox();
    final existingRaw = box.get(_gameRecordsKey);

    if (existingRaw is! Map) {
      await box.put(_gameRecordsKey, {
        'best_score': oldBestScore,
        'best_level': oldBestLevel,
        'best_combo': oldBestCombo,
        'updated_at': DateTime.now().toIso8601String(),
        'storage': 'Hive',
      });
    }

    await prefs.setBool(_gameRecordsMigrationKey, true);
  }

  static Future<void> _migrateOldInstrumentInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_instrumentMigrationKey) ?? false;

    if (migrated) return;

    final oldRaw = prefs.getString(_legacyInstrumentInterestsKey);
    if (oldRaw == null || oldRaw.trim().isEmpty) {
      await prefs.setBool(_instrumentMigrationKey, true);
      return;
    }

    try {
      final decoded = jsonDecode(oldRaw);
      if (decoded is! List) {
        await prefs.setBool(_instrumentMigrationKey, true);
        return;
      }

      final oldInterests = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final box = await _openBox();
      final existingRaw = box.get(_instrumentInterestsKey);
      final existingInterests = existingRaw is List
          ? existingRaw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (existingInterests.isEmpty && oldInterests.isNotEmpty) {
        await box.put(_instrumentInterestsKey, oldInterests);
      }

      await prefs.setBool(_instrumentMigrationKey, true);
    } catch (_) {
      await prefs.setBool(_instrumentMigrationKey, true);
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

    final ownerId = await _currentOwnerId();

    history.insert(0, {
      'title': title,
      'type': type,
      'score': score,
      'level': level,
      'combo': combo,
      'passed': passed,
      'metadata': metadata ?? {},
      'owner_id': ownerId,
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

    final ownerId = await _currentOwnerId();

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
          final itemOwner = item['owner_id']?.toString();

          if (itemOwner == null || itemOwner.isEmpty) {
            return false;
          }

          return itemOwner == ownerId;
        })
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

  static Future<List<Map<String, dynamic>>> getPracticeSchedules() async {
    await _migrateOldPracticeSchedules();

    final box = await _openBox();
    final raw = box.get(_practiceSchedulesKey);

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> savePracticeSchedules(
    List<Map<String, dynamic>> schedules,
  ) async {
    await _migrateOldPracticeSchedules();

    final box = await _openBox();
    await box.put(_practiceSchedulesKey, schedules);
  }

  static Future<Map<String, int>> getGameRecords() async {
    await _migrateOldGameRecords();

    final box = await _openBox();
    final raw = box.get(_gameRecordsKey);

    if (raw is! Map) {
      return {'best_score': 0, 'best_level': 0, 'best_combo': 0};
    }

    return {
      'best_score': raw['best_score'] is int ? raw['best_score'] as int : 0,
      'best_level': raw['best_level'] is int ? raw['best_level'] as int : 0,
      'best_combo': raw['best_combo'] is int ? raw['best_combo'] as int : 0,
    };
  }

  static Future<void> updateGameRecords({
    required int score,
    required int level,
    required int combo,
  }) async {
    await _migrateOldGameRecords();

    final box = await _openBox();
    final records = await getGameRecords();

    final bestScore = score > records['best_score']!
        ? score
        : records['best_score']!;
    final bestLevel = level > records['best_level']!
        ? level
        : records['best_level']!;
    final bestCombo = combo > records['best_combo']!
        ? combo
        : records['best_combo']!;

    await box.put(_gameRecordsKey, {
      'best_score': bestScore,
      'best_level': bestLevel,
      'best_combo': bestCombo,
      'updated_at': DateTime.now().toIso8601String(),
      'storage': 'Hive',
    });
  }

  static Future<List<Map<String, dynamic>>> getInstrumentInterests() async {
    await _migrateOldInstrumentInterests();

    final box = await _openBox();
    final raw = box.get(_instrumentInterestsKey);

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> saveInstrumentInterests(
    List<Map<String, dynamic>> interests,
  ) async {
    await _migrateOldInstrumentInterests();

    final box = await _openBox();
    await box.put(_instrumentInterestsKey, interests);
  }

  static Future<void> updateHistoryItem({
    required String createdAt,
    required String title,
    required String type,
    int? score,
    int? level,
    int? combo,
    bool? passed,
    Map<String, dynamic>? metadata,
  }) async {
    final box = await _openBox();
    final history = await getHistory();

    final index = history.indexWhere((item) {
      return item['created_at']?.toString() == createdAt;
    });

    if (index == -1) return;

    history[index] = {
      ...history[index],
      'title': title,
      'type': type,
      'score': score,
      'level': level,
      'combo': combo,
      'passed': passed,
      'metadata': metadata ?? {},
      'updated_at': DateTime.now().toIso8601String(),
      'storage': 'Hive',
    };

    await box.put(_historyKey, history);
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
