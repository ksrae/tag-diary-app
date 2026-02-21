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
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize AdMob
  MobileAds.instance.initialize();

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters (Diary, DiarySource, Mood, Weather)
  Hive.registerAdapter(DiaryAdapter());
  Hive.registerAdapter(DiarySourceAdapter());
  Hive.registerAdapter(WeatherAdapter()); // Mood is not a class but handled as String or Adapter needed if enum
  // Note: Mood is an enum, we are storing it as String in DiaryRepository, so we might not need an adapter if we didn't annotate it.
  // Checking Diary model: mood is String? so no adapter needed for Mood itself.
  
  // Open Encrypted Box
  // Moved this logic to DiaryRepository._init() lazy loading pattern, 
  // but if we want strictly pre-open we can do it here. 
  // For now, let's just ensure adapters are checked.
  const secureStorage = FlutterSecureStorage();
  final encryptionKeyString = await secureStorage.read(key: 'diary_encryption_key');
  
  List<int> encryptionKey;
  if (encryptionKeyString == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'diary_encryption_key',
      value: base64UrlEncode(key),
    );
    encryptionKey = key;
  } else {
    encryptionKey = base64Url.decode(encryptionKeyString);
  }

  // Open Encrypted Box (Commented out until adapters are ready)
  // await Hive.openBox<Diary>(
  //   'diaries',
  //   encryptionCipher: HiveAesCipher(encryptionKey),
  // );

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
