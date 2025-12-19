import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
      ),
      body: ListView(
        children: [
          // User info
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),

          // Settings sections
          _SettingsItem(
            icon: Icons.person_outline,
            title: 'Profiel bewerken',
            onTap: () {
              // TODO: Navigate to profile edit
            },
          ),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notificaties',
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          _SettingsItem(
            icon: Icons.credit_card_outlined,
            title: 'Abonnement',
            onTap: () {
              // TODO: Navigate to subscription
            },
          ),
          const Divider(),
          _SettingsItem(
            icon: Icons.info_outline,
            title: 'Over de app',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'VerhuurAgenda',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 VerhuurAgenda.nl',
              );
            },
          ),
          _SettingsItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              // TODO: Open help website
            },
          ),
          const Divider(),
          _SettingsItem(
            icon: Icons.logout,
            title: 'Uitloggen',
            textColor: Colors.red,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Uitloggen'),
                  content: const Text('Weet je zeker dat je wilt uitloggen?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuleren'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Uitloggen'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
