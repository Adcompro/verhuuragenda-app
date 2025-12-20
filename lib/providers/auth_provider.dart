import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../core/api/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';

// Auth State
class AuthState {
  final User? user;
  final bool isLoggedIn;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoggedIn = false,
    this.isLoading = true,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoggedIn,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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

    if (token != null && token.isNotEmpty) {
      try {
        // Verify token with server
        final response = await ApiClient.instance.get(ApiConfig.user);
        final user = User.fromJson(response.data);

        state = AuthState(
          user: user,
          isLoggedIn: true,
          isLoading: false,
        );
      } catch (e) {
        // Token invalid or expired
        await SecureStorage.deleteToken();
        state = const AuthState(isLoading: false);
      }
    } else {
      state = const AuthState(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient.instance.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
          'device_name': 'mobile_app',
        },
      );

      final token = response.data['token'];
      await SecureStorage.saveToken(token);

      // Get user info
      final userResponse = await ApiClient.instance.get(ApiConfig.user);
      final user = User.fromJson(userResponse.data);

      await SecureStorage.saveUserData(jsonEncode(user.toJson()));

      state = AuthState(
        user: user,
        isLoggedIn: true,
        isLoading: false,
      );

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

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Er is een fout opgetreden: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    // Clear local state first to prevent UI hanging
    await SecureStorage.clearAll();

    // Try to notify server (with short timeout, don't wait)
    try {
      await ApiClient.instance.post(
        ApiConfig.logout,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Ignore errors during logout - we already cleared local state
    }

    ApiClient.reset();
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
