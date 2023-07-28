class Subject < ApplicationRecord
  acts_as_paranoid
  belongs_to :user, class_name: User.name
  has_many :tests, dependent: nil
  has_many :questions, dependent: nil
  has_one_attached :image

  scope :newest, ->{order created_at: :desc}

  validates :name, presence: true,
            uniqueness: {case_sensitive: false}
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

  def self.ransackable_associations _auth_object = nil
    %w(image_attachment image_blob questions tests user)
  end

  def self.ransackable_attributes _auth_object = nil
    %w(created_at deleted_at description id name
      pass_score question_amount test_duration updated_at user_id)
  end
end
