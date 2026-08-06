import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import { hfAvatarUrl } from "../../lib/hf-format";

export default class HfCommentBox extends Component {
  @service currentUser;

  @tracked value = "";
  @tracked busy = false;
  @tracked error = null;

  get avatarSrc() {
    return hfAvatarUrl(this.currentUser?.avatar_template, 30);
  }

  get placeholderText() {
    return i18n(themePrefix("hf.comment_placeholder"));
  }

  get sendTitle() {
    return i18n(themePrefix("hf.reply"));
  }

  @action
  updateValue(event) {
    this.value = event.target.value;
  }

  @action
  async submit(event) {
    event?.preventDefault();
    const raw = this.value.trim();
    if (!raw || this.busy) {
      return;
    }
    this.busy = true;
    this.error = null;
    try {
      const post = await ajax("/posts.json", {
        type: "POST",
        data: {
          topic_id: this.args.topicId,
          raw,
          reply_to_post_number: this.args.replyToPostNumber ?? undefined,
        },
      });
      this.value = "";
      this.args.onPosted?.(post);
    } catch (e) {
      this.error = i18n(themePrefix("hf.composer.error_generic"));
      throw e;
    } finally {
      this.busy = false;
    }
  }

  @action
  onKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      this.submit();
    }
  }

  <template>
    <form class="hf-comment-box" {{on "submit" this.submit}}>
      {{#if this.currentUser}}
        <div class="hf-comment-box__avatar">
          <img src={{this.avatarSrc}} alt="" loading="lazy" />
        </div>
      {{/if}}
      <div class="hf-comment-box__field">
        <textarea
          rows="1"
          placeholder={{this.placeholderText}}
          value={{this.value}}
          disabled={{this.busy}}
          {{on "input" this.updateValue}}
          {{on "keydown" this.onKeydown}}
        ></textarea>
        <button
          type="submit"
          class="hf-comment-box__send"
          disabled={{this.busy}}
          title={{this.sendTitle}}
        >➤</button>
      </div>
      {{#if this.error}}
        <p class="hf-comment-box__error">{{this.error}}</p>
      {{/if}}
    </form>
  </template>
}
