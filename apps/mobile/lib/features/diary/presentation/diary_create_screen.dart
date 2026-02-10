import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/diary/application/diary_provider.dart';
import 'package:mobile/features/diary/data/diary_repository.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:mobile/features/diary/data/models/mood.dart';
import 'package:mobile/features/diary/data/models/source_item.dart';
import 'package:mobile/features/diary/presentation/diary_error_screen.dart';
import 'package:mobile/features/ai/presentation/ai_generation_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/premium/presentation/paywall_screen.dart';
import 'package:mobile/features/premium/application/purchase_provider.dart';
import 'package:mobile/features/ai/application/ai_service.dart';
import 'package:mobile/features/shared/data/health_repository.dart';
import 'package:mobile/features/shared/application/weather_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';

/// Single-page diary creation screen
/// Both Free and Pro: Show all today's photos, allow manual addition
/// Pro only: AI generation with max 3 selected photos
class DiaryCreateScreen extends ConsumerStatefulWidget {
  const DiaryCreateScreen({super.key, this.diary});
  final Diary? diary;

  @override
  ConsumerState<DiaryCreateScreen> createState() => _DiaryCreateScreenState();
}

class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> {
  Mood? _selectedMood;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isLoadingPhotos = true;
  bool _isAiGenerated = false;

  List<SourceItem> _photoItems = [];
  Weather? _weather;

