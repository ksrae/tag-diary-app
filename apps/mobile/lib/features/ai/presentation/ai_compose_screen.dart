
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:mobile/features/diary/data/models/mood.dart';
import 'package:mobile/features/diary/data/models/source_item.dart';
import 'package:mobile/features/ai/application/ai_service.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/features/shared/data/health_repository.dart';
import 'package:mobile/features/shared/data/models/health_info.dart';
import 'package:mobile/features/shared/application/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/premium/presentation/paywall_screen.dart';
import 'package:mobile/features/premium/application/purchase_provider.dart';

class AiComposeScreen extends ConsumerStatefulWidget {
  final List<SourceItem> initialPhotoItems;
  final Weather? weather; // Passed from previous screen or null
  final Mood? mood;

  const AiComposeScreen({
    super.key,
    required this.initialPhotoItems,
    this.weather,
    this.mood,
  });

  @override
  ConsumerState<AiComposeScreen> createState() => _AiComposeScreenState();
}

class _AiComposeScreenState extends ConsumerState<AiComposeScreen> {
  // State
  late Mood? _selectedMood;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  
  String _selectedStyle = 'sn_style'; // Default
  String _customStylePrompt = '';
  bool _isLoading = false;

  final Map<String, String> _styles = {
    'sn_style': 'SNS 스타일',
    'basic_style': '기본 일기',
    'poem_style': '시(Poem)',
    'letter_style': '편지 스타일',
    'custom': '직접 입력',
  };

  // Pre-defined tags for filter/suggestion
  final List<String> _registeredTags = ['운동', '독서', '공부', '여행', '맛집', '친구', '영화', '휴식'];

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.mood;
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    // Split by comma and trim
    final newTags = value.split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    
    if (newTags.isNotEmpty) {
      setState(() {
        for (var tag in newTags) {
          if (!_tags.contains(tag)) {
            _tags.add(tag);
          }
        }
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _generateDiary() async {
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final key = 'ai_usage_$today';
      final count = prefs.getInt(key) ?? 0;
      
      if (count >= 3) {
        if (mounted) {
           showDialog(
             context: context,
             builder: (context) => AlertDialog(
               title: const Text('일일 사용량 초과'),
               content: const Text('무료 버전은 하루 3회까지 AI 일기를 생성할 수 있습니다.\n무제한 생성을 위해 Pro로 업그레이드하세요.'),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                 FilledButton(
                   onPressed: () {
                     Navigator.pop(context);
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                   },
                   child: const Text('업그레이드'),
                 ),
               ],
             ),
           );
        }
        return;
      }
    }

    if (_tags.isEmpty && _selectedStyle != 'basic_style') {
       if (widget.initialPhotoItems.isEmpty && _tags.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('태그나 사진을 입력해주세요.')),
         );
         return;
       }
    }

    setState(() => _isLoading = true);

