import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import { generateTitle } from "../../lib/hf-composer";
import { hfAvatarUrl } from "../../lib/hf-format";

const DRAFT_KEY = "new_topic";

export default class HfComposer extends Component {
  @service currentUser;
  @service site;
  @service router;

  @tracked expanded = false;
  @tracked title = "";
  @tracked raw = "";
  @tracked linkPreview = true;
  @tracked categoryId = null;
  @tracked tagsInput = "";
  @tracked uploads = [];
  @tracked busy = false;
  @tracked error = null;

  draftSequence = 0;
  #draftTimer = null;

  restoreDraft = modifier(() => {
    this.args.onRegister?.({ expand: () => (this.expanded = true) });
    this.#restore();
    return () => clearTimeout(this.#draftTimer);
  });

  async #restore() {
    try {
      const data = await ajax(`/drafts/${DRAFT_KEY}.json`);
      this.draftSequence = data?.draft_sequence ?? 0;
      if (data?.draft) {
        const draft = JSON.parse(data.draft);
        this.raw = draft.reply ?? "";
        this.title = draft.title ?? "";
        if (this.raw || this.title) {
          this.expanded = true;
        }
      }
    } catch {
      // geen draft — prima
    }
  }

  get avatarSrc() {
    return hfAvatarUrl(this.currentUser?.avatar_template, 38);
  }

  get categories() {
    return (this.site.categories ?? []).filter((c) => !c.read_restricted);
  }

  get selectedCategoryId() {
    if (this.categoryId) {
      return this.categoryId;
    }
    const preset = parseInt(settings.default_category_id, 10);
    if (preset) {
      return preset;
    }
    return this.categories[0]?.id;
  }

  get placeholderLabel() {
    return i18n(themePrefix("hf.composer.placeholder"));
  }

  get titlePlaceholder() {
    return i18n(themePrefix("hf.composer.title_placeholder"));
  }

  get publishLabel() {
    return i18n(themePrefix("hf.composer.publish"));
  }

  get linkPreviewLabel() {
    return i18n(themePrefix("hf.composer.link_preview"));
  }

  get linkPreviewHint() {
    return i18n(themePrefix("hf.composer.link_preview_hint"));
  }

  @action
  expand() {
    this.expanded = true;
  }

  @action
  updateTitle(event) {
    this.title = event.target.value;
    this.#scheduleDraft();
  }

  @action
  updateRaw(event) {
    this.raw = event.target.value;
    this.#scheduleDraft();
  }

  @action
  updateCategory(event) {
    this.categoryId = parseInt(event.target.value, 10);
  }

  @action
  updateTags(event) {
    this.tagsInput = event.target.value;
  }

  @action
  toggleLinkPreview() {
    this.linkPreview = !this.linkPreview;
  }

  #scheduleDraft() {
    clearTimeout(this.#draftTimer);
    this.#draftTimer = setTimeout(() => this.#saveDraft(), 2000);
  }

