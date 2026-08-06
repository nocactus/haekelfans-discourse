# haekelfans-timeline

Discourse-plugin dat de datalaag levert voor het **Häkelfans theme** op
club.haekelfans.de. Consolideert en vervangt de eerdere plugins
**Tlp grid images** en **Top replies**.

## Wat het levert

Serializer-velden op elk topic in topiclijsten (`latest.json` e.d.):

| Veld | Inhoud |
|---|---|
| `hf_images` | `[{ url, thumb_url, width, height }]` van de first post, max `haekelfans_timeline_max_images` |
| `hf_replies` | laatste N zichtbare replies (oudste eerst): `{ post_id, post_number, reply_to_post_number, username, name, avatar_template, excerpt, created_at, like_count, current_user_reacted }` |
| `hf_reply_total` | totaal aantal zichtbare replies |
| `hf_likers` | `{ names: [max 2], count, current_user_liked }` van de first post |
| `hf_first_post_id` | post-id van post_number 1 (voor like/reactie-toggles) |

Endpoints:

| Endpoint | Inhoud |
|---|---|
| `GET /haekelfans/topic/:id/tree.json?page=0` | reply-boom, genest tot **max 4 niveaus** (dieper wordt platgeslagen), top-level gepagineerd per 50; guardian-gecontroleerd |
| `GET /haekelfans/online.json` | `{ count, users: [max 30] }` — leden gezien in de laatste 10 min, 60 s gecachet; alleen ingelogd |

Post-parameter:

- `hf_no_onebox: "true"` bij `POST /posts` → custom field op de post; bij het
  cooken worden `aside.onebox`-elementen vervangen door platte links en
  verliezen inline-oneboxes hun styling.

## Site settings

| Setting | Default | |
|---|---|---|
| `haekelfans_timeline_enabled` | `true` | hoofdschakelaar; uit = geen extra velden |
| `haekelfans_timeline_max_images` | `10` | max afbeeldingen per bericht in de lijst |
| `haekelfans_timeline_reply_preview_count` | `3` | reply-previews per topic in de lijst-payload |

## Installatie (productie, /var/discourse)

In `containers/app.yml` onder `hooks: after_code`:

```yaml
- git clone https://github.com/gekophaken/haekelfans-timeline.git
```

Daarna `./launcher rebuild app`.

## Migratie vanaf Tlp grid images / Top replies

1. Dit plugin installeren en rebuilden.
2. **Tlp grid images** en **Top replies** uitschakelen (admin › plugins) en uit
   `app.yml` verwijderen bij de volgende rebuild. Beide waren read-only
   caches/serializers; er hoeft geen data gemigreerd te worden.

## Wisselwerking met Reactions (Reaktionen)

Like-tellers en `current_user_reacted` lopen via core `PostAction` (type
like). Het Reactions-plugin synchroniseert emoji-reacties daarheen, dus de
tellers kloppen met én zonder Reactions. Emoji-details per reactie haalt het
theme rechtstreeks bij Reactions op.

## Ontwikkeling

Broncode leeft in de projectrepo (map `plugin/haekelfans-timeline`); sync naar
een lokale Discourse dev-checkout met `bin/sync-plugin.sh`. Tests:

```bash
docker exec -u discourse:discourse -w /src -e RAILS_ENV=test -e LOAD_PLUGINS=1 \
  discourse_dev bundle exec rspec plugins/haekelfans-timeline/spec -f doc
```
