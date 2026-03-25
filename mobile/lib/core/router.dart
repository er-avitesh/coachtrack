// lib/core/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/participant_shell.dart';

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
import '../screens/coach/coach_appointments_screen.dart';
import '../screens/coach/client_progress_screen.dart';

// Participant extras
import '../screens/participant/appointments_screen.dart';
import '../screens/participant/workout_history_screen.dart';
import '../screens/participant/food_log_screen.dart';

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

      // ── Participant shell (bottom nav persists across these 5 tabs) ──────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ParticipantShell(navigationShell: shell),
        branches: [
          // Tab 0 — Home
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          ]),
          // Tab 1 — Track
          StatefulShellBranch(routes: [
            GoRoute(path: '/tracking', builder: (_, __) => const TrackingScreen()),
          ]),
          // Tab 2 — Food Log
          StatefulShellBranch(routes: [
            GoRoute(path: '/food-log', builder: (_, __) => const FoodLogScreen()),
          ]),
          // Tab 3 — Workout (+ history nested)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/workout',
              builder: (_, __) => const WorkoutScreen(),
              routes: [
                GoRoute(path: 'history', builder: (_, __) => const WorkoutHistoryScreen()),
              ],
            ),
          ]),
          // Tab 4 — Progress
          StatefulShellBranch(routes: [
            GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
          ]),
        ],
      ),

      // ── Participant secondary (no bottom nav) ──────────────────────────
      GoRoute(path: '/profile',      builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/appointments', builder: (_, __) => const ParticipantAppointmentsScreen()),
      GoRoute(path: '/meals/calculator', builder: (_, __) => const MealCalculatorScreen()),
      GoRoute(path: '/meals',            builder: (_, __) => const MyMealsScreen()),

      // ── Coach ─────────────────────────────────────────────────────────
      GoRoute(path: '/coach', builder: (_, __) => const CoachDashboardScreen()),
      GoRoute(path: '/coach/appointments', builder: (_, __) => const CoachAppointmentsScreen()),
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
      GoRoute(
        path: '/coach/client/:id/progress',
        builder: (_, state) => ClientProgressScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
}
