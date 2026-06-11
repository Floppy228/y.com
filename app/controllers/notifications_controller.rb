class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.recent.includes(:actor, :notifiable)
    if current_user.notifications.unread.any?
      current_user.notifications.unread.update_all(read_at: Time.current)
      @total_unread_notifications = 0
      broadcast_notification_badge(current_user)
    end
  end

  def mark_read
    if current_user.notifications.unread.any?
      current_user.notifications.unread.update_all(read_at: Time.current)
      broadcast_notification_badge(current_user)
    end
    head :ok
  end
end
