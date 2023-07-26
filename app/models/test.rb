class Test < ApplicationRecord
  belongs_to :subject, with_deleted: true
  belongs_to :user
  has_many :test_questions, dependent: :destroy
  has_many :questions, through: :test_questions
  scope :newest, ->{order created_at: :desc}
  scope :completed,
        ->{where status: [:passed, :failed]}
  scope :progressing, ->{where status: :doing}
  enum status: {doing: 0, passed: 1, failed: 2}

  validates :status,
            inclusion: {in: statuses.keys}
  validates :score,
            numericality: {greater_than_or_equal_to: 0,
                           less_than_or_equal_to:
                           ->(record){record.subject.question_amount}}
  validates :remaining_time, presence: true,
            numericality: {less_than_or_equal_to:
                          ->(record){record.subject.test_duration}}
  validates :start_time, presence: true
  validate :start_before_end

  private

  def start_before_end
    return unless start_time && end_time && start_time >= end_time

    message = I18n.t("activerecord.validates.start_before_end")
    errors.add(:start_time, message)
  end
end
