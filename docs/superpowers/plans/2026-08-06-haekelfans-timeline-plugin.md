# haekelfans-timeline Plugin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Discourse-plugin dat alle tijdlijn-data levert voor het Häkelfans theme: afbeeldingen, reply-previews, likers, reply-boom, "Wer ist online" en onebox-onderdrukking per bericht.

**Architecture:** Serializer-uitbreidingen op `topic_list_item` (bulk-preloaded via `TopicList.on_preload`, geen N+1), een klein Rails-engine met twee endpoints (`tree`, `online`), en een post-custom-field `hf_no_onebox` dat oneboxes strip bij het cooken. Vervangt de bestaande plugins *Tlp grid images* en *Top replies*.

**Tech Stack:** Ruby (Discourse plugin-API, laatste stable), RSpec (`fab!`/Fabricator-patroon van Discourse core), geen eigen JS.

## Global Constraints

- Discourse: laatste stable; plugin-naam exact `haekelfans-timeline`.
- Alle site-settings prefix `haekelfans_timeline_`; hoofdschakelaar `haekelfans_timeline_enabled` (default `true`, `client: true`).
- Reactions (Reaktionen) is geïnstalleerd op productie, maar het plugin mag NIET crashen zonder (`defined?(DiscourseReactions)`-guard); fallback = core likes.
- Geen wijzigingen aan core-gedrag wanneer `haekelfans_timeline_enabled` uit staat.
- Alle queries voor lijstdata bulk (één query per lijst, nooit per topic).
- Automatische titelgeneratie zit bewust NIET in dit plugin maar in de theme-composer (client-side) — zie theme-plan Task 8; dit wijkt af van spec §2.2 omdat core de titel al valideert vóór server-side hooks bruikbaar zijn.
- Ontwikkelomgeving: lokale Discourse dev-checkout; plugin als symlink in `plugins/`. Testcommando altijd: `LOAD_PLUGINS=1 bundle exec rspec plugins/haekelfans-timeline/spec/<file> -f doc`.

## File Structure

```
haekelfans-timeline/
├── plugin.rb                                  # metadata, after_initialize wiring
├── config/
│   ├── settings.yml                           # site settings
│   ├── routes.rb                              # engine routes
│   └── locales/{server.de.yml,server.en.yml}
├── lib/haekelfans_timeline/
│   ├── engine.rb                              # Rails engine + mount
│   ├── timeline_data.rb                       # preload + images/replies/likers
│   └── reply_tree.rb                          # geneste boom, max 4 niveaus
├── app/controllers/haekelfans_timeline/
│   └── timeline_controller.rb                 # tree + online endpoints
└── spec/
    ├── plugin_spec.rb
    ├── lib/{timeline_data_spec.rb,reply_tree_spec.rb}
    ├── requests/timeline_controller_spec.rb
    └── integration/no_onebox_spec.rb
```

---

### Task 1: Dev-omgeving + plugin-skelet

**Files:**
- Create: `haekelfans-timeline/plugin.rb`
- Create: `haekelfans-timeline/config/settings.yml`
- Create: `haekelfans-timeline/config/locales/server.de.yml`, `server.en.yml`
- Create: `haekelfans-timeline/lib/haekelfans_timeline/engine.rb`
- Create: `haekelfans-timeline/config/routes.rb`
- Test: `haekelfans-timeline/spec/plugin_spec.rb`

**Interfaces:**
- Produces: module `::HaekelfansTimeline` (`PLUGIN_NAME = "haekelfans-timeline"`), engine gemount op `/haekelfans`, settings `haekelfans_timeline_enabled`, `haekelfans_timeline_max_images` (default 10), `haekelfans_timeline_reply_preview_count` (default 3).

- [ ] **Step 1: Discourse dev-checkout gereed maken (eenmalig)**

```bash
# in de repo-root van dit project
git clone https://github.com/discourse/discourse.git dev/discourse --depth 1
mkdir -p plugin && cd dev/discourse
bundle install && yarn install
bin/rails db:create db:migrate
ln -s "$(pwd)/../../plugin/haekelfans-timeline" plugins/haekelfans-timeline
```
Expected: symlink aanwezig; `bin/rails runner "puts 1"` draait zonder fout.

