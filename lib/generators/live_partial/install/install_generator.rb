# lib/generators/live_partial/install/install_generator.rb
module LivePartial
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      desc "Install LivePartial JavaScript files and configuration"

      def create_javascript_files
        if defined?(Webpacker)
          install_webpacker
        elsif defined?(Importmap)
          install_importmap
        else
          say "Neither Webpacker nor Importmap detected. Please manually include the JavaScript files.", :red
        end
      end

      def create_directories
        empty_directory "app/javascript/live_partial"
      end

      private

      def install_webpacker
        # Copy JavaScript files
        copy_file "consumer.js", "app/javascript/live_partial/consumer.js"
        copy_file "index.js", "app/javascript/live_partial/index.js"

        # Add to application.js pack
        append_to_file "app/javascript/packs/application.js" do
          "\nimport 'live_partial'\n"
        end

        say "Added LivePartial files to Webpacker configuration", :green
      end

      def install_importmap
        # Copy JavaScript files to app directory
        copy_file "consumer.js", "app/javascript/live_partial/consumer.js"
        copy_file "index.js", "app/javascript/live_partial/index.js"

        # Add importmap pins
        append_to_file "config/importmap.rb" do
          <<~RUBY

            # LivePartial
            pin "live_partial", to: "live_partial/index.js"
            pin "live_partial/consumer", to: "live_partial/consumer.js"
            pin "@rails/actioncable", to: "actioncable.esm.js"
          RUBY
        end

        say "Added LivePartial pins to importmap.rb", :green
      end
    end
  end
end
