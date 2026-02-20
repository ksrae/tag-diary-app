import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/diary/data/models/source_item.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:mobile/features/diary/data/models/mood.dart';
import 'package:mobile/features/shared/data/models/health_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Data Class ---

class AiGenerationOptions {
  final List<SourceItem> selectedPhotos;
  final bool includeHealth;
  final bool includeWeather;
  final String customPrompt;
  final String selectedStyle;
  final List<bool> photoSelections; // To restore specific checkmarks
  final List<String> selectedTags;
  final List<bool> tagSelections; // To restore specific checkmarks

  AiGenerationOptions({
    required this.selectedPhotos,
    required this.includeHealth,
    required this.includeWeather,
    required this.customPrompt,
    required this.selectedStyle,
    required this.photoSelections,
    required this.selectedTags,
    required this.tagSelections,
  });
}

// --- Input Sheet (Bottom Sheet) ---

/// Modal for AI diary generation input
/// - Style selection (persisted)
/// - Photo selection (max 3 from selected photos)
/// - Health info toggle
/// - Custom prompt
class AiGenerationInputSheet extends ConsumerStatefulWidget {
  final List<SourceItem> photos; // All available photos
  final HealthInfo? healthInfo;
  final Weather? weather;
  final List<String> tags;
  final Mood? mood;
  
  // Optional: Restore previous state if user clicked "Retry"
  final AiGenerationOptions? initialOptions;

  const AiGenerationInputSheet({
    super.key,
    required this.photos,
    this.healthInfo,
    this.weather,
    required this.tags,
    this.mood,
    this.initialOptions,
  });

  @override
  ConsumerState<AiGenerationInputSheet> createState() => _AiGenerationInputSheetState();
}

class _AiGenerationInputSheetState extends ConsumerState<AiGenerationInputSheet> {
  late List<bool> _photoSelections;
  late List<bool> _tagSelections;
  late bool _includeHealth;
  late bool _includeWeather;
  late String _selectedStyle;
  late TextEditingController _promptController;

  final Map<String, String> _styles = {
    'basic_style': '기본 일기',
    'sn_style': 'SNS 스타일',
    'poem_style': '시(Poem)',
    'letter_style': '편지 스타일',
  };

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() {
    if (widget.initialOptions != null) {
      // Restore from previous options
      final op = widget.initialOptions!;
      _selectedStyle = op.selectedStyle;
      _includeHealth = op.includeHealth;
      _includeWeather = op.includeWeather;
      _promptController = TextEditingController(text: op.customPrompt);
      // We need to restore photo selections carefully. 
      // If the photo list length changed (unlikely in this flow), this might be risky, 
      // but within the same screen session it should be fine.
      if (op.photoSelections.length == widget.photos.length) {
        _photoSelections = List.from(op.photoSelections);
      } else {
        _photoSelections = List.generate(widget.photos.length, (i) => i < 3);
      }

      if (op.tagSelections.length == widget.tags.length) {
        _tagSelections = List.from(op.tagSelections);
      } else {
        _tagSelections = List.generate(widget.tags.length, (_) => true);
      }
    } else {
      // Default init
      _selectedStyle = 'basic_style';
      _includeHealth = true;
      _includeWeather = true;
      _promptController = TextEditingController();
      _photoSelections = List.generate(widget.photos.length, (i) => i < 3);
      _tagSelections = List.generate(widget.tags.length, (_) => true);
      _loadSavedStyle();
    }
  }

  Future<void> _loadSavedStyle() async {
    if (widget.initialOptions != null) return; // Don't overwrite restored style
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

    final selectedTags = <String>[];
    for (int i = 0; i < widget.tags.length; i++) {
      if (_tagSelections[i]) {
        selectedTags.add(widget.tags[i]);
      }
    }

    final options = AiGenerationOptions(
      selectedPhotos: selectedPhotos,
      includeHealth: _includeHealth,
      includeWeather: _includeWeather,
      customPrompt: _promptController.text.trim(),
      selectedStyle: _selectedStyle,
      photoSelections: List.from(_photoSelections),
      selectedTags: selectedTags,
      tagSelections: List.from(_tagSelections),
    );

    Navigator.pop(context, options);
  }

