# Häkelfans Theme — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Volledig eigen Discourse-theme met Instagram-achtige tijdlijn als homepage, inline composer, berichtmodal met geneste reacties, lightbox, widgets, versimpeld profiel en eigen header/footer — ter vervanging van FKB Pro + 9 components + custom CSS.

**Architecture:** Glimmer-componenten (.gjs) in een theme, dat de discovery-route hergebruikt: de tijdlijn vervangt de topiclijst via de wrapper-outlet `discovery-list-area`, zodat core het laden/pagineren van topics blijft doen. Alle data komt uit core-endpoints plus de `hf_*`-velden en endpoints van het **haekelfans-timeline plugin** (zie dat plan; moet eerst af).

**Tech Stack:** Discourse theme (laatste stable), Ember/Glimmer .gjs, SCSS, `discourse_theme` CLI (live sync), Theme-QUnit op `/theme-qunit`.

## Global Constraints

- Alle ledenteksten Duits via `locales/de.yml` (met `en.yml` fallback); geen hardcoded strings in componenten.
- Alleen licht kleurenschema. Tokens exact: accent `#ea4f86`, accent-soft `#f6e8ea`, achtergrond `#faf7f5`, kaart `#ffffff`, tekst `#162c2d`, gedempt `#808989`, footer `#152b2c`.
- Kaarten: border-radius 16px, zachte schaduw; avatars 30–38px; systeemfontstack.
- Component-prefix `Hf`; SCSS-classprefix `hf-`; theme-settings in `settings.yml` zoals hieronder gedefinieerd.
- Tijdlijn standaard **chronologisch zonder bumping** (`/latest?order=created`).
- Mockups zijn de visuele referentie: `docs/…/2026-08-06`-artifact (zie spec §kop). Spec: `docs/superpowers/specs/2026-08-06-haekelfans-theme-design.md`.
- Dev-loop: `discourse_theme watch .` tegen de lokale dev-site; na elke taak handmatige controle in de browser hoort bij de stappen.
- Het plugin-plan levert: `hf_images`, `hf_replies`, `hf_reply_total`, `hf_likers` op elk topic-list-item; `GET /haekelfans/topic/:id/tree.json`; `GET /haekelfans/online.json`; post-param `hf_no_onebox`.

## File Structure

```
haekelfans-theme/
├── about.json
├── settings.yml
├── locales/{de.yml,en.yml}
├── common/
│   ├── common.scss              # tokens + basis
│   ├── header.scss
│   ├── timeline.scss            # kaart, masonry, comments, composer
│   ├── profile.scss             # profielversimpeling (verwijderlijst)
│   └── mobile.scss
├── javascripts/discourse/
│   ├── api-initializers/hf-theme.gjs          # setup, route-redirects, outlets
│   ├── connectors/discovery-list-area/hf-timeline-outlet.gjs
│   ├── connectors/topic-above-post-stream/hf-topic-view.gjs
│   ├── connectors/below-footer/hf-footer.gjs
│   └── components/hf/
│       ├── timeline.gjs         # kolommenlayout + filterbalk + lijst
│       ├── post-card.gjs        # de tijdlijnkaart
│       ├── gallery.gjs          # 1 foto / masonry / +N
│       ├── lightbox.gjs
│       ├── comment.gjs          # één reactie (bubble + like + antwoorden)
│       ├── comment-box.gjs      # "Schreib eine Reaktion…"
│       ├── composer.gjs         # inline composer
│       ├── post-modal.gjs       # volledig gesprek (boom)
│       ├── profile-card.gjs     # widget
│       └── online-widget.gjs    # widget
└── test/acceptance/
    ├── timeline-test.js
    └── composer-test.js
```

---

### Task 1: Theme-skelet + tokens + settings

**Files:**
- Create: `about.json`, `settings.yml`, `locales/de.yml`, `locales/en.yml`, `common/common.scss`
- Test: handmatig via `discourse_theme watch`

**Interfaces:**
- Produces: SCSS-custom-properties `--hf-accent`, `--hf-accent-soft`, `--hf-bg`, `--hf-card`, `--hf-ink`, `--hf-muted`, `--hf-footer`; theme-settings:

