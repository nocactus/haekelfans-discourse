# frozen_string_literal: true

module HaekelfansTimeline
  # Bulk-preload van tijdlijn-data voor topiclijsten. Alle queries draaien
  # één keer per lijst (nooit per topic); resultaten hangen als @hf_data
  # aan de topic-objecten zodat serializers geen queries meer doen.
  module TimelineData
    def self.preload(topics, current_user: nil)
      ids = topics.map(&:id)
      return if ids.empty?

      first_posts = Post.where(topic_id: ids, post_number: 1).pluck(:topic_id, :id).to_h
      topics.each { |t| merge_hf_data(t, first_post_id: first_posts[t.id]) }
      preload_images(topics, first_posts)
      preload_replies(topics, ids)
      preload_likers(topics, first_posts, current_user)
    end

    def self.images_for(topic)
      hf_data(topic)[:images] || []
    end

    def self.replies_for(topic)
      hf_data(topic)[:replies] || []
    end

    def self.reply_total_for(topic)
      hf_data(topic)[:reply_total] || 0
    end

    EMPTY_LIKERS = { names: [], count: 0, current_user_liked: false }.freeze

    def self.likers_for(topic)
      hf_data(topic)[:likers] || EMPTY_LIKERS
    end

    def self.first_post_id_for(topic)
      hf_data(topic)[:first_post_id]
    end

    def self.preload_likers(topics, first_posts, current_user)
      like_id = PostActionType.types[:like]
      likes =
        PostAction
          .where(post_id: first_posts.values, post_action_type_id: like_id, deleted_at: nil)
          .joins(:user)
          .order(:post_id, :created_at)
          .pluck(:post_id, :user_id, "users.name", "users.username")
      by_post = likes.group_by(&:first)
      topics.each do |t|
        list = by_post[first_posts[t.id]] || []
        next if list.empty?
        merge_hf_data(
          t,
          likers: {
            names: list.first(2).map { |(_p, _uid, name, username)| name.presence || username },
            count: list.size,
            current_user_liked:
              current_user ? list.any? { |(_p, uid, _n, _u)| uid == current_user.id } : false,
          },
        )
      end
    end

    def self.preload_replies(topics, ids)
      n = SiteSetting.haekelfans_timeline_reply_preview_count
      rows = DB.query(<<~SQL, ids: ids, n: n)
        SELECT * FROM (
          SELECT p.id, p.topic_id, p.post_number, p.reply_to_post_number, p.user_id,
                 p.cooked, p.created_at, p.like_count,
                 ROW_NUMBER() OVER (PARTITION BY p.topic_id ORDER BY p.post_number DESC) AS rn,
                 COUNT(*)    OVER (PARTITION BY p.topic_id) AS total
          FROM posts p
          WHERE p.topic_id IN (:ids) AND p.post_number > 1
            AND p.deleted_at IS NULL AND p.post_type = 1 AND p.hidden = false
        ) x WHERE rn <= :n
      SQL
      users = User.where(id: rows.map(&:user_id).uniq).index_by(&:id)
      images_by_post = images_for_posts(rows.map(&:id))
      rows
        .group_by(&:topic_id)
        .each do |tid, list|
          t = topics.find { |x| x.id == tid } or next
          replies =
            list.sort_by(&:post_number).map do |r|
              u = users[r.user_id]
              {
                post_id: r.id,
                post_number: r.post_number,
                reply_to_post_number: r.reply_to_post_number,
                username: u&.username,
                name: u&.name,
                avatar_template: u&.avatar_template,
                excerpt: reply_excerpt(r.cooked),
                images: images_by_post[r.id] || [],
                created_at: r.created_at,
                like_count: r.like_count,
                current_user_reacted: false,
              }
            end
          merge_hf_data(t, replies: replies, reply_total: list.first.total)
        end
    end

    def self.preload_images(topics, first_posts)
      by_post = images_for_posts(first_posts.values)
      topics.each { |t| merge_hf_data(t, images: by_post[first_posts[t.id]] || []) }
    end

    # Foto's (met thumbnail) per post-id, in uploadvolgorde, gemaximeerd.
    def self.images_for_posts(post_ids)
      return {} if post_ids.empty?
      refs =
        UploadReference
          .where(target_type: "Post", target_id: post_ids)
          .joins("JOIN uploads ON uploads.id = upload_references.upload_id")
          .where("uploads.width IS NOT NULL")
          .order(:target_id, :id)
          .pluck(
            "upload_references.target_id",
            "uploads.id",
            "uploads.url",
            "uploads.width",
            "uploads.height",
          )
      thumbs =
        OptimizedImage
          .where(upload_id: refs.map { |r| r[1] })
          .order(width: :desc)
          .group_by(&:upload_id)
      limit = SiteSetting.haekelfans_timeline_max_images

      refs
        .group_by(&:first)
        .transform_values do |rows|
          rows
            .first(limit)
            .map do |(_pid, upload_id, url, w, h)|
              thumb = thumbs[upload_id]&.first
              {
                url: UrlHelper.cook_url(url),
                thumb_url: UrlHelper.cook_url(thumb ? thumb.url : url),
                width: w,
                height: h,
              }
            end
        end
    end

    # Excerpt zonder foto's: die komen apart mee als images, anders
    # verschijnen ze als "[bestandsnaam]"-links in de tekst.
    def self.reply_excerpt(cooked)
      doc = Nokogiri::HTML5.fragment(cooked.to_s)
      doc.css(".lightbox-wrapper").each(&:remove)
      doc.css("img").each { |img| img.remove unless img["class"].to_s.include?("emoji") }
      PrettyText.excerpt(doc.to_html, 200, keep_emoji_images: true)
    end

    def self.hf_data(topic)
      topic.instance_variable_get(:@hf_data) || {}
    end

    def self.merge_hf_data(topic, **values)
      topic.instance_variable_set(:@hf_data, hf_data(topic).merge(values))
    end
  end
end
