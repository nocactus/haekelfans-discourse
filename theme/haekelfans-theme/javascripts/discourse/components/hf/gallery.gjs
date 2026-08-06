import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import HfLightbox from "./lightbox";

const MAX_TILES = 5;

export default class HfGallery extends Component {
  @tracked lightboxAt = null;

  get images() {
    return this.args.images ?? [];
  }

  get tiles() {
    return this.images.slice(0, MAX_TILES).map((image, index) => ({
      image,
      index,
      isLast: index === MAX_TILES - 1 && this.moreCount > 0,
    }));
  }

  get moreCount() {
    return Math.max(0, this.images.length - MAX_TILES);
  }

  get gridClass() {
    return `m${Math.min(this.images.length, MAX_TILES)}`;
  }

  @action
  open(index) {
    this.lightboxAt = index;
  }

  @action
  closeLightbox() {
    this.lightboxAt = null;
  }

  <template>
    {{#if this.images.length}}
      <div class="hf-gallery {{this.gridClass}}">
        {{#each this.tiles as |tile|}}
          <button
            type="button"
            class="hf-gallery__cell"
            {{on "click" (fn this.open tile.index)}}
          >
            <img
              src={{tile.image.thumb_url}}
              width={{tile.image.width}}
              height={{tile.image.height}}
              loading="lazy"
              alt=""
            />
            {{#if tile.isLast}}
              <span class="hf-gallery__more">+{{this.moreCount}}</span>
            {{/if}}
          </button>
        {{/each}}
      </div>
      {{#if (isPresent this.lightboxAt)}}
        <HfLightbox
          @images={{this.images}}
          @startIndex={{this.lightboxAt}}
          @title={{@title}}
          @onClose={{this.closeLightbox}}
        />
      {{/if}}
    {{/if}}
  </template>
}

function isPresent(value) {
  return value !== null && value !== undefined;
}
