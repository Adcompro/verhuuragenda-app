import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppModule {
  cleaning,
  maintenance,
  pool,
  garden,
  campaigns,
  statistics,
}

class ModuleVisibility {
  final Map<AppModule, bool> _flags;

  const ModuleVisibility(this._flags);

  /// Default: every optional module hidden until the user (or the
  /// onboarding wizard) explicitly turns it on. This keeps the
  /// bottom-nav clean for first-time users; the wizard writes
  /// explicit values for the modules the user said they need.
  factory ModuleVisibility.allDisabled() => ModuleVisibility({
        for (final m in AppModule.values) m: false,
      });

  factory ModuleVisibility.allEnabled() => ModuleVisibility({
        for (final m in AppModule.values) m: true,
      });

  bool isEnabled(AppModule module) => _flags[module] ?? false;

  ModuleVisibility copyWith(AppModule module, bool enabled) {
    final next = Map<AppModule, bool>.from(_flags);
    next[module] = enabled;
    return ModuleVisibility(next);
  }
}

class ModuleVisibilityNotifier extends StateNotifier<ModuleVisibility> {
  ModuleVisibilityNotifier() : super(ModuleVisibility.allDisabled()) {
    _load();
  }

  static String _key(AppModule m) => 'module_enabled_${m.name}';

  // One-shot migration so existing users (who upgraded from a
  // build where every module was visible by default) don't suddenly
  // lose their tabs. If they had already dismissed the onboarding
  // before this build, they were "old" users — keep their modules
  // on. New users start everything off.
  static const String _migratedKey = 'module_visibility_default_off_migrated';
  static const String _onboardingDismissedKey = 'onboarding_dismissed';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // First-launch migration for existing users.
    if (!(prefs.getBool(_migratedKey) ?? false)) {
      final wasExistingUser =
          prefs.getBool(_onboardingDismissedKey) ?? false;
      if (wasExistingUser) {
        for (final m in AppModule.values) {
          // Only set if not yet stored, so any explicit choice the
          // user already made (e.g. via the module-settings screen)
          // stays untouched.
          if (prefs.getBool(_key(m)) == null) {
            await prefs.setBool(_key(m), true);
          }
        }
      }
      await prefs.setBool(_migratedKey, true);
    }

    var visibility = ModuleVisibility.allDisabled();
    for (final m in AppModule.values) {
      final stored = prefs.getBool(_key(m));
      if (stored != null) {
        visibility = visibility.copyWith(m, stored);
      }
    }
    state = visibility;
  }

  Future<void> setEnabled(AppModule module, bool enabled) async {
    state = state.copyWith(module, enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(module), enabled);
  }

  /// Resets to the all-off baseline, the same default a brand-new
  /// install starts with.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final m in AppModule.values) {
      await prefs.remove(_key(m));
    }
    state = ModuleVisibility.allDisabled();
  }
}

final moduleVisibilityProvider =
    StateNotifierProvider<ModuleVisibilityNotifier, ModuleVisibility>((ref) {
  return ModuleVisibilityNotifier();
});
