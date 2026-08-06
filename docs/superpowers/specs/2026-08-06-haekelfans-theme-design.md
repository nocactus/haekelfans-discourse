# Häkelfans Theme voor Discourse — functioneel ontwerp

**Datum:** 2026-08-06
**Voor:** club.haekelfans.de (Discourse, laatste stable, eigen server)
**Vervangt:** FKB Pro theme + 9 losse theme-components + custom CSS
**Mockups:** https://claude.ai/code/artifact/5bfff779-c0a3-4863-b8a8-958826eed173

## 1. Doel en ontwerpprincipes

Eén eigen theme dat exact doet wat Häkelfans nodig heeft — niet meer en niet minder.

- **Radicale eenvoud.** De leden (Duitstalige haakliefhebbers, veelal niet technisch)
  krijgen alles wat ze nodig hebben en niets wat ze niet snappen. Elk standaard
  Discourse-element dat geen functie heeft voor deze community wordt niet verborgen
  met CSS-pleisters, maar bestaat in dit theme simpelweg niet.
- **Instagram/BuddyBoss-gevoel.** Het hart is een fotogerichte tijdlijn waarin álles
  inline gebeurt: lezen, liken, reageren, plaatsen.
- **Huisstijl Häkelfans.** Warme, lichte stijl van de bestaande sites. Alleen een
  licht kleurenschema; geen dark mode.
- **Alles Duits.** Alle teksten via vertaalbestanden (de + en-fallback), niets hardcoded.
- **Beheerbaar zonder code.** Header-links, footer-inhoud, widgets aan/uit e.d. zijn
  theme-instellingen.

## 2. Architectuur

Twee onderdelen met een strikte taakverdeling:

### 2.1 Theme `haekelfans-theme`
Alle presentatie en interactie: tijdlijn, kaarten, composer, berichtmodal, lightbox,
header, sidebars, widgets, footer, profielversimpeling, mobiele layout.

### 2.2 Plugin `haekelfans-timeline`
Alle data die core Discourse niet standaard levert. Consolideert en vervangt de twee
bestaande eigen plugins **Tlp grid images** en **Top replies**:

- Per topic in de lijst-serializer: afbeeldings-URLs (geoptimaliseerde thumbnails)
  van de first post, excerpt, de laatste reacties incl. nesting-structuur,
  reactie-samenvattingen (Reactions-data per post én per reply), en
  "geliket door"-namen ("Karin, Brenda und 3 anderen").
- Per-bericht vlag **"geen link-preview"** (custom field; onderdrukt onebox server-side).
- Endpoint voor **"Wer ist online"** (leden actief in de laatste 10 minuten).
- Automatische titel wanneer het lid geen titel invult (eerste ±8 woorden van de tekst).

### 2.3 Wat verdwijnt
FKB Pro, alle losse components (Add To Home Screen, Custom Header Links, Custom User
Menu, Easy Responsive Footer, HF aanpassingen, Navigation Menu Display Control,
TLP Grid Display, User Card Directory e.a.) en de volledige custom CSS. De functies
die ertoe doen (home-screen-meta, header-links, footer, profielkaart) gaan óp in het
theme; Tlp grid images en Top replies gaan óp in het plugin.

### 2.4 Wat blijft ongemoeid
OAuth2-login via Heppy, Reactions (Reaktionen), Poll (Umfrage), Automation,
Lazy videos, Rückblick, User notes, alle categorieën, tags en content.
Chat wordt later geïntroduceerd; de header reserveert er een plek voor
(theme-instelling `chat_icon_enabled`, standaard uit).

## 3. Stijl

| Token | Waarde | Gebruik |
|---|---|---|
| `--hf-accent` | `#ea4f86` | knoppen, titels, likes, actieve staat |
| `--hf-accent-soft` | `#f6e8ea` | badges, zachte vlakken |
| `--hf-bg` | `#faf7f5` | pagina-achtergrond |
| `--hf-card` | `#ffffff` | kaarten, header, widgets |
| `--hf-ink` | `#162c2d` | tekst |
| `--hf-muted` | `#808989` | secundaire tekst |
| `--hf-footer` | `#152b2c` | footer-achtergrond |

Systeemfontstack (zoals haekelfans.de), kaarten met afgeronde hoeken (16px) en
zachte schaduw. Avatars 30–38px. Alleen licht schema.

## 4. De tijdlijn (homepage)

- Homepage voor ingelogde leden; toont alle voor het lid zichtbare categorieën.
- **Sortering: puur chronologisch, nieuwste bericht eerst. Geen bumping** — een oud
  bericht met een nieuwe reactie blijft op zijn plek.
