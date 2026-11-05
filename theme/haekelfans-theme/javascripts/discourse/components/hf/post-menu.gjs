import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import FlagModal from "discourse/components/modal/flag";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import PostFlag from "discourse/lib/flag-targets/post-flag";
import { clipboardCopy } from "discourse/lib/utilities";
import Composer from "discourse/models/composer";
import { i18n } from "discourse-i18n";

// "⋯"-menu bij een bericht of reactie: Bearbeiten, Link kopieren,
// Lesezeichen, Melden, Löschen. Rechten worden server-side afgedwongen;
// hier tonen we alleen wat zinvol is voor de huidige gebruiker.
// Args: @postId, @postNumber, @topicId, @username, @onDeleted
export default class HfPostMenu extends Component {
  @service currentUser;
  @service composer;
  @service modal;
  @service dialog;
  @service store;
  @service toasts;

  @tracked open = false;

  closeOnOutside = modifier((element) => {
    const handler = (event) => {
      if (!element.contains(event.target)) {
        this.open = false;
      }
    };
    document.addEventListener("click", handler, true);
    return () => document.removeEventListener("click", handler, true);
  });

  get canManage() {
    return (
      !!this.currentUser &&
      (this.currentUser.staff || this.currentUser.username === this.args.username)
    );
  }

  get canFlag() {
    return !!this.currentUser && this.currentUser.username !== this.args.username;
  }

  label(key) {
    return i18n(themePrefix(`hf.menu.${key}`));
  }

  get labels() {
    return {
      more: this.label("more"),
      edit: this.label("edit"),
      copy: this.label("copy_link"),
      bookmark: this.label("bookmark"),
      flag: this.label("flag"),
      remove: this.label("delete"),
    };
  }

  async loadPost() {
    const [postJson, topicJson] = await Promise.all([
      ajax(`/posts/${this.args.postId}.json`),
      ajax(`/t/${this.args.topicId}.json`),
    ]);
    const topic = this.store.createRecord("topic", topicJson);
    return this.store.createRecord("post", { ...postJson, topic });
  }

  @action
  toggle(event) {
    event.stopPropagation();
    this.open = !this.open;
  }

  @action
  async edit() {
    this.open = false;
    try {
      const post = await this.loadPost();
      this.composer.open({
        post,
        action: Composer.EDIT,
        draftKey: post.topic.draft_key,
        draftSequence: post.topic.draft_sequence,
        skipJumpOnSave: true,
      });
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  copyLink() {
    this.open = false;
    const url = `${window.location.origin}/t/${this.args.topicId}/${this.args.postNumber}`;
    clipboardCopy(url);
    this.toasts.success({
      duration: "short",
      data: { message: this.label("link_copied") },
    });
  }

  @action
  async bookmark() {
    this.open = false;
    try {
      await ajax("/bookmarks.json", {
        type: "POST",
        data: { bookmarkable_id: this.args.postId, bookmarkable_type: "Post" },
      });
      this.toasts.success({
        duration: "short",
        data: { message: this.label("bookmarked") },
      });
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  async flag() {
    this.open = false;
    try {
      const post = await this.loadPost();
      this.modal.show(FlagModal, {
        model: {
          flagTarget: new PostFlag(),
          flagModel: post,
          setHidden: () => {},
        },
      });
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  remove() {
    this.open = false;
    this.dialog.yesNoConfirm({
      message: this.label("delete_confirm"),
      didConfirm: async () => {
        try {
          await ajax(`/posts/${this.args.postId}`, { type: "DELETE" });
          this.args.onDeleted?.();
        } catch (e) {
          popupAjaxError(e);
        }
      },
    });
  }

  <template>
    {{#if this.currentUser}}
      <div class="hf-post-menu" {{this.closeOnOutside}}>
        <button
          type="button"
          class="hf-post-menu__toggle"
          title={{this.labels.more}}
          aria-label={{this.labels.more}}
          aria-expanded={{if this.open "true" "false"}}
          {{on "click" this.toggle}}
        >{{icon "ellipsis"}}</button>
        {{#if this.open}}
          <div class="hf-post-menu__list" role="menu">
            {{#if this.canManage}}
              <button type="button" role="menuitem" {{on "click" this.edit}}>
                {{icon "pencil"}} {{this.labels.edit}}
              </button>
            {{/if}}
            <button type="button" role="menuitem" {{on "click" this.copyLink}}>
              {{icon "link"}} {{this.labels.copy}}
            </button>
            <button type="button" role="menuitem" {{on "click" this.bookmark}}>
              {{icon "bookmark"}} {{this.labels.bookmark}}
            </button>
            {{#if this.canFlag}}
              <button type="button" role="menuitem" {{on "click" this.flag}}>
                {{icon "flag"}} {{this.labels.flag}}
              </button>
            {{/if}}
            {{#if this.canManage}}
              <button
                type="button"
                role="menuitem"
                class="is-danger"
                {{on "click" this.remove}}
              >
                {{icon "trash-can"}} {{this.labels.remove}}
              </button>
            {{/if}}
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
