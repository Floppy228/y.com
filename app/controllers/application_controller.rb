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

  def excluded_user_ids
    return [] unless user_signed_in?

    blocker_ids = current_user.blocks_as_blocker.select(:blocked_id)
    blocked_by_ids = current_user.blocks_as_blocked.select(:blocker_id)
    [blocker_ids, blocked_by_ids].flatten
  end

  def create_notification(user:, actor:, notifiable:, action:)
    Notification.create!(user: user, actor: actor, notifiable: notifiable, action: action)
  end

  def broadcast_unread_badge(recipient)
    unread_count = DirectMessage.unread_for(recipient).count
    badge_html = render_to_string(partial: "layouts/unread_badge", locals: { count: unread_count })
    Turbo::StreamsChannel.broadcast_replace_to "messages_user_#{recipient.id}", target: "unread-badge", html: badge_html
  end

  def broadcast_notification_badge(user)
    count = Notification.unread.where(user: user).count
    badge_html = count > 0 ? render_to_string(partial: "layouts/unread_badge", locals: { count: count }) : ""
    Turbo::StreamsChannel.broadcast_replace_to "notifications_user_#{user.id}", target: "notification-badge", html: badge_html
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
