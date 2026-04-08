class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { member: 0, admin: 1 }, default: :member

  has_many :posts, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 80 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :username,
            presence: true,
            length: { minimum: 3, maximum: 30 },
            format: { with: /\A[a-zA-Z0-9_]+\z/, message: "может содержать только буквы, цифры и _" },
            uniqueness: { case_sensitive: false }
  validates :bio, length: { maximum: 160 }, allow_blank: true

  before_validation :normalize_username
  before_validation :normalize_email
  before_validation :set_default_profile_values, on: :create

  def posts_count
    posts.count
  end

  def followers_count
    0
  end

  def following_count
    0
  end

  private

  def normalize_username
    self.username = username.to_s.delete_prefix("@").strip.downcase.presence
  end

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def set_default_profile_values
    self.bio = nil if bio.blank?
  end
end
