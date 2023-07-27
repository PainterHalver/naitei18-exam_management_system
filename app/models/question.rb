class Question < ApplicationRecord
  acts_as_paranoid
  belongs_to :subject
  belongs_to :subject_including_deleted, class_name: Subject.name,
             foreign_key: :subject_id, with_deleted: true
  belongs_to :creator, class_name: User.name, foreign_key: :user_id
  has_many :answers, dependent: :destroy
  has_many :test_questions, dependent: :destroy
  accepts_nested_attributes_for :answers,
                                reject_if: :all_blank,
                                allow_destroy: true

  delegate :name, to: :subject, prefix: true
  scope :newest, ->{order created_at: :desc}
  # tat ca la Subject.with_deleted
  scope :exclude_deleted_subject, ->{where subject_id: Subject.pluck(:id)}

  enum question_type: {single_choice: 0, multiple_choice: 1}

  validates :content, presence: true
  validates :question_type, presence: true, inclusion: {in: question_types.keys}
  validates_associated :answers
  # Toi thieu 2 lua chon
  validates :answers, length: {minimum: Settings.digit.length_2,
                               too_short: I18n.t("errors.minimum_answers")}
  validate :must_have_one_correct_answer
  validate :validate_single_type, if: :single_choice?
  validate :validate_multiple_type, if: :multiple_choice?

  private

  def must_have_one_correct_answer
    return if answers.map(&:is_correct).include? true

    errors.add :base, I18n.t("errors.must_have_one_correct_answer")
  end

  def validate_single_type
    # Toi da 1 dap an dung
    return if answers.select(&:is_correct).count <= 1

    errors.add :base, I18n.t("errors.must_have_exactly_one_correct_answer")
  end

  def validate_multiple_type
    # Toi thieu 2 dap an dung
    return if answers.select(&:is_correct).count >= 2

    errors.add :base, I18n.t("errors.must_have_at_least_two_correct_answers")
  end
end
