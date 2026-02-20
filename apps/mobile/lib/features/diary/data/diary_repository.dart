
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:mobile/features/diary/data/models/diary.dart';

part 'diary_repository.g.dart';

/// Repository for diary operations (Encrypted Local File Storage)
class DiaryRepository {
  DiaryRepository();

  bool _isInitialized = false;
  late final Directory _diaryDir;
  late final encrypt.Encrypter _encrypter;

  // Key for SecureStorage - distinct from Hive key to correctly start fresh or migrate
  static const _keyStorageName = 'diary_file_aescbc_key';

  Future<void> _init() async {
    if (_isInitialized) return;

    // 1. Setup Directory
    final docsDir = await getApplicationDocumentsDirectory();
    _diaryDir = Directory('${docsDir.path}/diaries');
    if (!await _diaryDir.exists()) {
      await _diaryDir.create(recursive: true);
    }

    // 2. Setup Encryption Key
    const secureStorage = FlutterSecureStorage();
    String? keyString = await secureStorage.read(key: _keyStorageName);
    
    // We need a 32-byte key for AES-256
    List<int> keyBytes;
    if (keyString == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      keyBytes = key.bytes;
      await secureStorage.write(
        key: _keyStorageName,
        value: base64UrlEncode(keyBytes),
      );
    } else {
      keyBytes = base64Url.decode(keyString);
    }

    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
    _isInitialized = true;
  }

  encrypt.IV _generateIV() => encrypt.IV.fromSecureRandom(16);

  String _encryptData(String plainText) {
    final iv = _generateIV();
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String _decryptData(String encryptedString) {
    final parts = encryptedString.split(':');
    if (parts.length != 2) throw Exception('Invalid encrypted format');
    
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    
    return _encrypter.decrypt(encrypted, iv: iv);
  }

  Future<void> _saveDiaryToFile(Diary diary) async {
    final jsonString = jsonEncode(diary.toJson());
    final encryptedString = _encryptData(jsonString);
    
    final file = File('${_diaryDir.path}/${diary.id}.enc');
    await file.writeAsString(encryptedString, flush: true);
  }

  Future<List<Diary>> _getAllDiaries() async {
    final List<Diary> entries = [];
    final List<FileSystemEntity> files = _diaryDir.listSync();
    
    for (final file in files) {
      if (file is File && file.path.endsWith('.enc')) {
        try {
          final setContent = await file.readAsString();
          final jsonString = _decryptData(setContent);
          final entry = Diary.fromJson(jsonDecode(jsonString));
          entries.add(entry);
        } catch (e) {
          print('Error reading/decrypting file ${file.path}: $e');
        }
      }
    }
    // Sort newest first by default
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<List<Diary>> getAllDiaries() async {
    await _init();
    return _getAllDiaries();
  }

  Future<List<Diary>> getDiaries({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _init();
    
    var entries = await _getAllDiaries();
    
    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      entries = entries.where((d) => d.createdAt.compareTo(start) >= 0).toList();
    }
    
    if (endDate != null) {
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      entries = entries.where((d) => d.createdAt.compareTo(end) <= 0).toList();
    }
    
    return entries;
  }

  Future<List<Diary>> getDiariesPaginated({
    required DateTime fromDate,
    required int limit,
    bool loadOlder = true,
  }) async {
    await _init();
    
    var entries = await _getAllDiaries();
    
    if (loadOlder) {
      // Get entries older than or equal to fromDate
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day, 23, 59, 59, 999);
      entries = entries.where((d) => d.createdAt.compareTo(from) <= 0).toList();
      // entries are already sorted newest first
    } else {
      // Get entries newer than fromDate
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
      entries = entries.where((d) => d.createdAt.compareTo(from) > 0).toList();
      // Sort oldest first for "fetching newer", then we take 'limit', then reverse back
      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    final result = entries.take(limit).toList();
    
    if (!loadOlder) {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    return result;
  }

  Future<List<DateTime>> getDatesWithEntries() async {
    await _init();
    final diaries = await _getAllDiaries(); // Optimization: could just parse headers if separate
    final dates = diaries.map((e) {
      return DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    }).toSet().toList();
    return dates;
  }

  Future<Diary> getDiary(String id) async {
    await _init();
    final file = File('${_diaryDir.path}/$id.enc');
    if (!await file.exists()) {
      throw Exception('Diary not found');
    }
    final setContent = await file.readAsString();
    final jsonString = _decryptData(setContent);
    return Diary.fromJson(jsonDecode(jsonString));
  }

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
      userId: userId,
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

    await _saveDiaryToFile(newDiary);
    return newDiary;
  }

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
    
    // Get existing to modify
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

    await _saveDiaryToFile(updatedDiary);
    return updatedDiary;
  }

  Future<void> deleteDiary(String id) async {
    await _init();
    final file = File('${_diaryDir.path}/$id.enc');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Diary?> getYearAgoMemory(String userId) async {
    await _init();
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    
    final diaries = await _getAllDiaries();
    try {
      return diaries.firstWhere(
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

  Future<String> exportData() async {
    await _init();
    final allDiaries = await _getAllDiaries();
    final List<Map<String, dynamic>> jsonList = 
        allDiaries.map((d) => d.toJson()).toList();
    return jsonEncode(jsonList);
  }

  Future<int> importData(String jsonString) async {
    await _init();
    final List<dynamic> jsonList = jsonDecode(jsonString);
    var count = 0;

    for (final json in jsonList) {
      try {
        if (json is Map<String, dynamic>) {
          final diary = Diary.fromJson(json);
          await _saveDiaryToFile(diary); // Upsert
          count++;
        }
      } catch (e) {
        print('Error importing entry: $e');
      }
    }
    return count;
  }

  Future<void> clearAllData() async {
    await _init();
    if (await _diaryDir.exists()) {
      await _diaryDir.delete(recursive: true);
      await _diaryDir.create();
    }
  }
}

@riverpod
DiaryRepository diaryRepository(Ref ref) {
  return DiaryRepository();
}
