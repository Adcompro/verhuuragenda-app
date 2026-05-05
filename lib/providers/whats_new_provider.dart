import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _lastSeenKey = 'whats_new_last_seen_version';

class WhatsNewState {
  /// Current build version (e.g. "1.4.0+117").
  final String currentVersion;

  /// Last version the user has acknowledged. Null if first launch
  /// after install or before the feature existed.
  final String? lastSeenVersion;

  const WhatsNewState({
    required this.currentVersion,
    required this.lastSeenVersion,
  });

  /// True when the current version differs from the version the user
  /// has last seen — this is when we want to show the "what's new" panel.
  bool get shouldShow =>
      currentVersion.isNotEmpty && currentVersion != lastSeenVersion;
}

class WhatsNewNotifier extends StateNotifier<WhatsNewState> {
  WhatsNewNotifier()
      : super(const WhatsNewState(currentVersion: '', lastSeenVersion: '')) {
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    final current = '${info.version}+${info.buildNumber}';
    final prefs = await SharedPreferences.getInstance();
    state = WhatsNewState(
      currentVersion: current,
      lastSeenVersion: prefs.getString(_lastSeenKey),
    );
  }

  /// Marks the current version as seen so the panel won't show again
  /// until a new build is installed.
  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenKey, state.currentVersion);
    state = WhatsNewState(
      currentVersion: state.currentVersion,
      lastSeenVersion: state.currentVersion,
    );
  }
}

final whatsNewProvider =
    StateNotifierProvider<WhatsNewNotifier, WhatsNewState>((ref) {
  return WhatsNewNotifier();
});
