require Rails.root.join("config/env_file").to_s

# настройки Devise — аутентификация пользователей
Devise.setup do |config|
  # от кого приходят письма (сброс пароля и т.д.)
  config.mailer_sender = EnvFile.fetch("MAILER_FROM_EMAIL").presence || "no-reply@example.com"
  require 'devise/orm/active_record'
  config.case_insensitive_keys = [:email]        # email не чувствителен к регистру
  config.strip_whitespace_keys = [:email]         # обрезать пробелы у email
  config.skip_session_storage = [:http_auth]      # не хранить HTTP-авторизацию в сессии
  config.stretches = Rails.env.test? ? 1 : 12     # сколько раз хешировать пароль (в тестах 1, в остальном 12)
  config.reconfirmable = true                     # подтверждать новый email при смене
  config.expire_all_remember_me_on_sign_out = true # забывать всех при выходе
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours          # ссылка сброса пароля живет 6 часов
  config.sign_out_via = :delete                   # выход через DELETE-запрос
  config.responder.error_status = :unprocessable_content
  config.responder.redirect_status = :see_other
end
