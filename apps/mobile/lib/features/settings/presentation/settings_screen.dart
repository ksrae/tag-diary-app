import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/services/location_service.dart';
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
import 'package:permission_handler/permission_handler.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Feature flags
  bool _collectLocation = false;
  bool _collectNotification = false;
  bool _collectHealth = false;
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
        _collectLocation = prefs.getBool('feature_location_enabled') ?? false;
        _collectNotification = prefs.getBool('feature_notification_enabled') ?? false;
        _collectHealth = prefs.getBool('feature_health_enabled') ?? false;
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

          // Features & Permissions
          _buildSectionHeader(context, '기능 및 권한'),
          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: const Text('위치 정보'),
            subtitle: const Text('현재 위치와 날씨 자동 기록'),
            value: _collectLocation,
            onChanged: (value) => _togglePermission(
              Permission.location, 
              'feature_location_enabled', 
              value, 
              (v) => setState(() => _collectLocation = v)
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('알림'),
            subtitle: const Text('일기 작성 리마인더'),
            value: _collectNotification,
            onChanged: (value) => _togglePermission(Permission.notification, 'feature_notification_enabled', value, (v) => setState(() => _collectNotification = v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.health_and_safety),
            title: const Text('건강 정보 (Google Fit)'),
            subtitle: const Text('걸음 수 및 활동량 기록'),
            value: _collectHealth,
            onChanged: (value) => _togglePermission(Permission.activityRecognition, 'feature_health_enabled', value, (v) => setState(() => _collectHealth = v)),
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
          TextButton.icon(
            onPressed: () async {
              final service = ref.read(locationServiceProvider);
              final hasPermission = await service.requestPermission();
              if (hasPermission) {
                setState(() => _weatherRegion = '');
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('weather_region', '');
                await service.init(); // fetch location
                if (mounted) Navigator.pop(context);
              } else {
                await Geolocator.openAppSettings();
              }
            },
            icon: const Icon(Icons.my_location, size: 16),
            label: const Text('현재 위치 사용'),
          ),
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
  Future<void> _togglePermission(
    Permission permission, 
    String key, 
    bool value, 
    Function(bool) onUpdate
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      // User wants to ENABLE feature
      // 1. Check current status
      var status = await permission.status;
      
      if (status.isGranted) {
        onUpdate(true);
        await prefs.setBool(key, true);
      } else {
        // 2. Request permission
        final result = await permission.request();
        if (result.isGranted) {
          onUpdate(true);
          await prefs.setBool(key, true);
        } else if (result.isPermanentlyDenied) {
          // 3. Show settings dialog if permanently denied
          if (mounted) {
             showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('권한 설정 필요'),
                content: const Text('해당 기능을 사용하려면 설정에서 권한을 허용해야 합니다.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      openAppSettings();
                    },
                    child: const Text('설정으로 이동'),
                  ),
                ],
              ),
            );
          }
          // Reset toggle to false until they actually grant it
          onUpdate(false);
          await prefs.setBool(key, false);
        } else {
           // Normal denial
           onUpdate(false);
           await prefs.setBool(key, false);
        }
      }
    } else {
      // User wants to DISABLE feature
      // Just save preference, permission remains granted in system but app won't use it
      onUpdate(false);
      await prefs.setBool(key, false);
    }
  }
}
