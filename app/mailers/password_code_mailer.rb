class PasswordCodeMailer < ApplicationMailer
  def change_password_code(user, code)
    @user = user
    @code = code

    mail(to: user.email, subject: "Код для смены пароля Y.com")
  end
end