- [ ] **Step 2: Schrijf de falende smoke-test**

```ruby
# spec/plugin_spec.rb
# frozen_string_literal: true
RSpec.describe "haekelfans-timeline plugin" do
  it "is enabled by default" do
    expect(SiteSetting.haekelfans_timeline_enabled).to eq(true)
  end
end
```

- [ ] **Step 3: Run test → verwacht FAIL** (`NoMethodError: haekelfans_timeline_enabled`)

- [ ] **Step 4: Implementeer skelet**

```ruby
# plugin.rb
# frozen_string_literal: true
# name: haekelfans-timeline
# about: Tijdlijn-data voor het Häkelfans theme (afbeeldingen, replies, online, no-onebox)
# version: 1.0.0
# authors: Timo Roosendaal
# required_version: 2.7.0

enabled_site_setting :haekelfans_timeline_enabled

module ::HaekelfansTimeline
  PLUGIN_NAME = "haekelfans-timeline"
end

require_relative "lib/haekelfans_timeline/engine"

after_initialize do
  # serializer/velden komen in latere taken
end
```

```yaml
# config/settings.yml
plugins:
  haekelfans_timeline_enabled:
    default: true
    client: true
  haekelfans_timeline_max_images:
    default: 10
    client: true
  haekelfans_timeline_reply_preview_count:
    default: 3
    client: true
```

```ruby
# lib/haekelfans_timeline/engine.rb
# frozen_string_literal: true
module ::HaekelfansTimeline
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace HaekelfansTimeline
    config.autoload_paths << File.join(config.root, "lib")
  end
end

Discourse::Application.routes.append { mount ::HaekelfansTimeline::Engine, at: "/haekelfans" }
```

```ruby
# config/routes.rb
# frozen_string_literal: true
HaekelfansTimeline::Engine.routes.draw do
  get "/topic/:topic_id/tree" => "timeline#tree", constraints: { topic_id: /\d+/ }
  get "/online" => "timeline#online"
end
```

```yaml
# config/locales/server.de.yml
de:
  site_settings:
    haekelfans_timeline_enabled: "Häkelfans-Timeline-Daten aktivieren"
    haekelfans_timeline_max_images: "Maximale Anzahl Bilder pro Beitrag in der Timeline"
    haekelfans_timeline_reply_preview_count: "Anzahl Antwort-Vorschauen pro Beitrag in der Listen-Payload"
```
(en.yml: zelfde keys, Engelse tekst.)

- [ ] **Step 5: Run test → PASS**, daarna **commit** (`feat: plugin-skelet haekelfans-timeline`)

---

### Task 2: Afbeeldingen per topic (`hf_images`)

**Files:**
- Create: `lib/haekelfans_timeline/timeline_data.rb`
- Modify: `plugin.rb` (after_initialize)
- Test: `spec/lib/timeline_data_spec.rb`

**Interfaces:**
- Produces: `HaekelfansTimeline::TimelineData.preload(topics)` (bulk), `TimelineData.images_for(topic)` → `[{ url:, thumb_url:, width:, height: }, …]` (max `haekelfans_timeline_max_images`); serializer-veld `hf_images` op `topic_list_item`.
- Preload-cache zit op `topic.instance_variable @hf_data` zodat serializers geen queries doen.

- [ ] **Step 1: Falende test**

```ruby
# spec/lib/timeline_data_spec.rb
# frozen_string_literal: true
RSpec.describe HaekelfansTimeline::TimelineData do
  fab!(:user)
  fab!(:topic) { Fabricate(:topic, user: user) }
  fab!(:post1) { Fabricate(:post, topic: topic, user: user, post_number: 1) }
  fab!(:upload1) { Fabricate(:image_upload, width: 1200, height: 800) }
  fab!(:upload2) { Fabricate(:image_upload, width: 600, height: 900) }

  before do
    UploadReference.create!(target: post1, upload: upload1)
    UploadReference.create!(target: post1, upload: upload2)
  end

  it "levert first-post-afbeeldingen met thumbnail-urls in postvolgorde" do
    described_class.preload([topic])
    images = described_class.images_for(topic)
    expect(images.length).to eq(2)
    expect(images.first[:url]).to eq(upload1.url)
    expect(images.first[:width]).to eq(1200)
  end

  it "respecteert het maximum" do
    SiteSetting.haekelfans_timeline_max_images = 1
    described_class.preload([topic])
    expect(described_class.images_for(topic).length).to eq(1)
  end
end
```

