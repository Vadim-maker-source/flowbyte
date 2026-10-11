import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_motion.dart';
import '../features/ai_tutor/assistant_screen.dart';
import '../features/exercises/exercise_screen.dart';
import '../features/final_mission/final_mission_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lessons/lesson_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/profile/certificate_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/rewards/completion_screen.dart';
import '../features/rewards/reward_screen.dart';

CustomTransitionPage<void> _page(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.standard,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .015),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _page(state, const SplashScreen()),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) => _page(state, const WelcomeScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _page(state, const OnboardingScreen()),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _page(state, const HomeScreen()),
    ),
    GoRoute(
      path: '/lesson/:id',
      pageBuilder: (context, state) =>
          _page(state, LessonScreen(lessonId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/exercise/:id',
      pageBuilder: (context, state) =>
          _page(state, ExerciseScreen(exerciseId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/reward/:id',
      pageBuilder: (context, state) =>
          _page(state, RewardScreen(exerciseId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/final',
      pageBuilder: (context, state) => _page(state, const FinalMissionScreen()),
    ),
    GoRoute(
      path: '/complete',
      pageBuilder: (context, state) => _page(state, const CompletionScreen()),
    ),
    GoRoute(
      path: '/assistant',
      pageBuilder: (context, state) => _page(
        state,
        AssistantScreen(
          lessonId: state.uri.queryParameters['lesson'],
          moduleId: state.uri.queryParameters['module'],
          topic: state.uri.queryParameters['topic'],
        ),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _page(state, const ProfileScreen()),
    ),
    GoRoute(
      path: '/certificate/:moduleId',
      pageBuilder: (context, state) => _page(
        state,
        CertificateScreen(moduleId: state.pathParameters['moduleId']!),
      ),
    ),
  ],
);
