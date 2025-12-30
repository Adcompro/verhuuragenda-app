import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import 'subscription_screen.dart';
import 'notifications_screen.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'profile_edit_screen.dart';
import '../seasons/seasons_list_screen.dart';
import '../team/team_list_screen.dart';
import 'financial_year_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // User info header
          if (user != null)
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          _SectionHeader(title: l10n.profile),
          _SettingsItem(
            icon: Icons.person_outline,
            title: l10n.editProfile,
            subtitle: l10n.nameAndContact,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
          ),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            title: l10n.notifications,
            subtitle: l10n.pushNotifications,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          _SettingsItem(
            icon: Icons.credit_card_outlined,
            title: l10n.subscription,
            subtitle: l10n.viewPlanAndLimits,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),
          _SettingsItem(
            icon: Icons.language_outlined,
            title: l10n.language,
            subtitle: _getLanguageSubtitle(ref, l10n),
            onTap: () => _showLanguageDialog(context, ref, l10n),
          ),

          _SectionHeader(title: l10n.management),
          _SettingsItem(
            icon: Icons.calendar_month_outlined,
            title: l10n.seasons,
            subtitle: l10n.seasonsDescription,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeasonsListScreen()),
              );
            },
          ),
          _SettingsItem(
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.financialYear,
            subtitle: l10n.financialYearDescription,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinancialYearScreen()),
              );
            },
          ),
          _SettingsItem(
            icon: Icons.group_outlined,
            title: l10n.team,
            subtitle: l10n.teamDescription,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamListScreen()),
              );
            },
          ),

          _SectionHeader(title: l10n.support),
          _SettingsItem(
            icon: Icons.help_outline,
            title: l10n.helpAndSupport,
            subtitle: l10n.helpDescription,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
          _SettingsItem(
            icon: Icons.info_outline,
            title: l10n.aboutApp,
            subtitle: l10n.aboutDescription,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),

          _SectionHeader(title: l10n.data),
          _SettingsItem(
            icon: Icons.download_outlined,
            title: l10n.exportData,
            subtitle: l10n.exportDescription,
            onTap: () {
              _showExportDialog(context, l10n);
            },
          ),
          _SettingsItem(
            icon: Icons.delete_outline,
            title: l10n.deleteAccount,
            subtitle: l10n.deleteAccountDescription,
            textColor: Colors.red,
            onTap: () {
              _showDeleteAccountDialog(context, ref, l10n);
            },
          ),

          const SizedBox(height: 8),
          const Divider(),

          // Logout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context, ref, l10n),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text(l10n.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // App version
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                _version.isNotEmpty
                    ? '${l10n.appName} v$_version (build $_buildNumber)'
                    : l10n.appName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageSubtitle(WidgetRef ref, AppLocalizations l10n) {
    final locale = ref.watch(languageProvider);
    if (locale == null) {
      return l10n.systemDefault;
    }
    switch (locale.languageCode) {
      case 'nl':
        return l10n.dutch;
      case 'en':
        return l10n.english;
      case 'es':
        return l10n.spanish;
      case 'de':
        return l10n.german;
      case 'fr':
        return l10n.french;
      case 'it':
        return l10n.italian;
      default:
        return l10n.systemDefault;
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentLocale = ref.read(languageProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              title: l10n.systemDefault,
              subtitle: l10n.languageDescription,
              isSelected: currentLocale == null,
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage(null);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageChanged)),
                );
              },
            ),
            const Divider(),
            _LanguageOption(
              title: l10n.dutch,
              subtitle: 'Nederlands',
              isSelected: currentLocale?.languageCode == 'nl',
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage('nl');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageChanged)),
                );
              },
            ),
            _LanguageOption(
              title: l10n.english,
              subtitle: 'English',
              isSelected: currentLocale?.languageCode == 'en',
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage('en');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageChanged)),
                );
              },
            ),
            _LanguageOption(
              title: l10n.german,
              subtitle: 'Deutsch',
              isSelected: currentLocale?.languageCode == 'de',
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage('de');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageChanged)),
                );
              },
            ),
            _LanguageOption(
              title: l10n.french,
              subtitle: 'Français',
              isSelected: currentLocale?.languageCode == 'fr',
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage('fr');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageChanged)),
                );
              },
            ),
            _LanguageOption(
              title: l10n.spanish,
              subtitle: 'Español',
              isSelected: currentLocale?.languageCode == 'es',
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage('es');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageChanged)),
                );
              },
            ),
            _LanguageOption(
              title: l10n.italian,
              subtitle: 'Italiano',
              isSelected: currentLocale?.languageCode == 'it',
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage('it');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageChanged)),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exportDialog),
        content: Text(l10n.exportDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiClient.instance.post('${ApiConfig.profile}/export');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.exportRequested),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.exportFailed),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.exportData),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final emailController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
              const SizedBox(width: 12),
              Text(l10n.deleteAccountTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.deleteAccountWarning,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(l10n.deleteAccountConsequences),
              const SizedBox(height: 20),
              Text(
                l10n.confirmEmail,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'je@email.nl',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      final user = ref.read(currentUserProvider);
                      if (emailController.text.trim().toLowerCase() !=
                          user?.email.toLowerCase()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.emailNotMatch),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isDeleting = true);

                      try {
                        await ApiClient.instance.delete('${ApiConfig.profile}/delete-account');
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.pop(context);
                          context.go('/login');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.accountDeleted),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.deleteAccountFailed),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.permanentlyDelete),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout),
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
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppTheme.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: textColor ?? AppTheme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: textColor?.withOpacity(0.7) ?? Colors.grey[600],
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
      onTap: onTap,
    );
  }
}
