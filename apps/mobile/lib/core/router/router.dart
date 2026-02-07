import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/features/diary/presentation/diary_feed_screen.dart';
import 'package:mobile/features/diary/presentation/diary_create_screen.dart';
import 'package:mobile/features/diary/presentation/diary_detail_screen.dart';
import 'package:mobile/features/auth/presentation/signup_screen.dart';
import 'package:mobile/features/settings/presentation/settings_screen.dart';
import 'package:mobile/features/lock/presentation/pin_setup_screen.dart';
import 'package:mobile/features/lock/presentation/lock_screen.dart';

part 'router.g.dart';

@riverpod
/// The main router for the application.
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Main diary feed
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const DiaryFeedScreen(),
      ),
      // Create diary
      GoRoute(
        path: '/diary/create',
        builder: (context, state) => const DiaryCreateScreen(),
      ),
      // Diary detail
      GoRoute(
        path: '/diary/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DiaryDetailScreen(diaryId: id);
        },
      ),
      // Auth
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // App Lock Setup
      GoRoute(
        path: '/lock/setup',
        name: 'lock_setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
      // Lock Screen
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),
    ],
  );
}
