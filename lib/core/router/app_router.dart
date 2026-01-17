import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iwantsun/presentation/screens/welcome_screen.dart';
import 'package:iwantsun/presentation/screens/onboarding_screen.dart';
import 'package:iwantsun/presentation/screens/home_screen.dart';
import 'package:iwantsun/presentation/screens/search_simple_screen.dart';
import 'package:iwantsun/presentation/screens/search_advanced_screen.dart';
import 'package:iwantsun/presentation/screens/search_results_screen.dart';
import 'package:iwantsun/presentation/screens/favorites_screen_enhanced.dart';
import 'package:iwantsun/presentation/screens/history_screen.dart';
import 'package:iwantsun/presentation/screens/settings_screen.dart';
import 'package:iwantsun/core/theme/app_animations.dart';

/// Configuration du routeur de l'application
class AppRouter {
  static GoRouter get router => _router;

  static final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: AppAnimations.fadeTransition(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: AppAnimations.slideTransition(
            direction: SlideDirection.up,
          ),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: AppAnimations.fadeTransition(),
        ),
      ),
      GoRoute(
        path: '/search/simple',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchSimpleScreen(),
          transitionsBuilder: AppAnimations.slideTransition(
            direction: SlideDirection.left,
          ),
        ),
      ),
      GoRoute(
        path: '/search/advanced',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchAdvancedScreen(),
          transitionsBuilder: AppAnimations.slideTransition(
            direction: SlideDirection.left,
          ),
        ),
      ),
      GoRoute(
        path: '/search/results',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchResultsScreen(),
          transitionsBuilder: AppAnimations.slideTransition(
            direction: SlideDirection.up,
          ),
        ),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FavoritesScreenEnhanced(),
          transitionsBuilder: AppAnimations.scaleTransition(),
        ),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HistoryScreen(),
          transitionsBuilder: AppAnimations.slideTransition(
            direction: SlideDirection.left,
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: AppAnimations.slideTransition(
            direction: SlideDirection.left,
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page non trouvée: ${state.uri}'),
      ),
    ),
  );
}
