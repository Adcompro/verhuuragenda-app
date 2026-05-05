import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// In-app handleiding (Dutch-only for v1). Walks the user through
/// the main flows: first-time setup, manual property creation,
/// making bookings, seasonal pricing, modules and settings.
///
/// Reachable via Settings → Help → Handleiding.
class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manualTitle),
      ),
      body: ListView(
        children: [
          // Hero
          Container(
            color: AppTheme.primaryColor.withOpacity(0.08),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book,
                          size: 32, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.manualTitle,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            l10n.manualIntro,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          ..._sections(),
        ],
      ),
    );
  }

  List<Widget> _sections() {
    return [
      _ManualSection(
        icon: Icons.celebration_outlined,
        title: 'Eerste vakantiehuis aanmaken',
        children: [
          _ManualParagraph(
            'Bij je eerste login start de welkomstwizard automatisch. '
            'Hij leidt je in 6 stappen door alle basisinstellingen voor '
            'je eerste woning. Heb je de wizard overgeslagen, dan kun je '
            'altijd handmatig een woning toevoegen via Accommodaties → +.',
          ),
          _ManualHeader('Met de wizard (aanbevolen)'),
          _ManualNumberedList([
            'Welkom — overzicht van wat je gaat instellen',
            'Basisgegevens — naam, type woning (huis, appartement, '
                'villa, cabin, studio), stad',
            'Capaciteit — maximaal aantal gasten, aantal slaapkamers '
                'en badkamers',
            'Wat heeft je woning? — vink zwembad of tuin aan zodat '
                'die modules verschijnen, idem voor schoonmaak en '
                'onderhoud bijhouden',
            'Tarieven — kies tussen één vast tarief of per seizoen, '
                'schoonmaakkosten inbegrepen of apart',
            'Seizoenen (alleen bij seizoenstarieven) — stel voor laag, '
                'midden en hoog seizoen de datums in',
          ]),
          _ManualParagraph(
            'Klik op "Woning aanmaken" om alles op te slaan. De app '
            'maakt automatisch je accommodatie aan en (bij seizoenen) '
            'de bijbehorende seizoens-records.',
          ),
          _ManualHeader('Handmatig zonder wizard'),
          _ManualParagraph(
            'Een extra woning toevoegen of de wizard overgeslagen?',
          ),
          _ManualNumberedList([
            'Tik op Accommodaties in de onderbalk',
            'Tik op +',
            'Vul de basisvelden in: naam, type, capaciteit',
            'Vul de prijzen in (mag ook later)',
            'Bewaar',
          ]),
          _ManualParagraph(
            'Seizoenen kun je later toevoegen via Instellingen → Seizoenen.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.book_outlined,
        title: 'Een boeking maken',
        children: [
          _ManualParagraph(
            'Boekingen worden automatisch berekend op basis van de '
            'seizoens-tarieven en schoonmaakkosten van de woning. Je '
            'kunt altijd handmatig bijsturen.',
          ),
          _ManualNumberedList([
            'Tik op Boekingen in de onderbalk, daarna op +',
            'Kies de woning uit de dropdown',
            'Kies een bestaande gast, of maak met + een nieuwe aan '
                '(alleen voornaam en e-mail zijn verplicht)',
            'Vul check-in en check-out datum in',
            'Het Prijsoverzicht verschijnt: aantal nachten per seizoen '
                'met tarief, plus schoonmaakkosten en subtotaal',
            'Geef eventueel een korting in — het totaalbedrag past '
                'zich automatisch aan',
            'Pas het totaalbedrag handmatig aan als je iets afwijkends '
                'wil',
            'Kies status (aanvraag, optie, bevestigd) en bron (direct, '
                'Airbnb, Booking, …)',
            'Bewaar',
          ]),
          _ManualHeader('Beschikbaarheid'),
          _ManualParagraph(
            'Tijdens het invoeren van datums controleert de app of de '
            'woning beschikbaar is. Bij een conflict zie je de '
            'overlappende boeking en eventueel alternatieve woningen.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.euro_outlined,
        title: 'Tarieven en seizoenen',
        children: [
          _ManualHeader('Eén vast tarief vs. per seizoen'),
          _ManualParagraph(
            'Eén vast tarief = hetzelfde bedrag per week het hele jaar '
            'door. Per seizoen = verschillende tarieven voor laag, '
            'midden en hoog seizoen.',
          ),
          _ManualHeader('Schoonmaak inbegrepen of apart'),
          _ManualParagraph(
            'Inbegrepen = de schoonmaak zit al in de weekprijs. '
            'Apart = je rekent een vast bedrag per boeking bovenop de '
            'weekprijs. De app slaat dat bedrag op als cleaning_fee en '
            'telt het automatisch op bij elke nieuwe boeking.',
          ),
          _ManualHeader('Meerdere periodes per seizoen'),
          _ManualParagraph(
            'Per seizoenstype (laag/midden/hoog) kun je meerdere '
            'periodes toevoegen via "+ Periode toevoegen". Voorbeeld: '
            'laag seizoen kan zowel jan-apr als okt-dec zijn.',
          ),
          _ManualHeader('Jaardekking'),
          _ManualParagraph(
            'Onder de seizoens-stap zie je een gekleurde balk die per '
            'dag laat zien welk seizoen er geldt:',
          ),
          _ManualBulletList([
            'Blauw = laag seizoen',
            'Geel = midden seizoen',
            'Rood = hoog seizoen',
            'Grijs = nog niet ingedeeld',
            'Paars = overlap (dag valt onder twee seizoenen)',
          ]),
          _ManualParagraph(
            'Bij gaten verschijnt een knop "Vul ontbrekende dagen op '
            'met laag seizoen" die alles in één klik dekkend maakt. '
            'Bij overlap zie je een waarschuwing — je kunt dan een van '
            'de periodes aanpassen.',
          ),
          _ManualHeader('Seizoenen aanpassen na onboarding'),
          _ManualParagraph(
            'Ga naar Instellingen → Seizoenen om bestaande periodes '
            'te wijzigen of nieuwe toe te voegen voor het volgende '
            'jaar.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.tune_outlined,
        title: 'Modules in- en uitschakelen',
        children: [
          _ManualParagraph(
            'Niet elke verhuurder gebruikt elke module. Verberg de '
            'modules die je niet nodig hebt zodat je onderbalk '
            'overzichtelijk blijft.',
          ),
          _ManualNumberedList([
            'Ga naar Instellingen',
            'Tik op Modules',
            'Schakel modules uit die je niet gebruikt: schoonmaak, '
                'onderhoud, zwembad, tuin, mailings, statistieken',
            'Uitgeschakelde modules verdwijnen direct uit de '
                'navigatie. Je data blijft bewaard',
          ]),
          _ManualParagraph(
            'Heeft je woning later wél een zwembad of tuin? Schakel '
            'de module weer aan met dezelfde knop. De tabs verschijnen '
            'meteen weer.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.calendar_month_outlined,
        title: 'Kalender en synchronisatie',
        children: [
          _ManualParagraph(
            'De kalender toont al je boekingen visueel per woning. '
            'Boekingen verschijnen als gekleurde balken: groen = '
            'volledig betaald, oranje = aanbetaald, rood = openstaand.',
          ),
          _ManualHeader('iCal koppeling'),
          _ManualParagraph(
            'Verhuur je ook via Airbnb, Booking.com, VRBO of een '
            'andere site? Per accommodatie kun je iCal-URLs invoeren. '
            'De app synchroniseert automatisch externe boekingen zodat '
            'je nooit dubbele boekingen krijgt.',
          ),
          _ManualParagraph(
            'iCal instellen: Accommodaties → kies woning → bewerken '
            '→ scroll naar "iCal-koppelingen".',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.cleaning_services_outlined,
        title: 'Schoonmaak en onderhoud',
        children: [
          _ManualParagraph(
            'Bij elke check-out genereert de app automatisch een '
            'schoonmaaktaak. Je vinkt hem af zodra de woning klaar is.',
          ),
          _ManualNumberedList([
            'Schoonmaak (onderbalk) toont de planning per dag',
            'Tik op een woning om de status te wijzigen: gepland, '
                'bezig, klaar',
            'Externe boekingen via iCal genereren ook automatisch '
                'schoonmaaktaken',
          ]),
          _ManualParagraph(
            'Onderhoudstaken (bv. lekkende kraan, kapotte tv) maak '
            'je handmatig aan via Onderhoud → +. Ze hebben prioriteit '
            'en status zodat je niets vergeet.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.help_outline,
        title: 'Hulp nodig?',
        children: [
          _ManualParagraph(
            'Loop je vast of zit je met een vraag die hier niet '
            'beantwoord wordt? Wij helpen graag.',
          ),
          _ManualBulletList([
            'E-mail: support@verhuuragenda.nl (binnen 24 uur reactie)',
            'Telefoon: +31 6 83710971',
            'Of via Instellingen → Hulp & Support',
          ]),
        ],
      ),
      const SizedBox(height: 32),
    ];
  }
}

class _ManualSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ManualSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ManualParagraph extends StatelessWidget {
  final String text;
  const _ManualParagraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
          height: 1.5,
        ),
      ),
    );
  }
}

class _ManualHeader extends StatelessWidget {
  final String text;
  const _ManualHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _ManualNumberedList extends StatelessWidget {
  final List<String> items;
  const _ManualNumberedList(this.items);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.key + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ManualBulletList extends StatelessWidget {
  final List<String> items;
  const _ManualBulletList(this.items);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((text) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
