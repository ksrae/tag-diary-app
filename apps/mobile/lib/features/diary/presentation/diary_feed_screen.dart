import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/diary/application/diary_provider.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:mobile/features/diary/presentation/widgets/diary_card.dart';
import 'package:mobile/features/diary/presentation/widgets/memory_banner.dart';
import 'package:mobile/features/diary/presentation/widgets/diary_calendar.dart';

/// Main diary feed screen (SNS-style) with infinite scroll
class DiaryFeedScreen extends ConsumerStatefulWidget {
  const DiaryFeedScreen({super.key});

  @override
  ConsumerState<DiaryFeedScreen> createState() => _DiaryFeedScreenState();
}

class _DiaryFeedScreenState extends ConsumerState<DiaryFeedScreen> {
  bool _showCalendar = false;
  String? _selectedTag;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Near bottom, load older entries
      ref.read(infiniteScrollDiaryListProvider.notifier).loadOlder();
    }
    if (_scrollController.position.pixels <= 200) {
      // Near top, load newer entries
      ref.read(infiniteScrollDiaryListProvider.notifier).loadNewer();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollState = ref.watch(infiniteScrollDiaryListProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final memoryAsync = ref.watch(yearAgoMemoryProvider);
    final bannerDismissedAsync = ref.watch(memoryBannerDismissedProvider);
    final theme = Theme.of(context);
    
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');
    final isToday = _isSameDay(selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(infiniteScrollDiaryListProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header: TODAY + Date
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday ? '오늘' : '일기',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(selectedDate),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Calendar toggle
                      IconButton(
                        icon: Icon(
                          Icons.calendar_month,
                          color: _showCalendar 
                              ? theme.colorScheme.primary 
                              : null,
                        ),
                        onPressed: () {
                          setState(() => _showCalendar = !_showCalendar);
                        },
                      ),
                      // Filter
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
              ),

              // Calendar View (Expandable)
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: _showCalendar 
                      ? const DiaryCalendar() 
                      : const SizedBox.shrink(),
                ),
              ),

              // 1년 전 추억 배너
              bannerDismissedAsync.when(
                data: (isDismissed) {
                  if (isDismissed) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return memoryAsync.when(
                    data: (memory) => memory != null
                        ? SliverToBoxAdapter(
                            child: MemoryBanner(
                              diary: memory,
                              onTap: () => context.push('/diary/${memory.id}'),
                              onDismiss: () {
                                ref.read(memoryBannerDismissedProvider.notifier).dismiss();
                              },
                            ),
                          )
                        : const SliverToBoxAdapter(child: SizedBox.shrink()),
                    loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Section Header: Recent Entries
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '최근 일기',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Reset filter button - only show when filtered
                      if (!isToday || _selectedTag != null)
                        TextButton(
                          onPressed: () {
                            if (!isToday) {
                              ref.read(selectedDateProvider.notifier).goToToday();
                            }
                            if (_selectedTag != null) {
                              setState(() => _selectedTag = null);
                            }
                            _scrollToTop();
                          },
                          child: Text(
                            '오늘',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Loading newer indicator
              if (scrollState.isLoadingNewer)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),

              // Diary List
              if (scrollState.diaries.isEmpty && !scrollState.isLoadingOlder)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '아직 작성된 일기가 없어요',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '첫 일기를 작성해보세요!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final filteredDiaries = _selectedTag == null
                            ? scrollState.diaries
                            : scrollState.diaries.where((d) => 
                                d.sources.any((s) => s.type == 'tag' && s.contentPreview == _selectedTag)
                              ).toList();
                        
                        if (index >= filteredDiaries.length) return null;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DiaryCard(
                            diary: filteredDiaries[index],
                            onTap: () => context.push('/diary/${filteredDiaries[index].id}'),
                          ),
                        );
                      },
                      childCount: _selectedTag == null
                          ? scrollState.diaries.length
                          : scrollState.diaries.where((d) => 
                              d.sources.any((s) => s.type == 'tag' && s.contentPreview == _selectedTag)
                            ).length,
                    ),
                  ),
                ),

              // Loading older indicator
              if (scrollState.isLoadingOlder)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Go to Today button (only show if not viewing today)
          if (!isToday)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.small(
                heroTag: 'go_today',
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).goToToday();
                  ref.read(infiniteScrollDiaryListProvider.notifier).refresh();
                  _scrollToTop();
                },
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.today,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          // Create diary button
          // Create/Edit diary button
          FloatingActionButton(
            heroTag: 'create_diary',
            onPressed: () {
              // Check if there's already a diary for today in the loaded list
              // Note: This checks loaded diaries. For a robust solution, we might need a repository check,
              // but since the feed loads latest first, this should work for most cases.
              final today = DateTime.now();
              Diary? existingDiary;
              try {
                existingDiary = scrollState.diaries.firstWhere(
                  (d) => _isSameDay(d.createdAt, today),
                );
              } catch (_) {}

              if (existingDiary != null) {
                // Edit existing diary
                context.push('/diary/create', extra: existingDiary);
              } else {
                // Create new diary
                context.push('/diary/create');
              }
            },
            child: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
