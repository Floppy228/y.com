class Post < ApplicationRecord
  belongs_to :user

  validates :content, presence: true, length: { maximum: 1000 }

  scope :recent, -> { includes(:user).order(created_at: :desc) }
end