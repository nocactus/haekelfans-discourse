import { apiInitializer } from "discourse/lib/api";
import HfHeaderBell from "../components/hf/header-bell";
import HfNavLinks from "../components/hf/nav-links";
import { toggleUserMenu } from "../lib/hf-user-menu";

export default apiInitializer((api) => {
  api.renderInOutlet("before-header-panel", HfNavLinks);
  api.headerIcons.add("hf-bell", HfHeaderBell, { before: "user-menu" });

  // Avatar opent het profielmenu (de bel opent de meldingen).
  const header = api.container.lookup("service:header");
  if (window.__hfAvatarHandler) {
    document.removeEventListener("click", window.__hfAvatarHandler, true);
  }
  window.__hfAvatarHandler = (event) => {
    const avatar = event.target.closest?.(
      ".header-dropdown-toggle.current-user button, #toggle-current-user"
    );
    if (!avatar) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    toggleUserMenu(header, "profile");
  };
  document.addEventListener("click", window.__hfAvatarHandler, true);

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
