# Status: hf-discourse-theme

Status: actief
Bijgewerkt: 2026-11-19
Volgende stap: acceptance-tests van v1.6.4/v1.6.5 draaien in de dev-checkout (Docker)

<!--
Status-waarden: actief | geparkeerd | afgerond
De drie regels hierboven worden door dev-overzicht.sh uitgelezen. Houd het formaat precies zo aan.
-->

## Waar staat het

- Theme v1.6.5 staat live op club.haekelfans.de (deploy-repo nocactus/haekelfans-theme bijgewerkt, "Controleren op updates" gedaan).
- Plugin ongewijzigd sinds 1.1.1.
- Emoji in de tekst van tijdlijnkaarten worden als afbeelding getoond (core `escapedExcerpt`).
- Topics die via een directe link in de geneste weergave van Discourse openen, tonen alleen onze kaart; de rest van `.nested-view` is via CSS verborgen.

## Open beslissingen

- 

## Risico's en aandachtspunten

- Acceptance-tests voor de fixes van 2026-11-19 zijn geschreven maar nog niet gedraaid: op de MacBook staat geen Docker (de Docker.app-link is dood), dus de dev-checkout draait hier niet.
- De verberg-regel in `topic.scss` hangt af van de DOM-structuur van Discourse' geneste weergave: onze Glimmer-connector staat als `div.hf-topic-view` direct onder `.nested-view`, zonder wrapper. Na een Discourse-upgrade even controleren of de kaart nog zichtbaar is.

## Log

<!-- Nieuwste bovenaan, één regel per sessie. -->
- 2026-11-19: v1.6.4 (PR #18): emoji-shortcodes in kaarttekst als afbeelding + bericht niet meer dubbel bij directe link (geneste weergave). Regressie (eigen kaart ook verborgen) opgelost in v1.6.5 (PR #19). Beide live en in de browser gecontroleerd.
- 2026-11-18: STATUS.md aangemaakt (status automatisch: laatste activiteit 1 dagen geleden)
