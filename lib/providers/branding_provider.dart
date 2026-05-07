import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/api/api_client.dart';
import 'auth_provider.dart';

/// Reactive provider for the host-configurable app brand name.
///
/// Falls back to "CasaMio" when the user is not logged in or the API
/// hasn't returned a value yet.
final brandingProvider = StateNotifierProvider<BrandingNotifier, String>(
  (ref) {
    final notifier = BrandingNotifier();
    // Re-evaluate when auth state changes (login/logout)
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.isLoggedIn && next.isHost && next.user?.brandingAppName != null) {
        notifier.set(next.user!.brandingAppName!);
      } else if (!next.isLoggedIn) {
        notifier.reset();
      }
    });
    return notifier;
  },
);

class BrandingNotifier extends StateNotifier<String> {
  BrandingNotifier() : super('CasaMio');

  void set(String name) {
    if (name.trim().isNotEmpty) {
      state = name.trim();
    }
  }

  void reset() => state = 'CasaMio';

  /// Update the brand name on the server (host only) and locally.
  Future<bool> updateRemote(String name) async {
    try {
      final res = await ApiClient.instance.patch(
        '/branding',
        data: {'app_name': name},
      );
      final returned = (res.data is Map ? res.data['app_name'] : null) as String?;
      set(returned ?? name);
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
