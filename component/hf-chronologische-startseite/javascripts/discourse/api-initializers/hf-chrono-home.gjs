import { apiInitializer } from "discourse/lib/api";

// Kaal "/" of "/latest" → chronologisch (nieuwste berichten eerst,
// geen bumping door nieuwe reacties). Expliciete query's zoals
// ?order=activity blijven ongemoeid.
export default apiInitializer((api) => {
  api.onPageChange((url) => {
    if (url === "/" || url === "/latest") {
      api.container.lookup("service:router").replaceWith("/latest?order=created");
    }
  });
});
