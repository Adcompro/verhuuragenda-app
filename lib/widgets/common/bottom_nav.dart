import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;

  const BottomNavShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/bookings')) return 2;
    return 3; // More menu
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
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
