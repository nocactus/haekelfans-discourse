// Splitst het core user-menu in twee ingangen:
// - bel    → meldingen (tabs met meldingen, zonder profieltab)
// - avatar → profiel (Profil, Einstellungen, Abmelden …), zonder tabs
const MODES = ["notifications", "profile"];
const TAB_FOR_MODE = {
  notifications: "all-notifications",
  profile: "profile",
};

let currentMode = null;

function setModeClass(mode) {
  const html = document.documentElement;
  MODES.forEach((m) => html.classList.toggle(`hf-menu-${m}`, m === mode));
}

function selectTab(mode, tries = 30) {
  const button = document.getElementById(`user-menu-button-${TAB_FOR_MODE[mode]}`);
  if (button) {
    const menu = button.closest(".user-menu");
    if (menu?.dataset.tabId !== TAB_FOR_MODE[mode]) {
      button.click();
    }
    return;
  }
  if (tries > 0) {
    requestAnimationFrame(() => selectTab(mode, tries - 1));
  }
}

export function toggleUserMenu(header, mode) {
  if (header.userVisible && currentMode === mode) {
    header.userVisible = false;
    return;
  }
  currentMode = mode;
  setModeClass(mode);
  header.userVisible = true;
  selectTab(mode);
}
