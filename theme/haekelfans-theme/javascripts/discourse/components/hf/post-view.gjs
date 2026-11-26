import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { modifier } from "ember-modifier";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import HfCommentBox from "./comment-box";
import HfGallery from "./gallery";
import HfPostMenu from "./post-menu";
import HfSocialActions from "./social-actions";
import HfTreeNode from "./tree-node";

// Volledige weergave van één bericht + reply-boom. Gebruikt in de
// berichtmodal en (Task 7) op de topic-pagina voor deeplinks.
// @postData: { id, title, images, likers?, reply_total, first_post_id, excerpt? }
// likers ontbreekt bij een deeplink; dan halen we ze zelf op (fetchLikers).
export default class HfPostView extends Component {
  @tracked tree = null;
  @tracked cooked = null;
  @tracked extraRoots = [];
  @tracked page = 0;
  // Modal: likers uit de topiclijst als beginwaarde; deeplink: pas na het laden.
  @tracked likers = this.args.postData.likers ?? null;
  @tracked loadedFirstPostId = null;

  @service appEvents;
  @service currentUser;

  load = modifier((element) => {
    this.element = element;
    this.fetchAll();
    const refresh = () => this.fetchAll();
    this.appEvents.on("composer:edited-post", refresh);
    return () => this.appEvents.off("composer:edited-post", refresh);
  });

  get postData() {
    return this.args.postData;
  }

  get roots() {
    return [...(this.tree?.replies ?? []), ...this.extraRoots];
  }

  get canLoadMore() {
    return this.tree && this.tree.total > this.tree.per_page * (this.page + 1);
  }

  get loadMoreLabel() {
    return i18n(themePrefix("hf.modal.load_more"));
  }

  get firstPostId() {
    return this.postData.first_post_id ?? this.loadedFirstPostId;
  }

  get replyTotal() {
    return (this.postData.reply_total ?? 0) + this.extraRoots.length;
  }

  get cookedHtml() {
    return this.cooked ? htmlSafe(this.cooked) : null;
  }

  async fetchAll() {
    const id = this.postData.id;
    const [tree, topicJson] = await Promise.all([
      ajax(`/haekelfans/topic/${id}/tree.json`),
      ajax(`/t/${id}.json`).catch(() => null),
    ]);
    this.tree = tree;
    const firstPost = topicJson?.post_stream?.posts?.[0];
    this.cooked = firstPost?.cooked ?? null;
    this.loadedFirstPostId = firstPost?.id ?? null;
    this.highlight();
    await this.fetchLikers();
  }

  // Zelfde vorm als hf_likers uit de plugin (topiclijst): eerste twee namen
  // in volgorde van liken, totaal, en of de huidige gebruiker geliket heeft.
  async fetchLikers() {
    const postId = this.firstPostId;
    if (!postId) {
      return;
    }
    const data = await ajax("/post_action_users.json", {
      data: { id: postId, post_action_type_id: 2 },
    }).catch(() => null);
    const users = data?.post_action_users;
    if (!users) {
      return;
    }
    this.likers = {
      names: users.slice(0, 2).map((u) => u.name || u.username),
      count: data.total_rows_post_action_users ?? users.length,
      current_user_liked: users.some((u) => u.id === this.currentUser?.id),
    };
  }

  focusCommentBox = () => {
    this.element
      ?.querySelector(":scope > .hf-comment-box textarea")
      ?.focus();
  };

  highlight() {
    const number = this.args.highlightPostNumber;
    if (!number) {
      return;
    }
    requestAnimationFrame(() => {
      const el = document.querySelector(`[data-hf-post-number="${number}"]`);
      if (el) {
        el.scrollIntoView({ block: "center" });
        el.classList.add("is-highlighted");
      }
    });
  }

  loadMore = async () => {
    this.page += 1;
    const next = await ajax(
      `/haekelfans/topic/${this.postData.id}/tree.json?page=${this.page}`
    );
    this.tree = {
      ...this.tree,
      replies: [...this.tree.replies, ...next.replies],
    };
  };

  addRoot = (post) => {
    this.extraRoots = [
      ...this.extraRoots,
      {
        post_id: post.id,
        post_number: post.post_number,
        reply_to_post_number: null,
        username: post.username,
        name: post.name,
        avatar_template: post.avatar_template,
        cooked: post.cooked,
        created_at: post.created_at,
        like_count: 0,
        current_user_reacted: false,
        children: [],
      },
    ];
  };

  <template>
    <div class="hf-post-view" {{this.load}}>
      {{#if this.postData.first_post_id}}
        <div class="hf-post-view__menu">
          <HfPostMenu
            @postId={{this.postData.first_post_id}}
            @postNumber={{1}}
            @topicId={{this.postData.id}}
            @username={{@authorUsername}}
            @onDeleted={{@onDeleted}}
          />
        </div>
      {{/if}}
      {{#if this.cookedHtml}}
        <div
          class="hf-post-view__body
            {{if this.postData.images.length 'has-gallery'}}"
        >{{this.cookedHtml}}</div>
      {{/if}}

      {{#if this.postData.images.length}}
        <HfGallery @images={{this.postData.images}} @title={{this.postData.title}} />
      {{/if}}

      {{#if this.firstPostId}}
        <HfSocialActions
          @postId={{this.firstPostId}}
          @likers={{this.likers}}
          @replyTotal={{this.replyTotal}}
          @onReply={{this.focusCommentBox}}
        />
      {{/if}}

      <div class="hf-post-view__comments">
        {{#each this.roots as |node|}}
          <HfTreeNode @node={{node}} @topicId={{this.postData.id}} />
        {{/each}}
        {{#if this.canLoadMore}}
          <button type="button" class="hf-post-view__more" {{on "click" this.loadMore}}>
            {{this.loadMoreLabel}}
          </button>
        {{/if}}
      </div>

      <HfCommentBox @topicId={{this.postData.id}} @onPosted={{this.addRoot}} />
    </div>
  </template>
}
