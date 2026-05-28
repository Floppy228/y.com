require Rails.root.join("config/env_file").to_s

class ApplicationMailer < ActionMailer::Base
  default from: EnvFile.fetch("MAILER_FROM_EMAIL").presence || "no-reply@example.com"
  layout "mailer"
end
