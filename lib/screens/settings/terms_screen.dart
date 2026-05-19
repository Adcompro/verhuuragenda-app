import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';

/// CasaMio uses Apple's Standard End User License Agreement, as
/// declared in App Store Connect. To stay consistent with that
/// declaration (Guideline 3.1.2(b) / 2.3.10), this screen links the
/// user to Apple's hosted EULA instead of showing custom terms.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String _appleStdEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  Future<void> _openEula(BuildContext context) async {
    final uri = Uri.parse(_appleStdEulaUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kon de voorwaarden niet openen. Controleer je internetverbinding.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.terms)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined,
                        color: AppTheme.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Gebruiksvoorwaarden',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Voor het gebruik van de CasaMio app gelden Apple’s '
                'standaard gebruiksvoorwaarden voor App Store-applicaties '
                '(Apple Standard End User License Agreement).',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Tik op de knop hieronder om de volledige voorwaarden van '
                'Apple te openen.',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openEula(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Bekijk volledige voorwaarden'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                _appleStdEulaUrl,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'CasaMio',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© ${DateTime.now().year} Alle rechten voorbehouden',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
