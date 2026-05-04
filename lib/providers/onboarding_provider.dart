import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _dismissedKey = 'onboarding_dismissed';

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_dismissedKey) ?? false;
  }

  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
    state = true;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedKey);
    state = false;
  }
}

final onboardingDismissedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});
