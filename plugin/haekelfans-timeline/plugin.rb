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
  # Serializer-velden en event-hooks komen in latere taken.
end
