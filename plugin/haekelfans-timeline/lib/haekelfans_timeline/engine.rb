# frozen_string_literal: true

module ::HaekelfansTimeline
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace HaekelfansTimeline
    config.autoload_paths << File.join(config.root, "lib")
  end
end

Discourse::Application.routes.append { mount ::HaekelfansTimeline::Engine, at: "/haekelfans" }
