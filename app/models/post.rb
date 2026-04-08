class Post < ApplicationRecord
  belongs_to :user

  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :content, presence: true, length: { maximum: 1000 }

  scope :recent, -> { includes(:user, :likes, comments: :user).order(created_at: :desc) }

  def liked_by?(user)
    return false unless user

    likes.exists?(user: user)
  end

  def likes_count
    likes.count
  end

  def comments_count
    comments.count
  end
end