- [ ] **Step 2: Run → FAIL** (`uninitialized constant … TimelineData`)

- [ ] **Step 3: Implementatie**

```ruby
# lib/haekelfans_timeline/timeline_data.rb
# frozen_string_literal: true
module HaekelfansTimeline
  module TimelineData
    def self.preload(topics)
      ids = topics.map(&:id)
      first_posts =
        Post.where(topic_id: ids, post_number: 1).pluck(:topic_id, :id).to_h
      refs =
        UploadReference
          .where(target_type: "Post", target_id: first_posts.values)
          .joins("JOIN uploads ON uploads.id = upload_references.upload_id")
          .where("uploads.width IS NOT NULL")
          .order(:target_id, :id)
          .pluck("upload_references.target_id", "uploads.id", "uploads.url",
                 "uploads.width", "uploads.height")
      by_post = refs.group_by(&:first)
      limit = SiteSetting.haekelfans_timeline_max_images
      topics.each do |t|
        rows = (by_post[first_posts[t.id]] || []).first(limit)
        images = rows.map do |(_pid, upload_id, url, w, h)|
          thumb = OptimizedImage.where(upload_id: upload_id).order(width: :desc).first
          { url: UrlHelper.cook_url(url), thumb_url: thumb ? UrlHelper.cook_url(thumb.url) : UrlHelper.cook_url(url), width: w, height: h }
        end
        t.instance_variable_set(:@hf_data, (t.instance_variable_get(:@hf_data) || {}).merge(images: images))
      end
    end

    def self.images_for(topic)
      (topic.instance_variable_get(:@hf_data) || {})[:images] || []
    end
  end
end
```

```ruby
# plugin.rb — binnen after_initialize
require_relative "lib/haekelfans_timeline/timeline_data"

TopicList.on_preload do |topics, _topic_list|
  HaekelfansTimeline::TimelineData.preload(topics) if SiteSetting.haekelfans_timeline_enabled
end

add_to_serializer(:topic_list_item, :hf_images,
  include_condition: -> { SiteSetting.haekelfans_timeline_enabled }) do
  HaekelfansTimeline::TimelineData.images_for(object)
end
```

- [ ] **Step 4: Run → PASS.** Draai ook `spec/plugin_spec.rb` mee (regressie).
- [ ] **Step 5: Commit** (`feat: hf_images serializer-veld met bulk preload`)

---

### Task 3: Reply-previews (`hf_replies`) met reactie-samenvattingen

**Files:**
- Modify: `lib/haekelfans_timeline/timeline_data.rb`
- Modify: `plugin.rb`
- Test: `spec/lib/timeline_data_spec.rb` (uitbreiden)

**Interfaces:**
- Produces: `TimelineData.replies_for(topic)` → laatste N (`haekelfans_timeline_reply_preview_count`) zichtbare replies, oudste eerst:
  `[{ post_id:, post_number:, reply_to_post_number:, username:, name:, avatar_template:, excerpt:, created_at:, like_count:, current_user_reacted: }, …]`
  plus `TimelineData.reply_total_for(topic)` → integer. Serializer-velden `hf_replies`, `hf_reply_total`.

- [ ] **Step 1: Falende tests**

```ruby
it "levert de laatste N replies, oudste eerst, met excerpt en teller" do
  SiteSetting.haekelfans_timeline_reply_preview_count = 2
  p2 = Fabricate(:post, topic: topic, post_number: 2, raw: "Erste Antwort hier")
  p3 = Fabricate(:post, topic: topic, post_number: 3, raw: "Zweite Antwort hier")
  p4 = Fabricate(:post, topic: topic, post_number: 4, raw: "Dritte Antwort hier",
                 reply_to_post_number: 2)
  described_class.preload([topic])
  replies = described_class.replies_for(topic)
  expect(replies.map { |r| r[:post_number] }).to eq([3, 4])
  expect(replies.last[:reply_to_post_number]).to eq(2)
  expect(replies.last[:excerpt]).to include("Dritte")
  expect(described_class.reply_total_for(topic)).to eq(3)
end

it "slaat verwijderde en whisper-posts over" do
  p2 = Fabricate(:post, topic: topic, post_number: 2)
  p2.trash!
  described_class.preload([topic])
  expect(described_class.replies_for(topic)).to eq([])
end
```

