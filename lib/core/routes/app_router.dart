import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/history/presentation/interview_history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/interview/domain/interview_config.dart';
import '../../features/interview/domain/interview_result.dart';
import '../../features/interview/presentation/interview_report_screen.dart';
import '../../features/interview/presentation/interview_setup_screen.dart';
import '../../features/interview/presentation/resume_analysis_screen.dart';
import '../../features/interview/presentation/voice_interview_screen.dart';
import '../../features/interview/services/interview_engine.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      AuthService.instance.authStateChanges,
    ),
    redirect: _guard,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/resume-analysis',
        builder: (context, state) => const ResumeAnalysisScreen(),
      ),
      GoRoute(
        path: '/interview-setup',
        builder: (context, state) {
          final initialMode = state.extra as InterviewMode? ?? InterviewMode.skill;
          return InterviewSetupScreen(initialMode: initialMode);
        },
      ),
      GoRoute(
        path: '/voice-interview',
        builder: (context, state) {
          final config = state.extra as InterviewConfig?;
          return VoiceInterviewScreen(config: config);
        },
      ),
      GoRoute(
        path: '/interview-report',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is InterviewEngine) {
            return InterviewReportScreen(engine: extra);
          }
          if (extra is InterviewResult) {
            return InterviewReportScreen(result: extra);
          }
          return const InterviewReportScreen();
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const InterviewHistoryScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
    ],
  );

  /// Auth guard: protect routes; redirect logged-in users away from auth routes.
  static String? _guard(BuildContext context, GoRouterState state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;

    // Splash handles its own redirect — never intercept it.
    if (loc == '/') return null;

    final isAuthRoute = loc == '/login' || loc == '/signup';
    final protectedRoutes = [
      '/home',
      '/profile',
      '/resume-analysis',
      '/interview-setup',
      '/voice-interview',
      '/interview-report',
      '/history',
      '/analytics',
    ];
    final isProtected = protectedRoutes.contains(loc);

    if (isProtected && !loggedIn) return '/login';
    if (isAuthRoute && loggedIn) return '/home';

    return null;
  }
}
