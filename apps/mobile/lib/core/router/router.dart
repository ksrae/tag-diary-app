import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@riverpod
/// The main router for the application.
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (context, state) => const HomePage())],
  );
}

/// {@template home_page}
/// The home page of the application.
/// {@endtemplate}
class HomePage extends StatelessWidget {
  /// {@macro home_page}
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fullstack Starter')),
      body: const Center(child: Text('Welcome to Fullstack Starter')),
    );
  }
}
