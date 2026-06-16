source "https://rubygems.org"

# ядро
gem "rails", "~> 8.1.3"
gem "propshaft"       # пайплайн для стилей/скриптов
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"  # веб-сервер
gem "importmap-rails" # доставка JS без Webpack
gem "turbo-rails"     # Hotwire — обновления страницы без полной перезагрузки
gem "stimulus-rails"  # Hotwire — реакция на события в HTML
gem "jbuilder"        # JSON-шаблоны
gem "rails-i18n"      # русские переводы для дат и расстояний (например, "5 минут назад")
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Solid — база данных вместо Redis для кеша, очередей и WebSockets
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false # ускорение загрузки
gem "kamal", require: false    # деплой через Docker
gem "thruster", require: false # проксирование статики
gem "image_processing", "~> 2.0"
gem 'pg', '~> 1.5'            # PostgreSQL для продакшена

gem "devise"           # аутентификация
gem "tailwindcss-rails" # CSS-фреймворк

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false  # проверка уязвимостей в гемах
  gem "brakeman", require: false       # статический анализатор безопасности
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console" # интерактивная консоль на странице ошибки
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
