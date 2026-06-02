require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module YCom
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.i18n.default_locale = :ru # язык по умолчанию — русский
  end
end
