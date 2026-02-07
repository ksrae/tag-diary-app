import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/diary/application/diary_provider.dart';
import 'package:mobile/features/diary/presentation/widgets/diary_card.dart';
import 'package:mobile/features/diary/presentation/widgets/memory_banner.dart';

import 'package:mobile/features/diary/presentation/widgets/diary_calendar.dart';

/// Main diary feed screen (SNS-style)
class DiaryFeedScreen extends ConsumerStatefulWidget {
  const DiaryFeedScreen({super.key});

  @override
  ConsumerState<DiaryFeedScreen> createState() => _DiaryFeedScreenState();
}

class _DiaryFeedScreenState extends ConsumerState<DiaryFeedScreen> {
  bool _showCalendar = false;

  @override
  Widget build(BuildContext context) {
    final diariesAsync = ref.watch(diaryListProvider);
    final memoryAsync = ref.watch(yearAgoMemoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 일기'),
        actions: [
          IconButton(
            icon: Icon(_showCalendar ? Icons.view_list : Icons.calendar_today),
            onPressed: () {
              setState(() {
                _showCalendar = !_showCalendar;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(diaryListProvider.notifier).refresh(),
        child: Column(
          children: [
            // Calendar View
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _showCalendar 
                  ? const DiaryCalendar() 
                  : const SizedBox.shrink(),
            ),
            
            // List View
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // 1년 전 추억 배너
                  memoryAsync.when(
                    data: (memory) => memory != null
                        ? SliverToBoxAdapter(
                            child: MemoryBanner(
                              diary: memory,
                              onTap: () => context.push('/diary/${memory.id}'),
                            ),
                          )
                        : const SliverToBoxAdapter(child: SizedBox.shrink()),
                    loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
      
                  // 일기 피드
                  diariesAsync.when(
                    data: (diaries) => diaries.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.book_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '선택한 기간에 일기가 없어요',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '작성하거나 기간을 변경해보세요!',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: DiaryCard(
                                      diary: diaries[index],
                                      onTap: () => context.push('/diary/${diaries[index].id}'),
                                    ),
                                  );
                                },
                                childCount: diaries.length,
                              ),
                            ),
                          ),
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48),
                            const SizedBox(height: 16),
                            Text('오류가 발생했습니다: $error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(diaryListProvider),
                              child: const Text('재시도'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/diary/create'),
        icon: const Icon(Icons.add),
        label: const Text('일기 쓰기'),
      ),
    );
  }
}
