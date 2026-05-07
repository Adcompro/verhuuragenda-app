import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/module_visibility_provider.dart';
import '../../utils/responsive.dart';

class BottomNavShell extends ConsumerWidget {
  final Widget child;

  const BottomNavShell({super.key, required this.child});

  List<_NavItem> _buildItems(
    AppLocalizations l10n,
    ModuleVisibility visibility,
  ) {
    final items = <_NavItem>[
      _NavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.home,
        railIcon: Icons.dashboard_outlined,
        railSelectedIcon: Icons.dashboard,
        railLabel: l10n.dashboard,
        route: '/dashboard',
      ),
      _NavItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        label: l10n.calendar,
        route: '/calendar',
      ),
      _NavItem(
        icon: Icons.book_outlined,
        selectedIcon: Icons.book,
        label: l10n.bookings,
        route: '/bookings',
      ),
      _NavItem(
        icon: Icons.home_work_outlined,
        selectedIcon: Icons.home_work,
        label: l10n.accommodations,
        route: '/accommodations',
      ),
      _NavItem(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: l10n.guests,
        route: '/guests',
      ),
      _NavItem(
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        label: 'Berichten',
        route: '/conversations',
      ),
      if (visibility.isEnabled(AppModule.cleaning))
        _NavItem(
          icon: Icons.cleaning_services_outlined,
          selectedIcon: Icons.cleaning_services,
          label: l10n.cleaning,
          route: '/cleaning',
        ),
      if (visibility.isEnabled(AppModule.maintenance))
        _NavItem(
          icon: Icons.build_outlined,
          selectedIcon: Icons.build,
          label: l10n.maintenance,
          route: '/maintenance',
        ),
      if (visibility.isEnabled(AppModule.pool))
        _NavItem(
          icon: Icons.pool_outlined,
          selectedIcon: Icons.pool,
          label: l10n.poolMaintenance,
          route: '/pool',
        ),
      if (visibility.isEnabled(AppModule.garden))
        _NavItem(
          icon: Icons.yard_outlined,
          selectedIcon: Icons.yard,
          label: l10n.gardenMaintenance,
          route: '/garden',
        ),
      if (visibility.isEnabled(AppModule.campaigns))
        _NavItem(
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign,
          label: l10n.campaigns,
          route: '/campaigns',
        ),
      if (visibility.isEnabled(AppModule.statistics))
        _NavItem(
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          label: l10n.statistics,
          route: '/statistics',
        ),
      _NavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
        route: '/settings',
      ),
    ];
    return items;
  }

  int _selectedIndex(BuildContext context, List<_NavItem> items) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = items.indexWhere((it) => location.startsWith(it.route));
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final visibility = ref.watch(moduleVisibilityProvider);
    final items = _buildItems(l10n, visibility);
    final selectedIndex = _selectedIndex(context, items);

    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isActualTablet = shortestSide >= 600;

    if (isActualTablet) {
      return _buildTabletLayout(context, selectedIndex, items, l10n);
    }
    return _buildPhoneLayout(context, selectedIndex, items);
  }

  Widget _buildTabletLayout(
    BuildContext context,
    int selectedIndex,
    List<_NavItem> items,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => context.go(items[index].route),
            extended: Responsive.isDesktop(context),
            minExtendedWidth: 200,
            labelType: Responsive.isTablet(context)
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.none,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Responsive.isDesktop(context)
                  ? Text(
                      l10n.appName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(Icons.home_work, size: 32),
            ),
            destinations: items
                .map((it) => NavigationRailDestination(
                      icon: Icon(it.railIcon ?? it.icon),
                      selectedIcon: Icon(it.railSelectedIcon ?? it.selectedIcon),
                      label: Text(it.railLabel ?? it.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout(
    BuildContext context,
    int selectedIndex,
    List<_NavItem> items,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: isLandscape ? 56 : 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;

                return _ScrollableNavItem(
                  icon: isSelected ? item.selectedIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  isCompact: isLandscape,
                  onTap: () => context.go(item.route),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final IconData? railIcon;
  final IconData? railSelectedIcon;
  final String? railLabel;
  final String route;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    this.railIcon,
    this.railSelectedIcon,
    this.railLabel,
  });
}

class _ScrollableNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _ScrollableNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: isCompact ? 22 : 24,
            ),
            if (!isCompact) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
