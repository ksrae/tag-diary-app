import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/diary/data/models/source_item.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:mobile/features/diary/data/models/mood.dart';
import 'package:mobile/features/shared/data/models/health_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modal for AI diary generation
/// - Style selection (persisted)
/// - Photo selection (max 3 from selected photos)
/// - Health info toggle
/// - Custom prompt
class AiGenerationModal extends ConsumerStatefulWidget {
  final List<SourceItem> photos; // Already filtered to selected photos
  final HealthInfo? healthInfo;
  final Weather? weather;
  final List<String> tags;
  final Mood? mood;
  final Function(List<SourceItem> selectedPhotos, bool includeHealth, String customPrompt, String selectedStyle) onGenerate;

  const AiGenerationModal({
    super.key,
    required this.photos,
    this.healthInfo,
    this.weather,
    required this.tags,
    this.mood,
    required this.onGenerate,
  });

  @override
  ConsumerState<AiGenerationModal> createState() => _AiGenerationModalState();
}

class _AiGenerationModalState extends ConsumerState<AiGenerationModal> {
  late List<bool> _photoSelections;
  bool _includeHealth = true;
  String _selectedStyle = 'basic_style';
  final TextEditingController _promptController = TextEditingController();

  final Map<String, String> _styles = {
    'basic_style': '기본 일기',
    'sn_style': 'SNS 스타일',
    'poem_style': '시(Poem)',
    'letter_style': '편지 스타일',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedStyle();
    // Select up to first 3 photos by default
    _photoSelections = List.generate(
      widget.photos.length,
      (i) => i < 3,
    );
  }

  Future<void> _loadSavedStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('last_diary_style');
    if (saved != null && _styles.containsKey(saved)) {
      setState(() => _selectedStyle = saved);
    }
  }

  Future<void> _saveSelectedStyle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_diary_style', _selectedStyle);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  int get _selectedPhotoCount => _photoSelections.where((s) => s).length;

  void _togglePhoto(int index) {
    setState(() {
      if (_photoSelections[index]) {
        _photoSelections[index] = false;
      } else if (_selectedPhotoCount < 3) {
        _photoSelections[index] = true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI는 최대 3장의 사진만 참고할 수 있습니다'), duration: Duration(seconds: 1)),
        );
      }
    });
  }

  void _submit() async {
    await _saveSelectedStyle();
    
    final selectedPhotos = <SourceItem>[];
    for (int i = 0; i < widget.photos.length; i++) {
      if (_photoSelections[i]) {
        selectedPhotos.add(widget.photos[i]);
      }
    }
    widget.onGenerate(selectedPhotos, _includeHealth, _promptController.text.trim(), _selectedStyle);
    Navigator.pop(context);
  }

  // Build dynamic info summary based on current selections
  Widget _buildInfoSummary() {
    final List<Widget> chips = [];
    
    // Mood
    if (widget.mood != null) {
      chips.add(Chip(
        label: Text('${widget.mood!.emoji} ${widget.mood!.label}'),
        visualDensity: VisualDensity.compact,
      ));
    }
    
    // Tags
    for (final tag in widget.tags) {
      chips.add(Chip(
        label: Text('#$tag'),
        visualDensity: VisualDensity.compact,
      ));
    }
    
    // Photos (dynamic count based on selection)
    if (_selectedPhotoCount > 0) {
      chips.add(Chip(
        avatar: const Icon(Icons.photo, size: 16),
        label: Text('사진 $_selectedPhotoCount장'),
        visualDensity: VisualDensity.compact,
      ));
    }
    
    // Health (if included and available)
    if (_includeHealth && widget.healthInfo != null && !widget.healthInfo!.isEmpty) {
      chips.add(Chip(
        avatar: const Icon(Icons.favorite, size: 16),
        label: const Text('건강정보'),
        visualDensity: VisualDensity.compact,
      ));
    }
    
    if (chips.isEmpty) {
      return Text(
        '선택된 정보가 없습니다',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI 일기 생성', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // Dynamic summary of AI reference info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('AI가 참고할 정보에요', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoSummary(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Style Selector
            const Text('스타일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStyle,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _styles.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              )).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedStyle = v);
              },
            ),

            const SizedBox(height: 16),

            // Photo Selection (if photos exist, max 3)
            if (widget.photos.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('사진 선택 (최대 3장)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('$_selectedPhotoCount/3', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Max item size 80px - will fit 4+ items on normal phones, more on wider screens
                  const maxItemSize = 80.0;
                  const spacing = 6.0;
                  
                  // Calculate how many items fit per row
                  final itemsPerRow = (constraints.maxWidth / (maxItemSize + spacing)).floor().clamp(4, 10);
                  final itemWidth = (constraints.maxWidth - (spacing * (itemsPerRow - 1))) / itemsPerRow;
                  
                  // Calculate rows needed (max 2 rows visible)
                  final rowsNeeded = (widget.photos.length / itemsPerRow).ceil();
                  final visibleRows = rowsNeeded.clamp(1, 2);
                  final height = (itemWidth * visibleRows) + (spacing * (visibleRows - 1));

                  return SizedBox(
                    height: height,
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: rowsNeeded <= 2 
                          ? const NeverScrollableScrollPhysics() 
                          : const ClampingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: itemWidth,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                      ),
                      itemCount: widget.photos.length,
                      itemBuilder: (context, index) {
                        final photo = widget.photos[index];
                        final isSelected = _photoSelections[index];
                        return GestureDetector(
                          onTap: () => _togglePhoto(index),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: photo.imageFile != null
                                      ? Image.file(photo.imageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                      : photo.imagePath != null
                                          ? Image.file(File(photo.imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                          : const Center(child: Icon(Icons.image, size: 20)),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Include Health Toggle - only show if health data is available
            if (widget.healthInfo != null && !widget.healthInfo!.isEmpty)
              SwitchListTile(
                title: const Text('건강/활동 정보 포함'),
                subtitle: Text(widget.healthInfo!.summary, style: const TextStyle(fontSize: 12)),
                value: _includeHealth,
                onChanged: (v) => setState(() => _includeHealth = v),
                contentPadding: EdgeInsets.zero,
              ),

            const SizedBox(height: 16),

            // Custom Prompt
            const Text('추가 요청사항 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText: '예: 긍정적인 분위기로 작성해줘',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('일기 생성하기'),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }
}
