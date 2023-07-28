class User < ApplicationRecord
  has_many :subjects, dependent: :destroy
  has_many :tests, dependent: :destroy
  has_many :questions, dependent: :destroy

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  attr_accessor :remember_token, :reset_token

  scope :newest, ->{order created_at: :desc}
  scope :supervisors, ->{where is_supervisor: true}

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

    def ransackable_attributes _auth_object
      %w(id name email activated created_at)
    end

    def ransackable_associations _auth_object
      []
    end
  end

  def authenticated? attribute, token
    digest = send "#{attribute}_digest"
    return false if !token || !digest

    BCrypt::Password.new(digest).is_password? token
  end

  def activate
    send_activation_email if activated_at.nil?
    update_columns activated: true, activated_at: Time.zone.now
  end

  def deactivate
    update_columns activated: false
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_columns reset_digest: User.digest(reset_token),
                   reset_send_at: Time.zone.now
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_send_at < 10.minutes.ago
  end

  private

  def downcase_email
    email.downcase!
  end
end
