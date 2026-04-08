class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :content, presence: true, length: { maximum: 500 }

  scope :recent, -> { includes(:user).order(created_at: :asc) }
end
