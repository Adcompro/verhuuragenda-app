import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String supportEmail = 'support@verhuuragenda.nl';
  static const String phoneNumber = '+31 6 83710971';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppTheme.primaryColor.withOpacity(0.05),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.support_agent,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hoe kunnen we je helpen?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ons team staat voor je klaar op werkdagen\nvan 9:00 tot 17:00 uur',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Contact options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Neem contact op',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email card
                  _buildContactCard(
                    context,
                    icon: Icons.email_outlined,
                    title: 'E-mail',
                    subtitle: supportEmail,
                    description: 'We reageren binnen 24 uur',
                    onTap: () => _sendEmail(context),
                    onLongPress: () => _copyToClipboard(context, supportEmail),
                  ),
                  const SizedBox(height: 12),

                  // Phone card
                  _buildContactCard(
                    context,
                    icon: Icons.phone_outlined,
                    title: 'Telefoon',
                    subtitle: phoneNumber,
                    description: 'Ma-Vr 9:00 - 17:00',
                    onTap: () => _callPhone(context),
                    onLongPress: () => _copyToClipboard(context, phoneNumber),
                  ),
                  const SizedBox(height: 12),

                  // WhatsApp card
                  _buildContactCard(
                    context,
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp',
                    subtitle: 'Chat met ons',
                    description: 'Snelle reactie op werkdagen',
                    onTap: () => _openWhatsApp(context),
                    color: Colors.green,
                  ),

                  const SizedBox(height: 32),

                  // FAQ Section
                  const Text(
                    'Veelgestelde vragen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFaqItem(
                    'Hoe voeg ik een nieuwe accommodatie toe?',
                    'Ga naar Accommodaties in het menu en tik op de + knop. '
                    'Vul de gegevens in en voeg foto\'s toe. Je kunt later altijd wijzigingen maken.',
                  ),
                  _buildFaqItem(
                    'Hoe synchroniseer ik met Airbnb of Booking.com?',
                    'Ga naar je accommodatie instellingen en voeg de iCal URL toe van je externe platform. '
                    'VerhuurAgenda haalt automatisch de boekingen op.',
                  ),
                  _buildFaqItem(
                    'Hoe werkt het gastenportaal?',
                    'Bij elke boeking wordt automatisch een unieke link gegenereerd. '
                    'Deel deze met je gasten zodat ze kunnen inchecken en alle informatie kunnen bekijken.',
                  ),
                  _buildFaqItem(
                    'Kan ik meerdere gebruikers toevoegen?',
                    'Ja, afhankelijk van je abonnement kun je teamleden uitnodigen. '
                    'Ga naar Instellingen > Abonnement om je limieten te bekijken.',
                  ),
                  _buildFaqItem(
                    'Hoe kan ik mijn abonnement verlengen?',
                    'Ga naar Instellingen > Abonnement en tik op "Naar betaling op website". '
                    'Je wordt doorgestuurd naar onze beveiligde betaalpagina.',
                  ),

                  const SizedBox(height: 32),

                  // Feedback section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 32),
                        const SizedBox(height: 12),
                        const Text(
                          'Heb je een idee of suggestie?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We horen graag je feedback! Stuur ons een bericht met je idee en wie weet zit het in de volgende update.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _sendFeedback(context),
                          icon: const Icon(Icons.send),
                          label: const Text('Feedback versturen'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? color,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color ?? AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Support aanvraag VerhuurAgenda App',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _callPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/31683710971?text=Hallo,%20ik%20heb%20een%20vraag%20over%20VerhuurAgenda');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Feedback VerhuurAgenda App',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text gekopieerd'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