```yaml
# settings.yml
header_links:
  type: list
  list_type: compact
  default: "Häkelanleitungen,https://haekelfans.de/haekelanleitungen|Blog,https://haekelfans.de/blog|Mein Häkelfans,https://mitglieder.haekelfans.de|Impressum,https://seiten.haekelfans.de/impressum"
  description: "Label,URL — één per regel"
chat_icon_enabled:
  default: false
replies_shown:
  default: 2
  min: 0
  max: 5
show_profile_card:
  default: true
show_online_widget:
  default: true
excerpt_length:
  default: 300
footer_links_service: { type: list, default: "Impressum,…|AGB,…|Datenschutzerklärung,…|Nutzungsbedingungen,…|Lizenzbedingungen,…" }
footer_links_anleitungen: { type: list, default: "Häkelanleitungen,…|Meine Favoriten,…" }
footer_social_instagram: { default: "https://www.instagram.com/haekelfans" }
footer_social_facebook: { default: "https://www.facebook.com/haekelfans" }
```
(De `…`-URL's in de twee footer-lists zijn de echte huidige footer-URL's; neem ze over uit de live footer van club.haekelfans.de bij implementatie — ze staan in de Easy Responsive Footer-component-instellingen in admin.)

- [ ] **Step 1:** `about.json` (name "Häkelfans", component false, minimum_discourse_version van de dev-checkout), `settings.yml` zoals hierboven, lege locales met top-key `hf`.
- [ ] **Step 2:** `common/common.scss`:

```scss
:root {
  --hf-accent: #ea4f86; --hf-accent-soft: #f6e8ea; --hf-bg: #faf7f5;
  --hf-card: #ffffff; --hf-ink: #162c2d; --hf-muted: #808989; --hf-footer: #152b2c;
}
body { background: var(--hf-bg); color: var(--hf-ink); }
.hf-card {
  background: var(--hf-card); border-radius: 16px; padding: 1.25em;
  box-shadow: 0 1px 2px rgba(22,44,45,.05), 0 10px 28px rgba(22,44,45,.07);
}
```

- [ ] **Step 3:** `discourse_theme watch .` starten; check in browser: achtergrond is `#faf7f5`, geen console-errors, theme-settings zichtbaar in admin.
- [ ] **Step 4:** Commit (`feat: theme-skelet, tokens, settings`)

---

### Task 2: Theme-QUnit rig + eerste acceptatietest

**Files:**
- Create: `test/acceptance/timeline-test.js`

**Interfaces:**
- Produces: werkende testloop op `http://localhost:4200/theme-qunit`; helper `hfTopicListResponse()` die een `latest.json`-payload met `hf_*`-velden namaakt (pretender), herbruikt door alle latere tests.

- [ ] **Step 1: Schrijf falende acceptatietest**

```js
// test/acceptance/timeline-test.js
import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import topicFixtures from "discourse/tests/fixtures/discovery-fixtures";

export function hfTopicListResponse() {
  const list = structuredClone(topicFixtures["/latest.json"]);
  const t = list.topic_list.topics[0];
  t.title = "Decke gehäkelt";
  t.hf_images = [{ url: "/images/d1.jpg", thumb_url: "/images/d1.jpg", width: 1200, height: 800 }];
  t.hf_reply_total = 3;
  t.hf_likers = { names: ["Karin", "Brenda"], count: 5, current_user_liked: false };
  t.hf_replies = [{ post_id: 11, post_number: 3, reply_to_post_number: null,
    username: "marga", name: "Marga de Boer", avatar_template: "/letter_avatar_proxy/v4/letter/m/aaaaaa/{size}.png",
    excerpt: "Das wird schon toll!", created_at: "2026-08-01T10:00:00Z",
    like_count: 1, current_user_reacted: false }];
  return list;
}

acceptance("Häkelfans | timeline", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/latest.json", () => helper.response(hfTopicListResponse()));
  });

  test("toont tijdlijnkaarten in plaats van de topiclijst", async function (assert) {
    await visit("/latest");
    assert.dom(".hf-post-card").exists();
    assert.dom(".topic-list").doesNotExist();
    assert.dom(".hf-post-card .hf-post-card__title").hasText("Decke gehäkelt");
  });
});
```

- [ ] **Step 2:** Run op `/theme-qunit` → FAIL (`.hf-post-card` bestaat nog niet). Dit blijft rood tot Task 4; commit de test samen met Task 4. (Test-first over taakgrens heen is hier bewust: de rig zelf is de deliverable.)
- [ ] **Step 3:** Commit alleen de helper-file als hij los draait zonder syntaxfouten (`chore: theme-qunit rig`)

