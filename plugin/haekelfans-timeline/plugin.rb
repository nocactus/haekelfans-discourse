# frozen_string_literal: true
# name: haekelfans-timeline
# about: Tijdlijn-data voor het Häkelfans theme (afbeeldingen, replies, online, no-onebox)
# version: 1.0.0
# authors: Timo Roosendaal
# required_version: 2.7.0

enabled_site_setting :haekelfans_timeline_enabled

module ::HaekelfansTimeline
  PLUGIN_NAME = "haekelfans-timeline"
end

require_relative "lib/haekelfans_timeline/engine"

after_initialize do
  require_relative "lib/haekelfans_timeline/timeline_data"

  TopicList.on_preload do |topics, topic_list|
    if SiteSetting.haekelfans_timeline_enabled
      HaekelfansTimeline::TimelineData.preload(
        topics,
        current_user: topic_list.respond_to?(:current_user) ? topic_list.current_user : nil,
      )
    end
  end

  add_to_serializer(
    :topic_list_item,
    :hf_images,
    include_condition: -> { SiteSetting.haekelfans_timeline_enabled },
  ) { HaekelfansTimeline::TimelineData.images_for(object) }

  add_to_serializer(
    :topic_list_item,
    :hf_replies,
    include_condition: -> { SiteSetting.haekelfans_timeline_enabled },
  ) { HaekelfansTimeline::TimelineData.replies_for(object) }

  add_to_serializer(
    :topic_list_item,
    :hf_reply_total,
    include_condition: -> { SiteSetting.haekelfans_timeline_enabled },
  ) { HaekelfansTimeline::TimelineData.reply_total_for(object) }

  add_to_serializer(
    :topic_list_item,
    :hf_likers,
    include_condition: -> { SiteSetting.haekelfans_timeline_enabled },
  ) { HaekelfansTimeline::TimelineData.likers_for(object) }

  add_to_serializer(
    :topic_list_item,
    :hf_first_post_id,
    include_condition: -> { SiteSetting.haekelfans_timeline_enabled },
  ) { HaekelfansTimeline::TimelineData.first_post_id_for(object) }
end
