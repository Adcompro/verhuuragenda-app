import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String supportEmail = 'support@verhuuragenda.nl';
  static const String phoneNumber = '+31 6 83710971';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpTitle),
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
                  Text(
                    l10n.helpHowCanWeHelp,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.helpTeamAvailable,
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
                  Text(
                    l10n.helpContactUs,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email card
                  _buildContactCard(
                    context,
                    l10n,
                    icon: Icons.email_outlined,
                    title: l10n.helpEmailTitle,
                    subtitle: supportEmail,
                    description: l10n.helpEmailResponse,
                    onTap: () => _sendEmail(context),
                    onLongPress: () => _copyToClipboard(context, l10n, supportEmail),
                  ),
                  const SizedBox(height: 12),

                  // Phone card
                  _buildContactCard(
                    context,
                    l10n,
                    icon: Icons.phone_outlined,
                    title: l10n.helpPhoneTitle,
                    subtitle: phoneNumber,
                    description: l10n.helpPhoneHours,
                    onTap: () => _callPhone(context),
                    onLongPress: () => _copyToClipboard(context, l10n, phoneNumber),
                  ),
                  const SizedBox(height: 12),

                  // WhatsApp card
                  _buildContactCard(
                    context,
                    l10n,
                    icon: Icons.chat_outlined,
                    title: l10n.helpWhatsAppTitle,
                    subtitle: l10n.helpWhatsAppSubtitle,
                    description: l10n.helpWhatsAppResponse,
                    onTap: () => _openWhatsApp(context),
                    color: Colors.green,
                  ),

                  const SizedBox(height: 32),

                  // FAQ Section
                  Text(
                    l10n.helpFaqTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFaqItem(
                    l10n.helpFaq1Question,
                    l10n.helpFaq1Answer,
                  ),
                  _buildFaqItem(
                    l10n.helpFaq2Question,
                    l10n.helpFaq2Answer,
                  ),
                  _buildFaqItem(
                    l10n.helpFaq3Question,
                    l10n.helpFaq3Answer,
                  ),
                  _buildFaqItem(
                    l10n.helpFaq4Question,
                    l10n.helpFaq4Answer,
                  ),
                  _buildFaqItem(
                    l10n.helpFaq5Question,
                    l10n.helpFaq5Answer,
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
                        Text(
                          l10n.helpFeedbackTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.helpFeedbackDescription,
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
                          label: Text(l10n.helpFeedbackButton),
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
    BuildContext context,
    AppLocalizations l10n, {
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

  void _copyToClipboard(BuildContext context, AppLocalizations l10n, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.helpCopied(text)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