- [ ] **Step 2: Run → FAIL** (`undefined method replies_for`)

- [ ] **Step 3: Implementatie** — in `preload`, ná de images-lus:

```ruby
n = SiteSetting.haekelfans_timeline_reply_preview_count
rows = DB.query(<<~SQL, ids: ids, n: n)
  SELECT * FROM (
    SELECT p.id, p.topic_id, p.post_number, p.reply_to_post_number, p.user_id,
           p.cooked, p.created_at, p.like_count,
           ROW_NUMBER() OVER (PARTITION BY p.topic_id ORDER BY p.post_number DESC) AS rn,
           COUNT(*)    OVER (PARTITION BY p.topic_id) AS total
    FROM posts p
    WHERE p.topic_id IN (:ids) AND p.post_number > 1
      AND p.deleted_at IS NULL AND p.post_type = 1 AND p.hidden = false
  ) x WHERE rn <= :n
SQL
users = User.where(id: rows.map(&:user_id).uniq).index_by(&:id)
rows.group_by(&:topic_id).each do |tid, list|
  t = topics.find { |x| x.id == tid } or next
  replies = list.sort_by(&:post_number).map do |r|
    u = users[r.user_id]
    { post_id: r.id, post_number: r.post_number,
      reply_to_post_number: r.reply_to_post_number,
      username: u&.username, name: u&.name, avatar_template: u&.avatar_template,
      excerpt: PrettyText.excerpt(r.cooked, 200, keep_emoji_images: true),
      created_at: r.created_at, like_count: r.like_count, current_user_reacted: false }
  end
  t.instance_variable_set(:@hf_data,
    (t.instance_variable_get(:@hf_data) || {}).merge(replies: replies, reply_total: list.first.total))
end
```

`replies_for` / `reply_total_for` als accessors (zelfde patroon als `images_for`, defaults `[]` / `0`). In `plugin.rb`:

```ruby
add_to_serializer(:topic_list_item, :hf_replies,
  include_condition: -> { SiteSetting.haekelfans_timeline_enabled }) do
  HaekelfansTimeline::TimelineData.replies_for(object)
end
add_to_serializer(:topic_list_item, :hf_reply_total,
  include_condition: -> { SiteSetting.haekelfans_timeline_enabled }) do
  HaekelfansTimeline::TimelineData.reply_total_for(object)
end
```

- [ ] **Step 4: Run → PASS** · **Step 5: Commit** (`feat: hf_replies + hf_reply_total`)

---

### Task 4: Likers-samenvatting first post (`hf_likers`)

**Files:**
- Modify: `lib/haekelfans_timeline/timeline_data.rb`, `plugin.rb`
- Test: `spec/lib/timeline_data_spec.rb` (uitbreiden)

**Interfaces:**
- Produces: `TimelineData.likers_for(topic)` → `{ names: [max 2 weergavenamen], count: totaal, current_user_liked: bool }`; serializer-veld `hf_likers`. Werkt op core `PostAction` (type `:like`) — Reactions synct likes daarheen, dus dit dekt beide.
- Produces daarnaast: serializer-veld `hf_first_post_id` (integer, id van post_number 1) — het theme heeft dit nodig om de like/reactie-toggle op de first post te kunnen aanroepen. Zelfde preload (`first_posts`-hash is er al in Task 2); test: assert dat `hf_first_post_id == post1.id` in de serializer-output.

- [ ] **Step 1: Falende test**

