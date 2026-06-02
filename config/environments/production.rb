require "active_support/core_ext/integer/time"
require Rails.root.join("config/env_file").to_s

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  # кеш для статики на год вперёд (файлы с digest в имени)
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.active_storage.service = :local
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up" # не засорять логи проверками /up
  config.active_support.report_deprecations = false
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
  config.action_mailer.default_url_options = { host: "150.241.123.201" }
  # SMTP из .env — для отправки писем через внешний сервер
  config.action_mailer.smtp_settings = {
    address: EnvFile.fetch("SMTP_ADDRESS"),
    port: EnvFile.fetch("SMTP_PORT").to_i,
    domain: EnvFile.fetch("SMTP_DOMAIN"),
    user_name: EnvFile.fetch("SMTP_USERNAME"),
    password: EnvFile.fetch("SMTP_PASSWORD"),
    authentication: EnvFile.fetch("SMTP_AUTHENTICATION").presence || "plain",
    enable_starttls_auto: EnvFile.fetch("SMTP_ENABLE_STARTTLS_AUTO") == "true"
  }
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
end
