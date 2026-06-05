class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_badge

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current)
  end

  private

  def broadcast_badge
    count = Notification.unread.where(user: user).count
    badge_html = if count > 0
      "<span class=\"flex h-6 min-w-[24px] items-center justify-center rounded-full bg-indigo-500 px-1.5 text-xs font-bold text-white\">#{count}</span>"
    else
      ""
    end
    Turbo::StreamsChannel.broadcast_update_to "notifications_user_#{user_id}", target: "notification-badge", html: badge_html
  rescue StandardError => e
    Rails.logger.error "Notification broadcast failed: #{e.message}"
  end
end
