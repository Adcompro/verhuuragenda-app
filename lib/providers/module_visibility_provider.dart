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

  factory ModuleVisibility.allEnabled() => ModuleVisibility({
        for (final m in AppModule.values) m: true,
      });

  bool isEnabled(AppModule module) => _flags[module] ?? true;

  ModuleVisibility copyWith(AppModule module, bool enabled) {
    final next = Map<AppModule, bool>.from(_flags);
    next[module] = enabled;
    return ModuleVisibility(next);
  }
}

class ModuleVisibilityNotifier extends StateNotifier<ModuleVisibility> {
  ModuleVisibilityNotifier() : super(ModuleVisibility.allEnabled()) {
    _load();
  }

  static String _key(AppModule m) => 'module_enabled_${m.name}';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    var visibility = ModuleVisibility.allEnabled();
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

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final m in AppModule.values) {
      await prefs.remove(_key(m));
    }
    state = ModuleVisibility.allEnabled();
  }
}

final moduleVisibilityProvider =
    StateNotifierProvider<ModuleVisibilityNotifier, ModuleVisibility>((ref) {
  return ModuleVisibilityNotifier();
});
