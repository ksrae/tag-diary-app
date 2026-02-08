import 'dart:io';
import 'dart:ui' as ui;
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
  bool _tagsExpanded = false;
  
  @override
  void dispose() {
    super.dispose();
  }

  String _getMoodLabel(String? mood) {
    switch (mood) {
      case 'happy':
        return 'Feeling Happy';
      case 'sad':
        return 'Feeling Sad';
      case 'peaceful':
        return 'Feeling Peaceful';
      case 'angry':
        return 'Feeling Angry';
      case 'tired':
        return 'Feeling Tired';
      case 'loved':
        return 'Feeling Loved';
      default:
        return '';
    }
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

  String _getWeatherLabel(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return 'Sunny';
      case 'cloudy':
        return 'Cloudy';
      case 'rainy':
      case 'rain':
        return 'Rainy';
      case 'snowy':
      case 'snow':
        return 'Snowy';
      default:
        return 'Weather';
    }
  }

  IconData _getWeatherIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.cloud;
      case 'rainy':
      case 'rain':
        return Icons.water_drop;
      case 'snowy':
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
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
        ref.read(infiniteScrollDiaryListProvider.notifier).removeDiary(widget.diaryId);
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: diaryAsync.when(
        data: (diary) {
          final tags = diary.sources
              .where((s) => s.type == 'tag')
              .map((s) => s.contentPreview)
              .toSet()
              .toList();

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Image Slider with overlay controls
                  SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Photos Carousel
                    if (diary.photos.isNotEmpty)
                      DiaryImageSlider(
                        images: diary.photos,
                        editCount: diary.editCount,
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
                      )
                    else
                      const SizedBox(height: 60), // Spacing if no images

                    // Menu button overlay
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 8,
                      child: PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DiaryCreateScreen(diary: diary),
                              ),
                            ).then((_) {
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
                    ),
                  ],
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header with Back Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Back button (no background)
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const Spacer(),
                          // Right: Date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Large day number
                              Text(
                                diary.createdAt.day.toString(),
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              // Weekday
                              Text(
                                DateFormat('EEEE').format(diary.createdAt),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Month Year
                              Text(
                                DateFormat('MMMM yyyy').format(diary.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Weather row (separate from date)
                      if (diary.weather != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final q = 'weather ${DateFormat('yyyy-MM-dd').format(diary.createdAt)}';
                                launchUrl(Uri.parse('https://www.google.com/search?q=$q'), mode: LaunchMode.externalApplication);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getWeatherIcon(diary.weather!.condition),
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${diary.weather!.temp.round()}° ${_getWeatherLabel(diary.weather!.condition)}',
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Action chips: Gallery, Calendar, Activity, Tags
                      // Tags section with toggle

                      // Tags section with toggle
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() => _tagsExpanded = !_tagsExpanded),
                          child: _tagsExpanded
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ...tags.map((tag) => _buildTagChip(context, tag)),
                                  // Collapse indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.keyboard_arrow_up, size: 16, color: theme.colorScheme.outline),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final tagStyle = theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontSize: 12,
                                        );
                                        final plusStyle = theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.outline,
                                          fontSize: 12,
                                        );
                                        
                                        double availableWidth = constraints.maxWidth - 30; // Reserve for expand icon
                                        List<String> visibleTags = [];
                                        int remaining = 0;
                                        
                                        for (int i = 0; i < tags.length; i++) {
                                          final tagText = '#${tags[i]} ';
                                          final textPainter = TextPainter(
                                            text: TextSpan(text: tagText, style: tagStyle),
                                            maxLines: 1,
                                            textDirection: ui.TextDirection.ltr,
                                          )..layout();
                                          
                                          final plusTextPainter = TextPainter(
                                            text: TextSpan(text: '+${tags.length - i - 1}', style: plusStyle),
                                            maxLines: 1,
                                            textDirection: ui.TextDirection.ltr,
                                          )..layout();
                                          
                                          final neededForPlus = (i < tags.length - 1) ? plusTextPainter.width + 8 : 0;
                                          
                                          if (availableWidth - textPainter.width >= neededForPlus) {
                                            visibleTags.add(tags[i]);
                                            availableWidth -= textPainter.width;
                                          } else {
                                            remaining = tags.length - i;
                                            break;
                                          }
                                        }
                                        
                                        return Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                visibleTags.map((t) => '#$t').join(' '),
                                                maxLines: 1,
                                                overflow: TextOverflow.clip,
                                                style: tagStyle,
                                              ),
                                            ),
                                            if (remaining > 0) ...[
                                              const SizedBox(width: 4),
                                              Text('+$remaining', style: plusStyle),
                                            ],
                                            const SizedBox(width: 4),
                                            Icon(Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.outline),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Content text
                      Text(
                        diary.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Calendar Events Section
                      if (diary.sources.any((s) => s.type == 'calendar')) ...[
                        GestureDetector(
                          onTap: () {
                            final timestamp = diary.createdAt.millisecondsSinceEpoch;
                            final url = Platform.isAndroid 
                                ? 'content://com.android.calendar/time/$timestamp'
                                : 'calshow:${diary.createdAt.difference(DateTime(2001, 1, 1)).inSeconds}';
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      '이날의 일정',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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

                      // Map Preview
                      if (diary.sources.any((s) => s.type == 'location')) ...[
                        _buildMapPreview(
                          diary.sources.firstWhere((s) => s.type == 'location').contentPreview,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // AI Badge
                      if (diary.isAiGenerated)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'AI가 작성한 일기',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Bottom spacing
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          diaryAsync.whenData((diary) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiaryCreateScreen(diary: diary),
              ),
            ).then((_) {
              ref.invalidate(diaryDetailProvider(widget.diaryId));
            });
          });
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(BuildContext context, String tag) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$tag',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
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
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
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