- Tabs boven de tijdlijn: **Aktuell** (standaard) · **Aktive Beiträge** (recente
  activiteit eerst) · **Neu (x)** · **Meine Beiträge**.
- Filterknoppen **Kategorien** en **Schlagwörter** (dropdowns).
- Infinite scroll, ±20 topics per lading; afbeeldingen lazy-loaded als thumbnails
  (nooit originelen in de tijdlijn).

### 4.1 Anatomie van een tijdlijnkaart
1. Kop: avatar, naam (→ profiel), tijdstip; categorie-badge rechtsboven.
2. Titel in accentkleur (automatisch gegenereerd als niet ingevuld).
3. Tekst: eerste ±300 tekens, daarna *weiterlesen* (klapt uit in de kaart).
4. Foto's: 1 foto volle breedte; 2–5 masonry-grid; >5 grid met **+N-overlay**.
   Klik → lightbox.
5. Tags als stille chips.
6. Sociale regel: hartje + "X und Y und N anderen" | "N Reaktionen".
7. Actiebalk: **Gefällt mir** (klik = hart; hover/lang indrukken = emojipalet van
   Reactions, set instelbaar in het plugin-admin) en **Reaktion** (focust reactieveld).
8. De **laatste 2 reacties** (aantal instelbaar via theme-instelling; nieuwste
   onderaan), elk met eigen like-hartje en
   "Antworten". Meer reacties → "**Alle X Reaktionen ansehen**" opent de berichtmodal.
9. Reactieveld "Schreib eine Reaktion…" met foto- en emoji-knop; altijd zichtbaar.

Reageren, liken en uitklappen gebeurt inline zonder navigatie of herlaad.

## 5. Berichtmodal en topic-weergave

- Opent via "Alle X Reaktionen ansehen" of klik op de titel.
- Zelfde kaartopbouw, maar met álle reacties: **genest tot maximaal 4 niveaus**,
  niveau ≥2 ingeklapt achter "N weitere Antworten ansehen".
