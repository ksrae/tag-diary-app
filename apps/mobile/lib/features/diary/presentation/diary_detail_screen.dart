import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/diary/application/diary_provider.dart';
import 'package:mobile/features/diary/data/diary_repository.dart';
import 'package:mobile/features/diary/presentation/diary_create_screen.dart';
import 'package:mobile/features/diary/presentation/widgets/diary_image_slider.dart';
import 'package:mobile/features/diary/presentation/widgets/diary_gallery_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Diary detail screen with edit and delete options
class DiaryDetailScreen extends ConsumerStatefulWidget {
  const DiaryDetailScreen({super.key, required this.diaryId});

  final String diaryId;

  @override
  ConsumerState<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends ConsumerState<DiaryDetailScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  String _getMoodEmoji(String? mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'peaceful':
        return '😌';
      case 'angry':
        return '😤';
      case 'tired':
        return '😴';
      case 'loved':
        return '🥰';
      default:
        return '📝';
    }
  }

  Future<void> _deleteDiary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('정말로 이 일기를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(diaryRepositoryProvider).deleteDiary(widget.diaryId);
        ref.read(diaryListProvider.notifier).removeDiary(widget.diaryId);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaryAsync = ref.watch(diaryDetailProvider(widget.diaryId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('일기'),
        actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  diaryAsync.whenData((diary) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiaryCreateScreen(diary: diary),
                      ),
                    );
                    // Refresh after return
                    ref.invalidate(diaryDetailProvider(widget.diaryId));
                  });
                } else if (value == 'delete') {
                  _deleteDiary();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: diaryAsync.when(
        data: (diary) {
          final dateFormat = DateFormat('yyyy년 M월 d일 EEEE', 'ko');

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Photos Carousel (Moved to Top)
                if (diary.photos.isNotEmpty)
                  DiaryImageSlider(
                    images: diary.photos,
                    onImageTap: (index) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryGalleryScreen(
                            images: diary.photos,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Date & Mood Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(diary.createdAt),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Weather
                                    if (diary.weather != null) ...[
                                      GestureDetector(
                                        onTap: () {
                                          final q = 'weather ${DateFormat('yyyy-MM-dd').format(diary.createdAt)}';
                                          launchUrl(Uri.parse('https://www.google.com/search?q=$q'), mode: LaunchMode.externalApplication);
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.wb_sunny, size: 18, color: Colors.orange), // Increased size
                                            const SizedBox(width: 4),
                                            Text(
                                              '${diary.weather!.temp.round()}°C',
                                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), // Increased size
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                        ),
                                      ),
                                    ],
                                    // Steps
                                    if (diary.sources.any((s) => s.type == 'steps')) ...[
                                      GestureDetector(
                                        onTap: () {
                                           // Suggest opening health app
                                          final url = Platform.isIOS ? 'x-apple-health://' : 'https://fit.google.com';
                                          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.directions_walk, size: 16, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              diary.sources.firstWhere((s) => s.type == 'steps').contentPreview,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                decoration: TextDecoration.underline,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _getMoodEmoji(diary.mood),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3. Content
                      Text(
                        diary.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4. Calendar Events
                      if (diary.sources.any((s) => s.type == 'calendar')) ...[
                        GestureDetector(
                          onTap: () {
                            // Try to open calendar to the date
                            // Android: content://com.android.calendar/time/
                            // iOS: calshow:
                            final timestamp = diary.createdAt.millisecondsSinceEpoch;
                            final url = Platform.isAndroid 
                                ? 'content://com.android.calendar/time/$timestamp'
                                : 'calshow:${diary.createdAt.difference(DateTime(2001, 1, 1)).inSeconds}'; // iOS reference date
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) {
                               // Fallback?
                               return false;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text('이날의 일정',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        )),
                                     const Spacer(),
                                     const Icon(Icons.open_in_new, size: 12, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...diary.sources
                                    .where((s) => s.type == 'calendar')
                                    .map((s) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text('• ${s.contentPreview}', style: theme.textTheme.bodyMedium),
                                        )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 5. Map Preview
                      if (diary.sources.any((s) => s.type == 'location')) ...[
                        _buildMapPreview(
                            diary.sources.firstWhere((s) => s.type == 'location').contentPreview),
                        const SizedBox(height: 24),
                      ],

                      // 6. Tags
                      if (diary.sources.any((s) => s.type == 'tag')) ...[
                        Text('태그', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: diary.sources
                              .where((s) => s.type == 'tag')
                              .map((s) => Chip(
                                    label: Text('#${s.contentPreview}'),
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 7. AI Badge
                      if (diary.isAiGenerated)
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI가 작성한 일기',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('오류: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(diaryDetailProvider(widget.diaryId)),
                child: const Text('재시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSourceIcon(String type) {
    switch (type) {
      case 'photo':
        return Icons.photo;
      case 'calendar':
        return Icons.calendar_today;
      case 'memo':
        return Icons.note;
      case 'message':
        return Icons.message;
      default:
        return Icons.folder;
    }
  }

  Widget _buildMapPreview(String content) {
    // Extract lat/long
    final regex = RegExp(r'[-+]?([0-9]*\.[0-9]+|[0-9]+)');
    final matches = regex.allMatches(content).toList();
    
    if (matches.length < 2) return const SizedBox.shrink();
    
    final lat = double.tryParse(matches[0].group(0) ?? '');
    final lng = double.tryParse(matches[1].group(0) ?? '');
    
    if (lat == null || lng == null) return const SizedBox.shrink();
    
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Static-like
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mobile',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    alignment: Alignment.topCenter,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'map_btn',
              onPressed: () {
                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.map, color: Colors.blue),
            ),
          ),
          Positioned(
            left: 4,
            bottom: 2,
            child: Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 8, color: Colors.black54, backgroundColor: Colors.white.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
