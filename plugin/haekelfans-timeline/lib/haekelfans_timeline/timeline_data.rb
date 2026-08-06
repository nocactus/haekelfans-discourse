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
      preload_images(topics, first_posts)
    end

    def self.images_for(topic)
      hf_data(topic)[:images] || []
    end

    def self.preload_images(topics, first_posts)
      refs =
        UploadReference
          .where(target_type: "Post", target_id: first_posts.values)
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
      by_post = refs.group_by(&:first)
      limit = SiteSetting.haekelfans_timeline_max_images

      topics.each do |t|
        rows = (by_post[first_posts[t.id]] || []).first(limit)
        images =
          rows.map do |(_pid, upload_id, url, w, h)|
            thumb = thumbs[upload_id]&.first
            {
              url: UrlHelper.cook_url(url),
              thumb_url: UrlHelper.cook_url(thumb ? thumb.url : url),
              width: w,
              height: h,
            }
          end
        merge_hf_data(t, images: images)
      end
    end

    def self.hf_data(topic)
      topic.instance_variable_get(:@hf_data) || {}
    end

    def self.merge_hf_data(topic, **values)
      topic.instance_variable_set(:@hf_data, hf_data(topic).merge(values))
    end
  end
end
