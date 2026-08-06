import Component from "@glimmer/component";

// Stub — volledige kaart-anatomie volgt in Theme Task 4.
export default class HfPostCard extends Component {
  <template>
    <article class="hf-post-card hf-card">
      <h2 class="hf-post-card__title">{{@topic.title}}</h2>
    </article>
  </template>
}