  // Build dynamic info summary based on current selections
  Widget _buildInfoSummary() {
    final List<Widget> chips = [];
    
    if (widget.mood != null) {
      chips.add(Chip(
        label: Text('${widget.mood!.emoji} ${widget.mood!.label}'),
        visualDensity: VisualDensity.compact,
      ));
    }
    
    for (int i = 0; i < widget.tags.length; i++) {
      if (_tagSelections[i]) {
        chips.add(Chip(
          label: Text('#${widget.tags[i]}'),
          visualDensity: VisualDensity.compact,
        ));
      }
    }
    
    if (_selectedPhotoCount > 0) {
      chips.add(Chip(
        avatar: const Icon(Icons.photo, size: 16),
        label: Text('사진 $_selectedPhotoCount장'),
        visualDensity: VisualDensity.compact,
      ));
    }
    
    if (_includeWeather && widget.weather != null && widget.weather!.condition != 'unknown') {
      chips.add(Chip(
        avatar: Icon(
          widget.weather!.condition == 'sunny' ? Icons.wb_sunny : Icons.cloud,
          size: 16,
        ),
        label: const Text('날씨'),
        visualDensity: VisualDensity.compact,
      ));
    }
    
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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

            // Dynamic summary
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

            // Custom Prompt
            const Text('스타일에 추가 요청사항 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText: '예: 긍정적인 분위기로 작성해줘',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),
            
            // Tag Selection
            if (widget.tags.isNotEmpty) ...[
              const Text('태그 선택 (AI가 참고할 태그)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: List.generate(widget.tags.length, (index) {
                  final isSelected = _tagSelections[index];
                  return FilterChip(
                    label: Text('#${widget.tags[index]}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _tagSelections[index] = selected;
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],

            // Photo Selection
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
                  const maxItemSize = 80.0;
                  const spacing = 6.0;
                  final itemsPerRow = (constraints.maxWidth / (maxItemSize + spacing)).floor().clamp(4, 10);
                  final itemWidth = (constraints.maxWidth - (spacing * (itemsPerRow - 1))) / itemsPerRow;
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

            // Weather Toggle
            if (widget.weather != null && widget.weather!.condition != 'unknown')
              SwitchListTile(
                title: const Text('날씨 정보 포함'),
                subtitle: Text('${widget.weather!.temp.round()}°C 등', style: const TextStyle(fontSize: 12)),
                value: _includeWeather,
                onChanged: (v) => setState(() => _includeWeather = v),
                contentPadding: EdgeInsets.zero,
              ),

            // Health Toggle
            if (widget.healthInfo != null && !widget.healthInfo!.isEmpty)
              SwitchListTile(
                title: const Text('건강/활동 정보 포함'),
                subtitle: Text(widget.healthInfo!.summary, style: const TextStyle(fontSize: 12)),
                value: _includeHealth,
                onChanged: (v) => setState(() => _includeHealth = v),
                contentPadding: EdgeInsets.zero,
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
          ],
        ),
      ),
    );
  }
}

// --- Result Loading/Display Dialog (Centered) ---

class AiGenerationResultDialog extends ConsumerStatefulWidget {
  final AiGenerationOptions options;
  final Future<String> Function(AiGenerationOptions options) onGenerate;

  const AiGenerationResultDialog({
    super.key,
    required this.options,
    required this.onGenerate,
  });

  @override
  ConsumerState<AiGenerationResultDialog> createState() => _AiGenerationResultDialogState();
}

class _AiGenerationResultDialogState extends ConsumerState<AiGenerationResultDialog> {
  bool _isLoading = true;
  String? _generatedResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  void _startGeneration() async {
    try {
      final result = await widget.onGenerate(widget.options);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _generatedResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prevent back button when loading
    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) _buildLoadingView(),
              if (_errorMessage != null) _buildErrorView(),
              if (_generatedResult != null) _buildResultView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'AI가 일기를 작성하고 있어요...',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '잠시만 기다려주세요',
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
        const SizedBox(height: 16),
        Text(
          '생성 중 오류가 발생했습니다',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? '알 수 없는 오류',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog, end flow
              child: const Text('닫기'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'retry'), // Return 'retry' to screen
              child: const Text('다시 설정 및 시도'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            Text('AI 일기 생성 완료', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _generatedResult ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, 'retry'), // Retry with same options
                child: const Text('다시 생성'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _generatedResult), // Return text
                child: const Text('사용하기'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
