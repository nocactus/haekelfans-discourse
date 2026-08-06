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

acceptance("Häkelfans | timeline", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/latest.json", () => helper.response(hfTopicListResponse()));
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
});
