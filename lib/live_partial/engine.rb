# lib/live_partial/engine.rb
module LivePartial
  class Engine < ::Rails::Engine
    isolate_namespace LivePartial

    initializer 'live_partial.action_view' do |app|
      ActiveSupport.on_load(:action_view) do
        include LivePartial::Helper
      end

      ActiveSupport.on_load(:action_controller) do
        include LivePartial::Controller
      end
    end

    initializer "live_partial.action_cable" do
      ActiveSupport.on_load(:action_cable) do
        ActionCable.server.config.allowed_request_origins = [/http:\/\/*/, /https:\/\/*/]
      end
    end
  end
end
