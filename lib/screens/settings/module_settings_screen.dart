import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/module_visibility_provider.dart';

class ModuleSettingsScreen extends ConsumerWidget {
  const ModuleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final visibility = ref.watch(moduleVisibilityProvider);
    final notifier = ref.read(moduleVisibilityProvider.notifier);

    final tiles = <_ModuleTile>[
      _ModuleTile(
        module: AppModule.cleaning,
        icon: Icons.cleaning_services_outlined,
        label: l10n.cleaning,
      ),
      _ModuleTile(
        module: AppModule.maintenance,
        icon: Icons.build_outlined,
        label: l10n.maintenance,
      ),
      _ModuleTile(
        module: AppModule.pool,
        icon: Icons.pool_outlined,
        label: l10n.poolMaintenance,
      ),
      _ModuleTile(
        module: AppModule.garden,
        icon: Icons.yard_outlined,
        label: l10n.gardenMaintenance,
      ),
      _ModuleTile(
        module: AppModule.campaigns,
        icon: Icons.campaign_outlined,
        label: l10n.campaigns,
      ),
      _ModuleTile(
        module: AppModule.statistics,
        icon: Icons.bar_chart_outlined,
        label: l10n.statistics,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moduleSettingsTitle),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.moduleSettingsHint,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...tiles.map((tile) => SwitchListTile(
                value: visibility.isEnabled(tile.module),
                onChanged: (enabled) =>
                    notifier.setEnabled(tile.module, enabled),
                title: Text(tile.label),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    tile.icon,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                activeColor: AppTheme.primaryColor,
              )),
          const SizedBox(height: 16),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => notifier.resetAll(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.moduleResetAll),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile {
  final AppModule module;
  final IconData icon;
  final String label;

  const _ModuleTile({
    required this.module,
    required this.icon,
    required this.label,
  });
}
