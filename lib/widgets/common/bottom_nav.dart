import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                  ? const Text(
                      'VerhuurAgenda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(Icons.home_work, size: 32),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Kalender'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book),
                label: Text('Boekingen'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.home_work_outlined),
                selectedIcon: Icon(Icons.home_work),
                label: Text('Accommodaties'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Gasten'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.cleaning_services_outlined),
                selectedIcon: Icon(Icons.cleaning_services),
                label: Text('Schoonmaak'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build),
                label: Text('Onderhoud'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: Text('Campagnes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Statistieken'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Instellingen'),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Boekingen',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Meer',
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
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
              label: 'Accommodaties',
              onTap: () {
                Navigator.pop(context);
                context.go('/accommodations');
              },
            ),
            _MenuItem(
              icon: Icons.people_outline,
              label: 'Gasten',
              onTap: () {
                Navigator.pop(context);
                context.go('/guests');
              },
            ),
            _MenuItem(
              icon: Icons.cleaning_services_outlined,
              label: 'Schoonmaak',
              onTap: () {
                Navigator.pop(context);
                context.go('/cleaning');
              },
            ),
            _MenuItem(
              icon: Icons.build_outlined,
              label: 'Onderhoud',
              onTap: () {
                Navigator.pop(context);
                context.go('/maintenance');
              },
            ),
            _MenuItem(
              icon: Icons.campaign_outlined,
              label: 'Campagnes',
              onTap: () {
                Navigator.pop(context);
                context.go('/campaigns');
              },
            ),
            _MenuItem(
              icon: Icons.bar_chart_outlined,
              label: 'Statistieken',
              onTap: () {
                Navigator.pop(context);
                context.go('/statistics');
              },
            ),
            const Divider(),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Instellingen',
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
