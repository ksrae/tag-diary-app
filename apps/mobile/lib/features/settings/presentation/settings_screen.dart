import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/premium/presentation/paywall_screen.dart';
import 'package:mobile/features/premium/application/purchase_provider.dart';
import 'package:mobile/features/diary/data/diary_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/lock/application/lock_service.dart';
import 'package:go_router/go_router.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Settings values (mock for now, normally from prefs)
  bool _collectGallery = true;
  bool _collectCalendar = true;
  bool _collectLocation = true;
  bool _collectHealth = true;
  bool _isLockEnabled = false;
  String _weatherRegion = 'Seoul';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _collectGallery = prefs.getBool('collect_gallery') ?? true;
        _collectCalendar = prefs.getBool('collect_calendar') ?? true;
        _collectLocation = prefs.getBool('collect_location') ?? true;
        _collectHealth = prefs.getBool('collect_health') ?? true;
        _weatherRegion = prefs.getString('weather_region') ?? 'Seoul';
      });
      
      // Load lock state
      final lockEnabled = await ref.read(lockServiceProvider).isLockEnabled();
      if (mounted) {
        setState(() => _isLockEnabled = lockEnabled);
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          if (!isPro)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.deepPurple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaywallScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Pro로 업그레이드',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '무제한 기능 잠금 해제',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // General section (Formerly part of Account)
          // General section
          _buildSectionHeader(context, '일반'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('언어'),
            subtitle: const Text('시스템 설정 따름'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLanguageDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('날씨 지역'),
            subtitle: Text(_weatherRegion),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showWeatherRegionDialog(context);
            },
          ),
          const Divider(),

          // Security Section
          _buildSectionHeader(context, '보안'),
          SwitchListTile(
            secondary: const Icon(Icons.lock),
            title: const Text('앱 잠금'),
            subtitle: Text(_isLockEnabled ? '켜짐' : '꺼짐'),
            value: _isLockEnabled,
            onChanged: (value) async {
              if (value) {
                // Check if PIN already exists
                final hasPin = await ref.read(lockServiceProvider).hasPin();
                
                if (hasPin) {
                  // Re-enable existing lock
                  await ref.read(lockServiceProvider).enableLock();
                  await _loadSettings();
                } else {
                  // First time setup
                  final result = await context.pushNamed('lock_setup');
                  if (result == true) {
                    await _loadSettings(); 
                  }
                }
              } else {
                // Disable (keep PIN for convenience)
                await ref.read(lockServiceProvider).disableLock();
                setState(() => _isLockEnabled = false);
              }
            },
          ),
          if (_isLockEnabled)
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('비밀번호 변경'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                 await context.pushNamed('lock_setup');
                 await _loadSettings();
              },
            ),

          const Divider(),

          // Data collection section
          _buildSectionHeader(context, '데이터 수집'),
          SwitchListTile(
            secondary: const Icon(Icons.photo),
            title: const Text('갤러리'),
            subtitle: const Text('오늘 찍은 사진 수집'),
            value: _collectGallery,
            onChanged: (value) {
              setState(() => _collectGallery = value);
              _updateSetting('collect_gallery', value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_today),
            title: const Text('캘린더'),
            subtitle: const Text('오늘 일정 수집'),
            value: _collectCalendar,
            onChanged: (value) {
               setState(() => _collectCalendar = value);
               _updateSetting('collect_calendar', value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: const Text('위치'),
            subtitle: const Text('일기 작성 시 위치 정보 수집'),
            value: _collectLocation,
            onChanged: (value) {
               setState(() => _collectLocation = value);
               _updateSetting('collect_location', value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.directions_walk),
            title: const Text('활동'),
            subtitle: const Text('오늘의 걸음 수 수집'),
            value: _collectHealth,
            onChanged: (value) {
               setState(() => _collectHealth = value);
               _updateSetting('collect_health', value);
            },
          ),
          const Divider(),

          // Data Management section
          _buildSectionHeader(context, '데이터 관리'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('전체 일기 백업'), // Changed from json export to user request
            subtitle: const Text('현재까지의 모든 일기를 파일로 저장합니다'),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('일기 복원하기'),
            subtitle: const Text('백업 파일에서 일기를 불러옵니다'),
            onTap: () => _importData(context, ref),
          ),
          
          const Divider(),

          // Info section
          _buildSectionHeader(context, '정보'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('앱 정보'),
            subtitle: const Text('버전 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'AI 일기',
                applicationVersion: '1.0.0',
              );
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('언어 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('시스템 설정 따름'),
              value: 'system',
              groupValue: 'system',
              onChanged: (value) {
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('한국어'),
              value: 'ko',
              groupValue: 'system',
              onChanged: (value) {
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: 'system',
              onChanged: (value) {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWeatherRegionDialog(BuildContext context) {
    final TextEditingController cityController = TextEditingController(text: _weatherRegion);
    final regions = [
      'Seoul', 'Tokyo', 'New York', 'London', 'Paris', 'Berlin', 'Sydney', 'Singapore'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('날씨 지역 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('도시 이름을 영문으로 입력하거나 목록에서 선택하세요.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                hintText: '예: London, New York, Busan',
                labelText: '도시 이름',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final region = regions[index];
                  return ListTile(
                    title: Text(region),
                    dense: true,
                    onTap: () => cityController.text = region,
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final newRegion = cityController.text.trim();
              if (newRegion.isNotEmpty) {
                setState(() => _weatherRegion = newRegion);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('weather_region', newRegion);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }


  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(diaryRepositoryProvider);
      final jsonString = await repository.exportData();
      
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'diary_backup_$formattedDate.json';
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);
      
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'AI 일기 백업 ($formattedDate)',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 내보내기 실패: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        
        final repository = ref.read(diaryRepositoryProvider);
        final count = await repository.importData(jsonString);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count개의 일기 복원 완료')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 불러오기 실패: $e')),
        );
      }
    }
  }
}
