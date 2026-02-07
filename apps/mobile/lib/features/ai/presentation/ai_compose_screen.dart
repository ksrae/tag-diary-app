import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:mobile/features/diary/data/models/mood.dart';
import 'package:mobile/features/diary/data/models/source_item.dart';
import 'package:mobile/features/ai/application/ai_service.dart';

class AiComposeScreen extends ConsumerStatefulWidget {
  final List<SourceItem> initialPhotoItems;
  final List<SourceItem> initialOtherItems;
  final Weather? weather;
  final Mood? mood;

  const AiComposeScreen({
    super.key,
    required this.initialPhotoItems,
    required this.initialOtherItems,
    this.weather,
    this.mood,
  });

  @override
  ConsumerState<AiComposeScreen> createState() => _AiComposeScreenState();
}

class _AiComposeScreenState extends ConsumerState<AiComposeScreen> {
  late List<SourceItem> _photoItems;
  late List<SourceItem> _otherItems;
  String _selectedPromptTemplate = '따뜻하고 감성적인 일기';
  final _customPromptController = TextEditingController();
  bool _isLoading = false;

  final Map<String, String> _promptTemplates = {
    '따뜻하고 감성적인 일기': '오늘 하루를 아주 따뜻하고 감성적인 말투로 일기를 작성해줘. 소중한 순간들이 잘 드러나게 해줘.',
    '사실 위주의 간결한 일기': '오늘 있었던 일들을 사실 위주로 아주 간결하고 명확하게 일기로 작성해줘. 불필요한 수식어는 빼줘.',
    '생생하고 현장감 넘치는 일기': '오늘의 분위기와 현장감이 생생하게 느껴지도록 일기를 작성해줘. 당시에 느꼈던 감각들을 잘 묘사해줘.',
    '직접 입력': '',
  };

  @override
  void initState() {
    super.initState();
    _photoItems = List.from(widget.initialPhotoItems);
    _otherItems = List.from(widget.initialOtherItems);
  }

  @override
  void dispose() {
    _customPromptController.dispose();
    super.dispose();
  }

  Future<void> _generateDiary() async {
    setState(() => _isLoading = true);

    try {
      final selectedPhotos = _photoItems.where((i) => i.source.selected).toList();
      final selectedOthers = _otherItems.where((i) => i.source.selected).toList();
      
      final sortedItems = [...selectedPhotos, ...selectedOthers]
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      String contextData = sortedItems
          .where((i) => i.source.type != 'photo')
          .map((i) => '- [${i.source.appName}] ${i.source.contentPreview}')
          .join('\n');

      final userPrompt = _selectedPromptTemplate == '직접 입력' 
          ? _customPromptController.text 
          : _promptTemplates[_selectedPromptTemplate];

      final aiService = ref.read(aiServiceProvider);
      
      final result = await aiService.generateDiary(
        images: selectedPhotos.map((i) => i.imageFile!).toList(),
        contextData: contextData,
        mood: widget.mood?.label,
        weather: widget.weather?.toJson(),
        sources: selectedOthers.map((i) => i.source.toJson()).toList(),
        userPrompt: userPrompt,
      );

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일기 생성 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 일기 구성'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _generateDiary,
              child: const Text('생성하기', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text('Gemini가 일기를 작성하고 있습니다...', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('잠시만 기다려주세요.', style: theme.textTheme.bodySmall),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('사진 선택', '일기에 포함할 사진을 골라주세요.'),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoItems.length,
                  itemBuilder: (context, index) {
                    final item = _photoItems[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _photoItems[index] = item.copyWith(
                            source: item.source.copyWith(selected: !item.source.selected),
                          );
                        });
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: item.imageFile != null 
                                ? Image.file(item.imageFile!, fit: BoxFit.cover, width: 100, height: 120)
                                : item.imagePath != null 
                                  ? Image.file(File(item.imagePath!), fit: BoxFit.cover, width: 100, height: 120)
                                  : Container(color: Colors.grey[300]),
                            ),
                            if (item.source.selected)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.colorScheme.primary, width: 3),
                                  ),
                                  child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('기록 선택', '일기의 소재가 될 활동들을 선택해주세요.'),
              const SizedBox(height: 12),
              ..._otherItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return CheckboxListTile(
                  value: item.source.selected,
                  onChanged: (val) {
                    setState(() {
                      _otherItems[index] = item.copyWith(
                        source: item.source.copyWith(selected: val ?? false),
                      );
                    });
                  },
                  title: Text(item.source.contentPreview),
                  subtitle: Text(item.source.appName),
                  secondary: _getIconForType(item.source.type),
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 32),
              
              _buildSectionTitle('글 스타일 선택', '어떤 분위기로 일기를 작성할까요?'),
              const SizedBox(height: 16),
              ..._promptTemplates.keys.map((title) {
                final isSelected = _selectedPromptTemplate == title;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ChoiceChip(
                    label: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(title, textAlign: TextAlign.center),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPromptTemplate = title);
                    },
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }),
              
              if (_selectedPromptTemplate == '직접 입력') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customPromptController,
                  decoration: const InputDecoration(
                    hintText: 'AI에게 요청할 내용을 입력하세요 (예: 유머러스하게 써줘)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Icon _getIconForType(String type) {
    switch (type) {
      case 'calendar': return const Icon(Icons.calendar_today);
      case 'location': return const Icon(Icons.location_on);
      case 'steps': return const Icon(Icons.directions_walk);
      default: return const Icon(Icons.info_outline);
    }
  }
}
