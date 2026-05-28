class AiMessage < ApplicationRecord
  belongs_to :user

  ROLES = %w[user assistant].freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true
end
