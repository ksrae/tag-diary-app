import 'package:mobile/features/diary/data/diary_repository.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'diary_provider.g.dart';

/// Selected date for diary feed (single date selection)
@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void setDate(DateTime date) {
    state = date;
  }

  void goToToday() {
    state = DateTime.now();
  }
}

/// Legacy filter provider for backward compatibility
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

/// Infinite scroll diary list state
class InfiniteScrollState {
  final List<Diary> diaries;
  final bool isLoadingOlder;
  final bool isLoadingNewer;
  final bool hasMoreOlder;
  final bool hasMoreNewer;
  final String? error;

  const InfiniteScrollState({
    this.diaries = const [],
    this.isLoadingOlder = false,
    this.isLoadingNewer = false,
    this.hasMoreOlder = true,
    this.hasMoreNewer = true,
    this.error,
  });

  InfiniteScrollState copyWith({
    List<Diary>? diaries,
    bool? isLoadingOlder,
    bool? isLoadingNewer,
    bool? hasMoreOlder,
    bool? hasMoreNewer,
    String? error,
  }) {
    return InfiniteScrollState(
      diaries: diaries ?? this.diaries,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isLoadingNewer: isLoadingNewer ?? this.isLoadingNewer,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      hasMoreNewer: hasMoreNewer ?? this.hasMoreNewer,
      error: error,
    );
  }
}

/// Provider for infinite scroll diary list
@riverpod
class InfiniteScrollDiaryList extends _$InfiniteScrollDiaryList {
  static const int _pageSize = 10;

  @override
  InfiniteScrollState build() {
    // Watch selectedDate to trigger refresh when date changes
    ref.watch(selectedDateProvider);
    
    // Initial load
    _loadInitial();
    return const InfiniteScrollState();
  }

  Future<void> _loadInitial() async {
    final selectedDate = ref.read(selectedDateProvider);
    final repository = ref.read(diaryRepositoryProvider);

    try {
      final diaries = await repository.getDiariesPaginated(
        fromDate: selectedDate,
        limit: _pageSize,
        loadOlder: true,
      );

      state = state.copyWith(
        diaries: diaries,
        hasMoreOlder: diaries.length >= _pageSize,
        hasMoreNewer: !_isSameDay(selectedDate, DateTime.now()),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadOlder() async {
    if (state.isLoadingOlder || !state.hasMoreOlder) return;

    state = state.copyWith(isLoadingOlder: true);
    final repository = ref.read(diaryRepositoryProvider);

    try {
      final oldestDate = state.diaries.isNotEmpty
          ? state.diaries.last.createdAt.subtract(const Duration(days: 1))
          : DateTime.now();

      final olderDiaries = await repository.getDiariesPaginated(
        fromDate: oldestDate,
        limit: _pageSize,
        loadOlder: true,
      );

      state = state.copyWith(
        diaries: [...state.diaries, ...olderDiaries],
        isLoadingOlder: false,
        hasMoreOlder: olderDiaries.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingOlder: false, error: e.toString());
    }
  }

  Future<void> loadNewer() async {
    if (state.isLoadingNewer || !state.hasMoreNewer) return;

    state = state.copyWith(isLoadingNewer: true);
    final repository = ref.read(diaryRepositoryProvider);

    try {
      final newestDate = state.diaries.isNotEmpty
          ? state.diaries.first.createdAt
          : DateTime.now();

      final newerDiaries = await repository.getDiariesPaginated(
        fromDate: newestDate,
        limit: _pageSize,
        loadOlder: false,
      );

      state = state.copyWith(
        diaries: [...newerDiaries, ...state.diaries],
        isLoadingNewer: false,
        hasMoreNewer: newerDiaries.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoadingNewer: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const InfiniteScrollState();
    await _loadInitial();
  }

  void addDiary(Diary diary) {
    // Insert at the correct position based on date
    final newList = [...state.diaries];
    final insertIndex = newList.indexWhere(
      (d) => d.createdAt.isBefore(diary.createdAt),
    );
    if (insertIndex == -1) {
      newList.add(diary);
    } else {
      newList.insert(insertIndex, diary);
    }
    state = state.copyWith(diaries: newList);
  }

  void removeDiary(String id) {
    state = state.copyWith(
      diaries: state.diaries.where((d) => d.id != id).toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Provider for diary list (Legacy - for backward compatibility)
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

/// Memory banner dismiss state (stored in SharedPreferences)
@riverpod
class MemoryBannerDismissed extends _$MemoryBannerDismissed {
  static const _prefKey = 'memory_banner_dismissed_date';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedDateStr = prefs.getString(_prefKey);
    
    if (dismissedDateStr == null) return false;
    
    final dismissedDate = DateTime.tryParse(dismissedDateStr);
    if (dismissedDate == null) return false;
    
    // Check if dismissed today
    final now = DateTime.now();
    return dismissedDate.year == now.year &&
           dismissedDate.month == now.month &&
           dismissedDate.day == now.day;
  }

  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_prefKey, now.toIso8601String());
    state = const AsyncData(true);
  }
}

/// Provider for 1-year-ago memory
@riverpod
Future<Diary?> yearAgoMemory(Ref ref) async {
  final repository = ref.read(diaryRepositoryProvider);
  const userId = 'me';
  return repository.getYearAgoMemory(userId);
}