---

### Task 3: Tijdlijn-outlet + kolommenlayout + filterbalk

**Files:**
- Create: `javascripts/discourse/connectors/discovery-list-area/hf-timeline-outlet.gjs`
- Create: `javascripts/discourse/components/hf/timeline.gjs`
- Create: `common/timeline.scss` (layoutdeel)
- Modify: `locales/de.yml`

**Interfaces:**
- Consumes: outlet-args van `discovery-list-area`: `@outletArgs.model` (topic-lijstmodel met `topics`, `loadMore()`, `canLoadMore`).
- Produces: `<Hf::Timeline @model={{...}} />` die rendert: filterbalk (tabs + dropdowns + Neues Thema), composer-slot, kaartenlijst (`Hf::PostCard` per topic — Task 4), rechterkolom met widget-slots; infinite scroll via sentinel-div + IntersectionObserver die `model.loadMore()` roept.
- Tabs → URL's: Aktuell `/latest?order=created` · Aktive Beiträge `/latest` · Neu `/new` · Meine Beiträge `/filter?q=created-by%3Ame%20order%3Acreated`.
- Locale-keys: `hf.tabs.aktuell`, `hf.tabs.aktiv`, `hf.tabs.neu`, `hf.tabs.meine`, `hf.new_topic`, `hf.filter.categories`, `hf.filter.tags`.

- [ ] **Step 1:** Connector die de default lijst vervangt (wrapper-outlet):

```gjs
// connectors/discovery-list-area/hf-timeline-outlet.gjs
import Component from "@glimmer/component";
import HfTimeline from "../../components/hf/timeline";

export default class HfTimelineOutlet extends Component {
  // Alleen op de discovery-lijsten; categorie/tag-pagina's gebruiken 'm ook,
  // dat is gewenst (zelfde tijdlijn, gefilterd).
  <template><HfTimeline @model={{@outletArgs.model}} /></template>
}
```

Controleer de exacte outlet-args eerst met de outlet-debugger: `?safe_mode=no_themes` uit, dan in console `require("discourse/lib/plugin-outlet-debug")` of tijdelijk `{{log @outletArgs}}` — pas de property-namen aan wat de huidige core levert (naam kan `model` of `list` zijn).

- [ ] **Step 2:** `Hf::Timeline` met drie-kolomsgrid (CSS `grid-template-columns: 230px minmax(0,1fr) 250px`, sidebar links is core-sidebar dus alleen midden+rechts hier), filterbalk met `LinkTo`/`<a>` naar de vier tab-URL's (actieve tab o.b.v. `router.currentURL`), en de kaartenlus:

```gjs
{{#each @model.topics as |topic|}} <Hf::PostCard @topic={{topic}} /> {{/each}}
<div class="hf-timeline__sentinel"></div>
```

IntersectionObserver in `constructor`/`willDestroy` (modifier `{{didInsert}}`-stijl met `@ember/render-modifiers` of een eigen modifier) → `this.args.model.loadMore()` als `canLoadMore`. Goedkope virtualisatie voor lange sessies (spec §11): `.hf-post-card { content-visibility: auto; contain-intrinsic-size: auto 480px; }` in `timeline.scss`.

- [ ] **Step 3:** Tijdelijke stub `Hf::PostCard` die alleen `<div class="hf-post-card"><span class="hf-post-card__title">{{@topic.title}}</span></div>` rendert, zodat de QUnit-test uit Task 2 groen kan.
- [ ] **Step 4:** Run Theme-QUnit → timeline-test PASS. Browsercheck: `/latest?order=created` toont kaartenkolom, scroll laadt meer.
- [ ] **Step 5:** Commit (`feat: tijdlijn-outlet, layout, filterbalk, infinite scroll`)

---

### Task 4: De tijdlijnkaart (`Hf::PostCard`)

**Files:**
- Modify: `javascripts/discourse/components/hf/post-card.gjs` (stub → volledig)
- Create: `javascripts/discourse/components/hf/comment.gjs`, `comment-box.gjs`
- Modify: `common/timeline.scss`, `locales/de.yml`
- Test: `test/acceptance/timeline-test.js` (uitbreiden)

