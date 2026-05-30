class DirectMessage < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  validates :content, presence: true

  scope :between, lambda { |first_user, second_user|
    where(sender: first_user, recipient: second_user)
      .or(where(sender: second_user, recipient: first_user))
      .order(:created_at)
  }

  scope :unread, -> { where(read_at: nil) }

  scope :unread_for, ->(user) { where(recipient: user, read_at: nil) }
end
