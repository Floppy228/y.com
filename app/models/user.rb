class User < ApplicationRecord
  MESSAGE_SEND_SHORTCUTS = %w[enter ctrl_enter].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :ai_messages, dependent: :destroy
  has_many :sent_direct_messages, class_name: "DirectMessage", foreign_key: :sender_id, dependent: :destroy
  has_many :received_direct_messages, class_name: "DirectMessage", foreign_key: :recipient_id, dependent: :destroy
  has_one_attached :avatar
  has_one_attached :cover_image

  # Friendships
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships, source: :friend
  has_many :inverse_friendships, class_name: "Friendship", foreign_key: :friend_id, dependent: :destroy
  has_many :inverse_friends, through: :inverse_friendships, source: :user

  # Notifications
  has_many :notifications, dependent: :destroy
  has_many :acted_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :destroy

  validates :name, presence: true
  validates :username, presence: true, uniqueness: true
  validates :message_send_shortcut, presence: true, inclusion: { in: MESSAGE_SEND_SHORTCUTS }

  def friend_with?(user)
    friendships.exists?(friend: user, status: "accepted") ||
      inverse_friendships.exists?(user: user, status: "accepted")
  end

  def pending_friend_request_from?(user)
    inverse_friendships.exists?(user: user, status: "pending")
  end

  def pending_friend_request_to?(user)
    friendships.exists?(friend: user, status: "pending")
  end

  def friendship_status_with(user)
    return "self" if user == self
    return "accepted" if friend_with?(user)
    return "pending_from" if pending_friend_request_from?(user)
    return "pending_to" if pending_friend_request_to?(user)
    "none"
  end
end
