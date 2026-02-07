import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/diary/application/diary_provider.dart';
import 'package:mobile/features/diary/data/diary_repository.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:mobile/features/diary/data/models/mood.dart';
import 'package:mobile/features/diary/data/models/source_item.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_calendar/device_calendar.dart' as cal;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Event;
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/premium/presentation/paywall_screen.dart';
import 'package:mobile/features/premium/application/purchase_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/features/ai/application/ai_service.dart';
import 'package:mobile/features/ai/presentation/ai_compose_screen.dart';
import 'package:mobile/core/constants/prompts.dart';




// Models moved to external files

class DiaryCreateScreen extends ConsumerStatefulWidget {
  const DiaryCreateScreen({super.key, this.diary});
  
  final Diary? diary;

  @override
  ConsumerState<DiaryCreateScreen> createState() => _DiaryCreateScreenState();
}

class _DiaryCreateScreenState extends ConsumerState<DiaryCreateScreen> with WidgetsBindingObserver {
  int _currentStep = 0;
  Mood? _selectedMood;
  final _contentController = TextEditingController();
  final _promptController = TextEditingController();
  
  Weather? _weather;
  
  List<SourceItem> _photoItems = [];
  List<SourceItem> _calendarItems = [];
  List<SourceItem> _locationItems = [];
  List<SourceItem> _stepsItems = [];
  
  final _imagePicker = ImagePicker();
  final _deviceCalendarPlugin = cal.DeviceCalendarPlugin();
  
  bool _isLoading = false;
  bool _isAiGenerated = false;
  String _loadingStatus = '';
  
