import Component from "@glimmer/component";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

// Bel in de header met teller; linkt naar de meldingenpagina.
export default class HfHeaderBell extends Component {
  @service currentUser;

  get count() {
    return this.currentUser?.all_unread_notifications_count ?? 0;
  }

  get label() {
    return i18n(themePrefix("hf.notifications"));
  }

  get href() {
    return `/u/${this.currentUser.username}/notifications`;
  }

  <template>
    {{#if this.currentUser}}
      <li class="header-dropdown-toggle hf-bell">
        <a
          href={{this.href}}
          class="icon btn-flat hf-bell__link"
          title={{this.label}}
          aria-label={{this.label}}
        >
          {{icon "bell"}}
          {{#if this.count}}
            <span class="hf-bell__badge">{{this.count}}</span>
          {{/if}}
        </a>
      </li>
    {{/if}}
  </template>
}
