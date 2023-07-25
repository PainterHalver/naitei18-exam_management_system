class Subject < ApplicationRecord
  acts_as_paranoid
  belongs_to :user, class_name: User.name
  has_many :tests, dependent: nil
  has_many :questions, dependent: nil
  has_one_attached :image

  scope :newest, ->{order created_at: :desc}

  validates :name, presence: true
  validates :description, presence: true
  validates :question_amount,
            presence: true,
            numericality: {greater_than_or_equal_to: Settings.digit.length_0}
  validates :pass_score,
            presence: true,
            numericality: {greater_than_or_equal_to: Settings.digit.length_0,
                           less_than_or_equal_to: Settings.digit.length_100}
  validates :test_duration,
            presence: true,
            numericality: {greater_than_or_equal_to: Settings.digit.length_0}
end
