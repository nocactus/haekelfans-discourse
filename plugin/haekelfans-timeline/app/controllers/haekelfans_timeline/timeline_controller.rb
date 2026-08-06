# frozen_string_literal: true

module HaekelfansTimeline
  class TimelineController < ::ApplicationController
    requires_plugin HaekelfansTimeline::PLUGIN_NAME

    # Leden actief in de laatste 10 minuten; 60s gecachet omdat het
    # per widget-poll wordt opgevraagd.
    def online
      raise Discourse::InvalidAccess if current_user.nil?
      payload =
        Discourse.cache.fetch("haekelfans_online", expires_in: 60) do
          scope =
            User.real.activated.where(suspended_till: nil).where(
              "last_seen_at > ?",
              10.minutes.ago,
            )
          {
            count: scope.count,
            users:
              scope
                .order(last_seen_at: :desc)
                .limit(30)
                .map do |u|
                  {
                    id: u.id,
                    username: u.username,
                    name: u.name,
                    avatar_template: u.avatar_template,
                  }
                end,
          }
        end
      render json: payload
    end

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
