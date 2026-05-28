class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :ai_messages, dependent: :destroy
  has_one_attached :avatar
  has_one_attached :cover_image

  validates :name, presence: true
  validates :username, presence: true, uniqueness: true
end
