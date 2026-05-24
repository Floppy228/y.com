class Post < ApplicationRecord
  belongs_to :user          # пост принадлежит пользователю
  validates :content, presence: true, length: { maximum: 500 }
end