# lib/live_partial/updates_channel.rb
module LivePartial
  class UpdatesChannel < ActionCable::Channel::Base  # Change this line
    def subscribed
      stream_from "live_partial_#{params[:partial_id]}"
    end

    def unsubscribed
      stop_all_streams
    end
  end
end
