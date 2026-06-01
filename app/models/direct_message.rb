class DirectMessage < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  has_one_attached :image

  validates :content, presence: true, unless: -> { image.attached? }

  scope :between, lambda { |first_user, second_user|
    where(sender: first_user, recipient: second_user)
      .or(where(sender: second_user, recipient: first_user))
      .order(:created_at)
  }

  scope :unread, -> { where(read_at: nil) }

  scope :unread_for, ->(user) { where(recipient: user, read_at: nil) }

  after_create_commit :broadcast_new_message, unless: -> { content.blank? && !image.attached? }

  private

  def broadcast_new_message
    recipient_stream = "messages_user_#{recipient_id}"
    sender_stream = "messages_user_#{sender_id}"

    # Append message to recipient's chat
    broadcast_append_to recipient_stream,
      target: "messages",
      partial: "direct_messages/message",
      locals: { message: self, current_user: recipient }

    # Append message to sender's chat too
    broadcast_append_to sender_stream,
      target: "messages",
      partial: "direct_messages/message",
      locals: { message: self, current_user: sender }

    # Update unread badge for recipient
    unread_count = DirectMessage.unread_for(recipient).count
    badge_html = ApplicationController.render(partial: "layouts/unread_badge", locals: { count: unread_count })
    broadcast_replace_to recipient_stream, target: "unread-badge", html: badge_html
  rescue StandardError => e
    Rails.logger.error "=== Broadcast failed: #{e.message} ==="
  end
end
