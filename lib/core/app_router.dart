import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/coping/coping_screen.dart';
import '../features/cravings/cravings_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/quit/profile.dart';
import '../features/game/mario_game_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final onboarded = ref.watch(profileProvider.select((p) => p.isOnboarded));
  // Rebuild router when onboarding state changes
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      // Minimal stream to trigger refresh; here we derive from provider manually
      ref.watch(profileProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/onboarding';
      if (!onboarded && !loggingIn) return '/onboarding';
      if (onboarded && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fade(const OnboardingScreen()),
      ),
      GoRoute(
        path: '/cravings',
        pageBuilder: (context, state) => _fade(const CravingsScreen()),
      ),
      GoRoute(
        path: '/stats',
        pageBuilder: (context, state) => _fade(const StatsScreen()),
      ),
      GoRoute(
        path: '/coping',
        pageBuilder: (context, state) => _fade(const CopingScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _fade(const SettingsScreen()),
      ),
      GoRoute(
        path: '/game',
        pageBuilder: (context, state) => _fade(const MarioGameScreen()),
      ),
    ],
  );
});

CustomTransitionPage<void> _fade(Widget child) => CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );

// A simple wrapper to use a stream to refresh GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
