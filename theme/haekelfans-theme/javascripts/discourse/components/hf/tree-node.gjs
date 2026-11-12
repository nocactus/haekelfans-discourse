import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { i18n } from "discourse-i18n";
import HfComment from "./comment";
import HfCommentBox from "./comment-box";

// Recursieve knoop in de reply-boom. Alle niveaus staan standaard open
// (leden verwachten bij "Alle N Reaktionen ansehen" ook echt alles te zien).
export default class HfTreeNode extends Component {
  @tracked expanded = true;
  @tracked replying = false;
  @tracked extraChildren = [];
  @tracked deleted = false;

  get children() {
    return [...(this.args.node.children ?? []), ...this.extraChildren];
  }

  get moreLabel() {
    return i18n(themePrefix("hf.view_more_answers"), {
      count: this.children.length,
    });
  }

  @action
  markDeleted() {
    this.deleted = true;
  }

  @action
  toggleExpanded() {
    this.expanded = !this.expanded;
  }

  @action
  toggleReplying() {
    this.replying = !this.replying;
  }

  @action
  addChild(post) {
    this.extraChildren = [
      ...this.extraChildren,
      {
        post_id: post.id,
        post_number: post.post_number,
        reply_to_post_number: post.reply_to_post_number,
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
    this.expanded = true;
    this.replying = false;
  }

  <template>
    {{#unless this.deleted}}
    <div class="hf-tree-node">
      <HfComment
        @reply={{@node}}
        @topicId={{@topicId}}
        @onDeleted={{this.markDeleted}}
        @onAnswer={{this.toggleReplying}}
      >
        {{#if this.replying}}
          <HfCommentBox
            @topicId={{@topicId}}
            @replyToPostNumber={{@node.post_number}}
            @onPosted={{this.addChild}}
          />
        {{/if}}
      </HfComment>

      {{#if this.children.length}}
        <div class="hf-tree-node__children">
          {{#if this.expanded}}
            {{#each this.children as |child|}}
              <HfTreeNode @node={{child}} @topicId={{@topicId}} />
            {{/each}}
          {{else}}
            <button
              type="button"
              class="hf-tree-node__more"
              {{on "click" this.toggleExpanded}}
            >↳ {{this.moreLabel}}</button>
          {{/if}}
        </div>
      {{/if}}
    </div>
    {{/unless}}
  </template>
}
