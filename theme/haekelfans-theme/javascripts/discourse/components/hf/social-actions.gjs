import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { toggleLike } from "../../lib/hf-like";

// Likers-regel ("X, Y und 3 anderen gefällt das" + aantal reacties) en de
// knoppen "Gefällt mir" / "Reaktion" onder een bericht. Gebruikt op de
// tijdlijnkaart, in de berichtmodal en op de topic-pagina (deeplink).
// @postId: eerste post van het topic (doel van de like)
// @likers: { names, count, current_user_liked }
// @replyTotal: aantal reacties
// @onReply: actie voor de knop "Reaktion"
export default class HfSocialActions extends Component {
  // Eigen like-klik. Geldt alleen zolang @likers niet opnieuw geladen is;
  // komt er verse data binnen, dan wint die.
  @tracked local = null;

  get state() {
    const likers = this.args.likers;
    if (this.local && this.local.likers === likers) {
      return this.local;
    }
    return {
      liked: likers?.current_user_liked ?? false,
      count: likers?.count ?? 0,
    };
  }

  get likeIcon() {
    return this.state.liked ? "heart" : "far-heart";
  }

  get likersLabel() {
    const likers = this.args.likers;
    if (!likers?.count || this.state.count === 0) {
      return null;
    }
    const names = (likers.names ?? []).join(", ");
    const rest = this.state.count - (likers.names?.length ?? 0);
    if (rest > 0) {
      return i18n(themePrefix("hf.likers_summary"), { names, count: rest });
    }
    return i18n(themePrefix("hf.likers_names_only"), { names });
  }

  get reactionCountLabel() {
    return i18n(themePrefix("hf.reaction_count"), { count: this.args.replyTotal });
  }

  get likeLabel() {
    return i18n(themePrefix("hf.like"));
  }

  get replyLabel() {
    return i18n(themePrefix("hf.reply"));
  }

  @action
  async toggle() {
    const likers = this.args.likers;
    const before = this.state;
    this.local = {
      likers,
      liked: !before.liked,
      count: before.count + (before.liked ? -1 : 1),
    };
    try {
      await toggleLike(this.args.postId, before.liked);
    } catch (e) {
      this.local = { likers, ...before };
      throw e;
    }
  }

  <template>
    <div class="hf-social">
      <span class="hf-social__likers">
        {{#if this.likersLabel}}
          <span class="hf-social__heart">{{icon "heart"}}</span>
          {{this.likersLabel}}
        {{/if}}
      </span>
      <span class="hf-social__count">
        {{#if @replyTotal}}
          {{this.reactionCountLabel}}
        {{/if}}
      </span>
    </div>

    <div class="hf-actions">
      <button
        type="button"
        class="hf-actions__like {{if this.state.liked 'is-liked'}}"
        {{on "click" this.toggle}}
      >{{icon this.likeIcon}} {{this.likeLabel}}</button>
      <button
        type="button"
        class="hf-actions__reply"
        {{on "click" @onReply}}
      >{{icon "far-comment"}} {{this.replyLabel}}</button>
    </div>
  </template>
}
