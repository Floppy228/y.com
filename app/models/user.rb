class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :ai_messages, dependent: :destroy

  validates :name, presence: true
  validates :username, presence: true, uniqueness: true
end
