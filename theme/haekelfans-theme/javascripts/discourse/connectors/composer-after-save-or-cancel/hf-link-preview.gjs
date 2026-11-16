import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action, get } from "@ember/object";
import { modifier } from "ember-modifier";
import { i18n } from "discourse-i18n";

const syncHtmlClass = modifier((element, [off]) => {
  const html = document.documentElement;
  html.classList.toggle("hf-no-link-preview", !!off);
  return () => html.classList.remove("hf-no-link-preview");
});

export default class HfLinkPreview extends Component {
  get model() {
    return this.args.outletArgs?.model;
  }

  get enabled() {
    return this.model && get(this.model, "hf_no_onebox") !== "true";
  }

  get label() {
    return i18n(themePrefix("hf.composer.link_preview"));
  }

  @action
  toggle(event) {
    this.model.set("hf_no_onebox", event.target.checked ? "false" : "true");
  }

  <template>
    {{#if this.model}}
      <label
        class="hf-link-preview-toggle"
        {{syncHtmlClass (if this.enabled false true)}}
      >
        <input
          type="checkbox"
          checked={{this.enabled}}
          {{on "change" this.toggle}}
        />
        {{this.label}}
      </label>
    {{/if}}
  </template>
}
