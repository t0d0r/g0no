require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module G0no
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # The UI is in Bulgarian and English; the locale follows Accept-Language.
    config.i18n.available_locales = [ :en, :bg ]
    config.i18n.default_locale = :en

    # Attachments are served by NotesController#download_file, which requires
    # sign-in. Active Storage's own routes would serve them without it.
    config.active_storage.draw_routes = false
    # Attachments are downloaded as-is; no image variants are generated.
    config.active_storage.variant_processor = :disabled

    # Sign-up by anyone (Devise registrations). Closed in production unless
    # REGISTRATION_OPEN=true; administrators create users at /admin.
    config.x.registration_open =
      ENV.fetch("REGISTRATION_OPEN") { Rails.env.production? ? "false" : "true" } == "true"
  end
end
