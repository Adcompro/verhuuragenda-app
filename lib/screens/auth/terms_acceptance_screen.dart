import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';

/// Mandatory terms-acceptance screen shown after first login (and any
/// time the host has not accepted the current terms version yet).
class TermsAcceptanceScreen extends ConsumerStatefulWidget {
  const TermsAcceptanceScreen({super.key});

  @override
  ConsumerState<TermsAcceptanceScreen> createState() =>
      _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState
    extends ConsumerState<TermsAcceptanceScreen> {
  bool _checked = false;
  bool _busy = false;

  Future<void> _accept() async {
    if (!_checked || _busy) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.post('/terms/accept', data: {'version': User.currentTermsVersion});
      // Refresh user so the router knows about the new state
      await ref.read(authStateProvider.notifier).refreshUser();
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kon acceptatie niet opslaan. Probeer opnieuw.'),
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(brandingProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.description_outlined,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welkom bij $brand',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Voor we beginnen vragen we je akkoord te geven met onze voorwaarden en privacybeleid.',
                      style: TextStyle(
                          color: Colors.grey[700], fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 0,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Wat doet $brand?'),
                          const Text(
                            'Een beheersysteem voor vakantieverhuur: kalender, '
                            'boekingen, gastenportaal, schoonmaak- en '
                            'onderhoudsplanning, betalingen en chat met je '
                            'gasten.',
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Welke gegevens verwerken we?'),
                          const Text(
                            '• Jouw account- en bedrijfsgegevens\n'
                            '• Boekingen, gasten en betalingen die je invoert\n'
                            '• Foto\'s die je uploadt voor onderhoud of chat\n'
                            '• Pushtokens voor notificaties (als je toestemt)',
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Hoe verwerken we het?'),
                          const Text(
                            'Alle data wordt versleuteld over HTTPS verzonden '
                            'en opgeslagen op servers in de EU. We delen je '
                            'gegevens niet met derden buiten wettelijke '
                            'verplichtingen of jouw expliciete toestemming.',
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Jouw rechten'),
                          const Text(
                            'Je kunt op ieder moment je gegevens inzien, '
                            'exporteren of verwijderen via Instellingen → '
                            'Gegevens exporteren of Account verwijderen.',
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Gedragsregels in de chat'),
                          const Text(
                            'CasaMio hanteert een nultolerantie voor '
                            'ongepaste, beledigende, haatdragende, '
                            'bedreigende of intimiderende inhoud. Dergelijke '
                            'berichten worden verwijderd en de verantwoordelijke '
                            'wordt direct uit het platform geweerd.\n\n'
                            '• Houd een bericht ingedrukt om het te melden.\n'
                            '• Open een gesprek → menu rechtsboven → '
                            '"Gast blokkeren" om iemand te blokkeren.\n'
                            '• Meldingen worden binnen 24 uur beoordeeld.',
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Volledige voorwaarden'),
                                onPressed: () => _openUrl(
                                    'https://verhuuragenda.nl/algemene-voorwaarden'),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Privacybeleid'),
                                onPressed: () =>
                                    _openUrl('https://verhuuragenda.nl/privacy'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _checked,
                      onChanged: (v) => setState(() => _checked = v ?? false),
                      title: const Text(
                        'Ik ga akkoord met de algemene voorwaarden en het privacybeleid.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _busy ? null : _logout,
                            child: const Text('Uitloggen'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _checked && !_busy ? _accept : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Akkoord & doorgaan'),
                          ),
                        ),
                      ],
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
