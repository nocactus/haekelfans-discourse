import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import { hfAvatarUrl, hfTimeAgo } from "../../lib/hf-format";
import HfComment from "./comment";
import HfCommentBox from "./comment-box";
import HfGallery from "./gallery";
import HfPostMenu from "./post-menu";
import HfSocialActions from "./social-actions";

const eq = (a, b) => a === b;

export default class HfPostCard extends Component {
  @tracked expanded = false;
  @tracked fullCooked = null;
  @tracked extraReplies = [];
  @tracked replyTotal = this.args.topic.hf_reply_total ?? 0;
  @tracked answeringPostNumber = null;

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
    // Discourse bewaart emoji in de topic-excerpt als ":ghost:"-tekst;
    // escapedExcerpt (Topic-model) zet die om naar emoji-afbeeldingen.
    const excerpt = this.topic.escapedExcerpt ?? this.topic.excerpt;
    return excerpt ? htmlSafe(excerpt) : null;
  }

  get images() {
    return this.topic.hf_images ?? [];
  }

  get tagNames() {
    // Afhankelijk van Discourse-versie zijn tags strings of objecten.
    return (this.topic.tags ?? [])
      .map((t) => (typeof t === "string" ? t : t?.name))
      .filter(Boolean);
  }

  get replies() {
    const base = this.topic.hf_replies ?? [];
    return [...base, ...this.extraReplies];
  }

  get showViewAll() {
    return this.replyTotal > this.replies.length;
  }

  get weiterlesenLabel() {
    return i18n(themePrefix("hf.weiterlesen"));
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
  onPosted(post) {
    this.extraReplies = [
      ...this.extraReplies,
      {
        post_id: post.id,
        post_number: post.post_number,
        reply_to_post_number: post.reply_to_post_number,
        reply_to_name: post.reply_to_user?.name || post.reply_to_user?.username,
        username: post.username,
        name: post.name,
        avatar_template: post.avatar_template,
        cooked: post.cooked,
        created_at: post.created_at,
        like_count: 0,
        current_user_reacted: false,
      },
    ];
    this.replyTotal += 1;
    this.answeringPostNumber = null;
  }

  @action
  toggleAnswer(reply) {
    this.answeringPostNumber =
      this.answeringPostNumber === reply.post_number ? null : reply.post_number;
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
            <a
              href="/u/{{this.poster.username}}"
              data-user-card={{this.poster.username}}
              tabindex="-1"
            ><img src={{this.posterAvatarSrc}} alt="" loading="lazy" /></a>
          {{/if}}
        </div>
        <div class="hf-post-card__who">
          <a
            class="hf-post-card__name"
            href="/u/{{this.poster.username}}"
            data-user-card={{this.poster.username}}
          >
            {{#if this.poster.name}}{{this.poster.name}}{{else}}{{this.poster.username}}{{/if}}
          </a>
          <span class="hf-post-card__time">{{this.timeAgo}}</span>
        </div>
        {{#if this.category}}
          <a class="hf-post-card__cat" href="/c/{{this.category.slug}}/{{this.category.id}}">
            {{this.category.name}}
          </a>
        {{/if}}
        {{#if @topic.hf_first_post_id}}
          <div class="hf-post-card__menu">
            <HfPostMenu
              @postId={{@topic.hf_first_post_id}}
              @postNumber={{1}}
              @topicId={{@topic.id}}
              @username={{this.poster.username}}
              @onDeleted={{@onDeleted}}
            />
          </div>
        {{/if}}
      </header>

      <h2 class="hf-post-card__title">
        <button type="button" {{on "click" this.openModal}}>{{@topic.title}}</button>
      </h2>

      {{#if this.excerptHtml}}
        <div
          class="hf-post-card__text
            {{if this.expanded 'is-expanded'}}
            {{if this.images.length 'has-gallery'}}"
        >
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

      {{#if this.tagNames.length}}
        <div class="hf-post-card__tags">
          {{#each this.tagNames as |tag|}}
            <a class="hf-tag" href="/tag/{{tag}}">{{tag}}</a>
          {{/each}}
        </div>
      {{/if}}

      <HfSocialActions
        @postId={{@topic.hf_first_post_id}}
        @likers={{@topic.hf_likers}}
        @replyTotal={{this.replyTotal}}
        @onReply={{this.openModal}}
      />

      {{#if this.replies.length}}
        <div class="hf-post-card__comments">
          {{#each this.replies as |reply|}}
            <HfComment @reply={{reply}} @onAnswer={{this.toggleAnswer}}>
              {{#if (eq this.answeringPostNumber reply.post_number)}}
                <HfCommentBox
                  @topicId={{@topic.id}}
                  @replyToPostNumber={{reply.post_number}}
                  @onPosted={{this.onPosted}}
                />
              {{/if}}
            </HfComment>
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
