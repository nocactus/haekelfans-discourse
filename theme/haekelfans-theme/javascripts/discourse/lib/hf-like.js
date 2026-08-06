import { ajax } from "discourse/lib/ajax";

// Like-toggle voor een post. Probeert het Reactions-plugin (hart);
// als dat niet geïnstalleerd is (404) valt hij terug op de core-like.
export async function toggleLike(postId, currentlyLiked) {
  try {
    return await ajax(
      `/discourse-reactions/posts/${postId}/custom-reactions/heart/toggle.json`,
      { type: "PUT" }
    );
  } catch (e) {
    if (e.jqXHR?.status !== 404) {
      throw e;
    }
  }

  if (currentlyLiked) {
    return await ajax(`/post_actions/${postId}`, {
      type: "DELETE",
      data: { post_action_type_id: 2 },
    });
  }
  return await ajax("/post_actions", {
    type: "POST",
    data: { id: postId, post_action_type_id: 2 },
  });
}