  async #saveDraft() {
    if (!this.raw && !this.title) {
      return;
    }
    try {
      const result = await ajax("/drafts.json", {
        type: "POST",
        data: {
          draft_key: DRAFT_KEY,
          sequence: this.draftSequence,
          data: JSON.stringify({ reply: this.raw, title: this.title }),
        },
      });
      if (result?.draft_sequence !== undefined) {
        this.draftSequence = result.draft_sequence;
      }
    } catch {
      // conflict of offline — stil laten; volgende poging overschrijft
    }
  }

  @action
  async pickFiles(event) {
    const files = [...(event.target.files ?? [])];
    event.target.value = "";
    for (const file of files) {
      const form = new FormData();
      form.append("type", "composer");
      form.append("synchronous", "true");
      form.append("file", file);
      this.busy = true;
      try {
        const upload = await ajax("/uploads.json", {
          type: "POST",
          data: form,
          processData: false,
          contentType: false,
        });
        this.uploads = [...this.uploads, upload];
      } catch {
        this.error = i18n(themePrefix("hf.composer.error_generic"));
      } finally {
        this.busy = false;
      }
    }
  }

  @action
  removeUpload(upload) {
    this.uploads = this.uploads.filter((u) => u !== upload);
  }

  @action
  async publish(event) {
    event?.preventDefault();
    const body = this.raw.trim();
    if (!body || this.busy) {
      return;
    }
    this.busy = true;
    this.error = null;

    const imageMarkdown = this.uploads
      .map((u) => `![](${u.short_url ?? u.url})`)
      .join("\n");
    const raw = imageMarkdown ? `${body}\n\n${imageMarkdown}` : body;
    const tags = this.tagsInput
      .split(",")
      .map((t) => t.trim())
      .filter(Boolean);

    try {
      await ajax("/posts.json", {
        type: "POST",
        data: {
          title: this.title.trim() || generateTitle(body),
          raw,
          category: this.selectedCategoryId,
          tags,
          hf_no_onebox: this.linkPreview ? undefined : "true",
        },
      });
      this.raw = "";
      this.title = "";
      this.tagsInput = "";
      this.uploads = [];
      this.linkPreview = true;
      this.expanded = false;
      await ajax(`/drafts/${DRAFT_KEY}.json?sequence=${this.draftSequence}`, {
        type: "DELETE",
      }).catch(() => {});
      this.router.refresh();
    } catch (e) {
      this.error = i18n(themePrefix("hf.composer.error_generic"));
      throw e;
    } finally {
      this.busy = false;
    }
  }

  <template>
    <div class="hf-composer hf-card {{if this.expanded 'is-expanded'}}" {{this.restoreDraft}}>
      {{#unless this.expanded}}
        <div class="hf-composer__collapsed">
          <img class="hf-composer__avatar" src={{this.avatarSrc}} alt="" />
          <button
            type="button"
            class="hf-composer__opener"
            {{on "click" this.expand}}
          >{{this.placeholderLabel}}</button>
          <button type="button" class="hf-composer__cam" {{on "click" this.expand}}>📷</button>
        </div>
      {{else}}
        <form class="hf-composer__form" {{on "submit" this.publish}}>
          <input
            class="hf-composer__title"
            type="text"
            placeholder={{this.titlePlaceholder}}
            value={{this.title}}
            {{on "input" this.updateTitle}}
          />
          <textarea
            class="hf-composer__raw"
            rows="4"
            placeholder={{this.placeholderLabel}}
            value={{this.raw}}
            {{on "input" this.updateRaw}}
          ></textarea>

          <div class="hf-composer__uploads">
            {{#each this.uploads as |upload|}}
              <span class="hf-composer__thumb">
                <img src={{upload.url}} alt="" />
                <button
                  type="button"
                  class="hf-composer__thumb-x"
                  {{on "click" (fn this.removeUpload upload)}}
                >✕</button>
              </span>
            {{/each}}
            <label class="hf-composer__thumb hf-composer__add">
              +
              <input
                type="file"
                accept="image/*"
                multiple
                hidden
                {{on "change" this.pickFiles}}
              />
            </label>
          </div>

          <div class="hf-composer__meta">
            <select class="hf-composer__cat" {{on "change" this.updateCategory}}>
              {{#each this.categories as |cat|}}
                <option
                  value={{cat.id}}
                  selected={{if (eq cat.id this.selectedCategoryId) "selected"}}
                >{{cat.name}}</option>
              {{/each}}
            </select>
            <input
              class="hf-composer__tags"
              type="text"
              placeholder="Schlagwörter, mit Komma"
              value={{this.tagsInput}}
              {{on "input" this.updateTags}}
            />
          </div>

          <label class="hf-composer__toggle">
            <input
              type="checkbox"
              checked={{this.linkPreview}}
              {{on "change" this.toggleLinkPreview}}
            />
            {{this.linkPreviewLabel}}
            <span class="hf-composer__hint">{{this.linkPreviewHint}}</span>
          </label>

          {{#if this.error}}
            <p class="hf-composer__error">{{this.error}}</p>
          {{/if}}

          <div class="hf-composer__foot">
            <button
              type="submit"
              class="hf-composer__publish"
              disabled={{this.busy}}
            >{{this.publishLabel}}</button>
          </div>
        </form>
      {{/unless}}
    </div>
  </template>
}

function eq(a, b) {
  return a === b;
}
