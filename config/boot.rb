ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"       # подключает все гемы из Gemfile
require "bootsnap/setup"      # кеширует загрузку, чтобы рельсы стартовали быстрее
