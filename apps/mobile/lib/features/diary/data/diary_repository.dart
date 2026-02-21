import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:mobile/core/services/firestore_service.dart';
import 'package:mobile/core/services/cloud_storage_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/features/diary/data/models/diary.dart';

part 'diary_repository.g.dart';

/// Repository for diary operations (Firestore + Cloud Storage)
class DiaryRepository {
  final FirestoreService _firestoreService;
  final CloudStorageService _cloudStorageService;
  final String _uid;

  DiaryRepository({
    required FirestoreService firestoreService,
    required CloudStorageService cloudStorageService,
    required String uid,
  })  : _firestoreService = firestoreService,
        _cloudStorageService = cloudStorageService,
        _uid = uid;

  /// Stream all diaries (real-time updates from Firestore)
  Stream<List<Diary>> streamDiaries() {
    return _firestoreService.streamDiaries(_uid).map((maps) {
      return maps.map((map) => _diaryFromMap(map)).toList();
    });
  }

  /// Get all diaries (one-time fetch)
  Future<List<Diary>> getAllDiaries() async {
    final maps = await _firestoreService.streamDiaries(_uid).first;
    return maps.map((map) => _diaryFromMap(map)).toList();
  }

  Future<List<Diary>> getDiaries({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var entries = await getAllDiaries();

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
    var entries = await getAllDiaries();

    if (loadOlder) {
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day, 23, 59, 59, 999);
      entries = entries.where((d) => d.createdAt.compareTo(from) <= 0).toList();
    } else {
      final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
      entries = entries.where((d) => d.createdAt.compareTo(from) > 0).toList();
      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final result = entries.take(limit).toList();

    if (!loadOlder) {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  Future<List<DateTime>> getDatesWithEntries() async {
    final diaries = await getAllDiaries();
    final dates = diaries
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet()
        .toList();
    return dates;
  }

  Future<Diary> getDiary(String id) async {
    final diaries = await getAllDiaries();
    return diaries.firstWhere(
      (d) => d.id == id,
      orElse: () => throw Exception('Diary not found'),
    );
  }

  /// Upload images to Cloud Storage and return download URLs + total bytes
  Future<(List<String>, int)> _uploadImages({
    required String diaryId,
    required List<String> localPaths,
  }) async {
    final List<String> urls = [];
    int totalBytes = 0;

    for (final path in localPaths) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        // Already a cloud URL, keep as-is
        urls.add(path);
        continue;
      }

      final result = await _cloudStorageService.compressAndUploadImage(
        uid: _uid,
        imagePath: path,
        diaryId: diaryId,
      );

      if (result != null) {
        urls.add(result.$1);
        totalBytes += result.$2;
      }
    }

    return (urls, totalBytes);
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
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}';

    // Upload images to Cloud Storage
    List<String> photoUrls = [];
    int uploadedBytes = 0;
    if (photos != null && photos.isNotEmpty) {
      final (urls, bytes) = await _uploadImages(diaryId: id, localPaths: photos);
      photoUrls = urls;
      uploadedBytes = bytes;
    }

    final diary = Diary(
      id: id,
      userId: _uid,
      content: content,
      mood: mood,
      weather: weather,
      sources: sources ?? [],
      photos: photoUrls,
      isAiGenerated: isAiGenerated,
      createdAt: now,
      updatedAt: now,
      editCount: 0,
    );

    // Save to Firestore
    await _firestoreService.saveDiary(_uid, id, diary.toJson());

    // Update used bytes
    if (uploadedBytes > 0) {
      await _firestoreService.incrementUsedBytes(_uid, uploadedBytes);
    }

    return diary;
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
    final existingDiary = await getDiary(id);

    // Upload new local images
    List<String> photoUrls = existingDiary.photos;
    int uploadedBytes = 0;
    if (photos != null) {
      final (urls, bytes) = await _uploadImages(diaryId: id, localPaths: photos);
      photoUrls = urls;
      uploadedBytes = bytes;
    }

    final updatedDiary = existingDiary.copyWith(
      content: content ?? existingDiary.content,
      mood: mood ?? existingDiary.mood,
      weather: weather ?? existingDiary.weather,
      sources: sources ?? existingDiary.sources,
      photos: photoUrls,
      isAiGenerated: isAiGenerated ?? existingDiary.isAiGenerated,
      updatedAt: DateTime.now(),
      editCount: incrementEditCount ? existingDiary.editCount + 1 : existingDiary.editCount,
    );

    await _firestoreService.saveDiary(_uid, id, updatedDiary.toJson());

    if (uploadedBytes > 0) {
      await _firestoreService.incrementUsedBytes(_uid, uploadedBytes);
    }

    return updatedDiary;
  }

  Future<void> deleteDiary(String id) async {
    // Delete images from Storage
    await _cloudStorageService.deleteDiaryImages(_uid, id);
    // Delete diary from Firestore
    await _firestoreService.deleteDiary(_uid, id);
  }

  Future<Diary?> getYearAgoMemory(String userId) async {
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    final diaries = await getAllDiaries();
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

  /// Convert Firestore map to Diary model
  Diary _diaryFromMap(Map<String, dynamic> map) {
    // Handle Timestamp fields
    DateTime createdAt;
    if (map['createdAt'] is DateTime) {
      createdAt = map['createdAt'] as DateTime;
    } else if (map['createdAt'] != null) {
      // Firestore Timestamp
      createdAt = (map['createdAt'] as dynamic).toDate();
    } else {
      createdAt = DateTime.now();
    }

    DateTime? updatedAt;
    if (map['updatedAt'] is DateTime) {
      updatedAt = map['updatedAt'] as DateTime;
    } else if (map['updatedAt'] != null) {
      updatedAt = (map['updatedAt'] as dynamic).toDate();
    }

    return Diary(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? _uid,
      content: map['content'] as String? ?? '',
      mood: map['mood'] as String?,
      weather: map['weather'] != null
          ? Weather.fromJson(Map<String, dynamic>.from(map['weather'] as Map))
          : null,
      sources: (map['sources'] as List<dynamic>?)
              ?.map((s) => DiarySource.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          [],
      photos: (map['photos'] as List<dynamic>?)?.map((p) => p.toString()).toList() ?? [],
      isAiGenerated: map['isAiGenerated'] as bool? ?? false,
      editCount: map['editCount'] as int? ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@riverpod
DiaryRepository diaryRepository(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  final uid = authService.currentUser?.uid;

  if (uid == null) {
    throw Exception('User not authenticated');
  }

  return DiaryRepository(
    firestoreService: ref.watch(firestoreServiceProvider),
    cloudStorageService: ref.watch(cloudStorageServiceProvider),
    uid: uid,
  );
}
