# Status: hf-discourse-theme

Status: actief
Bijgewerkt: 2026-11-25
Volgende stap: acceptance-tests van v1.6.4 t/m v1.7.1 draaien in de dev-checkout (Docker)

<!--
Status-waarden: actief | geparkeerd | afgerond
De drie regels hierboven worden door dev-overzicht.sh uitgelezen. Houd het formaat precies zo aan.
-->

## Waar staat het

- Theme v1.7.2 staat live op club.haekelfans.de (deploy-repo nocactus/haekelfans-theme op `f3b85f2`, "Controleren op updates" gedaan).
- Plugin ongewijzigd sinds 1.1.1.
- Avatar en naam van de schrijver (tijdlijnkaart, topicweergave, berichtmodal, reacties) zijn links naar `/u/{gebruikersnaam}` met `data-user-card`: een klik opent de gebruikerskaart van Discourse, Cmd/Ctrl-klik het profiel in een nieuw tabblad.
- Emoji in de tekst van tijdlijnkaarten worden als afbeelding getoond (core `escapedExcerpt`).
- Titel en tekstveld van de composer (nieuw bericht op de tijdlijn) lopen over de volle breedte; het tekstveld is minimaal 8em hoog.
- Topics die via een directe link in de geneste weergave van Discourse openen, tonen alleen onze kaart; de rest van `.nested-view` is via CSS verborgen.

## Open beslissingen

- 

## Risico's en aandachtspunten

- Acceptance-tests voor v1.6.4 t/m v1.7.1 zijn geschreven maar nog niet gedraaid: op de MacBook staat geen Docker (de Docker.app-link is dood), dus de dev-checkout draait hier niet.
- De verberg-regel in `topic.scss` hangt af van de DOM-structuur van Discourse' geneste weergave: onze Glimmer-connector staat als `div.hf-topic-view` direct onder `.nested-view`, zonder wrapper. Na een Discourse-upgrade even controleren of de kaart nog zichtbaar is.
- Discourse core geeft `input[type="text"]` en `textarea` een vaste breedte (specificiteit 0,1,1). Eigen regels voor invoervelden hebben daarom minstens twee classes nodig (zie `.hf-composer__form .hf-composer__title` in `timeline.scss`).
- De gebruikerskaart staat in een float-kit-menu (`.fk-d-menu[data-identifier="usercard"]`, z-index 701 op desktop). `timeline.scss` hoogt dat op naar 9150 zolang de berichtmodal open is (alleen `desktop-view`). Na een Discourse-upgrade even controleren of de kaart in de modal nog bovenop staat.

## Log

<!-- Nieuwste bovenaan, één regel per sessie. -->
- 2026-11-25: v1.7.2 (PR #23): titel en tekstveld van de composer waren een smal blokje links (vaste breedte uit Discourse core); nu volle breedte. Live; gecontroleerd in Chrome (desktop en smal venster) en op een telefoon. Alleen CSS, geen acceptance-test.
- 2026-11-23: v1.7.0 (PR #20): avatar en naam openen de gebruikerskaart. In de berichtmodal viel de kaart erachter; opgelost in v1.7.1 (PR #21). Beide live; gecontroleerd in Chrome (desktop en smal venster) en op een telefoon, geen problemen.
- 2026-11-19: v1.6.4 (PR #18): emoji-shortcodes in kaarttekst als afbeelding + bericht niet meer dubbel bij directe link (geneste weergave). Regressie (eigen kaart ook verborgen) opgelost in v1.6.5 (PR #19). Beide live en in de browser gecontroleerd.
- 2026-11-18: STATUS.md aangemaakt (status automatisch: laatste activiteit 1 dagen geleden)
