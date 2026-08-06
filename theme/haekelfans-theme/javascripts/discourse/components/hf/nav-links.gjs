import Component from "@glimmer/component";

// Header-navigatielinks uit de theme-instelling `header_links`
// (formaat per regel: "Label,https://url").
export default class HfNavLinks extends Component {
  get links() {
    return String(settings.header_links || "")
      .split("|")
      .map((entry) => {
        const [label, ...urlParts] = entry.split(",");
        return { label: label?.trim(), url: urlParts.join(",").trim() };
      })
      .filter((l) => l.label && l.url);
  }

  <template>
    <nav class="hf-nav-links">
      {{#each this.links as |link|}}
        <a href={{link.url}}>{{link.label}}</a>
      {{/each}}
    </nav>
  </template>
}
