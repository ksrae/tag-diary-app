import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/firebase_options.dart';
import 'package:mobile/core/router/router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/lock/application/lock_service.dart';
import 'package:mobile/features/lock/presentation/lock_screen.dart';
import 'package:mobile/features/shared/data/health_repository.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/firestore_service.dart';
import 'package:mobile/features/premium/application/purchase_provider.dart';
import 'package:mobile/features/premium/presentation/paywall_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize AdMob
  MobileAds.instance.initialize();

  FlutterError.onError = (errorDetails) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(errorDetails);
    }
  };

  runApp(ProviderScope(
    child: const MyApp(),
    overrides: [],
  ));
}

/// {@template my_app}
/// The root widget of the application.
/// {@endtemplate}
class MyApp extends ConsumerStatefulWidget {
  /// {@macro my_app}
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isLocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    // Remove native splash immediately so Flutter's large logo splash is visible
    FlutterNativeSplash.remove();

    // Mark first run as done (permissions will be requested on-demand)
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('is_first_run') ?? true;
    if (isFirstRun) {
      await prefs.setBool('is_first_run', false);
    }
    
    // 1. Check lock settings
    final lockService = ref.read(lockServiceProvider);
    final enabled = await lockService.isLockEnabled();
    final hasPin = await lockService.hasPin();

    if (enabled && hasPin) {
      if (mounted) setState(() => _isLocked = true);
    }

    // 2. Initialize Health & Notification (only requests permission once)
    await _initHealth();

    // 3. Show 7-day deletion warning for free users
    _showFreeUserDeletionWarning();
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _initHealth() async {
    try {
      final healthRepo = ref.read(healthRepositoryProvider);
      await healthRepo.initWithPermission();
      
      // Init Notification Service
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.init();
    } catch (e) {
      debugPrint('Init error: $e');
    }
  }

  /// Shows a one-time-per-session warning to free users about 7-day data deletion.
  Future<void> _showFreeUserDeletionWarning() async {
    try {
      final plan = ref.read(subscriptionPlanProvider);
      if (plan != SubscriptionPlan.free) return;

      final authService = ref.read(authServiceProvider);
      final uid = authService.currentUser?.uid;
      if (uid == null) return;

      // Only show once per day
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastShown = prefs.getString('free_warning_last_shown');
      if (lastShown == today) return;
      await prefs.setString('free_warning_last_shown', today);

      // Wait for UI to settle
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Get the navigator context from the router
      final context = this.context;
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Flexible(child: Text('무료 플랜 안내')),
            ],
          ),
          content: const Text(
            '무료 플랜에서는 최근 3일간의 일기만 열람/수정할 수 있습니다.\n\n'
            '• 4~7일 전 일기: 잠금 처리됨\n'
            '• 7일 경과 일기: 서버에서 자동 삭제\n\n'
            '소중한 일기를 평생 보관하려면 업그레이드하세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: const Text('요금제 보기'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Free user warning error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If loading, show splash screen with LARGE logo (Hybrid Splash)
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF311B92), // Match native splash color
          body: Center(
            child: Image.asset(
              'assets/splash.png',
              width: 280, // Large logo size
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }
    
    if (_isLocked) {
      return MaterialApp(
        title: 'AI 일기 (잠금)',
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: LockScreen(
          onUnlock: () {
            setState(() => _isLocked = false);
          },
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko'), Locale('en')],
        localeResolutionCallback: _localeResolutionCallback,
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AI 일기',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en')],
      localeResolutionCallback: _localeResolutionCallback,
    );
  }

  Locale? _localeResolutionCallback(
      Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) {
      return const Locale('en');
    }

    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    return const Locale('en');
  }
}
