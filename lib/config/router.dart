import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/bookings/bookings_list_screen.dart';
import '../screens/bookings/booking_detail_screen.dart';
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
      final isLoggedIn = authState.valueOrNull?.isLoggedIn ?? false;
      final isLoading = authState.isLoading;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/';

      // Still loading auth state
      if (isLoading && isSplash) return null;

      // Not logged in and not on login page
      if (!isLoggedIn && !isLoginRoute) return '/login';

      // Logged in but on login page
      if (isLoggedIn && isLoginRoute) return '/dashboard';

      // Logged in and on splash
      if (isLoggedIn && isSplash) return '/dashboard';

      return null;
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
