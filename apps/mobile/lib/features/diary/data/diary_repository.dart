import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

part 'diary_repository.g.dart';

/// Repository for diary operations (Local Storage)
class DiaryRepository {
  DiaryRepository();

  static const String _boxName = 'diaries';
  Box<Diary>? _box;

  Future<void> _init() async {
    if (_box != null && _box!.isOpen) return;

    // Get encryption key
    const secureStorage = FlutterSecureStorage();
    final encryptionKeyString = await secureStorage.read(key: 'diary_encryption_key');
    
    List<int> encryptionKey;
    if (encryptionKeyString == null) {
      // Should satisfy 32 byte key for AES
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'diary_encryption_key',
        value: base64UrlEncode(key),
      );
      encryptionKey = key;
    } else {
      encryptionKey = base64Url.decode(encryptionKeyString);
    }

    _box = await Hive.openBox<Diary>(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  /// Get diaries filtering by date range
  Future<List<Diary>> getDiaries({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _init();
    
    var entries = _box!.values.toList();
    
    if (startDate != null) {
      // Normalize start date to beginning of day
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      entries = entries.where((d) => d.createdAt.compareTo(start) >= 0).toList();
    }
    
    if (endDate != null) {
      // Normalize end date to end of day
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      entries = entries.where((d) => d.createdAt.compareTo(end) <= 0).toList();
    }
    
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Get diaries with cursor-based pagination for infinite scroll
  /// [fromDate] - Reference date to start from
  /// [limit] - Number of entries to fetch
  /// [loadOlder] - If true, load entries older than fromDate; if false, load newer
  Future<List<Diary>> getDiariesPaginated({
    required DateTime fromDate,
    required int limit,
    bool loadOlder = true,
  }) async {
    await _init();
    
    var entries = _box!.values.toList();
    
    if (loadOlder) {
      // Get entries older than or equal to fromDate
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day, 23, 59, 59, 999);
      entries = entries.where((d) => d.createdAt.compareTo(from) <= 0).toList();
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
    } else {
      // Get entries newer than fromDate
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
      entries = entries.where((d) => d.createdAt.compareTo(from) > 0).toList();
      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Oldest first (then reverse for display)
    }
    
    final result = entries.take(limit).toList();
    
    // For newer entries, reverse to maintain newest-first order for display
    if (!loadOlder) {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    return result;
  }

  /// Get distinct dates that have entries (for calendar markers)
  Future<List<DateTime>> getDatesWithEntries() async {
    await _init();
    final dates = _box!.values.map((e) {
      return DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    }).toSet().toList();
    return dates;
  }

  /// Get a single diary by ID
  Future<Diary> getDiary(String id) async {
    await _init();
    final diary = _box!.values.firstWhere(
      (d) => d.id == id,
      orElse: () => throw Exception('Diary not found'),
    );
    return diary;
  }

  /// Create a new diary
  Future<Diary> createDiary({
    required String userId,
    required String content,
    String? mood,
    Weather? weather,
    List<DiarySource>? sources,
    List<String>? photos,
    bool isAiGenerated = false,
  }) async {
    await _init();
    
    final now = DateTime.now();
    final id = const Uuid().v4();
    
    final newDiary = Diary(
      id: id,
      userId: userId, // Can be dummy "me"
      content: content,
      mood: mood,
      weather: weather,
      sources: sources ?? [],
      photos: photos ?? [],
      isAiGenerated: isAiGenerated,
      createdAt: now,
      updatedAt: now,
      editCount: 0,
    );

    await _box!.put(id, newDiary);
    return newDiary;
  }

  /// Update a diary
  Future<Diary> updateDiary({
    required String id,
    String? content,
    String? mood,
    Weather? weather,
    List<DiarySource>? sources,
    List<String>? photos,
    bool? isAiGenerated,
    bool incrementEditCount = false,
  }) async {
    await _init();
    final existingDiary = await getDiary(id);
    
    final updatedDiary = existingDiary.copyWith(
      content: content ?? existingDiary.content,
      mood: mood ?? existingDiary.mood,
      weather: weather ?? existingDiary.weather,
      sources: sources ?? existingDiary.sources,
      photos: photos ?? existingDiary.photos,
      isAiGenerated: isAiGenerated ?? existingDiary.isAiGenerated,
      updatedAt: DateTime.now(),
      editCount: incrementEditCount ? existingDiary.editCount + 1 : existingDiary.editCount,
    );

    await _box!.put(id, updatedDiary);
    return updatedDiary;
  }

  /// Delete a diary
  Future<void> deleteDiary(String id) async {
    await _init();
    await _box!.delete(id);
  }

  /// Get diary from 1 year ago
  Future<Diary?> getYearAgoMemory(String userId) async {
    await _init();
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    
    try {
      return _box!.values.firstWhere(
        (diary) {
          final d = diary.createdAt;
          return d.year == oneYearAgo.year && 
                 d.month == oneYearAgo.month && 
                 d.day == oneYearAgo.day;
        },
      );
    } catch (_) {
      return null;
    }
  }

  /// Export all data to JSON string
  Future<String> exportData() async {
    await _init();
    final allDiaries = _box!.values.toList();
    final List<Map<String, dynamic>> jsonList = 
        allDiaries.map((d) => d.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Import data from JSON string
  Future<int> importData(String jsonString) async {
    await _init();
    final List<dynamic> jsonList = jsonDecode(jsonString);
    var count = 0;

    for (final json in jsonList) {
      try {
        if (json is Map<String, dynamic>) {
          final diary = Diary.fromJson(json);
          // Upsert based on ID
          await _box!.put(diary.id, diary);
          count++;
        }
      } catch (e) {
        // Skip invalid entries
        print('Error importing entry: $e');
      }
    }
    return count;
  }

  /// Delete ALL data (for App Lock Recovery)
  Future<void> clearAllData() async {
    await _init();
    await _box!.clear();
  }
}

@riverpod
DiaryRepository diaryRepository(Ref ref) {
  return DiaryRepository();
}
