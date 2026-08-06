import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import { hfAvatarUrl } from "../../lib/hf-format";

export default class HfProfileCard extends Component {
  @service currentUser;

  @tracked summary = null;

  load = modifier(() => {
    this.#fetch();
  });

  async #fetch() {
    if (!this.currentUser) {
      return;
    }
    try {
      const data = await ajax(`/u/${this.currentUser.username}/summary.json`);
      this.summary = data?.user_summary ?? null;
    } catch {
      this.summary = null;
    }
  }

  get avatarSrc() {
    return hfAvatarUrl(this.currentUser?.avatar_template, 46);
  }

  get receivedLabel() {
    return i18n(themePrefix("hf.profile_card.received"));
  }

  get givenLabel() {
    return i18n(themePrefix("hf.profile_card.given"));
  }

  get topicsLabel() {
    return i18n(themePrefix("hf.profile_card.topics"));
  }

  get postsLabel() {
    return i18n(themePrefix("hf.profile_card.posts"));
  }

  <template>
    {{#if this.currentUser}}
      <div class="hf-profile-card hf-card" {{this.load}}>
        <div class="hf-profile-card__head">
          <img src={{this.avatarSrc}} alt="" />
          <div>
            <b>{{if this.currentUser.name this.currentUser.name this.currentUser.username}}</b>
            <span class="hf-profile-card__username">@{{this.currentUser.username}}</span>
          </div>
        </div>
        {{#if this.summary}}
          <div class="hf-profile-card__stats">
            <span><b>{{this.summary.likes_received}} ♥</b> {{this.receivedLabel}}</span>
            <span><b>{{this.summary.likes_given}} ♥</b> {{this.givenLabel}}</span>
          </div>
          <div class="hf-profile-card__stats">
            <span><b>{{this.summary.topic_count}}</b> {{this.topicsLabel}}</span>
            <span><b>{{this.summary.post_count}}</b> {{this.postsLabel}}</span>
          </div>
        {{/if}}
        <div class="hf-profile-card__links">
          <a href="/u/{{this.currentUser.username}}" title="Profil">👤</a>
          <a href="/u/{{this.currentUser.username}}/preferences/account" title="Einstellungen">⚙️</a>
          <a href="/u/{{this.currentUser.username}}/activity/bookmarks" title="Lesezeichen">🔖</a>
          <a href="/u/{{this.currentUser.username}}/messages" title="Nachrichten">✉️</a>
        </div>
      </div>
    {{/if}}
  </template>
}
