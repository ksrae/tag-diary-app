import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/router/router.dart';
import 'package:mobile/core/router/router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/lock/application/lock_service.dart';
import 'package:mobile/features/lock/presentation/lock_screen.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/features/diary/data/models/diary.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const ProviderScope(child: MyApp()));
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
    final lockService = ref.read(lockServiceProvider);
    final enabled = await lockService.isLockEnabled();
    final hasPin = await lockService.hasPin();

    if (enabled && hasPin) {
      if (mounted) setState(() => _isLocked = true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    
    if (_isLocked) {
      return MaterialApp(
        title: 'AI 일기 (잠금)',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
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
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AI 일기',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en')],
    );
  }
}
