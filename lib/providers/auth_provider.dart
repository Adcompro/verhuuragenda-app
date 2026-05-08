import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/push_service.dart';

// Auth mode
enum AuthMode { host, guest }

// Auth State
class AuthState {
  final User? user;
  final bool isLoggedIn;
  final bool isLoading;
  final String? error;
  final AuthMode mode;
  final int? guestBookingId;

  const AuthState({
    this.user,
    this.isLoggedIn = false,
    this.isLoading = true,
    this.error,
    this.mode = AuthMode.host,
    this.guestBookingId,
  });

  bool get isGuest => mode == AuthMode.guest && isLoggedIn;
  bool get isHost => mode == AuthMode.host && isLoggedIn;

  AuthState copyWith({
    User? user,
    bool? isLoggedIn,
    bool? isLoading,
    String? error,
    AuthMode? mode,
    int? guestBookingId,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      mode: mode ?? this.mode,
      guestBookingId: guestBookingId ?? this.guestBookingId,
    );
  }
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await SecureStorage.getToken();
    final mode = await SecureStorage.getMode();

    if (token == null || token.isEmpty) {
      state = const AuthState(isLoading: false);
      return;
    }

    // Guest session: token belongs to a Booking, not a User.
    if (mode == 'guest') {
      final bookingId = await SecureStorage.getGuestBookingId();
      try {
        await ApiClient.instance.get(ApiConfig.guestBooking);
        state = AuthState(
          isLoggedIn: true,
          isLoading: false,
          mode: AuthMode.guest,
          guestBookingId: bookingId,
        );
      } catch (e) {
        await SecureStorage.clearAll();
        state = const AuthState(isLoading: false);
      }
      return;
    }

    // Host session
    try {
      final response = await ApiClient.instance.get(ApiConfig.user);
      final user = User.fromJson(response.data);
      state = AuthState(
        user: user,
        isLoggedIn: true,
        isLoading: false,
        mode: AuthMode.host,
      );
      // Make sure FCM gets a chance to (re-)register on every app
      // launch — this triggers the OS notification permission popup
      // the first time on a fresh install, and refreshes the device
      // token on later launches.
      unawaited(PushService.instance.registerToken());
    } catch (e) {
      await SecureStorage.deleteToken();
      state = const AuthState(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    // Reset any previous error state
    state = const AuthState(isLoading: true);

    try {
      // Ensure clean state before login
      await SecureStorage.deleteToken();
      ApiClient.reset();

      final response = await ApiClient.instance.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
          'device_name': 'mobile_app',
        },
      );

      final token = response.data['token'];
      if (token == null || token.isEmpty) {
        throw Exception('Geen token ontvangen van server');
      }

      await SecureStorage.saveToken(token);
      await SecureStorage.setMode('host');

      // Reset client to pick up new token
      ApiClient.reset();

      // Get user info with new token
      final userResponse = await ApiClient.instance.get(ApiConfig.user);
      final user = User.fromJson(userResponse.data);

      await SecureStorage.saveUserData(jsonEncode(user.toJson()));

      state = AuthState(
        user: user,
        isLoggedIn: true,
        isLoading: false,
        mode: AuthMode.host,
      );

      // Register the device with FCM so the host gets push pings.
      // Fire-and-forget — never block login.
      unawaited(PushService.instance.registerToken());

      return true;
    } on DioException catch (e) {
      String errorMessage = 'Inloggen mislukt. Controleer je gegevens.';

      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'];
        } else if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map;
          errorMessage = errors.values.first?.first ?? errorMessage;
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Verbinding timeout. Controleer je internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Kan geen verbinding maken met de server.';
      }

      state = AuthState(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: 'Er is een fout opgetreden: ${e.toString()}',
      );
      return false;
    }
  }

  /// Authenticate as a guest using their last name + 6-digit PIN.
  Future<bool> loginGuest(String lastName, String pin) async {
    state = const AuthState(isLoading: true);

    try {
      await SecureStorage.deleteToken();
      ApiClient.reset();

      final response = await ApiClient.instance.post(
        ApiConfig.guestLogin,
        data: {
          'last_name': lastName.trim(),
          'pin': pin.trim(),
          'device_name': 'guest_app',
        },
      );

      final apiToken = response.data['token'] as String?;
      final bookingId = response.data['booking_id'] as int?;
      if (apiToken == null || apiToken.isEmpty) {
        throw Exception('Geen token ontvangen van server');
      }

      await SecureStorage.saveToken(apiToken);
      await SecureStorage.setMode('guest');
      if (bookingId != null) {
        await SecureStorage.setGuestBookingId(bookingId);
      }

      ApiClient.reset();

      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        mode: AuthMode.guest,
        guestBookingId: bookingId,
      );
      return true;
    } on DioException catch (e) {
      String msg = 'Ongeldige token of pincode.';
      final data = e.response?.data;
      if (data is Map && data['errors'] != null) {
        final errors = data['errors'] as Map;
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) msg = first.first.toString();
      } else if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      state = AuthState(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: 'Er is een fout opgetreden: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final isGuest = state.mode == AuthMode.guest;
    // Drop the FCM token from the backend so this device stops getting
    // push pings for the now-logged-out account.
    if (!isGuest) {
      unawaited(PushService.instance.unregister());
    }
    // Try to notify server first (while we still have the token)
    try {
      await ApiClient.instance.post(
        isGuest ? ApiConfig.guestLogout : ApiConfig.logout,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Ignore errors during logout - we'll clear local state anyway
    }

    // Now clear local state
    await SecureStorage.clearAll();
    ApiClient.reset();

    // Reset to initial state (not logged in, not loading)
    state = const AuthState(isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refreshUser() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.user);
      final user = User.fromJson(response.data);
      await SecureStorage.saveUserData(jsonEncode(user.toJson()));
      state = state.copyWith(user: user);
    } catch (e) {
      // Silently fail - user data will be refreshed on next app start
    }
  }
}

// Providers
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoggedIn;
});

final isGuestModeProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isGuest;
});

final guestBookingIdProvider = Provider<int?>((ref) {
  return ref.watch(authStateProvider).guestBookingId;
});
