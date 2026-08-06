import Component from "@glimmer/component";
import HfTimeline from "../../components/hf/timeline";

// Wrapper-outlet: vervangt de standaard topiclijst op alle discovery-
// routes (ook categorie-/tagpagina's — zelfde tijdlijn, gefilterd).
export default class HfTimelineOutlet extends Component {
  <template><HfTimeline @model={{@outletArgs.model}} /></template>
}
