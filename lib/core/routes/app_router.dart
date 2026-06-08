import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/interview/presentation/resume_analysis_screen.dart';
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
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/resume-analysis',
        builder: (context, state) => const ResumeAnalysisScreen(),
      ),
    ],
  );

  /// Auth guard: protect /home and /profile; redirect logged-in users away
  /// from auth routes.
  static String? _guard(BuildContext context, GoRouterState state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;

    // Splash handles its own redirect — never intercept it.
    if (loc == '/') return null;

    final isAuthRoute = loc == '/login' || loc == '/signup';
    final isProtected =
        loc == '/home' || loc == '/profile' || loc == '/resume-analysis';

    if (isProtected && !loggedIn) return '/login';
    if (isAuthRoute && loggedIn) return '/home';

    return null;
  }
}
