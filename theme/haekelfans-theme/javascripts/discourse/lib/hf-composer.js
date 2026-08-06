// Titelgeneratie voor titelloze berichten: eerste 8 woorden van de
// tekst, zonder URL's en markdown-tekens, afgekapt op 60 tekens.
export function generateTitle(raw) {
  const words = (raw || "")
    .replace(/https?:\/\/\S+/g, " ")
    .replace(/!\[[^\]]*\]\([^)]*\)/g, " ")
    .replace(/[#*_`>\[\]()]/g, " ")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 8);
  let title = words.join(" ");
  if (title.length > 60) {
    title = title.slice(0, 60).replace(/\s+\S*$/, "");
  }
  return title;
}
