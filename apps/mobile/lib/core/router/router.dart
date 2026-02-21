import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/features/diary/presentation/diary_feed_screen.dart';
import 'package:mobile/features/diary/presentation/diary_create_screen.dart';
import 'package:mobile/features/diary/presentation/diary_detail_screen.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/settings/presentation/settings_screen.dart';
import 'package:mobile/features/lock/presentation/pin_setup_screen.dart';
import 'package:mobile/features/lock/presentation/lock_screen.dart';
import 'package:mobile/features/settings/presentation/notification_settings_screen.dart';

part 'router.g.dart';

@riverpod
/// The main router for the application.
GoRouter router(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == '/login';
      if (authState.isLoading) return null;

      final user = authState.value;

      if (user == null && !isAuthRoute) {
        return '/login';
      }

      if (user != null && isAuthRoute) {
        return '/';
      }

      return null;
    },
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'notification',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
        ],
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
