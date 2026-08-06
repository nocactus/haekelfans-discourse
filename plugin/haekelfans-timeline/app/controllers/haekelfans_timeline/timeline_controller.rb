# frozen_string_literal: true

module HaekelfansTimeline
  class TimelineController < ::ApplicationController
    requires_plugin HaekelfansTimeline::PLUGIN_NAME

    def tree
      topic = Topic.find_by(id: params[:topic_id].to_i)
      raise Discourse::NotFound unless topic
      guardian.ensure_can_see!(topic)
      render json:
               ReplyTree.build(
                 topic,
                 guardian,
                 page: params[:page].to_i,
                 current_user: current_user,
               )
    end
  end
end
