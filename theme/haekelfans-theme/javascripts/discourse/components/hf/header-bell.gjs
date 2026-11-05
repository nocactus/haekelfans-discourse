import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { toggleUserMenu } from "../../lib/hf-user-menu";

// Bel in de header met teller; opent het meldingenmenu (geen pagina).
export default class HfHeaderBell extends Component {
  @service currentUser;
  @service header;

  get count() {
    return this.currentUser?.all_unread_notifications_count ?? 0;
  }

  get label() {
    return i18n(themePrefix("hf.notifications"));
  }

  @action
  toggle(event) {
    event.preventDefault();
    event.stopPropagation();
    toggleUserMenu(this.header, "notifications");
  }

  <template>
    {{#if this.currentUser}}
      <li class="header-dropdown-toggle hf-bell">
        <button
          type="button"
          class="icon btn-flat hf-bell__link"
          title={{this.label}}
          aria-label={{this.label}}
          {{on "click" this.toggle}}
        >
          {{icon "bell"}}
          {{#if this.count}}
            <span class="hf-bell__badge">{{this.count}}</span>
          {{/if}}
        </button>
      </li>
    {{/if}}
  </template>
}