**Interfaces:**
- Consumes: `@topic` met `hf_images`, `hf_replies`, `hf_reply_total`, `hf_likers`, `excerpt`, `tags`, `category_id`, `last_poster/posters`, plus theme-setting `replies_shown`.
- Produces: kaart conform mockup-anatomie 1–9. Acties:
  - `Hf::Comment` args: `@reply` (shape = element uit `hf_replies`/tree-node), `@onLike`, `@onAnswer`.
  - `Hf::CommentBox` args: `@topicId`, `@replyToPostNumber` (optioneel), `@onPosted(post)` — POST naar `/posts` met `{ topic_id, raw, reply_to_post_number }` via `ajax` uit `discourse/lib/ajax`.
  - Like op first post: toggle via Reactions-endpoint `PUT /discourse-reactions/posts/{id}/custom-reactions/heart/toggle.json`; fallback (plugin uit) core `PostActionCreator`-endpoint `POST /post_actions` type 2. First-post-id komt uit `hf_first_post_id` (plugin-plan Task 4).
  - "Alle X Reaktionen ansehen" en klik op titel → opent `Hf::PostModal` (Task 6; tot die tijd knop met `@disabled`).
- Locale-keys: `hf.like`, `hf.reply`, `hf.view_all_replies` (met count-interpolatie), `hf.likers_summary` ("%{names} und %{rest} anderen"), `hf.weiterlesen`, `hf.comment_placeholder`.

- [ ] **Step 1: QUnit-test uitbreiden (falend):**

```js
test("kaart toont likers, replies en reactieveld", async function (assert) {
  await visit("/latest");
  assert.dom(".hf-post-card .hf-social__likers").includesText("Karin");
  assert.dom(".hf-post-card .hf-comment").exists({ count: 1 });
  assert.dom(".hf-post-card .hf-comment-box textarea").exists();
  assert.dom(".hf-post-card .hf-view-all").includesText("3");
});
```