    try {
      final health = await ref.read(todayHealthProvider.future);
      
      // Context Data Preparation (no location - only weather for display)
      final tagString = _tags.join(', ');
      final weatherStr = widget.weather != null 
          ? '${widget.weather!.temp}°C ${widget.weather!.condition}' 
          : '';
      final healthStr = health.summary;

      String contextData = '''
Tags: $tagString
Weather: $weatherStr
Health: $healthStr
''';

      // ... (Style Prompt) ...
      String stylePrompt = '';
      switch (_selectedStyle) {
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
        case 'custom':
          stylePrompt = _customStylePrompt;
          break;
      }

      final aiService = ref.read(aiServiceProvider);
      
      final tagSources = _tags.map((t) => {
        'type': 'tag',
        'appName': 'user',
        'contentPreview': t,
        'selected': true,
      }).toList();

      final result = await aiService.generateDiary(
        images: widget.initialPhotoItems.map((i) => i.imageFile!).toList(),
        contextData: contextData,
        mood: _selectedMood?.label,
        weather: widget.weather?.toJson(),
        sources: tagSources, 
        userPrompt: stylePrompt,
      );

      // Increment usage count on success
      if (!isPro) {
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now().toIso8601String().split('T')[0];
        final key = 'ai_usage_$today';
        final count = prefs.getInt(key) ?? 0;
        await prefs.setInt(key, count + 1);
      }

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(todayHealthProvider);
    final weatherAsync = ref.watch(currentWeatherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 일기 구성'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // 1. Emotions (Top)
              _buildMoodSelector(),
              
              const Divider(),
              
              // 2. Tags Input area (Middle - Expanded)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text('오늘의 태그', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 8),
                       Wrap(
                         spacing: 8,
                         children: _tags.map((tag) => Chip(
                           label: Text(tag),
                           onDeleted: () => _removeTag(tag),
                         )).toList(),
                       ),
                       TextField(
                         controller: _tagController,
                         decoration: const InputDecoration(
                           hintText: '일기 태그 입력 (쉼표로 구분)',
                           border: UnderlineInputBorder(),
                         ),
                         onSubmitted: _addTag,
                         onChanged: (val) {
                           if (val.endsWith(',')) {
                             _addTag(val.substring(0, val.length - 1));
                           }
                         },
                       ),
                       
                       const SizedBox(height: 16),
                       // Registered Tags Filter
                       const Text('자주 쓰는 태그', style: TextStyle(fontSize: 12, color: Colors.grey)),
                       const SizedBox(height: 4),
                       SingleChildScrollView(
                         scrollDirection: Axis.horizontal,
                         child: Row(
                           children: _registeredTags.map((tag) => Padding(
                             padding: const EdgeInsets.only(right: 8),
                             child: ActionChip(
                               label: Text(tag),
                               onPressed: () => _addTag(tag),
                             ),
                           )).toList(),
                         ),
                       ),
                    ],
                  ),
                ),
              ),
              
              // 3. Info Card (Bottom)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  children: [
                    // Collected Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Weather
                        weatherAsync.when(
                          data: (weather) => Column(
                            children: [
                              // Ideally use weather.icon logic
                              Icon(
                                weather.condition == 'sunny' ? Icons.wb_sunny : Icons.cloud,
                                color: weather.condition == 'sunny' ? Colors.orange : Colors.grey,
                              ),
                              Text('${weather.temp}°C'),
                            ],
                          ),
                          loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_,__) => const Icon(Icons.error_outline),
                        ),
                        // Health
                        healthAsync.when(
                          data: (h) => Column(
                            children: [
                              const Icon(Icons.favorite, color: Colors.red),
                              Text(h.summary, style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          error: (_,__) => const Icon(Icons.error),
                          loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    
                    // Style Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _styles.entries.map((e) {
                          final isSelected = _selectedStyle == e.key;
                          final isPro = ref.watch(isProProvider);
                          final isLocked = !isPro && e.key != 'basic_style';
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Row(
                                children: [
                                  if (isLocked) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock, size: 12)),
                                  Text(e.value),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                if (isLocked) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                                  return;
                                }
                                if (val) setState(() => _selectedStyle = e.key);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedStyle == 'custom')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextField(
                          decoration: const InputDecoration(hintText: '원하는 스타일 입력'),
                          onChanged: (v) => _customStylePrompt = v,
                        ),
                      ),
                      
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _generateDiary,
                        child: const Text('일기 생성하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildMoodSelector() {
    // Top 5 moods
    final moods = [
      Mood.happy,
      Mood.sad,
      Mood.angry,
      Mood.tired,
      Mood.peaceful,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: moods.map((m) {
          final isSelected = _selectedMood == m;
          return GestureDetector(
            onTap: () => setState(() => _selectedMood = m),
            child: Column(
              children: [
                Text(m.emoji, style: TextStyle(fontSize: 32, color: isSelected ? null : Colors.grey.withOpacity(0.5))),
                if (isSelected)
                  Text(m.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
