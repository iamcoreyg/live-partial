module LivePartial
  module Helper
    extend ActiveSupport::Concern

    def live_partial(name, options = {})
      raise ArgumentError, "live_partial requires an :id option" unless options[:id].present?
      raise ArgumentError, "live_partial requires either :for or :action option" unless options[:for].present? || options[:action].present?

      # Determine controller path and action
      if options[:for]
        resource = options[:for]

        # Default controller path includes current namespace
        namespace = controller.class.name.deconstantize.underscore
        base_controller = resource.class.name.underscore.pluralize
        default_controller_path = [namespace, base_controller].join('/')

        action_method = if options[:action]&.include?('#')
          options[:action]  # Full override with controller#action
        elsif options[:action]
          "#{default_controller_path}##{options[:action]}"  # Just action override
        else
          "#{default_controller_path}#update"  # Default to update
        end
      else
        action_method = options[:action]  # Full controller#action required when no :for
      end

      # Split controller and action
      controller_path, action = action_method.split('#')
      raise ArgumentError, "Invalid action format. Expected 'controller#action'" unless controller_path.present? && action.present?

      # Construct URL manually to ensure correct format
      url = if options[:for]
        "/#{controller_path}/#{options[:for].to_param}"
      else
        url_for(controller: controller_path, action: action, only_path: true)
      end

      content_tag :div,
        render(partial: name, locals: {
          **options.except(:id, :state, :action, :for),
          **options[:state],
          id: options[:id],
          resource: options[:for]
        }),
        data: {
          live_partial: true,
          partial_name: name,
          state: options[:state].to_json,
          url: url,
          resource_id: options[:for]&.id,
          resource_type: options[:for]&.class&.name&.underscore,
          http_method: (action == 'update' ? 'PATCH' : 'POST')  # Use PATCH for updates
        },
        id: options[:id]
    end
  end
end
