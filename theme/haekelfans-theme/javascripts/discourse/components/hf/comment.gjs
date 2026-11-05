import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { hfAvatarUrl, hfTimeAgo } from "../../lib/hf-format";
import { toggleLike } from "../../lib/hf-like";
import HfPostMenu from "./post-menu";

export default class HfComment extends Component {
  @tracked likeCount = this.args.reply.like_count ?? 0;
  @tracked liked = this.args.reply.current_user_reacted ?? false;

  @action
  async toggleLike() {
    const wasLiked = this.liked;
    this.liked = !wasLiked;
    this.likeCount += wasLiked ? -1 : 1;
    try {
      await toggleLike(this.args.reply.post_id, wasLiked);
    } catch (e) {
      this.liked = wasLiked;
      this.likeCount += wasLiked ? 1 : -1;
      throw e;
    }
  }

  get bodyHtml() {
    // Zowel cooked als excerpt zijn server-side gegenereerde, gesaneerde
    // HTML (excerpt bevat emoji-afbeeldingen en entities zoals &hellip;).
    const html = this.args.reply.cooked || this.args.reply.excerpt;
    return html ? htmlSafe(html) : null;
  }

  get avatarSrc() {
    return hfAvatarUrl(this.args.reply.avatar_template, 30);
  }

  get timeAgo() {
    return hfTimeAgo(this.args.reply.created_at);
  }

  get likeLabel() {
    return i18n(themePrefix("hf.like"));
  }

  get answerLabel() {
    return i18n(themePrefix("hf.answer"));
  }

  <template>
    <div class="hf-comment" data-hf-post-number={{@reply.post_number}}>
      <div class="hf-comment__avatar">
        <img src={{this.avatarSrc}} alt="" loading="lazy" />
      </div>
      <div class="hf-comment__body">
        <div class="hf-comment__bubble">
          <span class="hf-comment__name">{{if @reply.name @reply.name @reply.username}}</span>
          {{#if this.bodyHtml}}
            <div class="hf-comment__text">{{this.bodyHtml}}</div>
          {{/if}}
          {{#if this.likeCount}}
            <span class="hf-comment__likepill">{{icon "heart"}} {{this.likeCount}}</span>
          {{/if}}
        </div>
        <div class="hf-comment__meta">
          <button
            type="button"
            class="hf-comment__like {{if this.liked 'is-liked'}}"
            {{on "click" this.toggleLike}}
          >{{this.likeLabel}}</button>
          {{#if @onAnswer}}
            <button
              type="button"
              class="hf-comment__answer"
              {{on "click" (fn @onAnswer @reply)}}
            >{{this.answerLabel}}</button>
          {{/if}}
          <span class="hf-comment__time">{{this.timeAgo}}</span>
          {{#if @topicId}}
            <HfPostMenu
              @postId={{@reply.post_id}}
              @postNumber={{@reply.post_number}}
              @topicId={{@topicId}}
              @username={{@reply.username}}
              @onDeleted={{@onDeleted}}
            />
          {{/if}}
        </div>
        {{yield}}
      </div>
    </div>
  </template>
}
