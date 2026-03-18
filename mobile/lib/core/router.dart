// lib/core/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// Auth screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

// Participant screens
import '../screens/participant/dashboard_screen.dart';
import '../screens/participant/tracking_screen.dart';
import '../screens/participant/meal_calculator_screen.dart';
import '../screens/participant/my_meals_screen.dart';
import '../screens/participant/workout_screen.dart';
import '../screens/participant/progress_screen.dart';
import '../screens/participant/profile_screen.dart';

// Coach screens
import '../screens/coach/coach_dashboard_screen.dart';
import '../screens/coach/client_profile_screen.dart';
import '../screens/coach/assign_diet_screen.dart';
import '../screens/coach/assign_workout_screen.dart';
import '../screens/coach/assign_lifestyle_screen.dart';
import '../screens/coach/add_tips_screen.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onAuth = state.matchedLocation == '/login' ||
                     state.matchedLocation == '/register';

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) {
        return auth.isCoach ? '/coach' : '/dashboard';
      }
      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // ── Participant ───────────────────────────────────
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/tracking',  builder: (_, __) => const TrackingScreen()),
      GoRoute(path: '/meals/calculator', builder: (_, __) => const MealCalculatorScreen()),
      GoRoute(path: '/meals',     builder: (_, __) => const MyMealsScreen()),
      GoRoute(path: '/workout',   builder: (_, __) => const WorkoutScreen()),
      GoRoute(path: '/progress',  builder: (_, __) => const ProgressScreen()),
      GoRoute(path: '/profile',   builder: (_, __) => const ProfileScreen()),

      // ── Coach ─────────────────────────────────────────
      GoRoute(path: '/coach', builder: (_, __) => const CoachDashboardScreen()),
      GoRoute(
        path: '/coach/client/:id',
        builder: (_, state) => ClientProfileScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/coach/client/:id/diet',
        builder: (_, state) => AssignDietScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/coach/client/:id/workout',
        builder: (_, state) => AssignWorkoutScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/coach/client/:id/lifestyle',
        builder: (_, state) => AssignLifestyleScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/coach/client/:id/tips',
        builder: (_, state) => AddTipsScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
}