  // Autocomplete
  List<String> _allSavedTags = [];
  List<String> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _loadSavedTags();
    _tagController.addListener(_onTagInputChanged);
    if (widget.diary != null) {
      _initFromDiary(widget.diary!);
    } else {
      _collectTodayPhotos();
    }
  }

  Future<void> _loadSavedTags() async {
    try {
      final diaries = await ref.read(diaryListProvider.future);
      final tags = <String>{};
      for (final diary in diaries) {
        for (final source in diary.sources) {
          if (source.type == 'tag') tags.add(source.contentPreview);
        }
      }
      if (mounted) setState(() => _allSavedTags = tags.toList()..sort());
    } catch (_) {}
  }

  void _onTagInputChanged() {
    final query = _tagController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredTags = []);
    } else {
      setState(() {
        _filteredTags = _allSavedTags
            .where((t) => t.toLowerCase().contains(query) && !_tags.contains(t))
            .take(5)
            .toList();
      });
    }
  }

  void _initFromDiary(Diary diary) {
    _contentController.text = diary.content;
    _isLoadingPhotos = false;
    if (diary.mood != null) {
      try {
        _selectedMood = Mood.values.firstWhere((m) => m.value == diary.mood);
      } catch (_) {}
    }
    _weather = diary.weather;
    _tags.addAll(diary.sources.where((s) => s.type == 'tag').map((s) => s.contentPreview));
    _photoItems = diary.photos.map((path) => SourceItem(
      const DiarySource(type: 'photo', appName: '갤러리', contentPreview: '사진', selected: true),
      diary.createdAt,
      imagePath: path,
    )).toList();
  }

  Future<void> _collectTodayPhotos() async {
    setState(() => _isLoadingPhotos = true);
    
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        debugPrint('Photo permission denied');
        if (mounted) setState(() => _isLoadingPhotos = false);
        return;
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Try today's photos first
      var filterOption = FilterOptionGroup(
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      );

      var albums = await PhotoManager.getAssetPathList(type: RequestType.image, filterOption: filterOption);
      
      List<AssetEntity> assets = [];
      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        assets = await recentAlbum.getAssetListRange(start: 0, end: 30);
      }
      
      // Fallback removed: Only valid photos for today are shown automatically.
      // Users can manually add older photos.

      await _processPhotoAssets(assets);
    } catch (e) {
      debugPrint('Photo collection error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPhotos = false);
    }
  }

  Future<void> _processPhotoAssets(List<AssetEntity> assets) async {
    if (!mounted || assets.isEmpty) return;
    
    final List<SourceItem> newItems = [];
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final file = await asset.file;
      if (file != null) {
        // Select ALL photos by default (AI modal will limit to 3)
        newItems.add(SourceItem(
          DiarySource(
            type: 'photo',
            appName: '갤러리',
            contentPreview: '${asset.createDateTime.hour}:${asset.createDateTime.minute.toString().padLeft(2, '0')}',
            selected: true,
          ),
          asset.createDateTime,
          imageFile: file,
        ));
      }
    }
    setState(() => _photoItems = newItems);
  }

  Future<void> _pickPhotosManually() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty && mounted) {
        setState(() {
          for (final image in images) {
            final file = File(image.path);
            final now = DateTime.now();
            _photoItems.insert(0, SourceItem(
              DiarySource(
                type: 'photo',
                appName: '수동추가',
                contentPreview: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                selected: true, // Auto-select manually added photos
              ),
              now,
              imageFile: file,
            ));
          }
        });
      }
    } catch (e) {
      debugPrint('Pick photo error: $e');
    }
  }

  @override
  void dispose() {
    _tagController.removeListener(_onTagInputChanged);
    _tagController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    // Split by whitespace (space, tab, etc.) - no spaces allowed in tags
    final newTags = value.split(RegExp(r'\s+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (newTags.isNotEmpty) {
      setState(() {
        for (var tag in newTags) {
          if (!_tags.contains(tag)) _tags.add(tag);
        }
        _tagController.clear();
        _filteredTags = [];
      });
    }
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  List<SourceItem> get _selectedPhotos => _photoItems.where((p) => p.source.selected).toList();

  bool get _hasAnyInfo => 
      _tags.isNotEmpty || 
      _selectedMood != null || 
      _selectedPhotos.isNotEmpty;

  Future<int> _getAiRemainingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = 'ai_usage_$today';
    final count = prefs.getInt(key) ?? 0;
    return 3 - count; // Max 3 per day
  }

  Future<void> _showAiGenerationModal() async {
    // Validate: must have some info for AI to use
    if (!_hasAnyInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI가 참고할 정보를 입력해주세요 (태그, 기분, 또는 사진)'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final healthAsync = ref.read(todayHealthProvider);
    final health = healthAsync.valueOrNull;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Prevent dismissing during generation
      enableDrag: false,
      builder: (context) => AiGenerationModal(
        photos: _selectedPhotos, // Only pass selected photos
        healthInfo: health,
        weather: _weather,
        tags: _tags,
        mood: _selectedMood,
        onGenerate: _generateWithAI,
      ),
    );

    // Handle result from modal
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _contentController.text = result;
        _isAiGenerated = true;
      });
      
      // Auto-save the diary after AI generation
      await _saveDiary();
    }
  }


  Future<String> _generateWithAI(List<SourceItem> selectedPhotos, bool includeHealth, String customPrompt, String selectedStyle) async {
    final isPro = ref.read(isProProvider);
    
    // Free users cannot use AI at all
    if (!isPro) {
      throw Exception('Pro 전용 기능입니다. AI 일기 작성은 Pro 사용자만 이용할 수 있습니다.');
    }

    // Pro users: Check daily limit (3 per day)
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = 'ai_usage_$today';
    final count = prefs.getInt(key) ?? 0;

    if (count >= 3) {
      throw Exception('일일 사용량 초과: 하루 3회까지 AI 일기를 생성할 수 있습니다.');
    }

    final health = await ref.read(todayHealthProvider.future);
    final weather = await ref.read(currentWeatherProvider.future);
    _weather = weather;

    // Build context from user-provided info only
    List<String> contextParts = [];
    
    if (_tags.isNotEmpty) {
      contextParts.add('태그: ${_tags.join(", ")}');
    }
    
    if (_selectedMood != null) {
      contextParts.add('기분: ${_selectedMood!.label}');
    }
    
    contextParts.add('날씨: ${weather.temp}°C ${weather.condition}');
    
    if (includeHealth && !health.isEmpty) {
      contextParts.add('활동: ${health.summary}');
    }
    
    if (selectedPhotos.isNotEmpty) {
      contextParts.add('사진 ${selectedPhotos.length}장 첨부');
    }

    String contextData = contextParts.join('\n');

    String stylePrompt = '';
    switch (selectedStyle) {
      case 'sn_style':
        stylePrompt = 'SNS 업로드용으로 해시태그와 함께 경쾌하게 작성해줘.';
        break;
      case 'basic_style':
        stylePrompt = '담백하고 솔직한 일기 스타일로 작성해줘.';
        break;
      case 'poem_style':
        stylePrompt = '감성적인 시 형식으로 작성해줘.';
        break;
      case 'letter_style':
        stylePrompt = '미래의 나에게 쓰는 편지 형식으로 따뜻하게 작성해줘.';
        break;
    }

    if (customPrompt.isNotEmpty) {
      stylePrompt += ' 추가 요청: $customPrompt';
    }

    final aiService = ref.read(aiServiceProvider);
    final result = await aiService.generateDiary(
      images: selectedPhotos.take(3).where((p) => p.imageFile != null).map((i) => i.imageFile!).toList(),
      contextData: contextData,
      mood: _selectedMood?.label,
      weather: weather.toJson(),
      sources: _tags.map((t) => {'type': 'tag', 'appName': 'user', 'contentPreview': t, 'selected': true}).toList(),
      userPrompt: stylePrompt,
    );

    // Increment usage count AFTER successful generation
    await prefs.setInt(key, count + 1);

    return result;
  }


  Future<void> _saveDiary() async {
    if (_contentController.text.isEmpty && _tags.isEmpty && _selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('일기 내용, 태그, 또는 기분을 입력해주세요')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tagSources = _tags.map((t) => DiarySource(type: 'tag', appName: 'user', contentPreview: t, selected: true)).toList();
      final selectedPhotosPaths = _selectedPhotos.map((s) => s.imagePath ?? s.imageFile?.path ?? '').where((p) => p.isNotEmpty).toList();

      // Add health info as source
      final health = ref.read(todayHealthProvider).valueOrNull;
      List<DiarySource> allSources = [...tagSources];
      if (health != null && health.steps > 0) {
        allSources.add(DiarySource(
          type: 'steps',
          appName: 'health',
          contentPreview: '${health.steps}걸음',
          selected: true,
        ));
      }

      // Content is saved as-is (don't add mood emoji to content)
      // Mood is stored separately in the mood field
      String content = _contentController.text;
      
      // If content is empty (manual save without text), use mood as content
      // If AI generated (content is not empty), this block is skipped, so only AI text is saved.
      if (content.isEmpty && _selectedMood != null) {
        content = '${_selectedMood!.emoji} ${_selectedMood!.label}';
      }

      if (widget.diary != null) {
        final updatedDiary = await ref.read(diaryRepositoryProvider).updateDiary(
          id: widget.diary!.id,
          content: content,
          mood: _selectedMood?.value,
          weather: _weather,
          sources: allSources,
          photos: selectedPhotosPaths,
          isAiGenerated: _isAiGenerated || widget.diary!.isAiGenerated,
          incrementEditCount: _isAiGenerated,
        );
        // Update both providers for compatibility
        ref.read(infiniteScrollDiaryListProvider.notifier).refresh();
        ref.read(diaryListProvider.notifier).updateDiary(updatedDiary);
      } else {
        final diary = await ref.read(diaryRepositoryProvider).createDiary(
          userId: '11111111-1111-1111-1111-111111111111',
          content: content,
          mood: _selectedMood?.value,
          weather: _weather,
          sources: allSources,
          photos: selectedPhotosPaths,
          isAiGenerated: _isAiGenerated,
        );
        // Add to infinite scroll list for immediate display
        ref.read(infiniteScrollDiaryListProvider.notifier).addDiary(diary);
        ref.read(diaryListProvider.notifier).addDiary(diary);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final healthAsync = ref.watch(todayHealthProvider);
    final weatherAsync = ref.watch(currentWeatherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 쓰기'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          TextButton(onPressed: _isLoading ? null : _saveDiary, child: const Text('저장')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Mood Selector
                  _buildMoodSelector(),
                  const Divider(height: 24),

                  // 2. Info Row - Weather with region, Health with larger text
                  Row(
                    children: [
                      weatherAsync.when(
                        data: (w) {
                          final regionAsync = ref.watch(weatherRegionProvider);
                          final regionName = regionAsync.valueOrNull ?? '';
                          return GestureDetector(
                            onTap: () => context.push('/settings'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  w.condition == 'sunny' ? Icons.wb_sunny : Icons.cloud,
                                  size: 22,
                                  color: w.condition == 'sunny' ? Colors.orange : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text('$regionName ${w.temp.round()}°', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(width: 60, height: 22, child: LinearProgressIndicator()),
                        error: (_, __) => const Icon(Icons.error_outline, size: 22),
                      ),
                      const SizedBox(width: 16),
                      healthAsync.when(
                        data: (h) => h.isEmpty
                            ? Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final url = Platform.isIOS ? 'x-apple-health://' : 'https://fit.google.com';
                                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.directions_run, size: 16, color: Colors.grey.shade500),
                                        const SizedBox(width: 6),
                                        Text(
                                          '건강 앱 연결 필요',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Expanded(
                                child: Row(
                                  children: [
                                    _buildHealthItem(Icons.directions_walk, '${h.steps}'),
                                    const SizedBox(width: 14),
                                    _buildHealthItem(Icons.timer_outlined, '${h.activeMinutes}분'),
                                    const SizedBox(width: 14),
                                    _buildHealthItem(Icons.local_fire_department, '${h.calories.toInt()}kcal'),
                                  ],
                                ),
                              ),
                        loading: () => const Expanded(child: LinearProgressIndicator()),
                        error: (_, __) => Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final url = Platform.isIOS ? 'x-apple-health://' : 'https://fit.google.com';
                              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade400),
                                  const SizedBox(width: 6),
                                  Text(
                                    '건강 정보 불러오기 실패',
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Tags
                  const Text('태그', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags.map((tag) => Chip(
                      label: Text('#$tag'),
                      onDeleted: () => _removeTag(tag),
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                  TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: '태그 입력',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: _addTag,
                    onChanged: (val) {
                      if (val.endsWith(' ')) _addTag(val.substring(0, val.length - 1));
                    },
                  ),
                  if (_filteredTags.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _filteredTags.map((tag) => InkWell(
                          onTap: () => _addTag(tag),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Text('#$tag'),
                          ),
                        )).toList(),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 4. Photos Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('사진', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          if (_selectedPhotos.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '${_selectedPhotos.length}개 선택',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _pickPhotosManually,
                        icon: const Icon(Icons.add_photo_alternate, size: 18),
                        label: const Text('추가'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (_isLoadingPhotos)
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    )
                  else if (_photoItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 20, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text('사진이 없습니다', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Max item size 80px - will fit 4+ items on normal phones, more on wider screens
                        const maxItemSize = 80.0;
                        const spacing = 6.0;
                        
                        // Calculate how many items fit per row
                        final itemsPerRow = (constraints.maxWidth / (maxItemSize + spacing)).floor().clamp(4, 10);
                        final itemWidth = (constraints.maxWidth - (spacing * (itemsPerRow - 1))) / itemsPerRow;
                        
                        // Calculate rows needed (max 2 rows visible)
                        final rowsNeeded = (_photoItems.length / itemsPerRow).ceil();
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
                            itemCount: _photoItems.length,
                            itemBuilder: (context, index) {
                              final item = _photoItems[index];
                              final isSelected = item.source.selected;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _photoItems[index] = item.copyWith(
                                      source: item.source.copyWith(selected: !isSelected),
                                    );
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: item.imageFile != null
                                            ? Image.file(item.imageFile!, fit: BoxFit.cover)
                                            : item.imagePath != null
                                                ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                                                : const Icon(Icons.image),
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

                  const SizedBox(height: 24),

                  // 5. AI Button (Pro only with remaining count)
                  if (isPro)
                    FutureBuilder<int>(
                      future: _getAiRemainingCount(),
                      builder: (context, snapshot) {
                        final remaining = snapshot.data ?? 3;
                        final isDisabled = remaining <= 0;
                        
                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isDisabled ? null : _showAiGenerationModal,
                            icon: const Icon(Icons.auto_awesome),
                            label: Text(remaining > 0 
                              ? 'AI로 일기 생성 ($remaining회 남음)' 
                              : 'AI 사용량 초과 (자정에 초기화)'),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // 6. Content Editor
                  const Text('일기 내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: isPro ? 'AI가 생성하거나 직접 작성하세요' : '일기를 직접 작성하세요',
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  if (!isPro) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 18, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Pro로 업그레이드하면 AI가 일기를 작성해줍니다', style: TextStyle(fontSize: 12, color: Colors.amber.shade900))),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
                            child: const Text('Pro'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHealthItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 3),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildMoodSelector() {
    final isPro = ref.watch(isProProvider);
    const moods = [Mood.happy, Mood.sad, Mood.angry, Mood.tired, Mood.peaceful];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.map((m) {
        final isSelected = _selectedMood == m;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedMood = m);
            
            // Only insert mood phrase if NOT AI generated
            if (!_isAiGenerated) {
              final currentText = _contentController.text;
              // Check if first line already has a mood phrase
              final lines = currentText.split('\n');
              final hasMoodPhrase = Mood.values.any((mood) => 
                lines.isNotEmpty && lines.first.contains(mood.phrase.split('.').first));
              
              if (hasMoodPhrase && lines.isNotEmpty) {
                // Replace first line with new mood phrase
                lines[0] = m.phrase;
                _contentController.text = lines.join('\n');
              } else {
                // Insert at beginning
                _contentController.text = currentText.isEmpty 
                    ? m.phrase 
                    : '${m.phrase}\n$currentText';
              }
              _contentController.selection = TextSelection.fromPosition(
                TextPosition(offset: _contentController.text.length),
              );
            }
          },
          child: Column(
            children: [
              Text(m.emoji, style: TextStyle(fontSize: 28, color: isSelected ? null : Colors.grey.withOpacity(0.4))),
              if (isSelected) Text(m.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
