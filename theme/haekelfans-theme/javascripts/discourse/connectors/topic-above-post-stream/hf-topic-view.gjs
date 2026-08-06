import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import HfPostView from "../../components/hf/post-view";
import { hfAvatarUrl, hfTimeAgo } from "../../lib/hf-format";

// Deeplinks (/t/…): rendert het bericht in dezelfde kaartweergave als de
// modal; de standaard post-stream wordt via CSS verborgen (topic.scss).
export default class HfTopicView extends Component {
  @service router;

  get model() {
    return this.args.outletArgs.model;
  }

  get isRegularTopic() {
    return this.model?.archetype === "regular";
  }

  get creator() {
    return this.model?.details?.created_by;
  }

  get avatarSrc() {
    return hfAvatarUrl(this.creator?.avatar_template, 38);
  }

  get timeAgo() {
    return hfTimeAgo(this.model?.created_at);
  }

  get backLabel() {
    return i18n(themePrefix("hf.modal.back_to_timeline"));
  }

  get highlightPostNumber() {
    const match = this.router.currentURL?.match(/\/t\/[^/]+\/\d+\/(\d+)/);
    return match ? parseInt(match[1], 10) : null;
  }

  get postData() {
    return {
      id: this.model.id,
      title: this.model.title,
      images: this.model.hf_images ?? [],
      first_post_id: this.model.hf_first_post_id,
      reply_total: Math.max(0, (this.model.posts_count ?? 1) - 1),
    };
  }

  <template>
    {{#if this.isRegularTopic}}
      <div class="hf-topic-view">
        <a class="hf-topic-view__back" href="/latest?order=created">
          ← {{this.backLabel}}
        </a>
        <article class="hf-card">
          <header class="hf-post-card__head">
            <div class="hf-post-card__avatar">
              <img src={{this.avatarSrc}} alt="" />
            </div>
            <div class="hf-post-card__who">
              <span class="hf-post-card__name">
                {{#if this.creator.name}}{{this.creator.name}}{{else}}{{this.creator.username}}{{/if}}
              </span>
              <span class="hf-post-card__time">{{this.timeAgo}}</span>
            </div>
          </header>
          <h2 class="hf-post-modal__title">{{this.model.title}}</h2>
          <HfPostView
            @postData={{this.postData}}
            @highlightPostNumber={{this.highlightPostNumber}}
          />
        </article>
      </div>
    {{/if}}
  </template>
}