- [ ] **Step 2:** Run → FAIL. **Step 3:** Implementeer `post-card.gjs` volgens anatomie (kop met avatar via `avatar`-helper, categorie-badge via `categoryBadgeHTML` of eigen chip met `Category.findById(topic.category_id)`, excerpt met "weiterlesen"-toggle (`@tracked expanded`, dan `topic.excerpt` vervangen door fetch van de first-post cooked via `/t/{id}.json` post 1), `Hf::Gallery` (Task 5; tot dan eerste image als `<img>`), tags-chips uit `topic.tags`, sociale regel uit `hf_likers`, actiebalk, `{{#each (take settings.replies_shown topic.hf_replies)}}` → `Hf::Comment`, view-all-knop, `Hf::CommentBox` die na `@onPosted` de reply optimistisch aan `topic.hf_replies` toevoegt (`@tracked` kopie in component-state).
- [ ] **Step 4:** Run QUnit → PASS. Browsercheck met echte dev-data (topic met foto's + replies): kaart matcht mockup, reageren werkt zonder reload, hartje togglet (network-tab: reactions-call 200).
- [ ] **Step 5:** Commit (`feat: tijdlijnkaart met inline reacties en likes`)

---

### Task 5: Galerij + lightbox

**Files:**
- Create: `javascripts/discourse/components/hf/gallery.gjs`, `lightbox.gjs`
- Modify: `common/timeline.scss`
- Test: `test/acceptance/timeline-test.js` (uitbreiden)

**Interfaces:**
- Consumes: `@images` (array uit `hf_images`), `@title`.
- Produces: 1 foto → volle breedte; 2–5 → masonry-grid (CSS grid, eerste cel 2 rijen); >5 → 5 tegels met `+N`-overlay op de vijfde. Klik → `Hf::Lightbox` (in `#hf-lightbox-portal` bovenaan body): donkere overlay, `thumb_url`→`url` vol formaat, pijltjes + toetsen (←/→/Esc) + touch-swipe (pointer events, drempel 40px), teller "2 / 5", bijschrift `@title`.

- [ ] **Step 1: Falende test:** fixture uitbreiden naar 6 images; assert `.hf-gallery__cell` count 5 en `.hf-gallery__more` hasText "+2"; klik op cel → `.hf-lightbox` exists; `Esc` → verdwenen (`triggerKeyEvent`).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implementeren (grid-classes `m1/m3/m5` als in de mockup-CSS; lightbox met `@tracked index`, `willDestroy` verwijdert keydown-listener; `prefers-reduced-motion` respecteren: geen fade-animatie).
- [ ] **Step 4:** Run → PASS + browsercheck mobiel-emulatie (swipe werkt).
- [ ] **Step 5:** Commit (`feat: masonry-galerij en lightbox`)

---

### Task 6: Berichtmodal met reply-boom

**Files:**
- Create: `javascripts/discourse/components/hf/post-modal.gjs`
- Modify: `post-card.gjs` (openen), `comment.gjs` (genest + "Antworten ansehen")
- Test: `test/acceptance/timeline-test.js` (uitbreiden)

**Interfaces:**
- Consumes: `GET /haekelfans/topic/{id}/tree.json` (shape: zie plugin-plan Task 5) + `GET /t/{id}.json` voor de volledige first-post cooked.
- Produces: modal via core `DModal`-service (`this.modal.show(HfPostModal, { model: { topic } })`); rendert kaart-anatomie + volledige boom: niveau 1 direct zichtbaar, niveaus 2–4 ingeklapt achter "N weitere Antworten ansehen" per tak (`@tracked expandedIds` Set). Reageren per comment via `Hf::CommentBox` met `@replyToPostNumber`; na post → boom lokaal bijwerken (node toevoegen aan `children`). Paginering: "Weitere Reaktionen laden" onderaan bij `total > per_page`.

- [ ] **Step 1: Falende test** (pretender voor `/haekelfans/topic/*/tree.json` met 2 niveaus): klik `.hf-view-all` → `.hf-post-modal` exists; `.hf-comment--nested` exists; klik "1 weitere Antwort ansehen" → tweede niveau zichtbaar.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implementeren. **Step 4:** Run → PASS + browsercheck: deeplink-notificatie klikken opent topic (nog core-weergave; Task 7), modal vanuit tijdlijn toont volledige gesprek, antwoorden op niveau 3 belandt op niveau 4.
- [ ] **Step 5:** Commit (`feat: berichtmodal met geneste reply-boom`)

---

### Task 7: Topic-pagina (deeplinks) in kaartweergave

**Files:**
- Create: `javascripts/discourse/connectors/topic-above-post-stream/hf-topic-view.gjs`
- Modify: `common/timeline.scss` (verbergen post-stream op topic-route), `locales/de.yml`

**Interfaces:**
- Consumes: `@outletArgs.model` (topic-model op de topic-route) + zelfde tree-endpoint.
- Produces: op `/t/…`-URL's rendert de connector dezelfde kaart+boom-weergave als de modal (hergebruik: `Hf::PostModal` bevat een binnencomponent `Hf::PostView` die zowel in de modal als hier gebruikt wordt — refactor bij deze taak); CSS verbergt `.post-stream`, `.topic-map`, timeline-nav en topic-footer-buttons op topic-routes. Deeplink naar specifieke post (`/t/slug/id/3`) scrollt naar en highlight die comment (anchor op `data-hf-post-number`).

- [ ] **Step 1:** Refactor `Hf::PostView` uit `post-modal.gjs` (modal wordt dunne wrapper). QUnit-run: bestaande modal-tests blijven PASS (regressiecheck van de refactor).
- [ ] **Step 2:** Connector + CSS. Browsercheck: klik op mail-/notificatielink naar een reply → kaartweergave, juiste comment gehighlight, tijdlijn-terugknop ("Zur Häkelstube") bovenaan.
- [ ] **Step 3:** Commit (`feat: topic-deeplinks in kaartweergave`)

---

### Task 8: Inline composer

**Files:**
- Create: `javascripts/discourse/components/hf/composer.gjs`
- Modify: `timeline.gjs` (composer-slot + "Neues Thema"-knop → openklappen), `locales/de.yml`
- Test: `test/acceptance/composer-test.js`

**Interfaces:**
- Consumes: core `POST /posts` (`{ title, raw, category, tags, hf_no_onebox }`), uploads via core composer-upload-endpoint (`/uploads.json?client_id=…`, gebruik `UppyUpload`-mixin/`uppy` zoals core composer of simpelweg `ajax` multipart), `CategoryChooser`- en `TagChooser`-select-kit-componenten uit core.
- Produces: rust-stand (veld + camera-knop) → opengeklapt (titel optioneel, tekstveld, upload-thumbnails met verwijderknop, categorie-chip default Häkelstube (instelling? nee: eerste schrijfbare categorie; default categorie-id als theme-setting `default_category_id`, default 0 = eerste), tags, schakelaar "Link-Vorschau anzeigen" default aan, Veröffentlichen).
  - **Titelgeneratie client-side:** bij lege titel → eerste 8 woorden van raw (zonder markdown/URL's), afgekapt op 60 tekens. Exporteer als pure functie `generateTitle(raw)` voor de unit-test.
  - Schakelaar uit → `hf_no_onebox: "true"` in de POST-body.
  - Na succes: topic-object optimistisch vooraan `model.topics`; fout → foutmelding in het Duits boven de knop, invoer blijft staan. Draft: gebruik core drafts — `POST /drafts.json` met `draft_key: "new_topic"` en sequence (zelfde contract als core composer; zie `discourse/models/draft`), zodat concepten ook op andere apparaten terugkomen; wissen na succesvolle post via `DELETE /drafts/new_topic.json`.
- Locale-keys: `hf.composer.placeholder`, `.title_placeholder`, `.publish`, `.link_preview`, `.link_preview_hint`, `.error_generic`.

- [ ] **Step 1: Falende unit + acceptatietest:**

```js
import { generateTitle } from "../../javascripts/discourse/components/hf/composer";
test("generateTitle pakt de eerste woorden zonder links", function (assert) {
  assert.strictEqual(
    generateTitle("Schau mal https://x.de dieses tolle Garn das ich gefunden habe heute"),
    "Schau mal dieses tolle Garn das ich gefunden"
  );
});
```

Acceptance: open composer, vul raw, submit (pretender `POST /posts` → 200 met topic-payload incl. `hf_no_onebox`-echo), assert nieuwe `.hf-post-card` bovenaan en assert dat request-body `hf_no_onebox` bevatte toen de schakelaar uit stond.

- [ ] **Step 2:** Run → FAIL. **Step 3:** Implementeren. **Step 4:** Run → PASS + browsercheck: post met 2 foto's en link mét/zónder preview op dev-site (plugin actief: check cooked). Draft-gedrag: refresh mid-typen → tekst terug.
- [ ] **Step 5:** Commit (`feat: inline composer met no-onebox schakelaar`)

---

### Task 9: Header

**Files:**
- Modify: `javascripts/discourse/api-initializers/hf-theme.gjs`
- Create: `common/header.scss`

**Interfaces:**
- Consumes: theme-settings `header_links`, `chat_icon_enabled`; core header-outlets (`header-contents__before/after` — verifieer namen met outlet-debug zoals in Task 3).
- Produces: gestylede core-header (wit, sticky) met: core hamburger + logo; brede zoekbalk (core site-setting `search_experience: search_field` aanzetten op de site — documenteer in README-stap); nav-links-component uit `header_links` (render `<a>`-lijst, verbergen < 1100px); bel + avatar core; gereserveerde chat-plek: als `chat_icon_enabled` uit → CSS `display:none` op `.chat-header-icon`.
- User-menu versimpeling: via `api.` geen — CSS in `header.scss` verbergt user-menu-tabs die spec §8 schrapt (alles behalve notificaties/berichten/profiel/afmelden).

- [ ] **Step 1:** `api.renderInOutlet` met een kleine inline gjs-component voor de nav-links (parse `header_links` op `|` en `,`).
- [ ] **Step 2:** `header.scss` (hoogtes, wit vlak, schaduw, zoekveld breed).
- [ ] **Step 3:** Browsercheck desktop + mobiel breakpoints; QUnit-run als regressie.
- [ ] **Step 4:** Commit (`feat: header met instelbare links`)

---

### Task 10: Widgets (profielkaart + Wer ist online) en linker-sidebar

**Files:**
- Create: `components/hf/profile-card.gjs`, `components/hf/online-widget.gjs`
- Modify: `timeline.gjs` (rechterkolom vullen o.b.v. settings), `common/common.scss` (sidebar-styling)
- Test: `test/acceptance/timeline-test.js` (uitbreiden)

**Interfaces:**
- Consumes: `currentUser` service (naam, avatar, `likes_given/likes_received/topic_count/post_count` via `/u/{username}/summary.json` of user-fields op currentUser — gebruik summary-endpoint, cache in component), `GET /haekelfans/online.json` (poll elke 60 s, stop in `willDestroy`), settings `show_profile_card`, `show_online_widget`.
- Produces: widgets zoals mockup; sidebar: core-sidebar met CSS in Häkelfans-stijl; secties beperkt tot persoonlijke links + Kategorien + Schlagwörter (core sidebar-admin regelt de inhoud; document in README welke secties uit moeten).

- [ ] **Step 1: Falende test:** pretender `/haekelfans/online.json` → `{count: 3, users:[…]}`; assert `.hf-online-widget` toont "3". Setting-test: `show_online_widget: false` (via `settings`-override helper in theme-qunit) → widget afwezig.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implementeren. **Step 4:** PASS + browsercheck.
- [ ] **Step 5:** Commit (`feat: rechterkolom-widgets`)

---

### Task 11: Footer

**Files:**
- Create: `javascripts/discourse/connectors/below-footer/hf-footer.gjs`
- Modify: `common/common.scss`

**Interfaces:**
- Consumes: settings `footer_links_service`, `footer_links_anleitungen`, `footer_social_instagram/_facebook`.
- Produces: donkere footer (`--hf-footer`) met twee linkkolommen + social-iconen (inline SVG), op alle pagina's; vervangt Easy Responsive Footer.

- [ ] **Step 1:** Component + SCSS. **Step 2:** Browsercheck (ook mobiel: kolommen stapelen). **Step 3:** Commit (`feat: footer`)

---

### Task 12: Profielversimpeling + mobiel + PWA-afronding

**Files:**
- Create: `common/profile.scss`, `common/mobile.scss`
- Modify: `api-initializers/hf-theme.gjs` (route-redirects), `locales/de.yml`

**Interfaces:**
- Produces:
  - `profile.scss`: de definitieve verwijderlijst uit spec §8 (trust-level velden, badges, data-export, gekoppelde accounts, tracking, dempen, samenvattingen, drafts-nav, "Andere", stats-secties, kalender-abonnementen, user-nav-items — neem de selectors over van de huidige custom CSS als startpunt, geconsolideerd en becommentarieerd per blok).
  - Route-redirects: `api.onPageChange` → als pad matcht `/u/*/preferences/(tracking|users|navigation-menu|interface|apps)` of `/u/*/(badges|summary)` → `router.transitionTo` naar `/u/:username/preferences/account`.
  - `mobile.scss`: één kolom < 1000px, filterchips horizontaal scrollend, FAB rechtsonder (opent composer), widgets verborgen, kaart-marges compact.
  - PWA: `theme-color` meta `#faf7f5` via `api.` head-injectie; controleer Add-to-Home-Screen werkt (core manifest).
- [ ] **Step 1:** Implementeren. **Step 2:** Browsercheck mobiel (echte telefoon via dev-tunnel of netwerk-IP): FAB, chips, modal fullscreen, lightbox-swipe, PWA-install. Profiel: alle geschrapte items onvindbaar, Einstellungen toont alleen account-basics; QUnit volledige run groen.
- [ ] **Step 3:** Commit (`feat: profielversimpeling, mobiel, PWA`)

---

### Task 13: Eindcontrole + uitrolvoorbereiding

**Files:**
- Create: `haekelfans-theme/README.md`

- [ ] **Step 1:** README: installatie (git-repo → admin › Aanpassen › Thema's › Installeren via git), vereisten (haekelfans-timeline plugin actief, `search_experience: search_field`, Reactions-emoji-set instellen met hart als eerste), settings-tabel, welke oude components uitgeschakeld moeten worden (volledige lijst van 9 uit de spec §2.3), preview-instructie (`/admin/customize/themes` → Voorbeeld → delen met team via `?preview_theme_id=<id>`), omschakel- en rollback-stappen (spec §13).
- [ ] **Step 2:** Volledige regressie: alle QUnit-tests groen; handmatige checklist desktop+mobiel: tijdlijn scrollen/filteren, plaatsen mét foto's, reageren op 4 niveaus, liken van bericht én reply, lightbox, deeplink uit e-mail, profiel, footer-links, uitgelogde staat (login-redirect via Heppy blijft werken).
- [ ] **Step 3:** Commit (`docs: README en uitrolinstructies`)
