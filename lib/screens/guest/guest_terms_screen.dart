import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branding_provider.dart';
import '../settings/terms_screen.dart';
import '../settings/privacy_screen.dart';

/// Mandatory terms-acceptance screen for guests on first login.
class GuestTermsScreen extends ConsumerStatefulWidget {
  /// Callback fired when the guest successfully accepted the terms,
  /// so the parent (GuestHomeScreen) can refresh and continue.
  final VoidCallback onAccepted;

  const GuestTermsScreen({super.key, required this.onAccepted});

  @override
  ConsumerState<GuestTermsScreen> createState() => _GuestTermsScreenState();
}

class _GuestTermsScreenState extends ConsumerState<GuestTermsScreen> {
  bool _checked = false;
  bool _busy = false;

  Future<void> _accept() async {
    if (!_checked || _busy) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.post('/guest/terms/accept');
      if (!mounted) return;
      widget.onAccepted();
    } on DioException {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kon acceptatie niet opslaan. Probeer opnieuw.'),
        ),
      );
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
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
                      child: const Icon(Icons.privacy_tip_outlined,
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
                      'Even kort hoe we omgaan met je gegevens — voordat je aan je verblijf begint.',
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
                          _SectionTitle('Wat zie je in deze app?'),
                          const Text(
                            'Je boekingsdetails, contactgegevens van je '
                            'verhuurder, WiFi en check-in info, betalingen die '
                            'open staan, en een chat met je verhuurder.',
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Welke gegevens verwerken we?'),
                          const Text(
                            '• Je naam, e-mail en telefoonnummer (door je '
                            'verhuurder ingevoerd)\n'
                            '• De gegevens van je boeking\n'
                            '• Berichten en foto\'s die je in de chat stuurt\n'
                            '• Indien je inchekt: paspoort/identiteits-info '
                            'die je vrijwillig deelt',
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Hoe gebruiken we het?'),
                          const Text(
                            'Alleen om jouw verblijf goed te laten verlopen. '
                            'Je verhuurder is verantwoordelijk voor je '
                            'gegevens. Wij delen ze niet met derden buiten '
                            'wettelijke verplichtingen.',
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('Jouw rechten'),
                          const Text(
                            'Je kunt op ieder moment vragen welke gegevens er '
                            'over je zijn opgeslagen, of vragen ze te '
                            'verwijderen. Neem daarvoor contact op met je '
                            'verhuurder.',
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
                            'Meldingen worden binnen 24 uur beoordeeld.',
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.description_outlined,
                                    size: 16),
                                label: const Text('Volledige voorwaarden'),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const TermsScreen()),
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.privacy_tip_outlined,
                                    size: 16),
                                label: const Text('Privacybeleid'),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const PrivacyScreen()),
                                ),
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
                        'Ik ga akkoord met de voorwaarden en het privacybeleid.',
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
