# frozen_string_literal: true

module HaekelfansTimeline
  # Bouwt de geneste reply-boom voor de berichtmodal/topic-weergave.
  # Discourse-posts zijn vlak (reply_to_post_number); wij nesten tot
  # MAX_DEPTH niveaus — diepere antwoorden worden platgeslagen naar het
  # laatste niveau zodat de UI nooit dieper hoeft te renderen.
  module ReplyTree
    PER_PAGE = 50
    MAX_DEPTH = 4

    def self.build(topic, _guardian, page: 0, current_user: nil)
      posts =
        topic
          .posts
          .where("post_number > 1")
          .where(deleted_at: nil, post_type: Post.types[:regular], hidden: false)
          .includes(:user)
          .order(:post_number)
      liked_ids = liked_post_ids(current_user, posts)
      nodes = posts.map { |p| serialize(p, liked_ids) }
      by_number = nodes.index_by { |n| n[:post_number] }
      roots = []
      nodes.each do |n|
        parent = n[:reply_to_post_number] && by_number[n[:reply_to_post_number]]
        parent && parent != n ? (parent[:children] << n) : (roots << n)
      end
      roots.each { |r| clamp!(r, 1) }
      {
        topic_id: topic.id,
        total: roots.size,
        page: page,
        per_page: PER_PAGE,
        replies: roots.slice(page * PER_PAGE, PER_PAGE) || [],
      }
    end

    # Op diepte MAX_DEPTH-1 wordt de substructuur platgeslagen tot directe
    # children, zodat niets dieper dan MAX_DEPTH niveaus rendert.
    def self.clamp!(node, depth)
      if depth == MAX_DEPTH - 1
        node[:children] = flatten(node[:children])
        node[:children].each { |c| c[:children] = [] }
      else
        node[:children].each { |c| clamp!(c, depth + 1) }
      end
    end

    def self.flatten(children)
      children.flat_map { |c| [c] + flatten(c[:children]) }
    end

    def self.liked_post_ids(current_user, posts)
      return Set.new if current_user.nil?
      PostAction
        .where(
          post_id: posts.map(&:id),
          user_id: current_user.id,
          post_action_type_id: PostActionType.types[:like],
          deleted_at: nil,
        )
        .pluck(:post_id)
        .to_set
    end

    def self.serialize(post, liked_ids)
      u = post.user
      {
        post_id: post.id,
        post_number: post.post_number,
        reply_to_post_number: post.reply_to_post_number,
        username: u&.username,
        name: u&.name,
        avatar_template: u&.avatar_template,
        cooked: post.cooked,
        created_at: post.created_at,
        like_count: post.like_count,
        current_user_reacted: liked_ids.include?(post.id),
        children: [],
      }
    end
  end
end
