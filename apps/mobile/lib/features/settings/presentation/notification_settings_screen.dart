import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _isAllNotificationsEnabled = false;
  bool _isOneYearAgoEnabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isAllNotificationsEnabled = prefs.getBool('feature_all_notifications_enabled') ?? false;
        _isOneYearAgoEnabled = prefs.getBool('feature_notification_enabled') ?? false;
        final hour = prefs.getInt('notification_hour') ?? 9;
        final minute = prefs.getInt('notification_minute') ?? 0;
        _time = TimeOfDay(hour: hour, minute: minute);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feature_all_notifications_enabled', _isAllNotificationsEnabled);
    await prefs.setBool('feature_notification_enabled', _isOneYearAgoEnabled);
    await prefs.setInt('notification_hour', _time.hour);
    await prefs.setInt('notification_minute', 0); // Always 0 minutes
    
    final service = ref.read(notificationServiceProvider);

    if (_isAllNotificationsEnabled && mounted) {
      // If Master is ON, we request permissions regardless of sub-switches
      // Wait, permission is probably needed before anything.
      await service.requestPermissions();
      
      // Schedule Features
      if (_isOneYearAgoEnabled) {
         await service.scheduleMonthlyMemories(_time);
      } else {
         // Cancel only this feature? For now, cancelAll is okay unless we add more features.
         // But if we have multiple, we need granular cancel.
         // Current implementation of scheduleMonthlyMemories calls cancelAll first.
         // So if we have other features, we need to rewrite service.
         // For now, if OneYearAgo is OFF, we just don't schedule it. 
         // Since it's the only one, we actually cancel all.
         await service.cancelAll();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정이 저장되었습니다.')),
      );
    } else {
      // Master OFF -> Cancel All
      await service.cancelAll();
      if (mounted) {
         // Optional feedback
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final isPm = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = isPm ? '오후' : '오전';
    return '$period $displayHour시';
  }

  void _showTimePicker() {
    // Current selection
    int selectedAmPm = _time.hour >= 12 ? 1 : 0; // 0: AM, 1: PM
    int selectedHour = _time.hourOfPeriod;
    if (selectedHour == 0) selectedHour = 12; // 12 AM/PM is represented as 12, not 0 in UI

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소', style: TextStyle(color: Colors.grey)),
                    ),
                    const Text(
                      '시간 선택',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Calculate 24h format from selection
                        int hour24;
                        if (selectedAmPm == 0) { // AM
                          // 12 AM -> 0, 1 AM -> 1, ... 11 AM -> 11
                          hour24 = (selectedHour == 12) ? 0 : selectedHour;
                        } else { // PM
                          // 12 PM -> 12, 1 PM -> 13, ... 11 PM -> 23
                          hour24 = (selectedHour == 12) ? 12 : selectedHour + 12;
                        }

                        setState(() {
                          _time = TimeOfDay(hour: hour24, minute: 0);
                        });
                        Navigator.pop(context);
                        await _saveSettings();
                      },
                      child: const Text('완료', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Pickers
              Expanded(
                child: Row(
                  children: [
                    // AM/PM Picker
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(initialItem: selectedAmPm),
                        onSelectedItemChanged: (int index) {
                          selectedAmPm = index;
                        },
                        children: const [
                          Center(child: Text('오전')),
                          Center(child: Text('오후')),
                        ],
                      ),
                    ),
                    // Hour Picker (1-12)
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(initialItem: selectedHour - 1), // 0-based index
                        onSelectedItemChanged: (int index) {
                          selectedHour = index + 1;
                        },
                        children: List.generate(12, (index) {
                          return Center(child: Text('${index + 1}시'));
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('알림 설정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('알림 받기'),
            subtitle: const Text('모든 알림을 켜거나 끕니다'),
            value: _isAllNotificationsEnabled,
            onChanged: (value) async {
              setState(() => _isAllNotificationsEnabled = value);
              await _saveSettings();
            },
          ),
          const Divider(),
          Opacity(
            opacity: _isAllNotificationsEnabled ? 1.0 : 0.5,
            child: AbsorbPointer(
              absorbing: !_isAllNotificationsEnabled,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('알림 시간'),
                    subtitle: Text(
                      _formatTimeOfDay(_time),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.keyboard_arrow_down),
                    onTap: _showTimePicker,
                  ),
                  SwitchListTile(
                    title: const Text('1년 전 추억 알림'),
                    subtitle: const Text('매달 첫 번째 즐거운 추억을 알려드려요'),
                    value: _isOneYearAgoEnabled,
                    onChanged: (value) async {
                      setState(() => _isOneYearAgoEnabled = value);
                      await _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
