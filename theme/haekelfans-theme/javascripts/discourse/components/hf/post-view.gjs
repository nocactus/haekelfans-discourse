import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { htmlSafe } from "@ember/template";
import { modifier } from "ember-modifier";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import HfCommentBox from "./comment-box";
import HfGallery from "./gallery";
import HfTreeNode from "./tree-node";

// Volledige weergave van één bericht + reply-boom. Gebruikt in de
// berichtmodal en (Task 7) op de topic-pagina voor deeplinks.
// @postData: { id, title, images, likers, reply_total, first_post_id, excerpt? }
export default class HfPostView extends Component {
  @tracked tree = null;
  @tracked cooked = null;
  @tracked extraRoots = [];
  @tracked page = 0;

  load = modifier(() => {
    this.fetchAll();
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
    this.cooked = topicJson?.post_stream?.posts?.[0]?.cooked ?? null;
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
      {{#if this.cookedHtml}}
        <div class="hf-post-view__body">{{this.cookedHtml}}</div>
      {{/if}}

      {{#if this.postData.images.length}}
        <HfGallery @images={{this.postData.images}} @title={{this.postData.title}} />
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
