import 'package:flutter/material.dart';
import '../../config/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Algemene Voorwaarden'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
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
            _buildFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                const Text(
                  'Algemene Voorwaarden',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Laatst bijgewerkt: december 2024',
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

  Widget _buildFooter() {
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
            '© ${DateTime.now().year} Alle rechten voorbehouden',
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
