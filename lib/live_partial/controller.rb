module LivePartial
  module Controller
    extend ActiveSupport::Concern

    private

    def to_ostruct(obj)
      case obj
      when String
        begin
          parsed = JSON.parse(obj)
          to_ostruct(parsed)
        rescue JSON::ParserError, Encoding::UndefinedConversionError
          obj
        end
      when Hash
        return OpenStruct.new if obj.empty?
        OpenStruct.new(obj.compact.transform_values { |val| to_ostruct(val) })
      when Array
        return [] if obj.empty?
        obj.compact.map { |item| to_ostruct(item) }
      when ActionController::Parameters
        to_ostruct(obj.to_unsafe_h)
      when NilClass
        nil
      else
        obj
      end
    end

    def parse_state(state)
      return {} if state.nil? || state.empty?

      state.compact.transform_values do |value|
        case value
        when String
          begin
            JSON.parse(value)
          rescue JSON::ParserError, Encoding::UndefinedConversionError
            value
          end
        when Array
          value.compact.map { |item| item.respond_to?(:to_unsafe_h) ? item.to_unsafe_h : item }
        when ActionController::Parameters
          value.to_unsafe_h
        when NilClass
          nil
        else
          value
        end
      end
    end

    public

    def live_render(*args, **kwargs)
      if args.empty? && kwargs.key?(:state)
        # Simple format: live_render(state: { ... })
        handle_simple_render(kwargs[:state])
      else
        # Verbose format: live_render "path/to/partial", id: "my-id", state: { ... }
        handle_verbose_render(*args, **kwargs)
      end
    end

    private

    def handle_simple_render(state)
      Rails.logger.debug "LIVE_RENDER STATE: #{state.inspect}"

      if params[:_resource_type].present? && params[:_resource_id].present?
        begin
          resource_class = params[:_resource_type].classify.constantize
          @resource = resource_class.find(params[:_resource_id])
          instance_variable_set("@#{params[:_resource_type]}", @resource)
        rescue NameError, ActiveRecord::RecordNotFound => e
          Rails.logger.error "LivePartial Resource Error: #{e.message}"
          @resource = nil
        end
      end

      system_params = %w[
        controller action _live_partial_name _live_partial_id
        _resource_type _resource_id format authenticity_token
      ]

      begin
        filtered_state = params.to_unsafe_h.deep_dup.except(*system_params)
        parsed_state = parse_state(state)
        final_state = to_ostruct(parsed_state || filtered_state)

        rendered_html = render_to_string(
          partial: params[:_live_partial_name],
          locals: {
            **final_state.to_h,
            id: params[:_live_partial_id],
            resource: @resource
          }
        )

        ActionCable.server.broadcast(
          "live_partial_#{params[:_live_partial_id]}",
          { html: rendered_html }
        )

        render inline: rendered_html
      rescue StandardError => e
        Rails.logger.error "LivePartial Error: #{e.message}"
        rendered_html = render_to_string(
          partial: params[:_live_partial_name],
          locals: {
            id: params[:_live_partial_id],
            resource: @resource
          }
        )
        render inline: rendered_html
      end
    end

    def handle_verbose_render(partial_name_or_options, options = {})
      if partial_name_or_options.is_a?(String)
        options = {
          partial: partial_name_or_options,
          **options
        }
      else
        options = partial_name_or_options
      end

      raise ArgumentError, "live_render requires an :id option" unless options[:id].present?
      raise ArgumentError, "live_render requires a :partial option" unless options[:partial].present?

      if options[:for].present?
        resource = options[:for]
        instance_variable_set("@#{resource.class.name.underscore}", resource)
      end

      state = options[:state] || {}
      parsed_state = parse_state(state)
      final_state = to_ostruct(parsed_state)

      rendered_html = render_to_string(
        partial: options[:partial],
        locals: {
          **final_state.to_h,
          id: options[:id],
          resource: options[:for],
          data: {
            live_partial: true,
            partial_name: options[:partial],
            state: state.to_json
          }
        }
      )

      ActionCable.server.broadcast(
        "live_partial_#{options[:id]}",
        { html: rendered_html }
      )

      render inline: rendered_html
    end
  end
end
