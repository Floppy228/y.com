class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :sign_out_on_auth_page, if: :devise_controller?

  protected

  def after_sign_in_path_for(resource)
    root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def after_sign_up_path_for(resource)
    root_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :username, :bio])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :username, :bio])
  end

  def sign_out_on_auth_page
    return unless controller_name == "sessions" && action_name == "new"
    return unless request.path == new_user_session_path

    sign_out(:user) if user_signed_in?
  end
end
