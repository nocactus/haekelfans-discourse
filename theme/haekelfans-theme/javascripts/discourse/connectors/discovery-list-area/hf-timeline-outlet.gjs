import Component from "@glimmer/component";
import HfTimeline from "../../components/hf/timeline";

// Wrapper-outlet: vervangt de topiclijst door de tijdlijn op routes met een
// topiclijst (latest, categorie, tag). Pagina's zonder topiclijst, zoals
// /categories, krijgen de standaardweergave.
export default class HfTimelineOutlet extends Component {
  get hasTopicList() {
    return !!this.args.outletArgs?.model?.list;
  }

  <template>
    {{#if this.hasTopicList}}
      <HfTimeline @model={{@outletArgs.model}} />
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
