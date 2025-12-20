import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/bookings/bookings_list_screen.dart';
import '../screens/bookings/booking_detail_screen.dart';
import '../screens/bookings/booking_form_screen.dart';
import '../screens/accommodations/accommodations_list_screen.dart';
import '../screens/guests/guests_list_screen.dart';
import '../screens/cleaning/cleaning_screen.dart';
import '../screens/maintenance/maintenance_list_screen.dart';
import '../screens/campaigns/campaigns_list_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/common/bottom_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoading = authState.isLoading;
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/register' || path == '/forgot-password';
      final isSplash = path == '/';

      // Still loading auth state - stay on splash
      if (isLoading) {
        return isSplash ? null : '/';
      }

      // Not loading anymore - handle redirects
      if (!isLoggedIn) {
        // Not logged in: go to login (unless already on auth route)
        return isAuthRoute ? null : '/login';
      } else {
        // Logged in: go to dashboard (unless already in app)
        return (isSplash || isAuthRoute) ? '/dashboard' : null;
      }
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Register
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Forgot Password
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => BottomNavShell(child: child),
        routes: [
          // Dashboard (Home)
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // Calendar
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),

          // Bookings
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const BookingFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => BookingDetailScreen(
                  bookingId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),

          // More menu items
          GoRoute(
            path: '/accommodations',
            builder: (context, state) => const AccommodationsListScreen(),
          ),
          GoRoute(
            path: '/guests',
            builder: (context, state) => const GuestsListScreen(),
          ),
          GoRoute(
            path: '/cleaning',
            builder: (context, state) => const CleaningScreen(),
          ),
          GoRoute(
            path: '/maintenance',
            builder: (context, state) => const MaintenanceListScreen(),
          ),
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const CampaignsListScreen(),
          ),
          GoRoute(
            path: '/statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
