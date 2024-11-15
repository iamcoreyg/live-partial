# live_partial.gemspec
require_relative "lib/live_partial/version"

Gem::Specification.new do |spec|
  spec.name        = "live_partial"
  spec.version     = LivePartial::VERSION
  spec.authors     = ["Corey Griffin"]
  spec.email       = ["your.email@example.com"]
  spec.summary     = "Real-time partial updates for Rails applications"
  spec.description = "LivePartial allows you to create dynamic, real-time updating partial views in your Rails application with minimal setup"
  spec.homepage    = "https://github.com/cgriffin/live_partial"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir[
    "lib/**/*",
    "app/**/*",
    "config/**/*",
    "README.md",
    "Rakefile",
    "live_partial.gemspec"
  ]

  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 6.1", "< 8.0"
  spec.add_dependency "actioncable", ">= 6.1", "< 8.0"

  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
end
