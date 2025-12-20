import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Over VerhuurAgenda'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section with logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'VA',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'VerhuurAgenda',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versie $_version (build $_buildNumber)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Story section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Ons Verhaal',
                    'VerhuurAgenda is ontstaan uit onze eigen ervaring als vakantieverhuurders. '
                    'We weten hoe uitdagend het kan zijn om meerdere accommodaties te beheren, '
                    'boekingen bij te houden, en gasten een geweldige ervaring te bieden.\n\n'
                    'Daarom hebben we VerhuurAgenda ontwikkeld: een alles-in-één platform dat '
                    'speciaal is ontworpen voor Nederlandse verhuurders. Van boekingsbeheer tot '
                    'schoonmaakplanning, van gastenportaal tot financiële overzichten - alles '
                    'wat je nodig hebt op één plek.',
                  ),
                  const SizedBox(height: 32),

                  _buildSection(
                    'Onze Missie',
                    'We geloven dat vakantieverhuur persoonlijk en gastvrij moet zijn. '
                    'Onze missie is om verhuurders de tools te geven waarmee ze tijd besparen '
                    'op administratie, zodat ze zich kunnen focussen op wat echt belangrijk is: '
                    'het creëren van onvergetelijke ervaringen voor hun gasten.\n\n'
                    'Met VerhuurAgenda beheer je je verhuur professioneel, maar behoud je '
                    'het persoonlijke karakter dat jouw accommodatie uniek maakt.',
                  ),
                  const SizedBox(height: 32),

                  _buildSection(
                    'Waarom VerhuurAgenda?',
                    '',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.flag_outlined,
                    '100% Nederlands',
                    'Ontwikkeld in Nederland, voor Nederlandse verhuurders',
                  ),
                  _buildFeatureItem(
                    Icons.sync,
                    'Synchronisatie',
                    'Koppel met Airbnb, Booking.com en andere platforms',
                  ),
                  _buildFeatureItem(
                    Icons.phone_iphone,
                    'Altijd bij de hand',
                    'Beheer je verhuur onderweg met onze mobiele app',
                  ),
                  _buildFeatureItem(
                    Icons.support_agent,
                    'Persoonlijke support',
                    'Direct contact met ons team, geen chatbots',
                  ),
                  _buildFeatureItem(
                    Icons.security,
                    'Veilig & Betrouwbaar',
                    'Je gegevens zijn veilig opgeslagen in Nederland',
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Team section
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Gemaakt met',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite, color: Colors.red[400], size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'in Nederland',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '© ${DateTime.now().year} VerhuurAgenda.nl',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          'Alle rechten voorbehouden',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Links section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLinkButton('Website', 'https://verhuuragenda.nl'),
                      const SizedBox(width: 16),
                      _buildLinkButton('Privacy', 'https://verhuuragenda.nl/privacy'),
                      const SizedBox(width: 16),
                      _buildLinkButton('Voorwaarden', 'https://verhuuragenda.nl/voorwaarden'),
                    ],
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

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(String label, String url) {
    return TextButton(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 13,
        ),
      ),
    );
  }
}
