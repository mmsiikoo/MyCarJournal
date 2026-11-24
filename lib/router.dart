import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/delete_account_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/events/event_detail_screen.dart';
import 'features/events/event_form_screen.dart';
import 'features/events/events_screen.dart';
import 'features/events/photo_viewer_screen.dart';
import 'features/fuel/fuel_form_screen.dart';
import 'features/fuel/fuel_screen.dart';
import 'features/garage/garage_screen.dart';
import 'features/garage/vehicle_form_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shell/home_shell.dart';
import 'features/splash/splash_screen.dart';
import 'features/stats/stats_screen.dart';
import 'providers/auth_router_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRouterNotifierProvider);

  return GoRouter(
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';
      final isSplash = location == '/splash';
      final isVerify = location == '/verify-email';
      final isDelete = location == '/delete-account';

      if (!auth.initialized) {
        return isAuthRoute || isSplash ? null : '/splash';
      }
      if (auth.user == null) {
        return isAuthRoute ? null : '/login';
      }
      if (auth.user?.emailVerified != true) {
        if (isVerify || isDelete) return null;
        return '/verify-email';
      }
      if (isAuthRoute || isSplash || isVerify) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            HomeShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/fuel',
            builder: (context, state) => const FuelScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/garage',
            builder: (context, state) => const GarageScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/fuel/new',
        builder: (context, state) => const FuelFormScreen(),
      ),
      GoRoute(
        path: '/fuel/:id/edit',
        builder: (context, state) =>
            FuelFormScreen(entryId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/events/new',
        builder: (context, state) => const EventFormScreen(),
      ),
      GoRoute(
        path: '/events/:id/edit',
        builder: (context, state) =>
            EventFormScreen(eventId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/events/:id/photos',
        builder: (context, state) => PhotoViewerScreen(
          eventId: state.pathParameters['id']!,
          initialIndex:
              int.tryParse(state.uri.queryParameters['index'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/garage/new',
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: '/garage/:id/edit',
        builder: (context, state) =>
            VehicleFormScreen(vehicleId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/delete-account',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_outlined, size: 56),
            const SizedBox(height: 16),
            Text('Сторінку не знайдено: ${state.uri}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('На головну'),
            ),
          ],
        ),
      ),
    ),
  );
});
