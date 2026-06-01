class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"

  validates :status, inclusion: { in: %w[pending accepted] }
  validates :user_id, uniqueness: { scope: :friend_id, message: "уже отправлен запрос" }
end
