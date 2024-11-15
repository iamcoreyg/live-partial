# lib/live_partial.rb
require "active_support"
require "action_cable"
require "live_partial/version"
require "live_partial/controller"
require "live_partial/helper"
require "live_partial/updates_channel"
require "live_partial/engine"

module LivePartial
  class Error < StandardError; end
end
