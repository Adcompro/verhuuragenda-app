import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> with SingleTickerProviderStateMixin {
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
        title: Text(l10n.privacy),
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
          _buildHeader('Privacybeleid', 'Laatst bijgewerkt: december 2024'),
          const SizedBox(height: 24),
          _buildIntro(
            'Uw privacy is belangrijk',
            'Dit privacybeleid beschrijft hoe VerhuurAgenda uw persoonsgegevens verzamelt, gebruikt en beschermt. Wij verwerken uw gegevens in overeenstemming met de Algemene Verordening Gegevensbescherming (AVG).',
          ),
          const SizedBox(height: 24),
          _buildSection(
            '1. Wie zijn wij?',
            'VerhuurAgenda is een dienst voor het beheren van vakantieverhuur, aangeboden via de website verhuuragenda.nl en de VerhuurAgenda mobiele applicatie.\n\n'
            'Wij zijn verantwoordelijk voor de verwerking van uw persoonsgegevens zoals beschreven in dit privacybeleid.',
          ),
          _buildSection(
            '2. Welke gegevens verzamelen wij?',
            'Wij verzamelen en verwerken de volgende categorieën persoonsgegevens:\n\n'
            'Accountgegevens:\n'
            '• Naam en achternaam\n'
            '• E-mailadres\n'
            '• Telefoonnummer (optioneel)\n'
            '• Bedrijfsnaam (optioneel)\n'
            '• Wachtwoord (versleuteld opgeslagen)\n\n'
            'Gebruiksgegevens:\n'
            '• Inloggegevens en sessie-informatie\n'
            '• Apparaatinformatie (type, besturingssysteem)\n'
            '• App-gebruiksstatistieken\n\n'
            'Zakelijke gegevens:\n'
            '• Accommodatie-informatie\n'
            '• Boekingsgegevens\n'
            '• Gastgegevens die u invoert\n'
            '• Financiële overzichten\n\n'
            'Technische gegevens:\n'
            '• IP-adres\n'
            '• Push notification tokens (voor meldingen)\n'
            '• Foutmeldingen en crash logs',
          ),
          _buildSection(
            '3. Waarvoor gebruiken wij uw gegevens?',
            'Wij gebruiken uw gegevens voor de volgende doeleinden:\n\n'
            'Dienstverlening:\n'
            '• Het aanmaken en beheren van uw account\n'
            '• Het leveren van de boekingsbeheerfunctionaliteiten\n'
            '• Het synchroniseren van kalenders\n'
            '• Het versturen van push notificaties over boekingen\n\n'
            'Communicatie:\n'
            '• Het beantwoorden van uw vragen\n'
            '• Het versturen van service-gerelateerde mededelingen\n'
            '• Het informeren over wijzigingen in de dienst\n\n'
            'Verbetering:\n'
            '• Het analyseren van app-gebruik om de dienst te verbeteren\n'
            '• Het oplossen van technische problemen\n\n'
            'Juridisch:\n'
            '• Het voldoen aan wettelijke verplichtingen\n'
            '• Het beschermen van onze rechten',
          ),
          _buildSection(
            '4. Rechtsgronden voor verwerking',
            'Wij verwerken uw gegevens op basis van:\n\n'
            '• Uitvoering van de overeenkomst: voor het leveren van onze diensten.\n\n'
            '• Gerechtvaardigd belang: voor het verbeteren van onze dienst en het voorkomen van fraude.\n\n'
            '• Wettelijke verplichting: wanneer de wet ons verplicht gegevens te bewaren.\n\n'
            '• Toestemming: voor het versturen van marketing (waar van toepassing).',
          ),
          _buildSection(
            '5. Delen met derden',
            'Wij delen uw gegevens alleen met derden wanneer dit noodzakelijk is:\n\n'
            'Dienstverleners:\n'
            '• Hosting providers (servers in Nederland/EU)\n'
            '• E-mail dienstverleners\n'
            '• Betalingsverwerkers\n\n'
            'Wij verkopen uw gegevens nooit aan derden.\n\n'
            'Alle dienstverleners zijn gebonden aan verwerkersovereenkomsten en mogen uw gegevens alleen gebruiken voor de overeengekomen doeleinden.',
          ),
          _buildSection(
            '6. Gegevensbeveiliging',
            'Wij nemen passende technische en organisatorische maatregelen om uw gegevens te beschermen:\n\n'
            '• Versleutelde verbindingen (HTTPS/TLS)\n'
            '• Versleutelde opslag van wachtwoorden\n'
            '• Beperkte toegang tot persoonsgegevens\n'
            '• Regelmatige beveiligingsupdates\n'
            '• Back-ups van gegevens\n'
            '• Servers gehost in Nederland\n\n'
            'De app slaat inloggegevens veilig op in de beveiligde opslag van uw apparaat (Keychain op iOS, Encrypted SharedPreferences op Android).',
          ),
          _buildSection(
            '7. Bewaartermijnen',
            'Wij bewaren uw gegevens niet langer dan noodzakelijk:\n\n'
            '• Accountgegevens: tot 90 dagen na beëindiging account\n'
            '• Boekingsgegevens: 7 jaar (wettelijke bewaarplicht)\n'
            '• Factuurgegevens: 7 jaar (fiscale bewaarplicht)\n'
            '• Logbestanden: maximaal 12 maanden\n\n'
            'Na afloop van de bewaartermijn worden gegevens verwijderd of geanonimiseerd.',
          ),
          _buildSection(
            '8. Uw rechten',
            'Op grond van de AVG heeft u de volgende rechten:\n\n'
            '• Inzage: U kunt opvragen welke gegevens wij van u verwerken.\n\n'
            '• Rectificatie: U kunt onjuiste gegevens laten corrigeren.\n\n'
            '• Verwijdering: U kunt verzoeken uw gegevens te verwijderen.\n\n'
            '• Beperking: U kunt verzoeken de verwerking te beperken.\n\n'
            '• Overdraagbaarheid: U kunt uw gegevens in een gangbaar formaat ontvangen.\n\n'
            '• Bezwaar: U kunt bezwaar maken tegen bepaalde verwerkingen.\n\n'
            'Om uw rechten uit te oefenen, kunt u contact met ons opnemen via de contactgegevens onderaan dit beleid.\n\n'
            'U kunt ook een klacht indienen bij de Autoriteit Persoonsgegevens.',
          ),
          _buildSection(
            '9. Gegevens exporteren',
            'U kunt op elk moment een export van uw gegevens aanvragen via:\n\n'
            '• De app: Instellingen > Gegevens exporteren\n'
            '• De website: Mijn Account > Gegevens exporteren\n'
            '• E-mail naar: privacy@verhuuragenda.nl\n\n'
            'U ontvangt dan een bestand met al uw gegevens in een leesbaar formaat.',
          ),
          _buildSection(
            '10. Account verwijderen',
            'U kunt uw account verwijderen via:\n\n'
            '• De app: Instellingen > Account verwijderen\n'
            '• De website: Mijn Account > Account verwijderen\n\n'
            'Bij verwijdering worden al uw gegevens verwijderd, met uitzondering van gegevens die wij wettelijk moeten bewaren.',
          ),
          _buildSection(
            '11. Push notificaties',
            'De app kan push notificaties versturen voor:\n\n'
            '• Nieuwe boekingen\n'
            '• Check-in/check-out herinneringen\n'
            '• Betalingsherinneringen\n'
            '• Belangrijke service-updates\n\n'
            'U kunt push notificaties uitschakelen via:\n'
            '• De app-instellingen\n'
            '• De instellingen van uw apparaat',
          ),
          _buildSection(
            '12. Cookies en tracking',
            'De website gebruikt functionele cookies voor het goed functioneren van de dienst.\n\n'
            'De mobiele app verzamelt geen tracking data voor advertentiedoeleinden. Wij gebruiken alleen technische gegevens om de app te verbeteren en problemen op te lossen.',
          ),
          _buildSection(
            '13. Kinderen',
            'Onze dienst is niet bedoeld voor kinderen onder de 16 jaar. Wij verzamelen niet bewust gegevens van kinderen. Als u vermoedt dat wij gegevens van een kind hebben verzameld, neem dan contact met ons op.',
          ),
          _buildSection(
            '14. Internationale doorgifte',
            'Uw gegevens worden opgeslagen op servers in Nederland. Wij geven geen gegevens door naar landen buiten de Europese Economische Ruimte (EER), tenzij er passende waarborgen zijn getroffen.',
          ),
          _buildSection(
            '15. Wijzigingen',
            'Wij kunnen dit privacybeleid wijzigen. Belangrijke wijzigingen worden minimaal 30 dagen vooraf aangekondigd via e-mail of in de app.\n\n'
            'De datum van de laatste wijziging staat bovenaan dit document.',
          ),
          _buildSection(
            '16. Contact',
            'Voor vragen over dit privacybeleid of het uitoefenen van uw rechten:\n\n'
            'E-mail: privacy@verhuuragenda.nl\n\n'
            'Website: www.verhuuragenda.nl/contact\n\n'
            'Wij streven ernaar uw verzoeken binnen 30 dagen te beantwoorden.',
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
          _buildHeader('Privacy Policy', 'Last updated: December 2024'),
          const SizedBox(height: 24),
          _buildIntro(
            'Your privacy is important',
            'This privacy policy describes how VerhuurAgenda collects, uses, and protects your personal data. We process your data in accordance with the General Data Protection Regulation (GDPR).',
          ),
          const SizedBox(height: 24),
          _buildSection(
            '1. Who are we?',
            'VerhuurAgenda is a vacation rental management service offered through the website verhuuragenda.nl and the VerhuurAgenda mobile application.\n\n'
            'We are responsible for processing your personal data as described in this privacy policy.',
          ),
          _buildSection(
            '2. What data do we collect?',
            'We collect and process the following categories of personal data:\n\n'
            'Account data:\n'
            '• First and last name\n'
            '• Email address\n'
            '• Phone number (optional)\n'
            '• Company name (optional)\n'
            '• Password (stored encrypted)\n\n'
            'Usage data:\n'
            '• Login data and session information\n'
            '• Device information (type, operating system)\n'
            '• App usage statistics\n\n'
            'Business data:\n'
            '• Accommodation information\n'
            '• Booking data\n'
            '• Guest data you enter\n'
            '• Financial overviews\n\n'
            'Technical data:\n'
            '• IP address\n'
            '• Push notification tokens (for notifications)\n'
            '• Error messages and crash logs',
          ),
          _buildSection(
            '3. What do we use your data for?',
            'We use your data for the following purposes:\n\n'
            'Service delivery:\n'
            '• Creating and managing your account\n'
            '• Providing booking management functionality\n'
            '• Synchronizing calendars\n'
            '• Sending push notifications about bookings\n\n'
            'Communication:\n'
            '• Answering your questions\n'
            '• Sending service-related communications\n'
            '• Informing you about changes to the service\n\n'
            'Improvement:\n'
            '• Analyzing app usage to improve the service\n'
            '• Resolving technical issues\n\n'
            'Legal:\n'
            '• Complying with legal obligations\n'
            '• Protecting our rights',
          ),
          _buildSection(
            '4. Legal bases for processing',
            'We process your data based on:\n\n'
            '• Performance of contract: for providing our services.\n\n'
            '• Legitimate interest: for improving our service and preventing fraud.\n\n'
            '• Legal obligation: when the law requires us to retain data.\n\n'
            '• Consent: for sending marketing (where applicable).',
          ),
          _buildSection(
            '5. Sharing with third parties',
            'We only share your data with third parties when necessary:\n\n'
            'Service providers:\n'
            '• Hosting providers (servers in Netherlands/EU)\n'
            '• Email service providers\n'
            '• Payment processors\n\n'
            'We never sell your data to third parties.\n\n'
            'All service providers are bound by data processing agreements and may only use your data for the agreed purposes.',
          ),
          _buildSection(
            '6. Data security',
            'We take appropriate technical and organizational measures to protect your data:\n\n'
            '• Encrypted connections (HTTPS/TLS)\n'
            '• Encrypted password storage\n'
            '• Limited access to personal data\n'
            '• Regular security updates\n'
            '• Data backups\n'
            '• Servers hosted in the Netherlands\n\n'
            'The app stores login credentials securely in your device\'s secure storage (Keychain on iOS, Encrypted SharedPreferences on Android).',
          ),
          _buildSection(
            '7. Retention periods',
            'We do not retain your data longer than necessary:\n\n'
            '• Account data: up to 90 days after account termination\n'
            '• Booking data: 7 years (legal retention requirement)\n'
            '• Invoice data: 7 years (tax retention requirement)\n'
            '• Log files: maximum 12 months\n\n'
            'After the retention period expires, data is deleted or anonymized.',
          ),
          _buildSection(
            '8. Your rights',
            'Under the GDPR, you have the following rights:\n\n'
            '• Access: You can request which data we process about you.\n\n'
            '• Rectification: You can have incorrect data corrected.\n\n'
            '• Erasure: You can request deletion of your data.\n\n'
            '• Restriction: You can request to restrict processing.\n\n'
            '• Portability: You can receive your data in a common format.\n\n'
            '• Objection: You can object to certain processing.\n\n'
            'To exercise your rights, you can contact us using the contact details at the bottom of this policy.\n\n'
            'You can also file a complaint with the Data Protection Authority.',
          ),
          _buildSection(
            '9. Data export',
            'You can request an export of your data at any time via:\n\n'
            '• The app: Settings > Export data\n'
            '• The website: My Account > Export data\n'
            '• Email to: privacy@verhuuragenda.nl\n\n'
            'You will receive a file with all your data in a readable format.',
          ),
          _buildSection(
            '10. Delete account',
            'You can delete your account via:\n\n'
            '• The app: Settings > Delete account\n'
            '• The website: My Account > Delete account\n\n'
            'Upon deletion, all your data will be removed, except for data we are legally required to retain.',
          ),
          _buildSection(
            '11. Push notifications',
            'The app can send push notifications for:\n\n'
            '• New bookings\n'
            '• Check-in/check-out reminders\n'
            '• Payment reminders\n'
            '• Important service updates\n\n'
            'You can disable push notifications via:\n'
            '• The app settings\n'
            '• Your device settings',
          ),
          _buildSection(
            '12. Cookies and tracking',
            'The website uses functional cookies for the proper functioning of the service.\n\n'
            'The mobile app does not collect tracking data for advertising purposes. We only use technical data to improve the app and resolve issues.',
          ),
          _buildSection(
            '13. Children',
            'Our service is not intended for children under 16 years of age. We do not knowingly collect data from children. If you believe we have collected data from a child, please contact us.',
          ),
          _buildSection(
            '14. International transfer',
            'Your data is stored on servers in the Netherlands. We do not transfer data to countries outside the European Economic Area (EEA), unless appropriate safeguards are in place.',
          ),
          _buildSection(
            '15. Changes',
            'We may change this privacy policy. Significant changes will be announced at least 30 days in advance via email or in the app.\n\n'
            'The date of the last change is shown at the top of this document.',
          ),
          _buildSection(
            '16. Contact',
            'For questions about this privacy policy or exercising your rights:\n\n'
            'Email: privacy@verhuuragenda.nl\n\n'
            'Website: www.verhuuragenda.nl/contact\n\n'
            'We aim to respond to your requests within 30 days.',
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
          Icon(Icons.privacy_tip, color: AppTheme.primaryColor, size: 32),
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

  Widget _buildIntro(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.blue[900],
              height: 1.5,
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
          const SizedBox(height: 8),
          Text(
            'privacy@verhuuragenda.nl',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