- Eigen reactieveld onderin; antwoorden op een reactie kan per reactie ("Antworten").
- **Deeplinks** (notificaties, e-mail, gedeelde URL's naar `/t/…`): dezelfde weergave
  gerenderd als pagina met de tijdlijn eronder — geen aparte klassieke topic-pagina.
- Discourse-intern blijft alles een gewoon topic met vlakke posts +
  `reply_to_post_number`; de nesting is presentatie op basis van die data.

## 6. Inline composer

- Rust-stand bovenaan de tijdlijn: avatar + veld "Erzähl uns von deinem Projekt…"
  + camera-knop. Klik vouwt hem ter plekke open.
- Opengeklapt: optionele titel, tekstveld, foto-upload (slepen, plakken of knop) met
  thumbnails + verwijderknop, categorie-keuze (verplicht, standaard instelbaar,
  default Häkelstube), tags-keuze, emoji-knop.
- Schakelaar **"Link-Vorschau anzeigen"** (standaard aan): uit = links in dit bericht
  krijgen geen onebox/preview-kaart.
- **Veröffentlichen** plaatst zonder navigatie; het bericht verschijnt bovenaan de
  tijdlijn. Polls en geavanceerde opmaak blijven mogelijk via Markdown in het
  tekstveld; er is bewust géén tweede "geavanceerde composer".
- De knop "Neues Thema" in de filterbalk en de mobiele actieknop openen dezelfde composer.

## 7. Paginaopbouw

### 7.1 Header (sticky, wit)
Hamburger (mobiel: opent linkerkolom) · logo · brede zoekbalk (standaard
Discourse-zoek in eigen stijl) · navigatielinks (**theme-instelling**, start:
Häkelanleitungen, Blog, Mein Häkelfans, Impressum) · [gereserveerd: chat] ·
notificatiebel met teller · avatar met gebruikersmenu (Profil, Einstellungen,
Abmelden — meer niet).

### 7.2 Desktop: drie kolommen
- **Links:** persoonlijke links (Meine Beiträge, Meine Nachrichten; voor staf ook
  Überprüfen/Admin), daaronder Kategorien en Schlagwörter.
- **Midden:** filterbalk, composer, tijdlijn.
- **Rechts (widgets, elk aan/uit via theme-instelling):**
  - **Profielkaart:** avatar, naam, @gebruikersnaam, ♥ erhalten/gegeben,
    Themen/Beiträge, vier snelkoppelingen (profiel, instellingen, bladwijzers, berichten).
  - **Wer ist online:** avatarrij + "N Mitglieder jetzt online".

### 7.3 Mobiel (≤ tablet)
Eén kolom, app-gevoel: compacte header, horizontaal scrollende filterchips,
tijdlijn, roze **actieknop rechtsonder** voor een nieuw bericht. Linkerkolom achter
de hamburger; widgets vervallen. Geoptimaliseerd als PWA (manifest/meta zodat
Add-to-Home-Screen blijft werken zoals nu). Geen Discourse Hub.

### 7.4 Footer
Donker (`#152b2c`), inhoud via theme-instellingen (kolommen met links + social-
iconen). Start: Service (Impressum, AGB, Datenschutz, Nutzungsbedingungen,
Lizenzbedingungen) en Häkelanleitungen (Häkelanleitungen, Meine Favoriten) +
Instagram/Facebook.

## 8. Profiel — radicaal versimpeld

- **Drie tabs:** Aktivität (eigen berichten als mini-tijdlijn) · Nachrichten ·
  Einstellungen.
- **Einstellungen, één scherm:** profielfoto, naam, e-mail (alleen-lezen, beheerd
  door Heppy), titel/flair (indien beschikbaar), notificatie-schakelaars
  (e-mail bij reacties, wekelijkse samenvatting).
- Bestaat niet in dit theme (structureel, niet verborgen): trust levels, badges,
  data-export, gekoppelde accounts, tracking-voorkeuren, categorieën/gebruikers
  dempen, samenvattingen, drafts-overzicht, "Andere"-instellingen, statistieken-
  secties, kalender-abonnementen.
- Profielen van anderen: avatar, naam, flair, "Mitglied seit", Aktivität-tab.

## 9. Datastromen (plugin-API)

- **Tijdlijn:** core `latest.json`-flow met serializer-uitbreidingen van het plugin
  (afbeeldingen, excerpt, reply-preview-boom, reacties, likers). Geen eigen
  parallelle lijst-endpoint.
- **Reageren:** core `POST /posts` (met `reply_to_post_number` voor nesting);
  respons wordt inline in de kaart/modal gerenderd.
- **Likes/reacties:** endpoints van het Reactions-plugin, ook voor replies.
- **Volledige reply-boom:** `GET /haekelfans/topic/:id/tree.json` (plugin) levert de
  boom (max 4 niveaus) incl. reactie-data, gepagineerd bij zeer grote gesprekken.
- **Wer ist online:** `GET /haekelfans/online.json`, gecachet (±1 min).
- **Geen link-preview:** custom field op post; plugin onderdrukt onebox bij het
  cooken wanneer de vlag gezet is.

## 10. Foutafhandeling

- Mislukt plaatsen/reageren (netwerk, validatie): melding in de kaart/composer in
  begrijpelijk Duits, invoer blijft behouden, opnieuw proberen mogelijk.
- Composer-concepten gebruiken Discourse-drafts: onbedoeld sluiten = niets kwijt.
- Verwijderde/onzichtbare topics in een openstaande tijdlijn: kaart toont
  "Dieser Beitrag ist nicht mehr verfügbar" bij interactie.
- Rate-limits van core blijven gelden; melding met wachttijd.

## 11. Prestaties

- Thumbnails via Discourse' optimized images; lightbox laadt pas vol formaat.
- Reply-previews (laatste 2) zitten al in de lijst-payload — geen N+1-verzoeken.
- Infinite scroll met intersection observer; DOM van ver gescrolde kaarten wordt
  gevirtualiseerd/opgeruimd bij lange sessies.
- Plugin-serializers gebruiken bestaande queries met includes; "Wer ist online" en
  titelgeneratie zijn gecachet respectievelijk eenmalig.

## 12. Testen

- **Plugin:** RSpec voor serializers (afbeeldingen, boomstructuur, reactie-data),
  onebox-onderdrukking, online-endpoint, titelgeneratie.
- **Theme:** QUnit-tests voor kerncomponenten (kaart, composer, modal-gedrag);
  handmatige checklist per release op desktop + mobiel (echte telefoon, PWA).
- **Acceptatie:** het bestaande DE-forum met echte content in een testomgeving;
  het theme kan naast FKB Pro geïnstalleerd en via theme-preview (`?preview_theme_id`)
  beoordeeld worden vóór de omschakeling.

## 13. Uitrol

1. Plugin installeren (vervangt Tlp grid images + Top replies; die twee uit).
2. Theme installeren als niet-standaard theme; beoordelen via preview met het team.
3. Omschakelen als standaard theme; FKB Pro + components gearchiveerd laten staan
   tot het nieuwe theme een paar weken stabiel draait, daarna opruimen.

## 14. Buiten scope

- Chat (komt later; alleen de gereserveerde header-plek zit in v1)
- Dark mode
- Discourse Hub-app
- Wijzigingen aan Heppy/OAuth, categorieën of content
- Verjaardagen-widget e.d. (kan later als extra widget)
