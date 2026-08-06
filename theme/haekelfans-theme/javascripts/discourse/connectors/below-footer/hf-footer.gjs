import Component from "@glimmer/component";

function parseLinks(raw) {
  return String(raw || "")
    .split("|")
    .map((entry) => {
      const [label, ...urlParts] = entry.split(",");
      return { label: label?.trim(), url: urlParts.join(",").trim() };
    })
    .filter((l) => l.label && l.url);
}

export default class HfFooter extends Component {
  get serviceLinks() {
    return parseLinks(settings.footer_links_service);
  }

  get anleitungenLinks() {
    return parseLinks(settings.footer_links_anleitungen);
  }

  get instagram() {
    return settings.footer_social_instagram;
  }

  get facebook() {
    return settings.footer_social_facebook;
  }

  <template>
    <footer class="hf-footer">
      <div class="hf-footer__inner">
        <div class="hf-footer__col">
          <h5>Service</h5>
          <ul>
            {{#each this.serviceLinks as |link|}}
              <li><a href={{link.url}}>{{link.label}}</a></li>
            {{/each}}
          </ul>
        </div>
        <div class="hf-footer__col">
          <h5>Häkelanleitungen</h5>
          <ul>
            {{#each this.anleitungenLinks as |link|}}
              <li><a href={{link.url}}>{{link.label}}</a></li>
            {{/each}}
          </ul>
        </div>
        <div class="hf-footer__socials">
          {{#if this.instagram}}
            <a href={{this.instagram}} title="Instagram" aria-label="Instagram">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.2" cy="6.8" r="1" fill="currentColor" stroke="none"/></svg>
            </a>
          {{/if}}
          {{#if this.facebook}}
            <a href={{this.facebook}} title="Facebook" aria-label="Facebook">
              <svg viewBox="0 0 24 24"><text x="12" y="17" text-anchor="middle" font-size="15" font-weight="700" fill="currentColor">f</text></svg>
            </a>
          {{/if}}
        </div>
      </div>
    </footer>
  </template>
}
