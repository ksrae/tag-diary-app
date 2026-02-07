import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/diary/data/models/diary.dart';

/// SNS-style diary card widget
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

  String _getWeatherIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return '☀️';
      case 'cloudy':
        return '☁️';
      case 'rainy':
      case 'rain':
        return '🌧️';
      case 'snowy':
      case 'snow':
        return '❄️';
      default:
        return '🌤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos grid (Max 3)
            if (diary.photos.isNotEmpty)
              Container(
                height: 120, // Reduced height for thumbnails
                margin: const EdgeInsets.only(bottom: 0),
                child: Row(
                  children: [
                    for (int i = 0; i < diary.photos.length && i < 3; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 2.0 : 0),
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
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    // Fill remaining space if less than 3 photos to maintain aspect ratio?
                    // No, usually grid just takes available width. 
                    // If 1 photo: Full width (Expanded). 
                    // If 2 photos: 50% each.
                    // If 3 photos: 33% each.
                    // Doing 'Expanded' in a loop handles this automatically.
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date, mood, weather header
                  Row(
                    children: [
                      Text(
                        dateFormat.format(diary.createdAt),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _getMoodEmoji(diary.mood),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      if (diary.weather != null) ...[
                        Text(
                          _getWeatherIcon(diary.weather!.condition),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${diary.weather!.temp.round()}°',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Content preview
                  Text(
                    diary.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 12),

                  // Tags only
                  if (diary.sources.any((s) => s.type == 'tag'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: diary.sources
                            .where((s) => s.type == 'tag')
                            .map((s) => s.contentPreview) // Content preview holds the tag name
                            .toSet() 
                            .map((tagName) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#$tagName',
                                  style: theme.textTheme.labelSmall,
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),

                  // AI generated badge
                  if (diary.isAiGenerated)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI 작성',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
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
      case 'location':
        return Icons.location_on;
      case 'steps':
        return Icons.directions_walk;
      default:
        return Icons.link;
    }
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
              child: const Icon(Icons.image_not_supported, size: 24),
            ),
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image, size: 24),
            ),
          );
  }
}
