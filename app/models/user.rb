class User < ApplicationRecord
  MESSAGE_SEND_SHORTCUTS = %w[enter ctrl_enter].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :ai_messages, dependent: :destroy
  has_many :sent_direct_messages, class_name: "DirectMessage", foreign_key: :sender_id, dependent: :destroy
  has_many :received_direct_messages, class_name: "DirectMessage", foreign_key: :recipient_id, dependent: :destroy
  has_one_attached :avatar
  has_one_attached :cover_image

  validates :name, presence: true
  validates :username, presence: true, uniqueness: true
  validates :message_send_shortcut, presence: true, inclusion: { in: MESSAGE_SEND_SHORTCUTS }
end
