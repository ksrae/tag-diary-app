import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/diary/data/diary_repository.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  NotificationService(this._ref);

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Failed to get local timezone: $e');
      // Fallback to UTC or a default if possible, but scheduling might be off.
      // Usually works on real devices.
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Default behavior opens the app.
        // We can handle specific navigation here if we pass payload (e.g. diaryId).
      },
    );
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> scheduleMonthlyMemories(TimeOfDay alarmTime) async {
    // 1. Cancel all existing
    await cancelAll();

    // 2. Get all diaries
    final repo = _ref.read(diaryRepositoryProvider);
    final diaries = await repo.getAllDiaries();
    
    if (diaries.isEmpty) return;

    final now = DateTime.now();

    // 3. Iterate next 12 months (including current)
    for (int i = 0; i < 12; i++) {
      // Target Month (starts from "This Month")
      // Actually, if we are in Feb, and we find a target in Feb but date passed, we skip.
      // So checking 12 months is safe.
      
      // Calculate target Year/Month
      // DateTime handles overflow (month + i)
      final tempDate = DateTime(now.year, now.month + i);
      final targetYear = tempDate.year;
      final targetMonth = tempDate.month;
      
      // Look back 1 year from the target month
      final lookBackYear = targetYear - 1;
      
      // Find diaries in (lookBackYear, targetMonth)
      final candidates = diaries.where((d) {
        return d.createdAt.year == lookBackYear && 
               d.createdAt.month == targetMonth &&
               !_isBadMood(d.mood);
      }).toList();
      
      if (candidates.isEmpty) continue;

      // Sort by day ascending (find first one)
      candidates.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      final selectedDiary = candidates.first;
      
      // Construct Schedule Date in Current/Next Year
      // We want the same day of month.
      // Handle day overflow if selectedDiary is 29th, 30th, 31st and target month is shorter.
      final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      final day = selectedDiary.createdAt.day > daysInTargetMonth 
          ? daysInTargetMonth 
          : selectedDiary.createdAt.day;
      
      final scheduleDate = DateTime(
        targetYear, 
        targetMonth, 
        day, 
        alarmTime.hour, 
        alarmTime.minute,
      );
      
      // If scheduler date is in the past, skip this month (because logic is "once a month")
      // Unless it's today and time is future? 
      if (scheduleDate.isBefore(now)) {
        continue;
      }

      // Schedule it
      // Use "i" as ID or generate unique ID based on month
      // ID collision with other notifications? 
      // Safe to use 1000 + i
      
      debugPrint('Scheduling notification for $scheduleDate (Diary from ${selectedDiary.createdAt})');
      
      await _scheduleNotification(
        id: 1000 + i,
        title: '1년 전 오늘의 추억',
        body: '작년 ${selectedDiary.createdAt.month}월 ${selectedDiary.createdAt.day}일의 소중한 기억을 확인해보세요.',
        date: scheduleDate,
        payload: selectedDiary.id,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    String? payload,
  }) async {
    try {
      // Use TZDateTime
      final location = tz.local;
      final tzDate = tz.TZDateTime.from(date, location);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'memory_channel',
            '추억 알림',
            channelDescription: '1년 전 추억 알림입니다',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  bool _isBadMood(String? mood) {
    if (mood == null) return false;
    // Mood values from enum: happy, sad, peaceful, angry, tired, loved
    return ['sad', 'angry', 'tired'].contains(mood);
  }

  Future<void> scheduleTestNotification() async {
    final now = DateTime.now();
    final scheduleDate = now.add(const Duration(seconds: 5));
    
    await _scheduleNotification(
      id: 9999,
      title: '테스트 알림 완료!',
      body: '정상적으로 알림이 설정되었습니다. (이 알림은 설정 저장 5초 후 나타납니다)',
      date: scheduleDate,
    );
  }
}
