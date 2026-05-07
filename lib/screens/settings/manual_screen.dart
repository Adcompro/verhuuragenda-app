import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// In-app handleiding (Dutch-only voor v1). Voor beginners: legt
/// stap-voor-stap uit hoe CasaMio werkt — van eerste woning tot
/// boeking en exporteren.
///
/// Bereikbaar via Instellingen → Handleiding. Bij een eerste
/// installatie wordt de handleiding ook automatisch getoond direct
/// na de welkomstwizard.
class ManualScreen extends StatelessWidget {
  /// Of de handleiding wordt getoond als onderdeel van de
  /// onboarding-flow. In die modus krijgt de gebruiker een grote
  /// "Klaar, ga naar dashboard"-knop onderaan.
  final bool firstLaunch;

  const ManualScreen({super.key, this.firstLaunch = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manualTitle),
        // In first-launch mode there's no back arrow — the user
        // exits via the "Klaar" button at the bottom.
        automaticallyImplyLeading: !firstLaunch,
      ),
      body: ListView(
        children: [
          _Hero(firstLaunch: firstLaunch),
          ..._sections(context, l10n),
          if (firstLaunch) _DoneCta(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _sections(BuildContext context, AppLocalizations l10n) {
    return [
      _ManualSection(
        icon: Icons.flag_outlined,
        title: 'Welkom bij CasaMio',
        initiallyExpanded: true,
        children: [
          _ManualParagraph(
            'CasaMio helpt je om je vakantieverhuur vanuit één app te '
            'beheren — boekingen, kalender, gasten, schoonmaak, '
            'tarieven en meer. Hieronder leggen we kort uit hoe je '
            'aan de slag gaat.',
          ),
          _ManualParagraph(
            'Tip: deze handleiding vind je later altijd terug via '
            'Instellingen → Handleiding. Geen zorgen dus — je hoeft '
            'het niet allemaal in één keer te onthouden.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.checklist_outlined,
        title: 'Eerste keer? Doe dit eerst',
        initiallyExpanded: true,
        children: [
          _ManualNumberedList([
            'Doorloop de welkomstwizard die automatisch start. Hij '
                'helpt je in 6 korte stappen je eerste vakantiehuis '
                'aan te maken.',
            'Vink in stap 4 aan welke modules je gebruikt — bv. '
                '"Mijn woning heeft een zwembad" of "Ik wil schoonmaak '
                'bijhouden". Modules die je niet aanvinkt blijven '
                'verborgen.',
            'Stel in stap 5 je tarieven in: één vast tarief per week, '
                'óf verschillende prijzen voor laag, midden en hoog '
                'seizoen. Schoonmaak kan inbegrepen zijn of apart '
                'berekend worden.',
            'Bij seizoenstarieven kies je in stap 6 wanneer welk '
                'seizoen geldt. Met de gekleurde jaarbalk zie je in '
                'één oogopslag of het hele jaar gedekt is.',
            'Klik "Woning aanmaken" — de app maakt alles voor je aan.',
          ]),
          _ManualParagraph(
            'Was je niet klaar tijdens de wizard? Tik op "Misschien '
            'later". Je kan altijd later starten via Accommodaties → +.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.home_work_outlined,
        title: 'Een vakantiehuis aanmaken',
        children: [
          _ManualHeader('Met de wizard (aanbevolen voor beginners)'),
          _ManualParagraph(
            'Accommodaties → tik op + → kies "Met de wizard". Dezelfde '
            '6 stappen als bij eerste install, ook voor een 2e of 3e '
            'woning.',
          ),
          _ManualHeader('Handmatig (sneller voor ervaren gebruikers)'),
          _ManualParagraph(
            'Accommodaties → + → kies "Handmatig invullen". Je krijgt '
            'het volledige formulier met alle velden ineens. Prijzen '
            'mag je leeg laten en later aanvullen — de boekings-'
            'totaalberekening werkt pas zodra je tarieven hebt.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.book_outlined,
        title: 'Een boeking maken',
        children: [
          _ManualParagraph(
            'CasaMio rekent het totaalbedrag automatisch voor je uit '
            'op basis van je tarieven en de schoonmaakkosten. Je hoeft '
            'alleen de hoofdgegevens in te vullen.',
          ),
          _ManualNumberedList([
            'Tik op Boekingen → +',
            'Kies de woning',
            'Kies een bestaande gast — of maak met + een nieuwe aan '
                '(alleen voornaam en e-mail zijn verplicht)',
            'Kies check-in en check-out datum. Het Prijsoverzicht '
                'verschijnt automatisch met aantal nachten per seizoen, '
                'tarief per nacht, schoonmaak en subtotaal',
            'Vul eventueel een Korting in — het Totaalbedrag past '
                'zich live aan',
            'Kies status (aanvraag, optie, bevestigd) en bron (direct, '
                'Airbnb, Booking, …)',
            'Bewaar — je nieuwe boeking staat nu in de kalender',
          ]),
          _ManualHeader('Beschikbaarheid'),
          _ManualParagraph(
            'Tijdens het invoeren controleert de app of de woning vrij '
            'is. Bij een conflict zie je de overlappende boeking en '
            'eventueel alternatieve woningen voor diezelfde periode.',
          ),
          _ManualParagraph(
            'Tip: dezelfde dag check-out + check-in is toegestaan. '
            'Vakantieganger A vertrekt 10:00, B komt 15:00 — gewoon '
            'doorboeken op dezelfde datum.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.euro_outlined,
        title: 'Tarieven en seizoenen',
        children: [
          _ManualHeader('Vast tarief vs. seizoenstarief'),
          _ManualParagraph(
            '• Vast tarief: hetzelfde bedrag per week, het hele jaar\n'
            '• Per seizoen: verschillende tarieven voor laag, midden '
            'en hoog seizoen',
          ),
          _ManualHeader('Schoonmaak inbegrepen of apart'),
          _ManualParagraph(
            '• Inbegrepen = de schoonmaak zit in de weekprijs\n'
            '• Apart = vast bedrag per boeking bovenop de weekprijs '
            '(de app telt het automatisch op)',
          ),
          _ManualHeader('Meerdere periodes per seizoen'),
          _ManualParagraph(
            'Per seizoenstype (laag/midden/hoog) kun je meerdere '
            'periodes toevoegen — bv. laag = jan-apr én okt-dec. Tik '
            'op "+ Periode toevoegen" in de seizoenen-stap.',
          ),
          _ManualHeader('Jaardekking'),
          _ManualParagraph(
            'Onder de seizoenen-stap toont een gekleurde balk per dag '
            'welk seizoen er geldt. Blauw = laag, geel = midden, rood '
            '= hoog, grijs = niet gedekt, paars = overlap.',
          ),
          _ManualParagraph(
            'Bij gaten verschijnt een knop "Vul ontbrekende dagen op '
            'met laag seizoen" — dat dekt het hele jaar in één klik.',
          ),
          _ManualHeader('Seizoenen later aanpassen'),
          _ManualParagraph(
            'Ga naar Instellingen → Seizoenen voor wijzigingen of om '
            'volgend jaar te plannen.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.pool_outlined,
        title: 'Zwembad en tuin per woning',
        children: [
          _ManualParagraph(
            'Niet elke woning heeft een zwembad of tuin. CasaMio houdt '
            'dit per woning bij. De zwembad- en tuin-tab in de '
            'onderbalk verschijnen automatisch zodra ten minste één '
            'van je woningen het aanvinkt heeft.',
          ),
          _ManualHeader('Bij een nieuwe woning'),
          _ManualParagraph(
            'In de wizard (stap 4) of in het edit-formulier vink je '
            '"Mijn woning heeft een zwembad/tuin" aan.',
          ),
          _ManualHeader('Bij een bestaande woning'),
          _ManualParagraph(
            'Accommodaties → woning → Bewerken → schakelaars '
            'aan- of uitzetten → Bewaar. Je data blijft altijd '
            'bewaard, ook als je tijdelijk uitzet.',
          ),
          _ManualHeader('Gedeeld zwembad of tuin'),
          _ManualParagraph(
            'Hebben twee of meer woningen hetzelfde zwembad of '
            'dezelfde tuin? Schakel "heeft zwembad" aan op de eerste '
            'woning ("eigenaar"), bewaar. Bij volgende woningen '
            'verschijnt automatisch een "Wordt het zwembad gedeeld?"-'
            'dropdown — kies de eigenaar. Schoonmaak en metingen '
            'worden eenmalig op de eigenaar bijgehouden, niet dubbel.',
          ),
          _ManualParagraph(
            'Tip: geef de eigenaar een herkenbare naam in het veld '
            '"Naam van het zwembad" (bv. "Hoofdpool Resort"). Die '
            'naam zie je terug in de Zwembad-tab in plaats van de '
            'losse woningnamen.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.cleaning_services_outlined,
        title: 'Schoonmaak en onderhoud',
        children: [
          _ManualHeader('Automatische schoonmaak na check-out'),
          _ManualParagraph(
            'Bij elke check-out genereert CasaMio automatisch een '
            'schoonmaaktaak. Tik om af te vinken zodra de woning '
            'klaar is. Externe boekingen via iCal genereren ook '
            'taken.',
          ),
          _ManualHeader('Handmatige schoonmaak toevoegen'),
          _ManualParagraph(
            'Voor tussentijds schoonmaken of een grote voorjaarsbeurt: '
            'Schoonmaak → tik op de + knop → kies woning, datum en '
            'optionele beschrijving. Verschijnt op de juiste dag tussen '
            'de booking-gegenereerde taken.',
          ),
          _ManualHeader('Onderhoudstaken'),
          _ManualParagraph(
            'Voor een lekkende kraan, kapotte tv of jaarlijkse keuring: '
            'Onderhoud → +. Geef een titel, prioriteit en optionele '
            'foto. Status (open / bezig / klaar) houdt je werk-flow '
            'overzichtelijk.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.calendar_month_outlined,
        title: 'Kalender en iCal-koppeling',
        children: [
          _ManualParagraph(
            'De Kalender toont al je boekingen visueel per woning. '
            'Boekingen verschijnen als gekleurde balken: groen = '
            'volledig betaald, oranje = aanbetaald, rood = openstaand, '
            'roze = Airbnb, blauw = Booking.com.',
          ),
          _ManualHeader('iCal koppelen'),
          _ManualParagraph(
            'Verhuur je ook via Airbnb, Booking.com of een andere '
            'site? Per accommodatie kun je iCal-URLs invoeren. '
            'CasaMio synchroniseert automatisch externe boekingen — '
            'zo voorkom je dubbele boekingen.',
          ),
          _ManualParagraph(
            'iCal instellen: Accommodaties → woning → Bewerken → '
            'scroll naar "iCal-koppelingen" → plak de URL.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.table_chart_outlined,
        title: 'Verhuuropbrengsten exporteren',
        children: [
          _ManualParagraph(
            'Voor de boekhouder of een eigen jaaroverzicht kun je een '
            'Excel-bestand downloaden met alle boekingen van het '
            'lopende jaar.',
          ),
          _ManualNumberedList([
            'Ga naar Instellingen → Verhuuropbrengsten exporteren',
            'CasaMio bouwt het bestand en opent het iOS share-sheet',
            'Kies waar het bestand heen moet: Files, Mail, AirDrop, '
                'Numbers',
          ]),
          _ManualParagraph(
            'Het bestand bevat: Datum, Naam huurder, Accommodatie, '
            'Status, Opbrengst, Betaald, Openstaand — plus een '
            'TOTAAL-rij onderaan.',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.tune_outlined,
        title: 'Modules in- en uitschakelen',
        children: [
          _ManualParagraph(
            'Voor de overige modules (schoonmaak, onderhoud, mailings, '
            'statistieken) bepaal je centraal of je ze wilt zien. '
            'Verberg wat je niet gebruikt — de onderbalk wordt '
            'meteen overzichtelijker.',
          ),
          _ManualNumberedList([
            'Instellingen → Modules',
            'Schakelaars aan of uit',
            'Uitgeschakelde modules verdwijnen direct uit de '
                'navigatie. Je data blijft bewaard.',
          ]),
          _ManualParagraph(
            'Zwembad en tuin staan hier niet meer bij — die regel je '
            'per woning (zie eerder hoofdstuk).',
          ),
        ],
      ),
      _ManualSection(
        icon: Icons.help_outline,
        title: 'Hulp nodig?',
        children: [
          _ManualBulletList([
            'E-mail: support@casamio.app — binnen 24 uur reactie',
            'Of via Instellingen → Hulp & Support',
          ]),
          _ManualParagraph(
            'Geef bij een bugmelding zo veel mogelijk informatie: '
            'welk scherm, welke knop, welke foutmelding. Een '
            'screenshot helpt enorm.',
          ),
        ],
      ),
    ];
  }
}

class _Hero extends StatelessWidget {
  final bool firstLaunch;
  const _Hero({required this.firstLaunch});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book,
                size: 28, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstLaunch
                      ? 'Welkom bij ${l10n.appName}'
                      : l10n.manualTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  firstLaunch
                      ? 'Lees deze korte handleiding even door — je weet daarna precies hoe alles werkt.'
                      : l10n.manualIntro,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.manualDoneButton),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.manualFindHereLater,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ManualSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _ManualSection({
    required this.icon,
    required this.title,
    this.initiallyExpanded = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
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
