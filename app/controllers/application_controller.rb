class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  allow_browser versions: :modern

  stale_when_importmap_changes

  protected

  def authenticate_user!
    redirect_to auth_path unless user_signed_in?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :username])
  end
end