class ApplicationController < ActionController::Base
  before_action :require_login, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_unread_counts

  allow_browser versions: :modern
  stale_when_importmap_changes

  protected

  def require_login
    redirect_to auth_path unless user_signed_in?
  end

  def set_unread_counts
    return unless user_signed_in?

    @total_unread_count = DirectMessage.unread_for(current_user).count
    @total_unread_notifications = Notification.unread.where(user: current_user).count
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :username])
  end

  def after_sign_in_path_for(_resource)
    root_path
  end

  def after_sign_up_path_for(_resource)
    root_path
  end
end
