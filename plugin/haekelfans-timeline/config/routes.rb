# frozen_string_literal: true

HaekelfansTimeline::Engine.routes.draw do
  get "/topic/:topic_id/tree" => "timeline#tree", :constraints => { topic_id: /\d+/ }
  get "/online" => "timeline#online"
end