```ruby
it "vat likers van de first post samen" do
  liker1 = Fabricate(:user, name: "Karin R")
  liker2 = Fabricate(:user, name: "Brenda O")
  liker3 = Fabricate(:user, name: "Marga B")
  [liker1, liker2, liker3].each { |u| PostActionCreator.like(u, post1) }
  described_class.preload([topic], current_user: liker1)
  likers = described_class.likers_for(topic)
  expect(likers[:count]).to eq(3)
  expect(likers[:names].length).to eq(2)
  expect(likers[:current_user_liked]).to eq(true)
end
```

- [ ] **Step 2: Run → FAIL**
- [ ] **Step 3: Implementatie** — `preload` krijgt keyword `current_user: nil`; bulk:

```ruby
like_id = PostActionType.types[:like]
likes = PostAction
  .where(post_id: first_posts.values, post_action_type_id: like_id, deleted_at: nil)
  .joins(:user).order(:post_id, :created_at)
  .pluck(:post_id, :user_id, "users.name", "users.username")
likes.group_by(&:first).each do |pid, list|
  tid = first_posts.key(pid)
  t = topics.find { |x| x.id == tid } or next
  t.instance_variable_set(:@hf_data, (t.instance_variable_get(:@hf_data) || {}).merge(
    likers: {
      names: list.first(2).map { |(_p, _uid, name, username)| name.presence || username },
      count: list.size,
      current_user_liked: current_user ? list.any? { |(_p, uid, _n, _u)| uid == current_user.id } : false,
    }))
end
```

`TopicList.on_preload`-blok doorgeven: `HaekelfansTimeline::TimelineData.preload(topics, current_user: topic_list&.current_user)`. Serializer-veld `hf_likers` (default `{ names: [], count: 0, current_user_liked: false }`).

- [ ] **Step 4: Run → PASS** · **Step 5: Commit** (`feat: hf_likers samenvatting`)

---

### Task 5: Reply-boom endpoint (`GET /haekelfans/topic/:id/tree.json`)

**Files:**
- Create: `lib/haekelfans_timeline/reply_tree.rb`
- Create: `app/controllers/haekelfans_timeline/timeline_controller.rb`
- Test: `spec/lib/reply_tree_spec.rb`, `spec/requests/timeline_controller_spec.rb`

**Interfaces:**
- Produces: JSON `{ topic_id:, total:, page:, per_page: 50, replies: [<node>] }` waarbij `<node>` = alle velden van een reply uit Task 3 **plus** `children: [<node>]`, genest **max 4 niveaus** (diepere antwoorden worden platgeslagen naar niveau 4). Top-level gepagineerd per 50 (`?page=0,1,…`), children altijd volledig mee.
- Guardian: 403/404 voor topics die het lid niet mag zien.

- [ ] **Step 1: Falende boom-test**

```ruby
# spec/lib/reply_tree_spec.rb
RSpec.describe HaekelfansTimeline::ReplyTree do
  fab!(:topic)
  fab!(:op) { Fabricate(:post, topic: topic, post_number: 1) }

  def reply(to:, n:)
    Fabricate(:post, topic: topic, post_number: n, reply_to_post_number: to, raw: "Antwort #{n}")
  end

  it "nest replies en kapt op 4 niveaus" do
    r2 = reply(to: nil, n: 2)   # niveau 1
    r3 = reply(to: 2, n: 3)     # niveau 2
    r4 = reply(to: 3, n: 4)     # niveau 3
    r5 = reply(to: 4, n: 5)     # niveau 4
    r6 = reply(to: 5, n: 6)     # niveau 5 → platgeslagen naar 4
    tree = described_class.build(topic.reload, Guardian.new)
    root = tree[:replies].first
    expect(root[:post_number]).to eq(2)
    l4 = root[:children].first[:children].first[:children]
    expect(l4.map { |n| n[:post_number] }).to contain_exactly(5, 6)
  end
end
```

- [ ] **Step 2: Run → FAIL**
- [ ] **Step 3: Implementatie**

