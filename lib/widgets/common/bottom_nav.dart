import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    if (location.startsWith('/campaigns')) return 7;
    if (location.startsWith('/statistics')) return 8;
    if (location.startsWith('/settings')) return 9;
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
        context.go('/campaigns');
        break;
      case 8:
        context.go('/statistics');
        break;
      case 9:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isWide = Responsive.useWideLayout(context);

    if (isWide) {
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
            selectedIndex: selectedIndex > 9 ? 0 : selectedIndex,
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

    // Map full index to bottom nav index (0-3)
    int bottomNavIndex;
    if (selectedIndex <= 0) {
      bottomNavIndex = 0;
    } else if (selectedIndex == 1) {
      bottomNavIndex = 1;
    } else if (selectedIndex == 2) {
      bottomNavIndex = 2;
    } else {
      bottomNavIndex = 3; // More menu
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomNavIndex,
        onDestinationSelected: (index) {
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
              _showMoreMenu(context);
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.calendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: l10n.bookings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            selectedIcon: const Icon(Icons.more_horiz),
            label: l10n.more,
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _MenuItem(
              icon: Icons.home_work_outlined,
              label: l10n.accommodations,
              onTap: () {
                Navigator.pop(context);
                context.go('/accommodations');
              },
            ),
            _MenuItem(
              icon: Icons.people_outline,
              label: l10n.guests,
              onTap: () {
                Navigator.pop(context);
                context.go('/guests');
              },
            ),
            _MenuItem(
              icon: Icons.cleaning_services_outlined,
              label: l10n.cleaning,
              onTap: () {
                Navigator.pop(context);
                context.go('/cleaning');
              },
            ),
            _MenuItem(
              icon: Icons.build_outlined,
              label: l10n.maintenance,
              onTap: () {
                Navigator.pop(context);
                context.go('/maintenance');
              },
            ),
            _MenuItem(
              icon: Icons.campaign_outlined,
              label: l10n.campaigns,
              onTap: () {
                Navigator.pop(context);
                context.go('/campaigns');
              },
            ),
            _MenuItem(
              icon: Icons.bar_chart_outlined,
              label: l10n.statistics,
              onTap: () {
                Navigator.pop(context);
                context.go('/statistics');
              },
            ),
            const Divider(),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: l10n.settings,
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
