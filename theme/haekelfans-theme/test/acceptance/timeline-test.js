import { click, triggerKeyEvent, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import topicFixtures from "discourse/tests/fixtures/discovery-fixtures";

export function hfTopicListResponse() {
  const list = structuredClone(topicFixtures["/latest.json"]);
  const t = list.topic_list.topics[0];
  t.title = "Decke gehäkelt";
  t.hf_first_post_id = 101;
  t.hf_images = [1, 2, 3, 4, 5, 6].map((n) => ({
    url: `/images/d${n}.jpg`,
    thumb_url: `/images/d${n}.jpg`,
    width: 1200,
    height: 800,
  }));
  t.hf_reply_total = 3;
  t.hf_likers = { names: ["Karin", "Brenda"], count: 5, current_user_liked: false };
  t.hf_replies = [
    {
      post_id: 11,
      post_number: 3,
      reply_to_post_number: null,
      username: "marga",
      name: "Marga de Boer",
      avatar_template: "/letter_avatar_proxy/v4/letter/m/aaaaaa/{size}.png",
      excerpt: "Das wird schon toll!",
      created_at: "2026-08-01T10:00:00Z",
      like_count: 1,
      current_user_reacted: false,
    },
  ];
  return list;
}

export function hfTreeResponse(topicId) {
  return {
    topic_id: topicId,
    total: 1,
    page: 0,
    per_page: 50,
    replies: [
      {
        post_id: 11,
        post_number: 3,
        reply_to_post_number: null,
        username: "marga",
        name: "Marga de Boer",
        avatar_template: "/letter_avatar_proxy/v4/letter/m/aaaaaa/{size}.png",
        cooked: "<p>Das wird schon toll!</p>",
        created_at: "2026-08-01T10:00:00Z",
        like_count: 1,
        current_user_reacted: false,
        children: [
          {
            post_id: 12,
            post_number: 4,
            reply_to_post_number: 3,
            username: "ramona",
            name: "Ramona Klein",
            avatar_template: "/letter_avatar_proxy/v4/letter/r/bbbbbb/{size}.png",
            cooked: "<p>Danke Marga!</p>",
            created_at: "2026-08-02T10:00:00Z",
            like_count: 0,
            current_user_reacted: false,
            children: [],
          },
        ],
      },
    ],
  };
}

acceptance("Häkelfans | timeline", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/latest.json", () => helper.response(hfTopicListResponse()));
    server.get("/haekelfans/topic/:id/tree.json", (request) =>
      helper.response(hfTreeResponse(parseInt(request.params.id, 10)))
    );
    server.get("/t/:id.json", (request) =>
      helper.response({
        id: parseInt(request.params.id, 10),
        title: "Decke gehäkelt",
        post_stream: {
          posts: [
            {
              id: 101,
              post_number: 1,
              cooked: "<p>Endlich ist meine Decke fertig.</p>",
            },
          ],
        },
      })
    );
  });

  test("toont tijdlijnkaarten in plaats van de topiclijst", async function (assert) {
    await visit("/latest");
    assert.dom(".hf-post-card").exists("tijdlijnkaart wordt gerenderd");
    assert.dom(".topic-list").doesNotExist("standaard topiclijst is vervangen");
    assert
      .dom(".hf-post-card .hf-post-card__title")
      .hasText("Decke gehäkelt", "titel op de kaart");
  });

  test("kaart toont likers, replies en reactieveld", async function (assert) {
    await visit("/latest");
    const card = ".hf-post-card:nth-of-type(1)";
    assert.dom(`${card} .hf-social__likers`).includesText("Karin");
    assert.dom(`${card} .hf-comment`).exists({ count: 1 });
    assert.dom(`${card} .hf-comment-box textarea`).exists();
    assert.dom(`${card} .hf-view-all`).includesText("3");
    assert.dom(`${card} .hf-post-card__gallery img`).exists();
  });

  test("masonry-galerij met +N-overlay en lightbox", async function (assert) {
    await visit("/latest");
    const gallery = ".hf-post-card:nth-of-type(1) .hf-gallery";
    assert.dom(`${gallery} .hf-gallery__cell`).exists({ count: 5 }, "max 5 tegels");
    assert.dom(`${gallery} .hf-gallery__more`).hasText("+1", "overlay toont rest");
    await click(`${gallery} .hf-gallery__cell:nth-child(1)`);
    assert.dom(".hf-lightbox").exists("lightbox opent");
    assert.dom(".hf-lightbox__count").includesText("1 / 6");
    await triggerKeyEvent(document.body, "keydown", "ArrowRight");
    assert.dom(".hf-lightbox__count").includesText("2 / 6", "pijl navigeert");
    await triggerKeyEvent(document.body, "keydown", "Escape");
    assert.dom(".hf-lightbox").doesNotExist("Esc sluit");
  });

  test("topic-deeplink rendert kaartweergave", async function (assert) {
    await visit("/t/internationalization-localization/280");
    assert.dom(".hf-topic-view").exists("kaartweergave op topic-route");
    assert.dom(".hf-topic-view .hf-post-view").exists("post-view geladen");
    assert
      .dom(".hf-topic-view__back")
      .exists("terugknop naar de tijdlijn aanwezig");
  });

  test("berichtmodal toont volledige boom met uitklapbare niveaus", async function (assert) {
    await visit("/latest");
    await click(".hf-post-card:nth-of-type(1) .hf-view-all");
    assert.dom(".hf-post-modal").exists("modal opent");
    assert.dom(".hf-post-modal .hf-comment").exists({ count: 1 }, "niveau 1 zichtbaar");
    assert
      .dom(".hf-post-modal .hf-tree-node__more")
      .includesText("1", "toggle voor 1 antwoord");
    await click(".hf-post-modal .hf-tree-node__more");
    assert
      .dom(".hf-post-modal .hf-comment")
      .exists({ count: 2 }, "niveau 2 uitgeklapt");
    await click(".hf-post-modal__close");
    assert.dom(".hf-post-modal").doesNotExist("modal sluit");
  });
});