```ruby
# lib/haekelfans_timeline/reply_tree.rb
# frozen_string_literal: true
module HaekelfansTimeline
  module ReplyTree
    PER_PAGE = 50
    MAX_DEPTH = 4

    def self.build(topic, guardian, page: 0, current_user: nil)
      posts = topic.posts.where("post_number > 1")
        .where(deleted_at: nil, post_type: Post.types[:regular], hidden: false)
        .includes(:user).order(:post_number)
      nodes = posts.map { |p| serialize(p, current_user) }
      by_number = nodes.index_by { |n| n[:post_number] }
      roots = []
      nodes.each do |n|
        parent = n[:reply_to_post_number] && by_number[n[:reply_to_post_number]]
        parent && parent != n ? (parent[:children] << n) : (roots << n)
      end
      roots.each { |r| clamp!(r, 1) }
      { topic_id: topic.id, total: roots.size, page: page, per_page: PER_PAGE,
        replies: roots.slice(page * PER_PAGE, PER_PAGE) || [] }
    end

    # Op diepte MAX_DEPTH-1 wordt de hele substructuur platgeslagen tot
    # directe children, zodat niets dieper dan MAX_DEPTH niveaus rendert.
    def self.clamp!(node, depth)
      if depth == MAX_DEPTH - 1
        node[:children] = flatten(node[:children])
        node[:children].each { |c| c[:children] = [] }
      else
        node[:children].each { |c| clamp!(c, depth + 1) }
      end
    end

    def self.flatten(children)
      children.flat_map { |c| [c] + flatten(c[:children]) }
    end

    def self.serialize(post, current_user)
      u = post.user
      { post_id: post.id, post_number: post.post_number,
        reply_to_post_number: post.reply_to_post_number,
        username: u&.username, name: u&.name, avatar_template: u&.avatar_template,
        cooked: post.cooked, created_at: post.created_at,
        like_count: post.like_count,
        current_user_reacted: current_user ?
          PostAction.exists?(post_id: post.id, user_id: current_user.id,
            post_action_type_id: PostActionType.types[:like], deleted_at: nil) : false,
        children: [] }
    end
  end
end
```

```ruby
# app/controllers/haekelfans_timeline/timeline_controller.rb
# frozen_string_literal: true
module HaekelfansTimeline
  class TimelineController < ::ApplicationController
    requires_plugin HaekelfansTimeline::PLUGIN_NAME

    def tree
      topic = Topic.find_by(id: params[:topic_id].to_i)
      raise Discourse::NotFound unless topic
      guardian.ensure_can_see!(topic)
      render json: ReplyTree.build(topic, guardian,
        page: params[:page].to_i, current_user: current_user)
    end
  end
end
```

Request-test: ingelogde user krijgt 200 + boom; anonieme user op privé-categorie krijgt 403 (`sign_in(user)`-patroon uit core-specs).

- [ ] **Step 4: Run beide specs → PASS** · **Step 5: Commit** (`feat: reply-tree endpoint, max 4 niveaus`)

---

### Task 6: "Wer ist online" endpoint

**Files:**
- Modify: `app/controllers/haekelfans_timeline/timeline_controller.rb`
- Test: `spec/requests/timeline_controller_spec.rb` (uitbreiden)

**Interfaces:**
- Produces: `GET /haekelfans/online.json` → `{ count: <totaal>, users: [{ id, username, name, avatar_template }] }` (max 30 users, `last_seen_at` < 10 min, cache 60 s, alleen voor ingelogde leden — anoniem 403).

- [ ] **Step 1: Falende test**

```ruby
describe "#online" do
  fab!(:user)
  fab!(:online_user) { Fabricate(:user, last_seen_at: 2.minutes.ago) }
  fab!(:offline_user) { Fabricate(:user, last_seen_at: 2.hours.ago) }

  it "telt alleen recent geziene leden" do
    sign_in(user)
    get "/haekelfans/online.json"
    expect(response.status).to eq(200)
    usernames = response.parsed_body["users"].map { |u| u["username"] }
    expect(usernames).to include(online_user.username)
    expect(usernames).not_to include(offline_user.username)
  end

  it "weigert anoniem" do
    get "/haekelfans/online.json"
    expect(response.status).to eq(403)
  end
end
```

- [ ] **Step 2: Run → FAIL** · **Step 3: Implementatie**

