import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../firebase_options.dart';

/// Top-level handler for messages received while the app is in the
/// background or terminated. Firebase Messaging requires this to be
/// a top-level (non-anonymous) function.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase here too — the isolate is fresh.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {/* may already be initialized */}
}

/// Wraps Firebase Messaging setup. Designed to fail gracefully if
/// Firebase isn't configured (no GoogleService-Info.plist) so the rest
/// of the app keeps working until the credentials land.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _initialized = false;
  bool _firebaseUp = false;
  String? _cachedToken;

  /// Call once from main() before runApp. Idempotent.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseUp = true;
    } catch (e) {
      debugPrint(
        'PushService: Firebase.initializeApp failed. '
        'firebase_options.dart still has placeholder values? '
        'Push disabled. ($e)',
      );
      return;
    }

    // Register the OS-level background handler.
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Foreground messages: iOS does NOT show the system banner
    // automatically when the app is in the foreground. We could surface
    // an in-app banner here; for now we just rely on the in-app polling
    // mechanism + badges to update the UI.
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      debugPrint('Push received in foreground: ${msg.notification?.title}');
    });
  }

  /// Ask the user for notification permission (iOS shows the system
  /// dialog; Android 13+ also shows it). Returns true if granted.
  Future<bool> requestPermission() async {
    if (!_firebaseUp) return false;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Get the current FCM token and POST it to the backend so the
  /// server can address this device. Call after a successful host or
  /// guest login. Re-runs are cheap and idempotent.
  Future<void> registerToken() async {
    if (!_firebaseUp) return;
    try {
      final granted = await requestPermission();
      if (!granted) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      if (token == _cachedToken) return;

      await ApiClient.instance.post(
        '/notifications/register',
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      _cachedToken = token;

      // Re-register if FCM rotates the token mid-session.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken == _cachedToken) return;
        try {
          await ApiClient.instance.post(
            '/notifications/register',
            data: {
              'token': newToken,
              'platform': Platform.isIOS ? 'ios' : 'android',
            },
          );
          _cachedToken = newToken;
        } catch (_) {/* ignore */}
      });
    } catch (e) {
      debugPrint('PushService.registerToken failed: $e');
    }
  }

  /// Unregister this device's token from the backend (called on
  /// logout). The local cache is cleared too.
  Future<void> unregister() async {
    if (!_firebaseUp) return;
    final token = _cachedToken ?? await FirebaseMessaging.instance.getToken();
    _cachedToken = null;
    if (token == null) return;
    try {
      await ApiClient.instance.delete(
        '/notifications/unregister',
        data: {'token': token},
      );
    } catch (_) {/* ignore */}
  }
}
