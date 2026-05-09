import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_apns_only/flutter_apns_only.dart';

import '../core/api/api_client.dart';

/// Direct APNs push registration — no Firebase Messaging.
///
/// On iOS, asks for notification permission, gets the raw APNs hex
/// token, and POSTs it to /api/notifications/register so the server
/// can push directly via api.push.apple.com.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _connector = ApnsPushConnectorOnly();

  bool _initialized = false;
  String? _cachedToken;
  String? _lastError;
  String? _lastApnsToken;
  String? _lastAuthStatus;

  bool get isFirebaseUp => Platform.isIOS; // kept for diagnostics screen
  String? get currentToken => _cachedToken;
  String? get apnsToken => _lastApnsToken;
  String? get lastError => _lastError;
  String? get lastAuthStatus => _lastAuthStatus;

  /// Call once from main() before runApp.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!Platform.isIOS) return;

    _connector.shouldPresent = (_) async => true;
    _connector.configureApns(
      onLaunch: (msg) async {
        debugPrint('Push: launched from notification: ${msg.payload}');
      },
      onResume: (msg) async {
        debugPrint('Push: resumed from notification: ${msg.payload}');
      },
      onMessage: (msg) async {
        debugPrint('Push: foreground notification: ${msg.payload}');
      },
    );

    _connector.token.addListener(() {
      final token = _connector.token.value;
      if (token != null && token.isNotEmpty) {
        _lastApnsToken = token;
        unawaited(_sendTokenToBackend(token));
      }
    });
  }

  /// Get the current APNs token and POST it to the backend.
  /// Idempotent — safe to call on every login or app foreground.
  Future<void> registerToken() async {
    if (!Platform.isIOS) return;
    try {
      // Ask for notification permission. iOS shows the system dialog
      // the first time; subsequent calls return the cached decision.
      await _connector.requestNotificationPermissions();
      _lastAuthStatus = 'requested';

      // Token may already be available (set during init) or arrive
      // shortly after — wait up to 30 s.
      for (int i = 0; i < 60; i++) {
        final token = _connector.token.value;
        if (token != null && token.isNotEmpty) {
          _lastApnsToken = token;
          await _sendTokenToBackend(token);
          return;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _lastError = 'No APNs token after 30s. Check app entitlements / permissions.';
      debugPrint('PushService: timeout waiting for APNs token');
    } catch (e) {
      _lastError = 'registerToken: $e';
      debugPrint('PushService.registerToken failed: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    if (token == _cachedToken) return;
    try {
      await ApiClient.instance.post(
        '/notifications/register',
        data: {
          'token': token,
          'platform': 'ios',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      _cachedToken = token;
      _lastError = null;
      debugPrint('PushService: APNs token registered (${token.substring(0, 20)}…)');
    } catch (e) {
      _lastError = 'register POST: $e';
      debugPrint('PushService: token register POST failed: $e');
    }
  }

  Future<void> unregister() async {
    if (!Platform.isIOS) return;
    final token = _cachedToken;
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
