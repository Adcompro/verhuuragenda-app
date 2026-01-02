import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../utils/responsive.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;

  const BottomNavShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/bookings')) return 2;
    if (location.startsWith('/accommodations')) return 3;
    if (location.startsWith('/guests')) return 4;
    if (location.startsWith('/cleaning')) return 5;
    if (location.startsWith('/maintenance')) return 6;
    if (location.startsWith('/pool')) return 7;
    if (location.startsWith('/garden')) return 8;
    if (location.startsWith('/campaigns')) return 9;
    if (location.startsWith('/statistics')) return 10;
    if (location.startsWith('/settings')) return 11;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/calendar');
        break;
      case 2:
        context.go('/bookings');
        break;
      case 3:
        context.go('/accommodations');
        break;
      case 4:
        context.go('/guests');
        break;
      case 5:
        context.go('/cleaning');
        break;
      case 6:
        context.go('/maintenance');
        break;
      case 7:
        context.go('/pool');
        break;
      case 8:
        context.go('/garden');
        break;
      case 9:
        context.go('/campaigns');
        break;
      case 10:
        context.go('/statistics');
        break;
      case 11:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    // Use tablet layout only for actual tablets/desktops, not phones in landscape
    // Check shortest side to determine if it's a phone (< 600) or tablet (>= 600)
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isActualTablet = shortestSide >= 600;

    if (isActualTablet) {
      return _buildTabletLayout(context, selectedIndex);
    }
    return _buildPhoneLayout(context, selectedIndex);
  }

  Widget _buildTabletLayout(BuildContext context, int selectedIndex) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Rail
          NavigationRail(
            selectedIndex: selectedIndex > 11 ? 0 : selectedIndex,
            onDestinationSelected: (index) => _onDestinationSelected(context, index),
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
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: Text(l10n.dashboard),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: Text(l10n.calendar),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.book_outlined),
                selectedIcon: const Icon(Icons.book),
                label: Text(l10n.bookings),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.home_work_outlined),
                selectedIcon: const Icon(Icons.home_work),
                label: Text(l10n.accommodations),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: Text(l10n.guests),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.cleaning_services_outlined),
                selectedIcon: const Icon(Icons.cleaning_services),
                label: Text(l10n.cleaning),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.build_outlined),
                selectedIcon: const Icon(Icons.build),
                label: Text(l10n.maintenance),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.pool_outlined),
                selectedIcon: const Icon(Icons.pool),
                label: Text(l10n.poolMaintenance),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.yard_outlined),
                selectedIcon: const Icon(Icons.yard),
                label: Text(l10n.gardenMaintenance),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.campaign_outlined),
                selectedIcon: const Icon(Icons.campaign),
                label: Text(l10n.campaigns),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: Text(l10n.statistics),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(l10n.settings),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout(BuildContext context, int selectedIndex) {
    final l10n = AppLocalizations.of(context)!;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final navItems = [
      _NavItem(0, Icons.home_outlined, Icons.home, l10n.home, '/dashboard'),
      _NavItem(1, Icons.calendar_month_outlined, Icons.calendar_month, l10n.calendar, '/calendar'),
      _NavItem(2, Icons.book_outlined, Icons.book, l10n.bookings, '/bookings'),
      _NavItem(3, Icons.home_work_outlined, Icons.home_work, l10n.accommodations, '/accommodations'),
      _NavItem(4, Icons.people_outline, Icons.people, l10n.guests, '/guests'),
      _NavItem(5, Icons.cleaning_services_outlined, Icons.cleaning_services, l10n.cleaning, '/cleaning'),
      _NavItem(6, Icons.build_outlined, Icons.build, l10n.maintenance, '/maintenance'),
      _NavItem(7, Icons.pool_outlined, Icons.pool, l10n.poolMaintenance, '/pool'),
      _NavItem(8, Icons.yard_outlined, Icons.yard, l10n.gardenMaintenance, '/garden'),
      _NavItem(9, Icons.campaign_outlined, Icons.campaign, l10n.campaigns, '/campaigns'),
      _NavItem(10, Icons.bar_chart_outlined, Icons.bar_chart, l10n.statistics, '/statistics'),
      _NavItem(11, Icons.settings_outlined, Icons.settings, l10n.settings, '/settings'),
    ];

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
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = selectedIndex == item.index;

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
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  _NavItem(this.index, this.icon, this.selectedIcon, this.label, this.route);
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

