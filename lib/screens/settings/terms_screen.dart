import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.terms),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nederlands'),
            Tab(text: 'English'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDutchContent(),
          _buildEnglishContent(),
        ],
      ),
    );
  }

  Widget _buildDutchContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Algemene Voorwaarden', 'Laatst bijgewerkt: december 2024'),
          const SizedBox(height: 24),
          _buildSection(
            '1. Definities',
            'In deze algemene voorwaarden wordt verstaan onder:\n\n'
            '• VerhuurAgenda: de software en diensten aangeboden via verhuuragenda.nl en de VerhuurAgenda mobiele applicatie.\n\n'
            '• Gebruiker: de natuurlijke persoon of rechtspersoon die gebruik maakt van VerhuurAgenda.\n\n'
            '• Dienst: alle functionaliteiten en services die VerhuurAgenda aanbiedt, waaronder maar niet beperkt tot boekingsbeheer, kalenderintegratie, gastenportaal en financieel overzicht.\n\n'
            '• Account: de persoonlijke toegang tot de Dienst die wordt aangemaakt bij registratie.',
          ),
          _buildSection(
            '2. Toepasselijkheid',
            'Deze algemene voorwaarden zijn van toepassing op alle overeenkomsten tussen VerhuurAgenda en de Gebruiker.\n\n'
            'Door gebruik te maken van de Dienst of door het aanmaken van een Account, accepteert de Gebruiker deze voorwaarden.\n\n'
            'VerhuurAgenda behoudt zich het recht voor deze voorwaarden te wijzigen. Wijzigingen worden minimaal 30 dagen vooraf aangekondigd via e-mail of in de applicatie.',
          ),
          _buildSection(
            '3. Gebruik van de Dienst',
            'De Gebruiker is verantwoordelijk voor:\n\n'
            '• Het juiste gebruik van de Dienst conform de toepasselijke wet- en regelgeving.\n\n'
            '• Het vertrouwelijk houden van inloggegevens en het beveiligen van het Account.\n\n'
            '• De juistheid en volledigheid van de ingevoerde gegevens.\n\n'
            '• Het naleven van de Algemene Verordening Gegevensbescherming (AVG) bij het verwerken van gastgegevens.\n\n'
            'Het is niet toegestaan om:\n\n'
            '• De Dienst te gebruiken voor illegale activiteiten.\n\n'
            '• Gegevens van andere gebruikers te verzamelen of te gebruiken zonder toestemming.\n\n'
            '• De werking van de Dienst te verstoren of te proberen ongeautoriseerde toegang te verkrijgen.',
          ),
          _buildSection(
            '4. Proefperiode en Abonnementen',
            'VerhuurAgenda biedt een gratis proefperiode van 14 dagen. Na afloop van de proefperiode kan de Gebruiker kiezen voor een betaald abonnement.\n\n'
            'Abonnementen worden automatisch verlengd tenzij de Gebruiker tijdig opzegt. Opzegging dient minimaal 7 dagen voor het einde van de lopende periode te geschieden.\n\n'
            'Bij in-app aankopen via de App Store of Google Play gelden aanvullend de voorwaarden van Apple respectievelijk Google.',
          ),
          _buildSection(
            '5. Betalingen',
            'Betaling geschiedt vooraf voor de gekozen abonnementsperiode.\n\n'
            'Prijzen zijn in euro\'s en exclusief BTW, tenzij anders vermeld.\n\n'
            'Bij niet-tijdige betaling behoudt VerhuurAgenda zich het recht voor de toegang tot de Dienst op te schorten.',
          ),
          _buildSection(
            '6. Intellectueel Eigendom',
            'Alle intellectuele eigendomsrechten op de Dienst, inclusief maar niet beperkt tot software, ontwerp, logo\'s en documentatie, berusten bij VerhuurAgenda.\n\n'
            'De Gebruiker verkrijgt uitsluitend een beperkt, niet-exclusief en niet-overdraagbaar gebruiksrecht voor de duur van het abonnement.',
          ),
          _buildSection(
            '7. Gegevens en Privacy',
            'VerhuurAgenda verwerkt persoonsgegevens conform het Privacybeleid en de AVG.\n\n'
            'De Gebruiker blijft eigenaar van alle data die in de Dienst wordt ingevoerd. Bij beëindiging van het abonnement kan de Gebruiker een export van de gegevens aanvragen.\n\n'
            'VerhuurAgenda maakt regelmatig back-ups maar kan niet garanderen dat data in alle omstandigheden behouden blijft.',
          ),
          _buildSection(
            '8. Beschikbaarheid en Onderhoud',
            'VerhuurAgenda streeft naar een beschikbaarheid van 99,5% op jaarbasis.\n\n'
            'Gepland onderhoud wordt vooraf aangekondigd. VerhuurAgenda is niet aansprakelijk voor onderbrekingen door overmacht of noodzakelijk noodonderhoud.',
          ),
          _buildSection(
            '9. Aansprakelijkheid',
            'VerhuurAgenda spant zich in om een betrouwbare dienst te leveren, maar geeft geen garanties.\n\n'
            'VerhuurAgenda is niet aansprakelijk voor:\n\n'
            '• Indirecte schade, gevolgschade of gederfde winst.\n\n'
            '• Schade als gevolg van onjuist gebruik door de Gebruiker.\n\n'
            '• Schade door verlies van gegevens.\n\n'
            '• Schade door acties van derden.\n\n'
            'De totale aansprakelijkheid is beperkt tot het bedrag dat de Gebruiker in de 12 maanden voorafgaand aan de schade heeft betaald.',
          ),
          _buildSection(
            '10. Beëindiging',
            'De Gebruiker kan het abonnement op elk moment opzeggen via de accountinstellingen.\n\n'
            'VerhuurAgenda kan het Account opschorten of beëindigen bij:\n\n'
            '• Schending van deze voorwaarden.\n\n'
            '• Niet-betaling van verschuldigde bedragen.\n\n'
            '• Misbruik van de Dienst.\n\n'
            'Na beëindiging worden gegevens binnen 90 dagen verwijderd, tenzij wettelijk anders vereist.',
          ),
          _buildSection(
            '11. Toepasselijk Recht',
            'Op deze voorwaarden is Nederlands recht van toepassing.\n\n'
            'Geschillen worden voorgelegd aan de bevoegde rechter in Nederland.',
          ),
          _buildSection(
            '12. Contact',
            'Voor vragen over deze voorwaarden kunt u contact opnemen via:\n\n'
            'E-mail: info@verhuuragenda.nl\n\n'
            'Website: www.verhuuragenda.nl/contact',
          ),
          const SizedBox(height: 24),
          _buildFooter('Alle rechten voorbehouden'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEnglishContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Terms and Conditions', 'Last updated: December 2024'),
          const SizedBox(height: 24),
          _buildSection(
            '1. Definitions',
            'In these terms and conditions, the following definitions apply:\n\n'
            '• VerhuurAgenda: the software and services offered via verhuuragenda.nl and the VerhuurAgenda mobile application.\n\n'
            '• User: the natural person or legal entity using VerhuurAgenda.\n\n'
            '• Service: all functionalities and services offered by VerhuurAgenda, including but not limited to booking management, calendar integration, guest portal, and financial overview.\n\n'
            '• Account: the personal access to the Service created upon registration.',
          ),
          _buildSection(
            '2. Applicability',
            'These terms and conditions apply to all agreements between VerhuurAgenda and the User.\n\n'
            'By using the Service or by creating an Account, the User accepts these terms.\n\n'
            'VerhuurAgenda reserves the right to modify these terms. Changes will be announced at least 30 days in advance via email or in the application.',
          ),
          _buildSection(
            '3. Use of the Service',
            'The User is responsible for:\n\n'
            '• Proper use of the Service in accordance with applicable laws and regulations.\n\n'
            '• Keeping login credentials confidential and securing the Account.\n\n'
            '• The accuracy and completeness of entered data.\n\n'
            '• Compliance with the General Data Protection Regulation (GDPR) when processing guest data.\n\n'
            'It is not permitted to:\n\n'
            '• Use the Service for illegal activities.\n\n'
            '• Collect or use data from other users without permission.\n\n'
            '• Disrupt the operation of the Service or attempt to gain unauthorized access.',
          ),
          _buildSection(
            '4. Trial Period and Subscriptions',
            'VerhuurAgenda offers a free trial period of 14 days. After the trial period, the User can choose a paid subscription.\n\n'
            'Subscriptions are automatically renewed unless the User cancels in time. Cancellation must be made at least 7 days before the end of the current period.\n\n'
            'For in-app purchases via the App Store or Google Play, the terms of Apple and Google respectively apply additionally.',
          ),
          _buildSection(
            '5. Payments',
            'Payment is made in advance for the chosen subscription period.\n\n'
            'Prices are in euros and exclude VAT, unless otherwise stated.\n\n'
            'In case of late payment, VerhuurAgenda reserves the right to suspend access to the Service.',
          ),
          _buildSection(
            '6. Intellectual Property',
            'All intellectual property rights to the Service, including but not limited to software, design, logos, and documentation, belong to VerhuurAgenda.\n\n'
            'The User only obtains a limited, non-exclusive, and non-transferable right of use for the duration of the subscription.',
          ),
          _buildSection(
            '7. Data and Privacy',
            'VerhuurAgenda processes personal data in accordance with the Privacy Policy and GDPR.\n\n'
            'The User remains the owner of all data entered into the Service. Upon termination of the subscription, the User can request an export of the data.\n\n'
            'VerhuurAgenda makes regular backups but cannot guarantee that data will be preserved under all circumstances.',
          ),
          _buildSection(
            '8. Availability and Maintenance',
            'VerhuurAgenda strives for an availability of 99.5% annually.\n\n'
            'Scheduled maintenance is announced in advance. VerhuurAgenda is not liable for interruptions due to force majeure or necessary emergency maintenance.',
          ),
          _buildSection(
            '9. Liability',
            'VerhuurAgenda strives to provide a reliable service but provides no guarantees.\n\n'
            'VerhuurAgenda is not liable for:\n\n'
            '• Indirect damage, consequential damage, or lost profits.\n\n'
            '• Damage resulting from incorrect use by the User.\n\n'
            '• Damage from loss of data.\n\n'
            '• Damage from actions of third parties.\n\n'
            'Total liability is limited to the amount paid by the User in the 12 months preceding the damage.',
          ),
          _buildSection(
            '10. Termination',
            'The User can cancel the subscription at any time via the account settings.\n\n'
            'VerhuurAgenda can suspend or terminate the Account for:\n\n'
            '• Violation of these terms.\n\n'
            '• Non-payment of amounts due.\n\n'
            '• Abuse of the Service.\n\n'
            'After termination, data will be deleted within 90 days, unless otherwise required by law.',
          ),
          _buildSection(
            '11. Applicable Law',
            'These terms are governed by Dutch law.\n\n'
            'Disputes will be submitted to the competent court in the Netherlands.',
          ),
          _buildSection(
            '12. Contact',
            'For questions about these terms, you can contact us via:\n\n'
            'Email: info@verhuuragenda.nl\n\n'
            'Website: www.verhuuragenda.nl/contact',
          ),
          const SizedBox(height: 24),
          _buildFooter('All rights reserved'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String lastUpdated) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: AppTheme.primaryColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastUpdated,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(String rightsText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'VerhuurAgenda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© ${DateTime.now().year} $rightsText',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
