class User < ApplicationRecord
  has_many :subjects, dependent: :destroy
  has_many :tests, dependent: :destroy

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  attr_accessor :remember_token, :activation_token, :reset_token

  before_save :downcase_email

  validates :name,
            presence: true,
            length: {maximum: Settings.digit.length_30}
  validates :email,
            presence: true,
            length: {minimum: Settings.digit.length_10,
                     maximum: Settings.digit.length_255},
            format: {with: VALID_EMAIL_REGEX},
            uniqueness: {case_sensitive: false}
  validates :password,
            presence: true,
            length: {minimum: Settings.digit.length_6},
            allow_nil: true
  has_secure_password

  class << self
    def digest string
      cost = if ActiveModel::SecurePassword.min_cost
               BCrypt::Engine::MIN_COST
             else
               BCrypt::Engine.cost
             end
      BCrypt::Password.create string, cost: cost
    end

    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  private

  def downcase_email
    email.downcase!
  end
end
