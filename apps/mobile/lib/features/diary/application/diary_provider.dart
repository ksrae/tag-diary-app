import 'package:mobile/features/diary/data/diary_repository.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diary_provider.g.dart';

@riverpod
class DiaryFilter extends _$DiaryFilter {
  @override
  ({DateTime? start, DateTime? end}) build() {
    // Default: Last 7 days
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return (start: start, end: now);
  }

  void setRange(DateTime? start, DateTime? end) {
    state = (start: start, end: end);
  }
}

/// Provider for diary list (Local Storage with Date Filtering)
@riverpod
class DiaryList extends _$DiaryList {
  @override
  Future<List<Diary>> build() async {
    final filter = ref.watch(diaryFilterProvider);
    return _fetchDiaries(filter.start, filter.end);
  }

  Future<List<Diary>> _fetchDiaries(DateTime? start, DateTime? end) async {
    final repository = ref.read(diaryRepositoryProvider);
    const userId = 'me';
    
    return repository.getDiaries(
      userId: userId,
      startDate: start,
      endDate: end,
    );
  }

  Future<void> refresh() async {
    final filter = ref.read(diaryFilterProvider);
    state = const AsyncLoading();
    state = AsyncData(await _fetchDiaries(filter.start, filter.end));
  }

  void addDiary(Diary diary) {
    // Refresh to respect sort order and filter
    refresh();
  }

  void updateDiary(Diary diary) {
    refresh();
  }

  void removeDiary(String id) {
    refresh();
  }
}

/// Provider for calendar markers (dates with entries)
@riverpod
Future<List<DateTime>> diaryDates(Ref ref) async {
  final repository = ref.read(diaryRepositoryProvider);
  return repository.getDatesWithEntries();
}

/// Provider for single diary detail
@riverpod
Future<Diary> diaryDetail(Ref ref, String id) async {
  final repository = ref.read(diaryRepositoryProvider);
  return repository.getDiary(id);
}

/// Provider for 1-year-ago memory
@riverpod
Future<Diary?> yearAgoMemory(Ref ref) async {
  final repository = ref.read(diaryRepositoryProvider);
  const userId = 'me';
  return repository.getYearAgoMemory(userId);
}
