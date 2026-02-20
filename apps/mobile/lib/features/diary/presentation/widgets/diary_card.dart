import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/diary/data/models/diary.dart';

/// SNS-style diary card widget with date column layout
class DiaryCard extends StatelessWidget {
  const DiaryCard({
    super.key,
    required this.diary,
    this.onTap,
  });

  final Diary diary;
  final VoidCallback? onTap;

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

  Color _getWeatherColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Colors.orange;
      case 'cloudy':
        return Colors.blueGrey;
      case 'rainy':
      case 'rain':
        return Colors.blue;
      case 'snowy':
      case 'snow':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  /// Get subtle background color based on mood
  Color _getMoodBackgroundColor(String? mood, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final opacity = isDark ? 0.15 : 0.25;
    
    switch (mood) {
      case 'happy':
        return Colors.amber.withOpacity(opacity);
      case 'sad':
        return Colors.blue.withOpacity(opacity);
      case 'peaceful':
        return Colors.green.withOpacity(opacity);
      case 'angry':
        return Colors.red.withOpacity(opacity);
      case 'tired':
        return Colors.blueGrey.withOpacity(opacity);
      case 'loved':
        return Colors.pink.withOpacity(opacity);
      default:
        return theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');
    
    // Get title (first line of content or truncated)

    
    // Get tags
    final tags = diary.sources
        .where((s) => s.type == 'tag')
        .map((s) => s.contentPreview)
        .toSet()
        .toList();

    // Get mood-based background color
    final backgroundColor = _getMoodBackgroundColor(diary.mood, theme);

    return Card(
      elevation: 0,
      color: backgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Date Column
              Container(
                width: 50,
                padding: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Day number
                    Text(
                      diary.createdAt.day.toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    // Month in Korean
                    Text(
                      '${diary.createdAt.month}월',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Weather icon
                    if (diary.weather != null && 
                        diary.weather!.condition != 'unknown' && 
                        diary.weather!.condition != 'error')
                      Icon(
                        _getWeatherIcon(diary.weather!.condition),
                        size: 18,
                        color: _getWeatherColor(diary.weather!.condition),
                      ),
                    const SizedBox(height: 4),
                    // Mood emoji
                    Text(
                      _getMoodEmoji(diary.mood),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Right: Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First line: Tags + Time/AI aligned right
                    Row(
                      children: [
                        // Tags with dynamic +n display
                        if (tags.isNotEmpty)
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final tagStyle = theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontSize: 11,
                                );
                                final plusStyle = theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontSize: 11,
                                );
                                
                                double availableWidth = constraints.maxWidth;
                                List<String> visibleTags = [];
                                int remaining = 0;
                                
                                for (int i = 0; i < tags.length; i++) {
                                  final tagText = '#${tags[i]} ';
                                  final textPainter = TextPainter(
                                    text: TextSpan(text: tagText, style: tagStyle),
                                    maxLines: 1,
                                    textDirection: ui.TextDirection.ltr,
                                  )..layout();
                                  
                                  // Reserve space for "+n" if there might be more
                                  final plusTextPainter = TextPainter(
                                    text: TextSpan(text: '+${tags.length - i - 1}', style: plusStyle),
                                    maxLines: 1,
                                    textDirection: ui.TextDirection.ltr,
                                  )..layout();
                                  
                                  final neededForPlus = (i < tags.length - 1) ? plusTextPainter.width + 4 : 0;
                                  
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
                                  ],
                                );
                              },
                            ),
                          ),
                        if (tags.isEmpty)
                          const Spacer(),
                        const SizedBox(width: 8),
                        // AI indicator
                        if (diary.isAiGenerated)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        Text(
                          timeFormat.format(diary.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Content (clean, no filtering needed since AI won't add hashtags)
                    Text(
                      diary.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                    
                    // Photos (if any)
                    if (diary.photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: Row(
                          children: [
                            for (int i = 0; i < diary.photos.length && i < 3; i++)
                              Padding(
                                padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        _buildPhotoItem(context, diary.photos[i]),
                                        if (i == 2 && diary.photos.length > 3)
                                          Container(
                                            color: Colors.black.withOpacity(0.5),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '+${diary.photos.length - 3}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
                    

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildPhotoItem(BuildContext context, String path) {
    final isNetwork = path.startsWith('http');
    final theme = Theme.of(context);
    
    return isNetwork
        ? Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.image_not_supported, size: 20),
            ),
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image, size: 20),
            ),
          );
  }
}
