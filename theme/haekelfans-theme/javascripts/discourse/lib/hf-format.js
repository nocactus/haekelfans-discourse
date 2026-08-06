import { htmlSafe } from "@ember/template";
import { avatarUrl } from "discourse/lib/avatar-utils";
import { relativeAge } from "discourse/lib/formatter";

export function hfAvatarUrl(template, px = 40) {
  if (!template) {
    return "";
  }
  return avatarUrl(template, px * 2); // 2x voor retina
}

export function hfTimeAgo(dateLike) {
  if (!dateLike) {
    return "";
  }
  // relativeAge geeft bij "medium-with-ago" een html-string terug
  return htmlSafe(relativeAge(new Date(dateLike), { format: "medium-with-ago" }));
}
