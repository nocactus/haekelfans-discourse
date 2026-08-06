import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { modifier } from "ember-modifier";

export default class HfLightbox extends Component {
  @tracked index = this.args.startIndex ?? 0;

  #pointerStartX = null;

  keyboard = modifier(() => {
    const handler = (event) => {
      if (event.key === "Escape") {
        this.args.onClose?.();
      } else if (event.key === "ArrowRight") {
        this.next();
      } else if (event.key === "ArrowLeft") {
        this.prev();
      }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  });

  get images() {
    return this.args.images ?? [];
  }

  get current() {
    return this.images[this.index];
  }

  get countLabel() {
    return `${this.index + 1} / ${this.images.length}`;
  }

  @action
  next() {
    this.index = (this.index + 1) % this.images.length;
  }

  @action
  prev() {
    this.index = (this.index - 1 + this.images.length) % this.images.length;
  }

  @action
  close() {
    this.args.onClose?.();
  }

  @action
  backdropClick(event) {
    if (event.target === event.currentTarget) {
      this.close();
    }
  }

  @action
  pointerDown(event) {
    this.#pointerStartX = event.clientX;
  }

  @action
  pointerUp(event) {
    if (this.#pointerStartX == null) {
      return;
    }
    const dx = event.clientX - this.#pointerStartX;
    this.#pointerStartX = null;
    if (dx > 40) {
      this.prev();
    } else if (dx < -40) {
      this.next();
    }
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div
      class="hf-lightbox"
      {{this.keyboard}}
      {{on "click" this.backdropClick}}
      {{on "pointerdown" this.pointerDown}}
      {{on "pointerup" this.pointerUp}}
    >
      <span class="hf-lightbox__count">{{this.countLabel}}</span>
      <button type="button" class="hf-lightbox__close" {{on "click" this.close}}>✕</button>
      {{#if this.current}}
        <img class="hf-lightbox__img" src={{this.current.url}} alt="" />
      {{/if}}
      {{#if this.args.title}}
        <p class="hf-lightbox__caption">{{@title}}</p>
      {{/if}}
      <button type="button" class="hf-lightbox__arrow is-prev" {{on "click" this.prev}}>‹</button>
      <button type="button" class="hf-lightbox__arrow is-next" {{on "click" this.next}}>›</button>
    </div>
  </template>
}
