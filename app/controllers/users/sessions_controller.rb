class Users::SessionsController < Devise::SessionsController
  def create
    username = params.dig(:user, :username).to_s.strip.downcase
    password = params.dig(:user, :password).to_s
    self.resource = User.find_by("LOWER(username) = ?", username)

    if resource&.valid_password?(password)
      if resource.banned?
        sign_out if user_signed_in?
        reason = resource.ban_reason.presence || "Причина не указана"
        redirect_to auth_path(auth_mode: "login"), alert: "Ваш аккаунт заблокирован. Причина: #{reason}"
        return
      end
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      redirect_to after_sign_in_path_for(resource)
    else
      redirect_to auth_path(auth_mode: "login"), alert: "Invalid login or password."
    end
  end
end
