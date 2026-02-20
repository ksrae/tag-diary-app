import 'dart:io';
import 'package:flutter/material.dart';
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
import 'package:mobile/features/shared/application/weather_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _collectHealth = false;
  bool _isLockEnabled = false;
  // Notification settings for preview
  bool _isNotificationEnabled = false;
  bool _isAllNotificationsEnabled = false;
  String _notificationTime = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _collectHealth = prefs.getBool('feature_health_enabled') ?? false;
        
        _isAllNotificationsEnabled = prefs.getBool('feature_all_notifications_enabled') ?? false;
        _isNotificationEnabled = prefs.getBool('feature_notification_enabled') ?? false;
        
        if (_isAllNotificationsEnabled) {
           final hour = prefs.getInt('notification_hour') ?? 9;
           // Format: "오후 1시"
           final isPm = hour >= 12;
           final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
           final period = isPm ? '오후' : '오전';
           _notificationTime = '$period $displayHour시';
        }
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
    final savedLocationAsync = ref.watch(savedLocationProvider);

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
          // Weather / Location - inside General section
          savedLocationAsync.when(
            data: (location) {
              if (location != null) {
                return ListTile(
                  leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                  title: const Text('날씨 / 지역'),
                  subtitle: Text(location.city, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                        tooltip: '지역 초기화',
                        onPressed: () async {
                          final service = ref.read(locationServiceProvider);
                          await service.clearLocation();
                          ref.invalidate(savedLocationProvider);
                          ref.invalidate(currentWeatherProvider);
                        },
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showLocationSettingSheet(context),
                );
              }
              return ListTile(
                leading: Icon(Icons.wb_sunny_outlined, color: Colors.grey.shade400),
                title: const Text('날씨 / 지역'),
                subtitle: const Text('지역을 설정하면 날씨를 자동으로 가져옵니다'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLocationSettingSheet(context),
              );
            },
            loading: () => const ListTile(
              leading: Icon(Icons.wb_sunny_outlined),
              title: Text('날씨 / 지역'),
              subtitle: Text('로딩 중...'),
            ),
            error: (_, __) => ListTile(
              leading: Icon(Icons.wb_sunny_outlined, color: Colors.grey.shade400),
              title: const Text('날씨 / 지역'),
              subtitle: const Text('지역을 설정해주세요'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLocationSettingSheet(context),
            ),
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
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('알림 설정'),
            subtitle: Text(_isAllNotificationsEnabled ? '매일 $_notificationTime' : '꺼짐'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await context.push('/settings/notification');
              _loadSettings(); // Refresh settings when returning
            },
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
            title: const Text('전체 일기 백업'),
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

  /// Show location setting bottom sheet with search and GPS button
  void _showLocationSettingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LocationSettingSheet(
        onLocationSaved: () {
          // Invalidate providers to refresh weather
          ref.invalidate(savedLocationProvider);
          ref.invalidate(currentWeatherProvider);
        },
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
      var status = await permission.status;
      
      if (status.isGranted) {
        onUpdate(true);
        await prefs.setBool(key, true);
      } else {
        final result = await permission.request();
        if (result.isGranted) {
          onUpdate(true);
          await prefs.setBool(key, true);
        } else if (result.isPermanentlyDenied) {
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
          onUpdate(false);
          await prefs.setBool(key, false);
        } else {
           onUpdate(false);
           await prefs.setBool(key, false);
        }
      }
    } else {
      // User wants to DISABLE feature
      onUpdate(false);
      await prefs.setBool(key, false);
    }
  }
}

/// Bottom sheet for setting weather location
class _LocationSettingSheet extends ConsumerStatefulWidget {
  final VoidCallback onLocationSaved;

  const _LocationSettingSheet({required this.onLocationSaved});

  @override
  ConsumerState<_LocationSettingSheet> createState() => _LocationSettingSheetState();
}

class _LocationSettingSheetState extends ConsumerState<_LocationSettingSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  List<_GeoSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isGpsLoading = false;
  bool _isReverseGeocoding = false;

  // Selected location for map preview (before closing)
  _GeoSearchResult? _selectedResult;

  // Map controller to move the map when tapping
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final response = await _dio.get(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {
          'name': query,
          'count': 10,
          'language': 'ko',
          'format': 'json',
        },
      );

      if (response.statusCode == 200 && response.data['results'] != null) {
        final results = (response.data['results'] as List).map((r) {
          return _GeoSearchResult(
            name: r['name'] as String? ?? '',
            country: r['country'] as String? ?? '',
            admin1: r['admin1'] as String? ?? '',
            latitude: (r['latitude'] as num).toDouble(),
            longitude: (r['longitude'] as num).toDouble(),
          );
        }).toList();
        setState(() => _searchResults = results);
      } else {
        setState(() => _searchResults = []);
      }
    } catch (_) {
      setState(() => _searchResults = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGpsLoading = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final result = await locationService.updateLocationFromGPS();
      if (result != null && mounted) {
        widget.onLocationSaved();
        // Show map preview instead of closing
        setState(() {
          _selectedResult = _GeoSearchResult(
            name: result.city,
            country: '',
            admin1: '',
            latitude: result.latitude,
            longitude: result.longitude,
          );
          _searchResults = [];
          _searchController.clear();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치를 가져올 수 없습니다. 위치 권한을 확인해주세요.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 가져오기 실패')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGpsLoading = false);
    }
  }

  /// Handle map tap: reverse geocode and save the tapped location
  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    // Immediately update marker position
    setState(() {
      _isReverseGeocoding = true;
      _selectedResult = _GeoSearchResult(
        name: '위치 확인 중...',
        country: '',
        admin1: '',
        latitude: point.latitude,
        longitude: point.longitude,
      );
    });

    // Reverse geocode to get city name
    final locationService = ref.read(locationServiceProvider);
    String city = await locationService.reverseGeocode(point.latitude, point.longitude);
    if (city.isEmpty) {
      city = '선택한 위치';
    }

    // Save the location
    await locationService.saveManualLocation(city, point.latitude, point.longitude);
    widget.onLocationSaved();

    if (mounted) {
      setState(() {
        _isReverseGeocoding = false;
        _selectedResult = _GeoSearchResult(
          name: city,
          country: '',
          admin1: '',
          latitude: point.latitude,
          longitude: point.longitude,
        );
      });
    }
  }

  Future<void> _selectLocation(_GeoSearchResult result) async {
    final locationService = ref.read(locationServiceProvider);
    await locationService.saveManualLocation(
      result.name,
      result.latitude,
      result.longitude,
    );
    widget.onLocationSaved();
    if (mounted) {
      // Show map preview instead of closing
      setState(() {
        _selectedResult = result;
        _searchResults = [];
        _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Text(
                  '날씨 / 지역',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '도시 이름으로 검색 (예: 서울, 부산)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _searchLocation(value);
                } else {
                  setState(() => _searchResults = []);
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          // GPS button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGpsLoading ? null : _useCurrentLocation,
                icon: _isGpsLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, size: 18),
                label: Text(_isGpsLoading ? 'GPS로 위치 확인 중...' : '현재 위치로 설정하기', style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),

          // Content area: search results OR map preview
          Expanded(
            child: _buildContentArea(scrollController),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(ScrollController scrollController) {
    // Show search results if searching or have results
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        controller: scrollController,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(result.name),
            subtitle: Text(
              [result.admin1, result.country]
                  .where((s) => s.isNotEmpty)
                  .join(', '),
            ),
            dense: true,
            onTap: () => _selectLocation(result),
          );
        },
      );
    }

    // Show map preview if a location is selected
    if (_selectedResult != null) {
      return _buildMapPreview(_selectedResult!);
    }

    // Default - show saved location map or empty state
    final currentLocation = ref.watch(savedLocationProvider);
    return currentLocation.when(
      data: (loc) {
        if (loc != null) {
          return _buildMapPreview(_GeoSearchResult(
            name: loc.city,
            country: '',
            admin1: '',
            latitude: loc.latitude,
            longitude: loc.longitude,
          ));
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                '도시를 검색하거나\nGPS로 현재 위치를 감지하세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMapPreview(_GeoSearchResult location) {
    final center = LatLng(location.latitude, location.longitude);

    return Column(
      children: [
        // Location info bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: _isReverseGeocoding
                    ? Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '지역 확인 중...',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        location.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 14,
                        ),
                      ),
              ),
              if (!_isReverseGeocoding && (location.admin1.isNotEmpty || location.country.isNotEmpty))
                Text(
                  [location.admin1, location.country].where((s) => s.isNotEmpty).join(', '),
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                ),
            ],
          ),
        ),
        // Map fills remaining space
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                        ),
                      ],
                    ),
                  ],
                ),
                // Hint overlay at bottom of map
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '지도를 터치하여 위치를 변경할 수 있습니다',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GeoSearchResult {
  final String name;
  final String country;
  final String admin1;
  final double latitude;
  final double longitude;

  const _GeoSearchResult({
    required this.name,
    required this.country,
    required this.admin1,
    required this.latitude,
    required this.longitude,
  });
}
