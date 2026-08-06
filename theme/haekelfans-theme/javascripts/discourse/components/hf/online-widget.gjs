import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { modifier } from "ember-modifier";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import { hfAvatarUrl } from "../../lib/hf-format";

const POLL_MS = 60_000;

export default class HfOnlineWidget extends Component {
  @tracked count = 0;
  @tracked users = [];

  poll = modifier(() => {
    this.#fetch();
    const timer = setInterval(() => this.#fetch(), POLL_MS);
    return () => clearInterval(timer);
  });

  async #fetch() {
    try {
      const data = await ajax("/haekelfans/online.json");
      this.count = data?.count ?? 0;
      this.users = (data?.users ?? []).slice(0, 6).map((u) => ({
        ...u,
        avatar: hfAvatarUrl(u.avatar_template, 32),
      }));
    } catch {
      // widget is decoratief; fouten stil negeren
    }
  }

  get titleLabel() {
    return i18n(themePrefix("hf.online.title"));
  }

  get countLabel() {
    return i18n(themePrefix("hf.online.count"), { count: this.count });
  }

  get extraCount() {
    return Math.max(0, this.count - this.users.length);
  }

  <template>
    <div class="hf-online-widget hf-card" {{this.poll}}>
      <h4>{{this.titleLabel}}</h4>
      <div class="hf-online-widget__row">
        {{#each this.users as |user|}}
          <img src={{user.avatar}} alt={{user.username}} title={{user.username}} />
        {{/each}}
        {{#if this.extraCount}}
          <span class="hf-online-widget__moreCount">+{{this.extraCount}}</span>
        {{/if}}
      </div>
      <p class="hf-online-widget__note">
        <span class="hf-online-widget__dot"></span>{{this.countLabel}}
      </p>
    </div>
  </template>
}
