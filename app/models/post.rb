class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  validates :content, presence: true, unless: -> { image.attached? }
  validates :content, length: { maximum: 500 }
end