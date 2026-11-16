# frozen_string_literal: true
# name: haekelfans-timeline
# about: Tijdlijn-data voor het Häkelfans theme (afbeeldingen, replies, online, no-onebox)
# version: 1.1.1
# authors: Timo Roosendaal
# required_version: 2.7.0

enabled_site_setting :haekelfans_timeline_enabled

module ::HaekelfansTimeline
  PLUGIN_NAME = "haekelfans-timeline"

  def self.no_onebox?(value)
    [true, "true", "t"].include?(value)
  end
end

require_relative "lib/haekelfans_timeline/engine"

after_initialize do
  require_relative "lib/haekelfans_timeline/timeline_data"
  require_relative "lib/haekelfans_timeline/reply_tree"

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

  # Deeplinks: het theme rendert de topic-pagina in kaartweergave en
  # heeft daarvoor dezelfde velden nodig als in de lijst.
  add_to_serializer(
    :topic_view,
    :hf_images,
    include_condition: -> { SiteSetting.haekelfans_timeline_enabled },
  ) do
    HaekelfansTimeline::TimelineData.preload([object.topic])
    HaekelfansTimeline::TimelineData.images_for(object.topic)
  end

  add_to_serializer(
    :topic_view,
    :hf_first_post_id,
    include_condition: -> { SiteSetting.haekelfans_timeline_enabled },
  ) do
    HaekelfansTimeline::TimelineData.preload([object.topic])
    HaekelfansTimeline::TimelineData.first_post_id_for(object.topic)
  end

  # Per-bericht "geen link-preview": composer stuurt hf_no_onebox mee;
  # bij het post-processen worden oneboxes vervangen door platte links.
  register_post_custom_field_type("hf_no_onebox", :boolean)
  add_permitted_post_create_param(:hf_no_onebox)

  on(:post_created) do |post, opts, _user|
    if opts[:hf_no_onebox].to_s == "true"
      post.custom_fields["hf_no_onebox"] = true
      post.save_custom_fields
    end
  end

  # Bij bewerken kan de schakelaar ook wijzigen; zonder tekstwijziging
  # moet het bericht dan opnieuw gerenderd worden.
  add_permitted_post_update_param(:hf_no_onebox) do |post, value|
    wanted = value.to_s == "true"
    current = HaekelfansTimeline.no_onebox?(post.custom_fields["hf_no_onebox"])
    next if wanted == current

    if wanted
      post.custom_fields["hf_no_onebox"] = true
    else
      post.custom_fields.delete("hf_no_onebox")
    end
    post.save_custom_fields(true)
    post.rebake!
  end

  topic_view_post_custom_fields_allowlister { ["hf_no_onebox"] }

  add_to_serializer(:post, :hf_no_onebox) do
    HaekelfansTimeline.no_onebox?(post_custom_fields["hf_no_onebox"])
  end

  on(:post_process_cooked) do |doc, post|
    if HaekelfansTimeline.no_onebox?(post.custom_fields["hf_no_onebox"])
      doc
        .css("aside.onebox")
        .each do |node|
          href = node.at_css("a")&.[]("href") || node["data-onebox-src"]
          if href
            safe = CGI.escapeHTML(href.to_s)
            node.replace("<p><a href=\"#{safe}\">#{safe}</a></p>")
          else
            node.remove
          end
        end
      doc.css("a.inline-onebox").each { |a| a.remove_attribute("class") }
    end
  end
end
