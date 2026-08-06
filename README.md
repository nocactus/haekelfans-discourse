# Häkelfans Discourse — monorepo

Bron van waarheid voor het Häkelfans-theme en het bijbehorende plugin
voor club.haekelfans.de. Ontwikkeling en review gebeuren hier;
Discourse installeert vanuit de twee **deploy-repos** (subtree-splits
van deze repo):

| Deploy-repo | Inhoud | Installatie |
|---|---|---|
| [nocactus/haekelfans-theme](https://github.com/nocactus/haekelfans-theme) | `theme/haekelfans-theme` | Admin › Aanpassen › Thema's › Installeren › git-URL |
| [nocactus/haekelfans-timeline](https://github.com/nocactus/haekelfans-timeline) | `plugin/haekelfans-timeline` | `app.yml` › hooks › after_code › git clone |

## Wijzigingen uitrollen

Na een merge in `main` de deploy-repos bijwerken:

```bash
git subtree push --prefix=theme/haekelfans-theme https://github.com/nocactus/haekelfans-theme.git main
git subtree push --prefix=plugin/haekelfans-timeline https://github.com/nocactus/haekelfans-timeline.git main
```

Daarna in Discourse: theme "Controleren op updates", plugin via
`./launcher rebuild app`.

## Structuur

- `docs/superpowers/specs/` — functioneel ontwerp
- `docs/superpowers/plans/` — implementatieplannen
- `theme/haekelfans-theme/` — het theme (zie README aldaar)
- `plugin/haekelfans-timeline/` — het plugin (zie README aldaar)
- `bin/sync-theme.sh` / `bin/sync-plugin.sh` — sync naar de lokale
  Discourse dev-checkout (`~/Developer/discourse-dev`, Docker/Colima)
