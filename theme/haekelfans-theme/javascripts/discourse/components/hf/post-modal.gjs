import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { modifier } from "ember-modifier";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { hfAvatarUrl, hfTimeAgo } from "../../lib/hf-format";
import HfPostView from "./post-view";

export default class HfPostModal extends Component {
  // Achtergrond niet laten meescrollen zolang de modal open is.
  lockScroll = modifier(() => {
    document.documentElement.classList.add("hf-modal-open");
    return () => document.documentElement.classList.remove("hf-modal-open");
  });

  @action
  deleted() {
    this.args.onDeleted?.();
  }

  escape = modifier(() => {
    const handler = (event) => {
      if (event.key === "Escape") {
        this.args.onClose?.();
      }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  });

  get topic() {
    return this.args.topic;
  }

  get poster() {
    const posters = this.topic.posters ?? [];
    const op =
      posters.find((p) => (p.description || "").includes("Original")) ?? posters[0];
    return op?.user ?? null;
  }

  get titleLabel() {
    return i18n(themePrefix("hf.modal.title"), {
      name: this.poster?.name || this.poster?.username || "",
    });
  }

  get posterAvatarSrc() {
    return hfAvatarUrl(this.poster?.avatar_template, 34);
  }

  get timeAgo() {
    return hfTimeAgo(this.topic.created_at ?? this.topic.createdAt);
  }

  get postData() {
    return {
      id: this.topic.id,
      title: this.topic.title,
      images: this.topic.hf_images ?? [],
      likers: this.topic.hf_likers,
      reply_total: this.topic.hf_reply_total ?? 0,
      first_post_id: this.topic.hf_first_post_id,
    };
  }

  @action
  backdropClick(event) {
    if (event.target === event.currentTarget) {
      this.args.onClose?.();
    }
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div
      class="hf-post-modal"
      {{this.escape}}
      {{this.lockScroll}}
      {{on "click" this.backdropClick}}
    >
      <div class="hf-post-modal__dialog hf-card">
        <header class="hf-post-modal__head">
          <img class="hf-post-modal__avatar" src={{this.posterAvatarSrc}} alt="" />
          <div class="hf-post-modal__who">
            <b>{{this.titleLabel}}</b>
            <span class="hf-post-modal__time">{{this.timeAgo}}</span>
          </div>
          <button
            type="button"
            class="hf-post-modal__close"
            {{on "click" @onClose}}
          >{{icon "xmark"}}</button>
        </header>
        <h2 class="hf-post-modal__title">{{this.topic.title}}</h2>
        <HfPostView
          @postData={{this.postData}}
          @authorUsername={{this.poster.username}}
          @onDeleted={{this.deleted}}
        />
      </div>
    </div>
  </template>
}
