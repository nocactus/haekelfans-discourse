import { apiInitializer } from "discourse/lib/api";
import HfNavLinks from "../components/hf/nav-links";

export default apiInitializer((api) => {
  api.renderInOutlet("before-header-panel", HfNavLinks);

  // PWA: adresbalk/systeem-UI in de warme achtergrondkleur
  const meta = document.createElement("meta");
  meta.name = "theme-color";
  meta.content = "#faf7f5";
  document.head.appendChild(meta);

  // Profiel-versimpeling: routes van geschrapte onderdelen sturen door
  // naar de accountinstellingen (spec §8).
  api.onPageChange((url) => {
    // Startpagina altijd chronologisch (nieuwste eerst, geen bumping)
    if (url === "/" || url === "/latest") {
      api.container.lookup("service:router").replaceWith("/latest?order=created");
      return;
    }

    const removed =
      /^\/u\/([^/]+)\/(badges|summary|preferences\/(tracking|users|navigation-menu|apps|calendar-subscriptions))/;
    const match = url.match(removed);
    if (match) {
      const router = api.container.lookup("service:router");
      router.replaceWith(`/u/${match[1]}/preferences/account`);
    }
  });
});
