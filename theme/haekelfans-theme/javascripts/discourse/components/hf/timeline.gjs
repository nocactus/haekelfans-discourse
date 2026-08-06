import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { i18n } from "discourse-i18n";
import HfPostCard from "./post-card";
import HfPostModal from "./post-modal";

export default class HfTimeline extends Component {
  @service router;

  @tracked openTopic = null;

  @action
  openModal(topic) {
    this.openTopic = topic;
  }

  @action
  closeModal() {
    this.openTopic = null;
  }

  observeSentinel = modifier((element) => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) {
          this.loadMore();
        }
      },
      { rootMargin: "600px" }
    );
    observer.observe(element);
    return () => observer.disconnect();
  });

  get list() {
    return this.args.model?.list;
  }

  get topics() {
    return this.list?.topics ?? [];
  }

  get currentPath() {
    return this.router.currentURL?.split("#")[0] ?? "";
  }

  get tabs() {
    return [
      {
        key: "aktuell",
        url: "/latest?order=created",
        label: i18n(themePrefix("hf.tabs.aktuell")),
        active:
          this.currentPath.startsWith("/latest") &&
          this.currentPath.includes("order=created"),
      },
      {
        key: "aktiv",
        url: "/latest",
        label: i18n(themePrefix("hf.tabs.aktiv")),
        active:
          this.currentPath.startsWith("/latest") &&
          !this.currentPath.includes("order=created"),
      },
      {
        key: "neu",
        url: "/new",
        label: i18n(themePrefix("hf.tabs.neu")),
        active: this.currentPath.startsWith("/new"),
      },
      {
        key: "meine",
        url: "/filter?q=created-by%3Ame%20order%3Acreated",
        label: i18n(themePrefix("hf.tabs.meine")),
        active: this.currentPath.startsWith("/filter"),
      },
    ];
  }

  loadMore() {
    if (this.list?.canLoadMore) {
      this.list.loadMore();
    }
  }

  <template>
    <div class="hf-timeline">
      <div class="hf-timeline__main">
        <nav class="hf-filterbar hf-card">
          <div class="hf-filterbar__tabs">
            {{#each this.tabs as |tab|}}
              <a
                href={{tab.url}}
                class="hf-filterbar__tab {{if tab.active 'is-active'}}"
              >{{tab.label}}</a>
            {{/each}}
          </div>
        </nav>

        <div class="hf-timeline__list">
          {{#each this.topics as |topic|}}
            <HfPostCard @topic={{topic}} @onOpen={{this.openModal}} />
          {{/each}}
        </div>
        <div class="hf-timeline__sentinel" {{this.observeSentinel}}></div>
      </div>

      <aside class="hf-timeline__aside">
        {{! widgets volgen in Task 10 }}
      </aside>

      {{#if this.openTopic}}
        <HfPostModal @topic={{this.openTopic}} @onClose={{this.closeModal}} />
      {{/if}}
    </div>
  </template>
}