  Position? _currentPosition;
  
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _showContactOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.diary != null) {
      _initFromDiary(widget.diary!);
    } else {
      _fetchWeather();
      _requestPermissionsAndCollectData();
    }
    _contentController.addListener(_onTextChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ONLY auto-refresh if we don't have location yet
      _checkLocationPermission().then((_) {
        if (!_locationPermissionDenied && _locationItems.isEmpty) {
          _collectLocation(onlyRestore: false);
        }
      });
    }
  }

  void _initFromDiary(Diary diary) {
    _contentController.text = diary.content;
    
    if (diary.mood != null) {
      try {
        _selectedMood = Mood.values.firstWhere((m) => m.value == diary.mood);
      } catch (_) {}
    }
    
    _weather = diary.weather;
    _currentStep = 0; 
    
    // Restore photos - we treat these as "already selected"
    // We can't easily re-fetch "unselected" photos from that day without PhotoManager.
    // So we just show the ones that were saved.
    _photoItems = diary.photos.map((path) => SourceItem(
      const DiarySource(
        type: 'photo', 
        appName: '갤러리', 
        contentPreview: '사진', 
        selected: true
      ),
      diary.createdAt,
      imagePath: path,
    )).toList();

    // Trigger data collection for the diary date to populate other lists (Calendar, Steps, etc.)
    _requestPermissionsAndCollectData(targetDate: diary.createdAt);
  }
  
  // Track location loading state
  bool _isLocationLoading = false;
  bool _locationPermissionDenied = false;


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contentController.removeListener(_onTextChanged);
    _contentController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (selection.baseOffset > 0) {
      final lastChar = text.substring(selection.baseOffset - 1, selection.baseOffset);
      if (lastChar == '@') {
        _loadContacts();
        setState(() => _showContactOverlay = true);
      } else if (_showContactOverlay) {
        final lastAtIdx = text.lastIndexOf('@', selection.baseOffset - 1);
        if (lastAtIdx != -1) {
          final query = text.substring(lastAtIdx + 1, selection.baseOffset).toLowerCase();
          setState(() {
            _filteredContacts = _contacts.where((c) {
              final name = '${c.name.first} ${c.name.last}'.toLowerCase();
              return name.contains(query);
            }).toList();
          });
        }
        if (lastChar == ' ' || lastChar == '\n') {
          setState(() => _showContactOverlay = false);
        }
      }
    } else {
      setState(() => _showContactOverlay = false);
    }
  }

  Future<void> _loadContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
      });
    }
  }

  void _tagContact(Contact contact) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final lastAtIdx = text.lastIndexOf('@', selection.baseOffset - 1);
    
    if (lastAtIdx != -1) {
      final name = contact.displayName;
      final newText = text.replaceRange(lastAtIdx, selection.baseOffset, '@$name ');
      _contentController.text = newText;
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: lastAtIdx + name.length + 2),
      );
    }
    setState(() => _showContactOverlay = false);
  }

  Future<void> _fetchWeather() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Try GPS location first if available
    if (_currentPosition != null) {
      if (mounted) {
        setState(() {
          // Mock weather for current coordinates
          _weather = const Weather(temp: 18.2, condition: 'sunny', icon: 'gps');
        });
      }
      return;
    }

    // 2. Fallback to user-defined region (Global City Support)
    final region = prefs.getString('weather_region') ?? 'Seoul';
    
    if (mounted) {
      setState(() {
        // Mock data based on city name
        double temp = 15;
        if (region.toLowerCase().contains('seoul')) temp = -5; // Winter in Korea
        if (region.toLowerCase().contains('tokyo')) temp = 7;
        if (region.toLowerCase().contains('london')) temp = 4;
        if (region.toLowerCase().contains('new york')) temp = -2;
        if (region.toLowerCase().contains('sydney')) temp = 25; // Summer in Australia
        
        _weather = Weather(
          temp: temp, 
          condition: 'cloudy',
          icon: 'city',
        );
      });
    }
  }

  Future<void> _requestPermissionsAndCollectData({DateTime? targetDate}) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _loadingStatus = '데이터를 불러오는 중...';
    });
    
    final now = targetDate ?? DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    try {
      // Photos - auto-load today's photos
      if (mounted) setState(() => _loadingStatus = '오늘의 사진 확인 중...');
      await _collectTodayPhotos(startOfDay, endOfDay);
      
      // Calendar
      final calendarStatus = await Permission.calendar.status;
      if (calendarStatus.isGranted) {
        if (mounted) setState(() => _loadingStatus = '캘린더 확인 중...');
        await _collectCalendar(startOfDay, endOfDay, now);
      } else if (calendarStatus.isDenied) {
        final result = await Permission.calendar.request();
        if (result.isGranted) {
          if (mounted) setState(() => _loadingStatus = '캘린더 확인 중...');
          await _collectCalendar(startOfDay, endOfDay, now);
        }
      }

      // Location: Fetch immediately for new diaries if not already present
      await _checkLocationPermission();
      if (widget.diary != null) {
        await _collectLocation(onlyRestore: true);
      } else if (_locationItems.isEmpty) {
        // Only fetch if we don't have it yet (avoid redundant calls)
        if (mounted) setState(() => _loadingStatus = '현재 위치 확인 중...');
        await _collectLocation(onlyRestore: false);
      }
      
      // Activity (Steps)
      if (await Permission.activityRecognition.request().isGranted) {
        if (mounted) setState(() => _loadingStatus = '걸음 수 확인 중...');
        await _collectSteps(startOfDay, endOfDay, now);
      }
      
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = '';
        });
      }
    }
  }
  
  /// Collect today's photos from device gallery using photo_manager
  Future<void> _collectTodayPhotos(DateTime startOfDay, DateTime endOfDay) async {
    try {
      // Request permission
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        debugPrint('Photo permission not granted');
        return;
      }
      
      // Create filter for today's photos only
      final filterOption = FilterOptionGroup(
        createTimeCond: DateTimeCond(
          min: startOfDay,
          max: endOfDay,
        ),
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      );
      
      // Get all asset paths (albums)
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );
      
      if (albums.isEmpty) return;
      
      // Get photos from the main album (usually "Recent" or "All Photos")
      final recentAlbum = albums.first;
      final assets = await recentAlbum.getAssetListRange(start: 0, end: 50); // Limit to 50 photos
      
      if (mounted && assets.isNotEmpty) {
        final List<SourceItem> newPhotoItems = [];
        
        for (final asset in assets) {
          final file = await asset.file;
          if (file != null) {
            newPhotoItems.add(SourceItem(
              DiarySource(
                type: 'photo',
                appName: '갤러리',
                contentPreview: '${asset.createDateTime.hour}:${asset.createDateTime.minute.toString().padLeft(2, '0')} 사진',

                selected: true, // Default selected as per user request
              ),
              asset.createDateTime,
              imageFile: file,
            ));
          }
        }
        
        setState(() {
          _photoItems = newPhotoItems;
        });
      }
    } catch (e) {
      debugPrint('Error collecting photos: $e');
    }
  }
  
  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (mounted) {
      setState(() {
        _locationPermissionDenied = status.isDenied || status.isPermanentlyDenied;
      });
    }
  }

  
  Future<void> _collectCalendar(DateTime startOfDay, DateTime endOfDay, DateTime now) async {
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars().timeout(
        const Duration(seconds: 10),
      );
      
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        debugPrint('Calendar: Found ${calendarsResult.data!.length} calendars. Fetching events from $startOfDay to $endOfDay');
        final List<cal.Event> todaysEvents = [];
        for (var calendar in calendarsResult.data!) {
          try {
             debugPrint('Calendar: Checking "${calendar.name}" (ID: ${calendar.id}, Account: ${calendar.accountName}, Type: ${calendar.accountType})');
            final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
              calendar.id,
              cal.RetrieveEventsParams(startDate: startOfDay, endDate: endOfDay),
            ).timeout(const Duration(seconds: 5));
            
            if (eventsResult.isSuccess && eventsResult.data != null) {
              if (eventsResult.data!.isNotEmpty) {
                 debugPrint('Calendar: Found ${eventsResult.data!.length} events in "${calendar.name}"');
                 todaysEvents.addAll(eventsResult.data!);
              }
            } else {
              debugPrint('Calendar: Failed events fetch for "${calendar.name}" - ${eventsResult.errors.join(', ')}');
            }
          } catch (e) {
            debugPrint('Calendar: Error fetching events from "${calendar.name}": $e');
          }
        }
        
        debugPrint('Calendar: Total events for today: ${todaysEvents.length}');
        
        if (mounted) {
          setState(() {
            _calendarItems = todaysEvents.map((event) {
              final content = '${event.title ?? "일정"} (${_formatTime(event.start)})';
              final isSelected = widget.diary?.sources.any(
                (s) => s.type == 'calendar' && s.contentPreview == content && s.selected
              ) ?? false;
              
              return SourceItem(
                DiarySource(
                  type: 'calendar',
                  appName: '캘린더',
                  contentPreview: content,
                  selected: isSelected,
                ),
                event.start != null ? DateTime.fromMillisecondsSinceEpoch(event.start!.millisecondsSinceEpoch) : now,
              );
            }).toList();
          });
        }
      } else {
        debugPrint('Calendar: Failed to retrieve calendars - isSuccess: ${calendarsResult.isSuccess}');
      }
    } catch (e) {
      debugPrint('Calendar: Exception during collection: $e');
    }
  }
  
  Future<void> _collectLocation({bool onlyRestore = false, bool force = false}) async {
    // GUARD: If we already have location and not forcing, skip.
    if (!force && !onlyRestore && _locationItems.isNotEmpty) return;

    try {
      // 1. Restore from Diary if available
      if (widget.diary != null && _locationItems.isEmpty) {
        final savedLocation = widget.diary!.sources.firstWhere(
          (s) => s.type == 'location', 
          orElse: () => const DiarySource(type: 'none', appName: '', contentPreview: '', selected: false)
        );
        
        if (savedLocation.type == 'location') {
           if (mounted) {
             setState(() {
               _locationItems = [
                 SourceItem(
                   savedLocation,
                   widget.diary!.createdAt,
                 )
               ];
             });
           }
        }
      }
      
      if (onlyRestore) return;
      if (!force && _locationItems.isNotEmpty) return;

      // 2. Fetch Current Location
      if (await Permission.location.request().isGranted) {
         if (mounted) {
           setState(() {
             _loadingStatus = '위치 확인 중...';
             _isLocationLoading = true;
           });
         }
         
         _currentPosition = await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 10),
         );
        
        if (mounted && _currentPosition != null) {
          setState(() {
            final content = '현재 위치: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
            
            _locationItems = [
              SourceItem(
                DiarySource(
                  type: 'location',
                  appName: '위치',
                  contentPreview: content,
                  selected: true, // Auto-select when manually added/refreshed
                ),
                DateTime.now(),
              ),
            ];
            _loadingStatus = '';
          });
          // Update weather after getting exact location
          _fetchWeather();
        }
      }
    } catch (_) {
       // If fetch failed, keep existing items or show error
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }
  
  Future<void> _collectSteps(DateTime startOfDay, DateTime endOfDay, DateTime now) async {
    try {
      final health = Health();
      final types = [HealthDataType.STEPS];
      
      final healthData = await health.getHealthDataFromTypes(
        types: types,
        startTime: startOfDay,
        endTime: endOfDay,
      ).timeout(const Duration(seconds: 5));
      
      int totalSteps = 0;
      for (var data in healthData) {
        if (data.type == HealthDataType.STEPS) {
          totalSteps += (data.value as num).toInt();
        }
      }
      
      if (mounted && totalSteps > 0) {
        setState(() {
          final content = '오늘 $totalSteps걸음 걸었어요';
          final isSelected = widget.diary?.sources.any(
            (s) => s.type == 'steps' && s.selected // steps content might differ slightly if updated, but logic holds. 
            // Better to check type 'steps' since usually only one per day.
          ) ?? false;
          
          _stepsItems = [
            SourceItem(
              DiarySource(
                type: 'steps',
                appName: '활동',
                contentPreview: content,
                selected: isSelected,
              ),
              now,
            ),
          ];
        });
      }
    } catch (_) {}
  }
  


  Future<void> _pickPhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty && mounted) {
        setState(() {
          for (final image in images) {
            final file = File(image.path);
            final now = DateTime.now();
            _photoItems.add(SourceItem(
              DiarySource(
                type: 'photo',
                appName: '갤러리',
                contentPreview: '${now.hour}:${now.minute.toString().padLeft(2, '0')} 사진',
                selected: true,
              ),
              now,
              imageFile: file,
            ));
          }
        });
      }
    } catch (_) {}
  }
  
  String _formatTime(cal.TZDateTime? time) {
    if (time == null) return '';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _onItemSelected(List<SourceItem> items, int index, bool selected) {
    setState(() {
      items[index] = items[index].copyWith(
        source: items[index].source.copyWith(selected: selected),
      );
    });
  }

  List<DiarySource> get _selectedSources {
    return [
      ..._photoItems.where((s) => s.source.selected).map((s) => s.source),
      ..._calendarItems.where((s) => s.source.selected).map((s) => s.source),
      ..._locationItems.where((s) => s.source.selected).map((s) => s.source),
      ..._stepsItems.where((s) => s.source.selected).map((s) => s.source),
    ];
  }
  
  List<SourceItem> get _selectedSourceItems {
    return [
      ..._photoItems.where((s) => s.source.selected),
      ..._calendarItems.where((s) => s.source.selected),
      ..._locationItems.where((s) => s.source.selected),
      ..._stepsItems.where((s) => s.source.selected),
    ];
  }

  Future<void> _generateWithAI() async {
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaywallScreen()),
      );
      return;
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => AiComposeScreen(
          initialPhotoItems: _photoItems,
          initialOtherItems: [..._calendarItems, ..._locationItems, ..._stepsItems],
          weather: _weather,
          mood: _selectedMood,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _contentController.text = result;
        _isAiGenerated = true;
      });
    }
  }

  Future<void> _saveDiary() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기 내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.diary != null) {
        // Update existing diary
        final updatedDiary = await ref.read(diaryRepositoryProvider).updateDiary(
          id: widget.diary!.id,
          content: _contentController.text,
          mood: _selectedMood?.value,
          weather: _weather,
          sources: _selectedSources,
          photos: _photoItems.where((s) => s.source.selected).map((s) => s.imagePath ?? s.imageFile?.path ?? '').toList(),
          isAiGenerated: _isAiGenerated || widget.diary!.isAiGenerated,
          incrementEditCount: _isAiGenerated, // Increment only if AI was used in this session
        );
         ref.read(diaryListProvider.notifier).updateDiary(updatedDiary);
      } else {
        // Create new diary
        final diary = await ref.read(diaryRepositoryProvider).createDiary(
          userId: '11111111-1111-1111-1111-111111111111', 
          content: _contentController.text,
          mood: _selectedMood?.value,
          weather: _weather,
          sources: _selectedSources,
          photos: _photoItems.where((s) => s.source.selected).map((s) => s.imagePath ?? s.imageFile?.path ?? '').toList(),
          isAiGenerated: _isAiGenerated,
        );
        ref.read(diaryListProvider.notifier).addDiary(diary);
      }
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      debugPrint('Error saving diary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isPro ? Colors.amber : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPro ? 'PRO' : 'FREE',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildCurrentStep(),
          if (_showContactOverlay) _buildContactOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // Helper widget to build badge, avoiding massive rebuilds if possible, 
  // but simpler to just put logic in build or extract widget. 
  // Let's modify build() method instead to watch provider.


  Widget _buildContactOverlay() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _filteredContacts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('연락처를 찾을 수 없습니다.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    return ListTile(
                      title: Text(contact.displayName),
                      onTap: () => _tagContact(contact),
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return '기록 선택';
      case 1: return '기분 선택';
      case 2: return '일기 작성';
      default: return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildDataSelectionStep();
      case 1: return _buildMoodSelectionStep();
      case 2: return _buildWritingStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildDataSelectionStep() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (_loadingStatus.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _loadingStatus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }
  
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '오늘 하루를 기록할 항목을 선택해주세요.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '모든 데이터는 기기에만 저장되며, 외부로 전송되지 않습니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        _buildPhotoSection(),
        const SizedBox(height: 24),
        _buildDataSection(
          title: '캘린더 일정',
          count: _calendarItems.length,
          items: _calendarItems,
          icon: Icons.calendar_today,
          buildItem: (item, index) => _buildListItem(item, index, _calendarItems),
        ),
        const SizedBox(height: 24),
        _buildLocationSection(),
        const SizedBox(height: 24),
        _buildDataSection(
          title: '걸음 수',
          count: _stepsItems.length,
          items: _stepsItems,
          icon: Icons.directions_walk,
          buildItem: (item, index) => _buildListItem(item, index, _stepsItems),
        ),
      ],
    );
  }
  
  Widget _buildDataSection({
    required String title,
    required int count,
    required List<SourceItem> items,
    required IconData icon,
    VoidCallback? onAdd,
    String? addLabel,
    IconData? addIcon,
    required Widget Function(SourceItem, int) buildItem,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '$title ($count)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (onAdd != null)
              FilledButton.icon(
                onPressed: onAdd,
                icon: Icon(addIcon ?? Icons.add, size: 18),
                label: Text(addLabel ?? '추가'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.grey[600])),
          )
        else
          ...items.asMap().entries.map((entry) => buildItem(entry.value, entry.key)),
      ],
    );
  }
  
  /// Custom location section with permission denied handling
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '위치 (${_locationItems.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (!_locationPermissionDenied && !_isLocationLoading)
              FilledButton.icon(
                onPressed: () => _collectLocation(onlyRestore: false, force: true),
                icon: Icon(_locationItems.isEmpty ? Icons.add_location : Icons.refresh, size: 18),
                label: Text(_locationItems.isEmpty ? '위치 추가' : '새로고침'),
              ),
            if (_isLocationLoading)
              const SizedBox(
                width: 16, 
                height: 16, 
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLocationLoading)
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('위치 정보를 가져오는 중입니다...', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          )
        else if (_locationPermissionDenied && _locationItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '위치 권한이 없어 정보를 가져올 수 없습니다.',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Try opening specific location settings first
                        final opened = await Geolocator.openLocationSettings();
                        if (!opened) {
                           // Fallback to app settings
                           openAppSettings();
                        }
                      },
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('설정에서 허용하기'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () => _collectLocation(onlyRestore: false, force: true),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('다시 시도'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (_locationItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.grey[600])),
          )
        else
          ..._locationItems.asMap().entries.map((entry) => _buildLocationItem(entry.value, entry.key)),
      ],
    );
  }

  /// Grid view for photos (3 columns)
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '오늘의 사진 (${_photoItems.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('추가'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photoItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('오늘 찍은 사진이 없습니다.', style: TextStyle(color: Colors.grey[600])),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: _photoItems.length,
            itemBuilder: (context, index) => _buildPhotoGridItem(_photoItems[index], index),
          ),
      ],
    );
  }

  Widget _buildPhotoGridItem(SourceItem item, int index) {
    return InkWell(
      onTap: () => _onItemSelected(_photoItems, index, !item.source.selected),
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageFile != null
              ? Image.file(
                  item.imageFile!,
                  fit: BoxFit.cover,
                )
              : _contextPreviewOrPath(item),
          ),
          if (item.source.selected)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _contextPreviewOrPath(SourceItem item) {
      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
          return Image.file(File(item.imagePath!), fit: BoxFit.cover);
      }
      return Container(color: Colors.grey[300], child: const Icon(Icons.error));
  }

  
  Widget _buildPhotoItem(SourceItem item, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _onItemSelected(_photoItems, index, !item.source.selected),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: item.source.selected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey.shade300,
              width: item.source.selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (item.imageFile != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: Image.file(
                    item.imageFile!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else if (item.imagePath != null && item.imagePath!.isNotEmpty)
                 ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: Image.file(
                    File(item.imagePath!),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 24),
                      );
                    },
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.source.contentPreview)),
                      if (item.source.selected)
                        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLocationItem(SourceItem item, int index) {
    return ListTile(
      leading: Checkbox(
        value: item.source.selected,
        onChanged: (value) => _onItemSelected(_locationItems, index, value ?? false),
      ),
      title: Text(item.source.contentPreview),
      subtitle: GestureDetector(
        onTap: () {
            // Extract lat/long
            final regex = RegExp(r'[-+]?([0-9]*\.[0-9]+|[0-9]+)');
            final matches = regex.allMatches(item.source.contentPreview).toList();
            if (matches.length >= 2) {
              final lat = matches[0].group(0);
              final lng = matches[1].group(0);
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
              launchUrl(url, mode: LaunchMode.externalApplication);
            }
        },
        child: const Row(
          children: [
            Icon(Icons.map, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text('지도 앱에서 보기', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
          ],
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildListItem(SourceItem item, int index, List<SourceItem> sourceList) {
    return CheckboxListTile(
      value: item.source.selected,
      onChanged: (value) => _onItemSelected(sourceList, index, value ?? false),
      title: Text(item.source.contentPreview),
      subtitle: Text('${item.dateTime.hour}:${item.dateTime.minute.toString().padLeft(2, '0')}'),
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildMoodSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('이 일기에 감정을 포함할까요?', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('오늘의 감정을 아이콘으로 남겨보세요.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: Mood.values.map((mood) {
              final isSelected = _selectedMood == mood;
              return InkWell(
                onTap: () => setState(() => _selectedMood = mood),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                    boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(mood.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => setState(() => _selectedMood = null),
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('감정 없이 작성하기'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: _selectedMood == null ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWritingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('오늘의 일기', style: Theme.of(context).textTheme.titleSmall),
              if (_selectedSourceItems.isNotEmpty && ref.watch(isProProvider))
                TextButton.icon(
                  onPressed: _isLoading ? null : _generateWithAI,
                  icon: Icon(
                    Icons.auto_awesome, 
                    size: 16, 
                    color: ref.watch(isProProvider) ? Colors.amber : Colors.grey,
                  ),
                  label: Text(
                    'AI로 일기 작성',
                    style: TextStyle(
                      color: ref.watch(isProProvider) ? Colors.amber : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '오늘의 일기를 작성하세요... @를 입력하여 연락처를 태그할 수 있습니다.',
                border: OutlineInputBorder(),
              ),
              maxLines: 15,
              minLines: 8,
            ),
            const SizedBox(height: 16),
            if (!ref.watch(isProProvider))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pro 버전으로 업그레이드하고, AI가 써주는 특별한 하루를 경험해보세요! ✨',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentStep--), child: const Text('이전'))),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isLoading ? null : () {
                  if (_currentStep < 2) setState(() => _currentStep++);
                  else _saveDiary();
                },
                child: Text(_currentStep < 2 ? '다음' : '완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
