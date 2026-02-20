import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme/app_theme.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback? onDone;

  const PermissionScreen({super.key, this.onDone});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  // Permission Statuses (Actual System Status)
  bool _isPhotosGranted = false;
  bool _isNotificationGranted = false;
  bool _isHealthGranted = false;

  // Checkbox States (User Choice)
  bool _isPhotosChecked = false; // Initially false, interactive
  bool _isNotificationChecked = false; // Initially false
  bool _isHealthChecked = false;

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    final photos = await Permission.photos.status;
    final storage = await Permission.storage.status;
    final notification = await Permission.notification.status;
    // Health (Sensors/Activity)
    final sensors = await Permission.sensors.status; 
    final activity = await Permission.activityRecognition.status;

    if (mounted) {
      setState(() {
        _isPhotosGranted = photos.isGranted || storage.isGranted;
        _isNotificationGranted = notification.isGranted;
        _isHealthGranted = activity.isGranted || sensors.isGranted;
        
        _isPhotosChecked = false;
        _isNotificationChecked = false;
        _isHealthChecked = false;
      });
    }
  }

  Future<void> _checkPermissionsOnly() async {
     // Only update system status, DO NOT touch checkboxes (user intent)
    final photos = await Permission.photos.status;
    final storage = await Permission.storage.status;
    final notification = await Permission.notification.status;
    final sensors = await Permission.sensors.status; 
    final activity = await Permission.activityRecognition.status;

    if (mounted) {
      setState(() {
        _isPhotosGranted = photos.isGranted || storage.isGranted;
        _isNotificationGranted = notification.isGranted;
        _isHealthGranted = activity.isGranted || sensors.isGranted;
      });
    }
  }

  Future<void> _requestSelected() async {
    List<Permission> permissionsToRequest = [];

    // Photos is MANDATORY (if checked)
    if (_isPhotosChecked && !_isPhotosGranted) {
      if (await Permission.photos.request().isGranted) {
         // Good
      } else if (await Permission.storage.request().isGranted) {
         // Good (Android < 13)
      }
    }

    // Optional permissions - only if checked
    if (_isNotificationChecked && !_isNotificationGranted) {
      permissionsToRequest.add(Permission.notification);
    }
    if (_isHealthChecked && !_isHealthGranted) {
      permissionsToRequest.add(Permission.activityRecognition);
      // Note: sensors doesn't always need runtime request depending on Android version, but activity does.
    }

    if (permissionsToRequest.isNotEmpty) {
      await permissionsToRequest.request();
    }

    await _checkPermissionsOnly();

    // Final Check: If user checked mandatory but permission is still denied (e.g. permanently denied),
    // we must block or guide them. The user said "If mandatory not checked, disable button".
    // But what if they check it, click confirm, deny system dialog?
    // Then _isPhotosGranted is false. Should we block?
    // The previous logic blocked. I will keep blocking logic if they INTENDED to grant it but failed.
    if (_isPhotosChecked && !_isPhotosGranted) {
      if (mounted) _showMandatoryDialog();
    } else {
      await _finishOnboarding();
    }
  }
  
  void _showMandatoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('필수 권한 안내'),
        content: const Text('일기 작성을 위해 사진/저장소 접근 권한은 필수입니다.\n설정에서 권한을 허용해주세요.'),
        actions: [
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

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_run', false);
    
    // Save User Choices for features
    await prefs.setBool('feature_health_enabled', _isHealthChecked);
    await prefs.setBool('feature_notification_enabled', _isNotificationChecked);
    
    if (mounted) {
      if (widget.onDone != null) {
        widget.onDone!();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Button is disabled only if Mandatory (Photos) is unchecked
    final bool canProceed = _isPhotosChecked;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      '권한 설정',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '원활한 앱 사용을 위해 권한을 설정해주세요.\n필수 권한은 허용해야 계속 진행할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // MANDATORY: Photos
                    _PermissionCheckboxItem(
                      icon: Icons.photo_library_outlined,
                      title: '사진 접근 (필수)',
                      description: '일기에 사진을 첨부하기 위해 필요합니다.',
                      value: _isPhotosChecked, 
                      onChanged: (v) => setState(() => _isPhotosChecked = v ?? false),
                      isLocked: false, // User can uncheck, but button disables
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // OPTIONAL: Notification
                    _PermissionCheckboxItem(
                      icon: Icons.notifications_none_outlined,
                      title: '알림 (선택)',
                      description: '일기 리마인더 알림을 받습니다.',
                      value: _isNotificationChecked,
                      onChanged: (v) => setState(() => _isNotificationChecked = v ?? false),
                    ),

                    const SizedBox(height: 24),

                    // OPTIONAL: Health
                    _PermissionCheckboxItem(
                      icon: Icons.health_and_safety_outlined,
                      title: '건강 정보 (선택)',
                      description: '오늘의 활동량(걸음 수 등)을 일기에 기록합니다.\n(Google Fit 계정 연동 필요)',
                      value: _isHealthChecked,
                      onChanged: (v) => setState(() => _isHealthChecked = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: canProceed ? _requestSelected : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: canProceed ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCheckboxItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool isLocked;

  const _PermissionCheckboxItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLocked ? null : () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox or Icon
          Container(
            padding: const EdgeInsets.all(2), // Checkbox padding
            child: Checkbox(
              value: value,
              onChanged: isLocked ? null : onChanged,
              activeColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10), // Align with checkbox
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
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
