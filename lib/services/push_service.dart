// ignore_for_file: unused_element
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
  String? _lastError;
  String? _lastApnsToken;
  String? _lastAuthStatus;

  bool get isFirebaseUp => _firebaseUp;
  String? get currentToken => _cachedToken;
  String? get apnsToken => _lastApnsToken;
  String? get lastError => _lastError;
  String? get lastAuthStatus => _lastAuthStatus;

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
      _lastError = 'Firebase.initializeApp: $e';
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
    _lastAuthStatus = settings.authorizationStatus.toString();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Get the current FCM token and POST it to the backend so the
  /// server can address this device. Call after a successful host or
  /// guest login. Re-runs are cheap and idempotent.
  ///
  /// On iOS, the APNs device token may not be available the first
  /// few seconds after install; getToken() then returns null silently.
  /// We retry briefly and ALSO subscribe to onTokenRefresh so a
  /// late-arriving token still gets registered.
  Future<void> registerToken() async {
    if (!_firebaseUp) return;

    // Always set the listener so a refresh / first-arrival registers
    // even if the immediate getToken() below returns null.
    if (!_refreshSubscribed) {
      _refreshSubscribed = true;
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('PushService: onTokenRefresh fired');
        unawaited(_sendTokenToBackend(newToken));
      });
    }

    try {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('PushService: notification permission not granted');
        return;
      }

      // On iOS, wait up to 30 seconds for the APNs token. On a slow
      // network or first-install Apple can take longer to hand it back.
      if (Platform.isIOS) {
        for (int i = 0; i < 60; i++) {
          final apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns != null && apns.isNotEmpty) {
            _lastApnsToken = apns;
            break;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        _lastError = 'getToken returned null — relying on onTokenRefresh';
        debugPrint(
          'PushService: getToken returned null — '
          'will rely on onTokenRefresh.',
        );
        return;
      }
      await _sendTokenToBackend(token);
    } catch (e) {
      _lastError = 'registerToken: $e';
      debugPrint('PushService.registerToken failed: $e');
    }
  }

  bool _refreshSubscribed = false;

  Future<void> _sendTokenToBackend(String token) async {
    if (token == _cachedToken) return;
    try {
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
      _lastError = null;
      debugPrint('PushService: token registered (${token.substring(0, 20)}…)');
    } catch (e) {
      _lastError = 'register POST: $e';
      debugPrint('PushService: token register POST failed: $e');
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
