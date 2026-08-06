# Häkelfans Theme

Volledig eigen Discourse-theme voor club.haekelfans.de: Instagram-achtige
tijdlijn als homepage, inline composer, berichtmodal met geneste reacties
(max 4 niveaus), lightbox, widgets, versimpeld profiel en eigen
header/footer. Vervangt FKB Pro + alle losse theme-components.

## Vereisten

1. **haekelfans-timeline plugin** geïnstalleerd en actief (levert de
   `hf_*`-serializervelden en endpoints; zie de plugin-README).
2. Site setting **`search_experience: search_field`** (brede zoekbalk in
   de header).
3. Site setting **`always_include_topic_excerpts: true`** (tekstfragment
   op elke tijdlijnkaart).
4. **Reactions (Reaktionen)** actief, met hart als eerste emoji in
   `discourse_reactions_enabled_reactions` — de like-knop gebruikt
   `heart`, met automatische fallback naar core-likes.
5. Kleurenschema "Häkelfans Licht" (wordt bij installatie meegeleverd
   via about.json) als actief schema instellen.

## Installatie

Admin › Aanpassen › Thema's › Installeren › *Uit een git-repository*:
deze repo-URL. Daarna: thema als standaard instellen en de oude
componenten uitschakelen (zie hieronder).

## Uit te schakelen na omschakeling

FKB Pro theme en de 9 losse componenten: Add To Home Screen, Custom
Header Links, Custom User Menu, Easy Responsive Footer, HF aanpassingen,
Navigation Menu Display Control, TLP Grid Display, User Card Directory,
discourse-left-side-burger — plus de volledige oude custom CSS. Ook de
plugins *Tlp grid images* en *Top replies* gaan uit (vervangen door
haekelfans-timeline).

## Theme-instellingen

| Instelling | Doel |
|---|---|
| `header_links` | navigatielinks in de header ("Label,URL" per regel) |
| `chat_icon_enabled` | chat-icoon tonen zodra chat wordt geïntroduceerd |
| `replies_shown` | aantal zichtbare reacties per kaart (default 2) |
| `show_profile_card` / `show_online_widget` | widgets rechterkolom |
| `excerpt_length` | tekstlengte vóór "weiterlesen" |
| `default_category_id` | standaardcategorie composer (0 = eerste) |
| `footer_links_service` / `footer_links_anleitungen` | footer-kolommen |
| `footer_social_instagram` / `footer_social_facebook` | social-iconen |

## Beoordelen vóór omschakeling (preview)

Installeer het theme zonder het standaard te maken en deel met het team:
`https://club.haekelfans.de/?preview_theme_id=<id>` (id staat in de
adminlijst). Rollback = standaardtheme terugzetten op FKB Pro; er wordt
niets destructiefs gewijzigd.

## Ontwikkeling

Broncode leeft in de projectrepo (map `theme/haekelfans-theme`). Sync +
import naar de lokale dev-checkout: `bin/sync-theme.sh`. Tests:

```bash
docker exec -u discourse:discourse -w /src -e LOAD_PLUGINS=1 \
  -e DISCOURSE_DISABLE_BROWSER_SANDBOX=1 discourse_dev \
  bundle exec rake "themes:qunit[name,Häkelfans]"
```

Let op: stop `bin/dev` vóór een QUnit-run (zelfde ember-build).

## Handmatige release-checklist

Desktop + telefoon (PWA): tijdlijn scrollen/filteren/tabs, bericht
plaatsen mét foto's en mét/zonder link-preview, reageren op 4 niveaus,
bericht én reactie liken, lightbox (pijltjes/swipe/Esc), deeplink uit
e-mailnotificatie, profiel (alleen versimpelde items zichtbaar),
footer-links, "Wer ist online", uitgelogde staat (Heppy-login-redirect).
