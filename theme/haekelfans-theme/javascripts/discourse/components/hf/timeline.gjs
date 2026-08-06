import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { i18n } from "discourse-i18n";
import HfComposer from "./composer";
import HfOnlineWidget from "./online-widget";
import HfPostCard from "./post-card";
import HfPostModal from "./post-modal";
import HfProfileCard from "./profile-card";

export default class HfTimeline extends Component {
  @service router;

  @tracked openTopic = null;

  composerApi = null;

  registerComposer = (api) => {
    this.composerApi = api;
  };

  @action
  newTopic() {
    this.composerApi?.expand();
    document
      .querySelector(".hf-composer")
      ?.scrollIntoView({ block: "center", behavior: "smooth" });
  }

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

  get newTopicLabel() {
    return i18n(themePrefix("hf.new_topic"));
  }

  get showProfileCard() {
    return String(settings.show_profile_card) === "true";
  }

  get showOnlineWidget() {
    return String(settings.show_online_widget) === "true";
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
          <button
            type="button"
            class="hf-filterbar__new"
            {{on "click" this.newTopic}}
          >✎ {{this.newTopicLabel}}</button>
        </nav>

        <HfComposer @onRegister={{this.registerComposer}} />

        <div class="hf-timeline__list">
          {{#each this.topics as |topic|}}
            <HfPostCard @topic={{topic}} @onOpen={{this.openModal}} />
          {{/each}}
        </div>
        <div class="hf-timeline__sentinel" {{this.observeSentinel}}></div>
      </div>

      <aside class="hf-timeline__aside">
        {{#if this.showProfileCard}}
          <HfProfileCard />
        {{/if}}
        {{#if this.showOnlineWidget}}
          <HfOnlineWidget />
        {{/if}}
      </aside>

      {{#if this.openTopic}}
        <HfPostModal @topic={{this.openTopic}} @onClose={{this.closeModal}} />
      {{/if}}

      <button
        type="button"
        class="hf-fab"
        aria-label={{this.newTopicLabel}}
        {{on "click" this.newTopic}}
      >＋</button>
    </div>
  </template>
}