```ruby
def online
  raise Discourse::InvalidAccess unless current_user
  payload = Discourse.cache.fetch("haekelfans_online", expires_in: 60) do
    scope = User.real.activated.where(suspended_till: nil)
      .where("last_seen_at > ?", 10.minutes.ago)
    {
      count: scope.count,
      users: scope.order(last_seen_at: :desc).limit(30)
        .map { |u| { id: u.id, username: u.username, name: u.name,
                     avatar_template: u.avatar_template } },
    }
  end
  render json: payload
end
```

(Cache in de test omzeilen met `Discourse.cache.delete("haekelfans_online")` in een `before`.)

- [ ] **Step 4: Run → PASS** · **Step 5: Commit** (`feat: online endpoint`)

---

### Task 7: Onebox-onderdrukking per bericht (`hf_no_onebox`)

**Files:**
- Modify: `plugin.rb`
- Test: `spec/integration/no_onebox_spec.rb`

**Interfaces:**
- Consumes: composer stuurt `hf_no_onebox: "true"` mee bij `POST /posts` (theme-plan Task 8).
- Produces: post-custom-field `hf_no_onebox` (boolean); bij gezette vlag bevat `post.cooked` na processing géén `aside.onebox`/`a.inline-onebox` meer — links worden platte `<a>`.

- [ ] **Step 1: Falende integratietest**

```ruby
# spec/integration/no_onebox_spec.rb
RSpec.describe "hf_no_onebox" do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }

  it "bewaart de vlag vanuit het create-param en stript oneboxes" do
    post = PostCreator.create!(user,
      title: "Ein Beitrag mit Link",
      raw: "Schau mal https://haekelfans.de hier",
      hf_no_onebox: "true")
    expect(post.custom_fields["hf_no_onebox"]).to eq(true)
    CookedPostProcessor.new(post).post_process
    expect(post.cooked).not_to include("onebox")
    expect(post.cooked).to include(%{<a href="https://haekelfans.de"})
  end
end
```

- [ ] **Step 2: Run → FAIL** · **Step 3: Implementatie** in `after_initialize`:

```ruby
register_post_custom_field_type("hf_no_onebox", :boolean)
add_permitted_post_create_param(:hf_no_onebox)

on(:post_created) do |post, opts, _user|
  if opts[:hf_no_onebox].to_s == "true"
    post.custom_fields["hf_no_onebox"] = true
    post.save_custom_fields
  end
end

on(:post_process_cooked) do |doc, post|
  if post.custom_fields["hf_no_onebox"]
    doc.css("aside.onebox").each do |node|
      href = node.at_css("a")&.[]("href") || node["data-onebox-src"]
      node.replace(%{<p><a href="#{CGI.escapeHTML(href.to_s)}">#{CGI.escapeHTML(href.to_s)}</a></p>}) if href
    end
    doc.css("a.inline-onebox").each { |a| a.remove_attribute("class") }
  end
end
```

- [ ] **Step 4: Run → PASS** · **Step 5: Commit** (`feat: hf_no_onebox vlag onderdrukt link-previews`)

---

### Task 8: README, migratie-notities en eindcontrole

**Files:**
- Create: `haekelfans-timeline/README.md`
- Test: volledige suite

**Interfaces:**
- Produces: installatie-instructies (`git clone` in `/var/discourse` containers/app.yml hooks), en de expliciete migratiestap: **Tlp grid images en Top replies uitschakelen** zodra dit plugin actief is (functioneel overlappend).

- [ ] **Step 1: Schrijf README** met: wat het plugin levert (velden + endpoints uit de Interfaces-blokken hierboven, letterlijk overnemen), settings-tabel, install via app.yml, migratie-sectie ("deactiveer tlp-grid-images en top-replies; data hoeft niet gemigreerd, beide waren read-only caches"), en de wisselwerking met Reactions.
- [ ] **Step 2: Volledige suite:** `LOAD_PLUGINS=1 bundle exec rspec plugins/haekelfans-timeline/spec -f doc` → alles PASS.
- [ ] **Step 3: Handmatige rooktest** in dev (`bin/ember-cli -u`): maak topic met 2 foto's + 3 replies, check `latest.json` bevat `hf_images/hf_replies/hf_reply_total/hf_likers`; check `/haekelfans/topic/<id>/tree.json` en `/haekelfans/online.json` in de browser.
- [ ] **Step 4: Commit** (`docs: README + migratienotities`)
