import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import { hfAvatarUrl, hfTimeAgo } from "../../lib/hf-format";
import { toggleLike } from "../../lib/hf-like";
import HfComment from "./comment";
import HfCommentBox from "./comment-box";
import HfGallery from "./gallery";

export default class HfPostCard extends Component {
  @tracked expanded = false;
  @tracked fullCooked = null;
  @tracked liked = this.args.topic.hf_likers?.current_user_liked ?? false;
  @tracked likeCount = this.args.topic.hf_likers?.count ?? 0;
  @tracked extraReplies = [];
  @tracked replyTotal = this.args.topic.hf_reply_total ?? 0;

  get topic() {
    return this.args.topic;
  }

  get poster() {
    const posters = this.topic.posters ?? [];
    const op =
      posters.find((p) => (p.description || "").includes("Original")) ?? posters[0];
    return op?.user ?? null;
  }

  get category() {
    return this.topic.category;
  }

  get posterAvatarSrc() {
    return hfAvatarUrl(this.poster?.avatar_template, 38);
  }

  get timeAgo() {
    return hfTimeAgo(this.topic.created_at ?? this.topic.createdAt);
  }

  get excerptHtml() {
    if (this.expanded && this.fullCooked) {
      return htmlSafe(this.fullCooked);
    }
    return this.topic.excerpt ? htmlSafe(this.topic.excerpt) : null;
  }

  get images() {
    return this.topic.hf_images ?? [];
  }

  get replies() {
    const base = this.topic.hf_replies ?? [];
    return [...base, ...this.extraReplies];
  }

  get likersLabel() {
    const likers = this.topic.hf_likers;
    if (!likers || likers.count === 0) {
      return null;
    }
    const names = (likers.names ?? []).join(", ");
    const rest = this.likeCount - (likers.names?.length ?? 0);
    if (rest > 0) {
      return i18n(themePrefix("hf.likers_summary"), { names, count: rest });
    }
    return i18n(themePrefix("hf.likers_names_only"), { names });
  }

  get showViewAll() {
    return this.replyTotal > this.replies.length;
  }

  get weiterlesenLabel() {
    return i18n(themePrefix("hf.weiterlesen"));
  }

  get likeLabel() {
    return i18n(themePrefix("hf.like"));
  }

  get replyLabel() {
    return i18n(themePrefix("hf.reply"));
  }

  get reactionCountLabel() {
    return i18n(themePrefix("hf.reaction_count"), { count: this.replyTotal });
  }

  get viewAllLabel() {
    return i18n(themePrefix("hf.view_all_replies"), { count: this.replyTotal });
  }

  @action
  async expand() {
    this.expanded = true;
    if (!this.fullCooked) {
      const data = await ajax(`/t/${this.topic.id}.json`);
      this.fullCooked = data?.post_stream?.posts?.[0]?.cooked ?? null;
    }
  }

  @action
  async toggleTopicLike() {
    const wasLiked = this.liked;
    this.liked = !wasLiked;
    this.likeCount += wasLiked ? -1 : 1;
    try {
      await toggleLike(this.topic.hf_first_post_id, wasLiked);
    } catch (e) {
      this.liked = wasLiked;
      this.likeCount += wasLiked ? 1 : -1;
      throw e;
    }
  }

  @action
  onPosted(post) {
    this.extraReplies = [
      ...this.extraReplies,
      {
        post_id: post.id,
        post_number: post.post_number,
        reply_to_post_number: post.reply_to_post_number,
        username: post.username,
        name: post.name,
        avatar_template: post.avatar_template,
        excerpt: post.cooked?.replace(/<[^>]+>/g, "").slice(0, 200),
        created_at: post.created_at,
        like_count: 0,
        current_user_reacted: false,
      },
    ];
    this.replyTotal += 1;
  }

  @action
  openModal() {
    this.args.onOpen?.(this.topic);
  }

  <template>
    <article class="hf-post-card hf-card">
      <header class="hf-post-card__head">
        <div class="hf-post-card__avatar">
          {{#if this.poster}}
            <img src={{this.posterAvatarSrc}} alt="" loading="lazy" />
          {{/if}}
        </div>
        <div class="hf-post-card__who">
          <span class="hf-post-card__name">
            {{#if this.poster.name}}{{this.poster.name}}{{else}}{{this.poster.username}}{{/if}}
          </span>
          <span class="hf-post-card__time">{{this.timeAgo}}</span>
        </div>
        {{#if this.category}}
          <a class="hf-post-card__cat" href="/c/{{this.category.slug}}/{{this.category.id}}">
            {{this.category.name}}
          </a>
        {{/if}}
      </header>

      <h2 class="hf-post-card__title">
        <button type="button" {{on "click" this.openModal}}>{{@topic.title}}</button>
      </h2>

      {{#if this.excerptHtml}}
        <div class="hf-post-card__text {{if this.expanded 'is-expanded'}}">
          {{this.excerptHtml}}
          {{#unless this.expanded}}
            {{#if @topic.excerptTruncated}}
              <button
                type="button"
                class="hf-post-card__more"
                {{on "click" this.expand}}
              >{{this.weiterlesenLabel}}</button>
            {{/if}}
          {{/unless}}
        </div>
      {{/if}}

      {{#if this.images.length}}
        <div class="hf-post-card__gallery">
          <HfGallery @images={{this.images}} @title={{@topic.title}} />
        </div>
      {{/if}}

      {{#if @topic.tags.length}}
        <div class="hf-post-card__tags">
          {{#each @topic.tags as |tag|}}
            <a class="hf-tag" href="/tag/{{tag}}">{{tag}}</a>
          {{/each}}
        </div>
      {{/if}}

      <div class="hf-social">
        <span class="hf-social__likers">
          {{#if this.likersLabel}}
            <span class="hf-social__heart">♥</span>
            {{this.likersLabel}}
          {{/if}}
        </span>
        <span class="hf-social__count">
          {{#if this.replyTotal}}
            {{this.reactionCountLabel}}
          {{/if}}
        </span>
      </div>

      <div class="hf-actions">
        <button
          type="button"
          class="hf-actions__like {{if this.liked 'is-liked'}}"
          {{on "click" this.toggleTopicLike}}
        >♥ {{this.likeLabel}}</button>
        <button
          type="button"
          class="hf-actions__reply"
          {{on "click" this.openModal}}
        >💬 {{this.replyLabel}}</button>
      </div>

      {{#if this.replies.length}}
        <div class="hf-post-card__comments">
          {{#each this.replies as |reply|}}
            <HfComment @reply={{reply}} />
          {{/each}}
          {{#if this.showViewAll}}
            <button type="button" class="hf-view-all" {{on "click" this.openModal}}>
              ↳ {{this.viewAllLabel}}
            </button>
          {{/if}}
        </div>
      {{/if}}

      <HfCommentBox @topicId={{@topic.id}} @onPosted={{this.onPosted}} />
    </article>
  </template>
}
